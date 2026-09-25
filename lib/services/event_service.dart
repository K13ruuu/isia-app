import 'package:cloud_firestore/cloud_firestore.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> addEvent({
    required String title,
    required String description,
    required String location,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String postedBy,
    String targetSection = 'All',
  }) async {
    try {
      await _firestore.collection('events').add({
        'title': title,
        'description': description,
        'location': location,
        'date': Timestamp.fromDate(date),
        'startTime': startTime,
        'endTime': endTime,
        'postedBy': postedBy,
        'targetSection': targetSection,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to add event: $e';
    }
  }

  Stream<QuerySnapshot> getUpcomingEvents() {
    return _firestore
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots();
  }

  Future<void> deleteEvent(String docId) async {
    await _firestore.collection('events').doc(docId).delete();
  }
}