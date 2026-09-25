import 'package:cloud_firestore/cloud_firestore.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, List<Map<String, dynamic>>>> searchAll({
    required String keyword,
    required String role,      // 'admin' or 'student'
    required String section,   // student's section (empty for teacher)
  }) async {
    final q = keyword.trim().toLowerCase();
    if (q.isEmpty) {
      return {
        'announcements': [],
        'schedules': [],
        'deadlines': [],
        'events': [],
        'contacts': [],
      };
    }

    final results = <String, List<Map<String, dynamic>>>{
      'announcements': [],
      'schedules': [],
      'deadlines': [],
      'events': [],
      'contacts': [],
    };

    // --- Announcements ---
    final annSnap = await _firestore.collection('announcements').get();
    for (final doc in annSnap.docs) {
      final data = doc.data();
      final title = (data['title'] ?? '').toString().toLowerCase();
      final message = (data['message'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();
      if (title.contains(q) || message.contains(q) || category.contains(q)) {
        results['announcements']!.add({...data, 'id': doc.id});
      }
    }

    // --- Schedules ---
    final schSnap = await _firestore.collection('schedules').get();
    for (final doc in schSnap.docs) {
      final data = doc.data();
      // students only see their own section
      if (role == 'student' && section.isNotEmpty) {
        if ((data['section'] ?? '') != section) continue;
      }
      final haystack = [
        data['subject'] ?? '',
        data['teacher'] ?? '',
        data['room'] ?? '',
        data['day'] ?? '',
        data['section'] ?? '',
      ].join(' ').toLowerCase();
      if (haystack.contains(q)) {
        results['schedules']!.add({...data, 'id': doc.id});
      }
    }

    // --- Deadlines ---
    final dlSnap = await _firestore.collection('deadlines').get();
    for (final doc in dlSnap.docs) {
      final data = doc.data();
      if (role == 'student' && section.isNotEmpty) {
        if ((data['section'] ?? '') != section) continue;
      }
      final haystack = [
        data['title'] ?? '',
        data['subject'] ?? '',
        data['type'] ?? '',
        data['description'] ?? '',
        data['section'] ?? '',
      ].join(' ').toLowerCase();
      if (haystack.contains(q)) {
        results['deadlines']!.add({...data, 'id': doc.id});
      }
    }

    // --- Events ---
    final evSnap = await _firestore.collection('events').get();
    for (final doc in evSnap.docs) {
      final data = doc.data();
      final haystack = [
        data['title'] ?? '',
        data['description'] ?? '',
        data['location'] ?? '',
      ].join(' ').toLowerCase();
      if (haystack.contains(q)) {
        results['events']!.add({...data, 'id': doc.id});
      }
    }

    // --- Contacts ---
    final ctSnap = await _firestore.collection('contacts').get();
    for (final doc in ctSnap.docs) {
      final data = doc.data();
      final haystack = [
        data['name'] ?? '',
        data['role'] ?? '',
        data['phone'] ?? '',
        data['email'] ?? '',
      ].join(' ').toLowerCase();
      if (haystack.contains(q)) {
        results['contacts']!.add({...data, 'id': doc.id});
      }
    }

    return results;
  }
}