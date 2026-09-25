import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Submit a check-in (multiple allowed)
  Future<String?> checkIn({
    required String mood,        // emoji
    required String moodLabel,   // 'Great', 'Good', etc.
    required String note,
    required String fullName,
    required String section,
  }) async {
    final uid = _uid;
    if (uid == null) return 'Not signed in.';

    try {
      await _firestore.collection('mood_checkins').add({
        'uid': uid,
        'fullName': fullName,
        'section': section,
        'mood': mood,
        'moodLabel': moodLabel,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to save check-in: $e';
    }
  }

  // The student's most recent check-in (to show "last check-in today")
  Stream<QuerySnapshot> getMyLatestCheckIn() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('mood_checkins')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots();
  }

  // All check-ins (teacher view), newest first
  Stream<QuerySnapshot> getAllCheckIns() {
    return _firestore
        .collection('mood_checkins')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();
  }
}