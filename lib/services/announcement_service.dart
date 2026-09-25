import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> createAnnouncement({
    required String title,
    required String message,
    required String category,
    required String postedBy,
    required String postedByName,
    String targetSection = 'All',
  }) async {
    try {
      await _firestore.collection('announcements').add({
        'title': title.trim(),
        'message': message.trim(),
        'category': category,
        'postedBy': postedBy,
        'postedByName': postedByName,
        'targetSection': targetSection,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to post announcement: $e';
    }
  }

  Stream<QuerySnapshot> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getAnnouncementsForStudent(String section) {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String?> deleteAnnouncement(String docId) async {
    try {
      await _firestore.collection('announcements').doc(docId).delete();
      return null;
    } catch (e) {
      return 'Failed to delete announcement: $e';
    }
  }
}