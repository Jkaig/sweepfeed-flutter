import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/contest.dart';
import '../../../core/utils/logger.dart';

/// Tracks incomplete contest entries when users click external links
/// but don't complete the entry process
class IncompleteEntryTracker {
  IncompleteEntryTracker._();
  static final IncompleteEntryTracker _instance = IncompleteEntryTracker._();
  factory IncompleteEntryTracker() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Track when user clicks to enter a contest (opens external link)
  Future<void> trackEntryAttempt(String contestId, String contestTitle) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('incompleteEntries')
          .doc(contestId)
          .set({
        'contestId': contestId,
        'contestTitle': contestTitle,
        'attemptedAt': FieldValue.serverTimestamp(),
        'lastAttempt': FieldValue.serverTimestamp(),
        'attemptCount': FieldValue.increment(1),
        'status': 'incomplete',
      }, SetOptions(merge: true));

      logger.i('Tracked incomplete entry attempt: $contestId');
    } catch (e) {
      logger.e('Error tracking incomplete entry', error: e);
    }
  }

  /// Mark entry as completed (user confirms they finished)
  Future<void> markEntryCompleted(String contestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('incompleteEntries')
          .doc(contestId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      logger.i('Marked entry as completed: $contestId');
    } catch (e) {
      logger.e('Error marking entry as completed', error: e);
    }
  }

  /// Get all incomplete entries for the current user
  Future<List<Map<String, dynamic>>> getIncompleteEntries() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('incompleteEntries')
          .where('status', isEqualTo: 'incomplete')
          .orderBy('lastAttempt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      logger.e('Error getting incomplete entries', error: e);
      return [];
    }
  }

  /// Remove an incomplete entry
  Future<void> removeIncompleteEntry(String contestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('incompleteEntries')
          .doc(contestId)
          .delete();

      logger.i('Removed incomplete entry: $contestId');
    } catch (e) {
      logger.e('Error removing incomplete entry', error: e);
    }
  }
}
