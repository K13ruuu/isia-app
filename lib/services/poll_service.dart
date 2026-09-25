import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PollService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<String?> createPoll({
    required String question,
    required List<String> options,
    required String postedBy,
    required String postedByName,
    String targetSection = 'All',
  }) async {
    if (question.trim().isEmpty || options.length < 2) {
      return 'Please enter a question and at least 2 options.';
    }

    final cleanOptions =
        options.map((o) => o.trim()).where((o) => o.isNotEmpty).toList();

    if (cleanOptions.length < 2) {
      return 'Please fill at least 2 options.';
    }

    try {
      await _firestore.collection('polls').add({
        'question': question.trim(),
        'options': cleanOptions,
        'isOpen': true,
        'postedBy': postedBy,
        'postedByName': postedByName,
        'targetSection': targetSection,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to create poll: $e';
    }
  }

  Stream<QuerySnapshot> getAllPolls() {
    return _firestore
        .collection('polls')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Stream<QuerySnapshot> getVotes(String pollId) {
    return _firestore
        .collection('polls')
        .doc(pollId)
        .collection('poll_votes')
        .snapshots();
  }

  Future<String?> submitVote({
    required String pollId,
    required int optionIndex,
  }) async {
    final uid = _uid;
    if (uid == null) return 'Not signed in.';

    try {
      await _firestore
          .collection('polls')
          .doc(pollId)
          .collection('poll_votes')
          .doc(uid)
          .set({
        'optionIndex': optionIndex,
        'votedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to submit vote: $e';
    }
  }

  Future<int?> getMyVote(String pollId) async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final doc = await _firestore
          .collection('polls')
          .doc(pollId)
          .collection('poll_votes')
          .doc(uid)
          .get();

      if (doc.exists) {
        return (doc.data()?['optionIndex'] as num?)?.toInt();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> togglePollStatus(String pollId, bool isOpen) async {
    await _firestore.collection('polls').doc(pollId).update({
      'isOpen': !isOpen,
    });
  }

  Future<void> deletePoll(String pollId) async {
    final votesSnap = await _firestore
        .collection('polls')
        .doc(pollId)
        .collection('poll_votes')
        .get();

    final batch = _firestore.batch();
    for (final doc in votesSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('polls').doc(pollId));
    await batch.commit();
  }
}