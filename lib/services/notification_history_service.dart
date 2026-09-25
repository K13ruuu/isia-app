import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Stream of all announcements, newest first
  Stream<QuerySnapshot> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Stream of IDs of announcements this user has read
  Stream<QuerySnapshot> getReadIds() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('notification_reads')
        .doc(uid)
        .collection('read')
        .snapshots();
  }

  // Mark one announcement as read
  Future<void> markAsRead(String announcementId) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore
        .collection('notification_reads')
        .doc(uid)
        .collection('read')
        .doc(announcementId)
        .set({'readAt': FieldValue.serverTimestamp()});
  }

  // Mark many as read at once
  Future<void> markManyAsRead(List<String> announcementIds) async {
    final uid = _uid;
    if (uid == null || announcementIds.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in announcementIds) {
      final ref = _firestore
          .collection('notification_reads')
          .doc(uid)
          .collection('read')
          .doc(id);
      batch.set(ref, {'readAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }
}