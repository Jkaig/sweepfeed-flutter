import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/contest.dart';
import '../../../core/services/dust_bunnies_service.dart';
import '../../../core/utils/logger.dart';
import '../../reminders/services/reminder_service.dart';

class EntryService {
  EntryService({
    required this.gamificationService,
    FirebaseFirestore? firestore,
    this.reminderService,
  }) : firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore firestore;
  final DustBunniesService gamificationService;
  final ReminderService? reminderService;

  Future<void> enterSweepstake(
    String userId,
    String contestId, {
    Contest? contest,
  }) async {
    final userRef = firestore.collection('users').doc(userId);
    final entryRef = firestore.collection('user_entries').doc();

    // Use a transaction to ensure atomicity
    await firestore.runTransaction((transaction) async {
      // 1. Record the new entry
      transaction.set(entryRef, {
        'userId': userId,
        'contestId': contestId,
        'entryDate': FieldValue.serverTimestamp(),
      });

      // 2. Update the user's stats
      transaction.update(userRef, {
        'contestsEntered': FieldValue.increment(1),
        'monthlyEntries': FieldValue.increment(1),
      });
    });

    // 3. Award DustBunnies for the entry (can happen outside the transaction)
    await gamificationService.awardDustBunnies(
      userId: userId,
      action: 'contest_entry',
    );

    // 4. Schedule contest end reminder notification
    if (reminderService != null && contest != null) {
      try {
        await reminderService!.scheduleContestEndReminder(contest);
      } catch (e) {
        // Silently fail if notification scheduling fails - don't block entry
        logger.e('Failed to schedule contest end reminder: $e');
      }
    }
  }

  Future<bool> hasEntered(String userId, String contestId) async {
    final querySnapshot = await firestore
        .collection('user_entries')
        .where('userId', isEqualTo: userId)
        .where('contestId', isEqualTo: contestId)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Stream<bool> hasEnteredStream(String userId, String contestId) => firestore
      .collection('user_entries')
      .where('userId', isEqualTo: userId)
      .where('contestId', isEqualTo: contestId)
      .limit(1)
      .snapshots()
      .map((snapshot) => snapshot.docs.isNotEmpty);

  /// Get all contest IDs that the user has entered (for efficient filtering)
  Future<Set<String>> getEnteredContestIds(String userId) async {
    try {
      final snapshot = await firestore
          .collection('user_entries')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['contestId'] as String)
          .toSet();
    } catch (e) {
      logger.e('Error getting entered contest IDs', error: e);
      return <String>{};
    }
  }
}
