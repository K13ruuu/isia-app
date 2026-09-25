import 'package:cloud_firestore/cloud_firestore.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> addContact({
    required String name,
    required String role,
    required String phone,
    required String email,
  }) async {
    try {
      await _firestore.collection('contacts').add({
        'name': name,
        'role': role,
        'phone': phone,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to add contact: $e';
    }
  }

  Stream<QuerySnapshot> getContacts() {
    return _firestore
        .collection('contacts')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> deleteContact(String docId) async {
    await _firestore.collection('contacts').doc(docId).delete();
  }
}