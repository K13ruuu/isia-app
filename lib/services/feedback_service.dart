import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit feedback (anonymous optional)
  Future<String?> submitFeedback({
    required String category,
    required String message,
    required bool anonymous,
    required String fullName,
    required String section,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Not signed in.';

    try {
      await _firestore.collection('feedback').add({
        'category': category,
        'message': message.trim(),
        'anonymous': anonymous,
        'uid': anonymous ? 'anonymous' : user.uid,
        'fullName': anonymous ? 'Anonymous' : fullName,
        'section': anonymous ? '' : section,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to send feedback: $e';
    }
  }

  // Stream of all feedback (teacher view), newest first
  Stream<QuerySnapshot> getAllFeedback() {
    return _firestore
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();
  }

  Future<void> deleteFeedback(String docId) async {
    await _firestore.collection('feedback').doc(docId).delete();
  }
}