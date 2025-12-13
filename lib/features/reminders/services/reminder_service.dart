import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/models/contest.dart';
import '../../../core/services/feature_unlock_service.dart';
import '../../../core/utils/logger.dart';

/// A service to handle scheduling and managing local notifications for reminders.
class ReminderService {
  final FeatureUnlockService _unlockService;
  
  ReminderService(this._unlockService);

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initializes the notification service and sets up platform-specific
  /// configurations.
  Future<void> init() async {
    // Initialize timezone database
    initializeTimeZones();

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettingsIOS = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        // Handle notification tapped while app is in background or terminated
      },
    );

    await _createAndroidNotificationChannel();
  }

  /// Create Android notification channels (required for Android 8.0+)
  Future<void> _createAndroidNotificationChannel() async {
    const sweepstakeChannel = AndroidNotificationChannel(
      'sweepstake_reminder_channel', // id
      'Sweepstake Reminders', // title
      description:
          'Notifications to remind you to enter contests', // description
      importance: Importance.max,
    );

    const dailyChannel = AndroidNotificationChannel(
      'daily_reminder_channel', // id
      'Daily Reminders', // title
      description:
          'A single daily reminder for all your saved sweepstakes.', // description
      importance: Importance.high, // Changed from defaultImportance
    );

    final androidFlutterLocalNotificationsPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidFlutterLocalNotificationsPlugin
        ?.createNotificationChannel(sweepstakeChannel);
    await androidFlutterLocalNotificationsPlugin
        ?.createNotificationChannel(dailyChannel);
  }

  /// Requests notification permissions on iOS.
  /// This should be called before scheduling any notification.
  Future<void> requestIOSPermissions() async {
    try {
      final iosPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

        if (granted == true) {
          logger.i('iOS notification permissions granted');
        } else {
          logger.w('iOS notification permissions denied');
        }
      }
    } catch (e) {
      logger.e('Error requesting iOS permissions', error: e);
    }
  }

  /// Schedules a one-time reminder for a specific contest at a given time.
  Future<void> scheduleReminder(Contest contest, DateTime scheduledTime) async {
    await requestIOSPermissions();

    const androidDetails = AndroidNotificationDetails(
      'sweepstake_reminder_channel',
      'Sweepstake Reminders',
      channelDescription: 'Notifications to remind you to enter sweepstakes',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // Use stable ID based on contest ID to avoid hash collisions
      final notificationId = _generateStableId(contest.id, 'reminder');

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Sweepstake Reminder',
        "It's time to enter the ${contest.title} sweepstake again!",
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: contest.id,
      );

      logger.i('Scheduled reminder for contest: ${contest.id}');
    } catch (e) {
      logger.e('Error scheduling reminder for contest ${contest.id}', error: e);
      rethrow;
    }
  }

  /// Schedules a notification for when a contest is about to end.
  /// Notifies user 24 hours before the contest ends.
  Future<void> scheduleContestEndReminder(Contest contest) async {
    await requestIOSPermissions();

    final now = DateTime.now();
    final endDate = contest.endDate;
    final notifyTime = endDate.subtract(const Duration(hours: 24));

    // Only schedule if the notification time is in the future
    if (notifyTime.isAfter(now)) {
      const androidDetails = AndroidNotificationDetails(
        'sweepstake_reminder_channel',
        'Sweepstake Reminders',
        channelDescription: 'Notifications for contest endings',
        importance: Importance.max,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      try {
        // Use stable ID for end reminders
        final notificationId = _generateStableId(contest.id, 'end');

        await _notificationsPlugin.zonedSchedule(
          notificationId,
          'Contest Ending Soon! 🏆',
          "${contest.title} ends in 24 hours! Don't miss your chance to win ${contest.prize}!",
          tz.TZDateTime.from(notifyTime, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: contest.id,
        );

        logger.i('Scheduled end reminder for contest: ${contest.id}');
      } catch (e) {
        logger.e(
          'Error scheduling end reminder for contest ${contest.id}',
          error: e,
        );
        rethrow;
      }
    } else {
      logger.d(
        'Contest end reminder not scheduled. Notify time is in the past for contest: ${contest.id}',
      );
    }
  }

  /// Cancels a contest end reminder
  Future<void> cancelContestEndReminder(String contestId) async {
    try {
      final notificationId = _generateStableId(contestId, 'end');
      await _notificationsPlugin.cancel(notificationId);
      logger.i('Cancelled end reminder for contest: $contestId');
    } catch (e) {
      logger.e(
        'Error cancelling end reminder for contest $contestId',
        error: e,
      );
    }
  }

  /// Schedules a daily repeating notification based on user's settings.
  Future<void> scheduleDailyReminder(SharedPreferences prefs) async {
    try {
      final enabled = prefs.getBool('dailyReminderEnabled') ?? false;
      var timeString = prefs.getString('dailyReminderTime');

      if (enabled) {
        // Enforce default time if not unlocked (Smart/Custom Reminders)
        final isUnlocked = await _unlockService.hasUnlockedFeature('tool_daily_reminder');
        if (!isUnlocked) {
           // Default to 9:00 AM if locked, regardless of what's in prefs
           // Note: We don't overwrite prefs here to preserve user intent for when they unlock
           timeString = '09:00'; 
           logger.i('Daily Reminder locked: Enforcing default time 09:00');
        } else {
           // If unlocked, ensure we have a time, default to 9:00 if null
           timeString ??= '09:00';
        }
      
        // Validate time format
        if (!_isValidTimeFormat(timeString)) {
          logger.e('Invalid time format: $timeString');
          return;
        }

        final timeParts = timeString.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        // Validate hour and minute ranges
        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
          logger.e('Invalid time values: hour=$hour, minute=$minute');
          return;
        }

        // Generate stable ID based on time
        final notificationId = _generateDailyReminderId(hour, minute);

        await _notificationsPlugin.zonedSchedule(
          notificationId,
          'Your Daily Contests are Ready!',
          isUnlocked 
              ? 'Maximize your odds! Your custom entry time has arrived.' 
              : 'You have new daily contests to enter. Good luck!',
          _nextInstanceOfTime(hour, minute),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_reminder_channel',
              'Daily Reminders',
              channelDescription: 'A daily reminder for all your sweepstakes.',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        );

        logger.i(
          'Scheduled daily reminder for $hour:${minute.toString().padLeft(2, '0')}',
        );
      }
    } catch (e) {
      logger.e('Error scheduling daily reminder', error: e);
      rethrow;
    }
  }

  /// Cancels the daily repeating notification.
  Future<void> cancelDailyReminder(SharedPreferences prefs) async {
    try {
      final timeString = prefs.getString('dailyReminderTime');

      if (timeString != null && _isValidTimeFormat(timeString)) {
        final timeParts = timeString.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        final notificationId = _generateDailyReminderId(hour, minute);
        await _notificationsPlugin.cancel(notificationId);
        logger.i(
          'Cancelled daily reminder for $hour:${minute.toString().padLeft(2, '0')}',
        );
      } else {
        // Fallback: cancel all possible daily reminder IDs
        await _cancelAllDailyReminders();
      }
    } catch (e) {
      logger.e('Error cancelling daily reminder', error: e);
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Generate stable notification ID to avoid hash collisions
  int _generateStableId(String contestId, String type) {
    // Use a combination of contest ID hash and type to create stable IDs
    final contestHash = contestId.hashCode.abs();
    final typeHash = type.hashCode.abs();

    // Combine hashes in a way that minimizes collisions
    return (contestHash * 31 + typeHash) % 2147483647; // Max int value
  }

  /// Generate daily reminder ID based on time
  int _generateDailyReminderId(int hour, int minute) {
    // Use hour and minute to create unique ID (max 24*60 = 1440 possible values)
    return 1000000 +
        (hour * 60) +
        minute; // Offset to avoid collision with other IDs
  }

  /// Validate time format (HH:mm)
  bool _isValidTimeFormat(String timeString) {
    final regex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(timeString);
  }

  /// Cancel all possible daily reminder notifications (fallback)
  Future<void> _cancelAllDailyReminders() async {
    try {
      // Cancel reminders for all possible times (0:00 to 23:59)
      for (var hour = 0; hour < 24; hour++) {
        for (var minute = 0; minute < 60; minute += 15) {
          // Check every 15 minutes
          final id = _generateDailyReminderId(hour, minute);
          await _notificationsPlugin.cancel(id);
        }
      }
      logger.i('Cancelled all possible daily reminders');
    } catch (e) {
      logger.e('Error cancelling all daily reminders', error: e);
    }
  }

  /// Get all pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      logger.e('Error getting pending notifications', error: e);
      return [];
    }
  }

  /// Cancel a specific reminder by contest ID
  Future<void> cancelReminder(String contestId) async {
    try {
      final notificationId = _generateStableId(contestId, 'reminder');
      await _notificationsPlugin.cancel(notificationId);
      logger.i('Cancelled reminder for contest: $contestId');
    } catch (e) {
      logger.e('Error cancelling reminder for contest $contestId', error: e);
    }
  }
}
