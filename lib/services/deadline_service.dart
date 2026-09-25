import 'package:cloud_firestore/cloud_firestore.dart';

class DeadlineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> addDeadline({
    required String section,
    required String subject,
    required String title,
    required String type,
    required DateTime dueDate,
    required String description,
  }) async {
    try {
      await _firestore.collection('deadlines').add({
        'section': section,
        'subject': subject,
        'title': title,
        'type': type,
        'dueDate': Timestamp.fromDate(dueDate),
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to add deadline: $e';
    }
  }

  // Student view — filter by section only.
  // No .orderBy() so we avoid needing a Firestore composite index.
  // Sorting happens client-side in the screen.
  Stream<QuerySnapshot> getDeadlinesForSection(String section) {
    return _firestore
        .collection('deadlines')
        .where('section', isEqualTo: section)
        .snapshots();
  }

  // Teacher view — everything, sorted server-side by dueDate.
  // Single-field orderBy uses Firestore's automatic index.
  Stream<QuerySnapshot> getAllDeadlines() {
    return _firestore
        .collection('deadlines')
        .orderBy('dueDate', descending: false)
        .snapshots();
  }

  Future<void> deleteDeadline(String docId) async {
    await _firestore.collection('deadlines').doc(docId).delete();
  }
}