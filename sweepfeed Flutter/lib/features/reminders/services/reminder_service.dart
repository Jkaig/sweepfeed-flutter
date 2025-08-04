import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sweep_feed/core/models/contest_model.dart'; // Assuming Contest model path
import 'package:sweep_feed/core/models/reminder_model.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Reminder> _userRemindersRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('reminders')
        .withConverter<Reminder>(
          fromFirestore: (snapshots, _) => Reminder.fromFirestore(snapshots),
          toFirestore: (reminder, _) => reminder.toJson(),
        );
  }

  Future<void> addReminder(String userId, Contest contest, DateTime reminderDateTime) async {
    try {
      final reminder = Reminder(
        contestId: contest.id,
        reminderTimestamp: Timestamp.fromDate(reminderDateTime),
        createdAt: Timestamp.now(),
        contestTitle: contest.title,
        contestEndDate: Timestamp.fromDate(contest.endDate),
      );
      await _userRemindersRef(userId).doc(contest.id).set(reminder);
      debugPrint('Reminder added for contest ${contest.id}');
      await scheduleLocalNotification(reminder); // Call placeholder
    } catch (e) {
      debugPrint('Error adding reminder: $e');
      rethrow;
    }
  }

  Future<void> removeReminder(String userId, String contestId) async {
    try {
      await _userRemindersRef(userId).doc(contestId).delete();
      debugPrint('Reminder removed for contest $contestId');
      // TODO: Cancel local notification if one was scheduled
    } catch (e) {
      debugPrint('Error removing reminder: $e');
      rethrow;
    }
  }

  Future<bool> hasReminder(String userId, String contestId) async {
    try {
      final doc = await _userRemindersRef(userId).doc(contestId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking reminder: $e');
      return false;
    }
  }

  Future<Reminder?> getReminder(String userId, String contestId) async {
    try {
      final doc = await _userRemindersRef(userId).doc(contestId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Error getting reminder: $e');
      return null;
    }
  }

  Future<void> scheduleLocalNotification(Reminder reminder) async {
    // This is a placeholder for actual local notification scheduling logic
    debugPrint('Placeholder: Schedule local notification for ${reminder.contestTitle} at ${reminder.reminderTimestamp.toDate()}');
    // Example: await FlutterLocalNotificationsPlugin().zonedSchedule(...);
  }
}
