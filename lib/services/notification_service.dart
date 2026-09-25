import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'isia_alerts_v2';
  static const String _channelName = 'ISIA Alerts';
  static const String _channelDescription =
      'Important school updates and alerts';

  Future<void> initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
    }
  }

  Future<bool> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<void> saveTokenForCurrentUser() async {
    try {
      String? token = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }

      if (token != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': token,
            'tokenUpdatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get FCM token: $e');
      }
    }
  }

  void listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _firestore.collection('users').doc(user.uid).update({
          'fcmToken': newToken,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<String?> sendNotificationToAllStudents({
    required String title,
    required String body,
    String targetSection = 'All',
  }) async {
    try {
      final serviceAccountJson =
          await rootBundle.loadString('assets/service-account.json');
      final serviceAccount = json.decode(serviceAccountJson);

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
      final client = await clientViaServiceAccount(credentials, scopes);

      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final projectId = serviceAccount['project_id'];
      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );

      int successCount = 0;
      int failCount = 0;

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        if (targetSection != 'All') {
          if ((data['section'] ?? '') != targetSection) continue;
        }

        final token = data['fcmToken'] as String?;
        if (token == null || token.isEmpty) {
          failCount++;
          continue;
        }

        // notification block → Android auto-displays when app is
        // background or closed. data block only carries channel_id
        // so we don't trigger a second display from our own code.
        final payload = {
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': {
              'channel_id': _channelId,
            },
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': _channelId,
                'sound': 'default',
                'default_vibrate_timings': true,
              },
            },
          },
        };

        final response = await client.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        );

        if (response.statusCode == 200) {
          successCount++;
        } else {
          failCount++;
          if (kDebugMode) {
            print('FCM error: ${response.body}');
          }
        }
      }

      client.close();
      return 'Sent: $successCount, Failed: $failCount';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Foreground-only: Android does not auto-display when app is open,
  // so this local display is the ONLY path — no duplication.
  void listenForForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) print('Foreground message: ${message.data}');

      final notification = message.notification;
      final title = notification?.title;
      final body = notification?.body;

      if (title != null && body != null) {
        _localNotifications.show(
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
          ),
        );
      }
    });
  }
}