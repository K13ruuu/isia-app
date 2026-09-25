import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper: convert "HH:MM" to minutes since midnight
  int _toMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  // Check if [newStart, newEnd) overlaps with any existing class
  // in the same section + day
  Future<String?> _findOverlap({
    required String section,
    required String day,
    required String startTime,
    required String endTime,
  }) async {
    final snap = await _firestore
        .collection('schedules')
        .where('section', isEqualTo: section)
        .where('day', isEqualTo: day)
        .get();

    final newStart = _toMinutes(startTime);
    final newEnd = _toMinutes(endTime);

    for (final doc in snap.docs) {
      final data = doc.data();
      final existingStart = _toMinutes(data['startTime'] ?? '00:00');
      final existingEnd = _toMinutes(data['endTime'] ?? '00:00');

      // Overlap: newStart < existingEnd && existingStart < newEnd
      if (newStart < existingEnd && existingStart < newEnd) {
        return 'This time slot is already taken for $section on $day '
            '(${data['subject']}, ${data['startTime']}-${data['endTime']}). '
            'Please choose a different time.';
      }
    }
    return null;
  }

  Future<String?> addClass({
    required String section,
    required String day,
    required String startTime,
    required String endTime,
    required String subject,
    required String teacher,
    required String room,
  }) async {
    // Validate start < end
    if (_toMinutes(startTime) >= _toMinutes(endTime)) {
      return 'End time must be after start time.';
    }

    // Check overlap
    final overlapError = await _findOverlap(
      section: section,
      day: day,
      startTime: startTime,
      endTime: endTime,
    );
    if (overlapError != null) return overlapError;

    try {
      await _firestore.collection('schedules').add({
        'section': section,
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
        'subject': subject,
        'teacher': teacher,
        'room': room,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to add class: $e';
    }
  }

  Stream<QuerySnapshot> getScheduleForSection(String section) {
    return _firestore
        .collection('schedules')
        .where('section', isEqualTo: section)
        .snapshots();
  }

  Future<void> deleteClass(String docId) async {
    await _firestore.collection('schedules').doc(docId).delete();
  }
}