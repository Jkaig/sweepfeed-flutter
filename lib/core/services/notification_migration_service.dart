import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class NotificationMigrationService {
  factory NotificationMigrationService() => _instance;
  NotificationMigrationService._internal();
  static final NotificationMigrationService _instance =
      NotificationMigrationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> migrateNotificationSettings(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (prefs.getBool('notification_settings_migrated_v2') == true) {
        logger.i('Notification settings already migrated for user: $userId');
        return;
      }

      logger.i('Starting notification settings migration for user: $userId');

      final settings = _getSharedPreferencesSettings(prefs);

      final firestoreSettings = _convertToFirestoreStructure(settings);

      await _firestore.collection('users').doc(userId).set(
            firestoreSettings,
            SetOptions(merge: true),
          );

      await prefs.setBool('notification_settings_migrated_v2', true);

      _cleanupOldKeys(prefs);

      logger.i(
        'Notification settings migration completed successfully for user: $userId',
      );
    } catch (e) {
      logger.e('Error migrating notification settings', error: e);
    }
  }

  Map<String, bool> _getSharedPreferencesSettings(SharedPreferences prefs) => {
        'new_contests': prefs.getBool('new_contests') ?? true,
        'ending_soon': prefs.getBool('ending_soon') ?? true,
        'high_value': prefs.getBool('high_value') ?? false,
        'winner_announcements': prefs.getBool('winner_announcements') ?? true,
        'weekly_digest': prefs.getBool('weekly_digest') ?? false,
        'promotional': prefs.getBool('promotional') ?? false,
        'security_alerts': prefs.getBool('security_alerts') ?? true,
      };

  Map<String, dynamic> _convertToFirestoreStructure(
    Map<String, bool> settings,
  ) =>
      {
        'notificationSettings': {
          'permissionStatus': 'notDetermined',
          'push': {
            'enabled': true,
            'types': {
              'newSweepstakes': settings['new_contests'] ?? true,
              'endingSoon': settings['ending_soon'] ?? true,
              'highValue': settings['high_value'] ?? false,
              'wins': settings['winner_announcements'] ?? true,
              'dailyDigest': false,
              'weeklyRoundup': settings['weekly_digest'] ?? false,
              'personalizedAlerts': false,
              'securityAlerts': settings['security_alerts'] ?? true,
            },
          },
          'email': {
            'enabled': true,
            'types': {
              'newSweeps': true,
              'weekly': false,
              'winners': false,
              'promotions': settings['promotional'] ?? false,
            },
          },
          'sms': {
            'enabled': false,
            'types': {
              'highValue': false,
              'endingSoon': false,
            },
          },
          'quietHours': {
            'enabled': false,
            'start': '22:00',
            'end': '08:00',
          },
          'preferences': {
            'sound': true,
            'vibration': true,
            'led': true,
            'lockScreen': true,
            'tone': 'Default',
            'priority': 'High',
          },
        },
      };

  Future<void> _cleanupOldKeys(SharedPreferences prefs) async {
    final keysToRemove = [
      'new_contests',
      'ending_soon',
      'high_value',
      'winner_announcements',
      'weekly_digest',
      'promotional',
      'security_alerts',
    ];

    for (final key in keysToRemove) {
      try {
        await prefs.remove(key);
      } catch (e) {
        logger.w('Could not remove old key: $key', error: e);
      }
    }

    logger.i('Old SharedPreferences keys cleaned up');
  }

  Future<bool> isMigrationNeeded(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notification_settings_migrated_v2') != true;
    } catch (e) {
      logger.e('Error checking migration status', error: e);
      return false;
    }
  }

  Future<void> forceMigration(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notification_settings_migrated_v2');
      await migrateNotificationSettings(userId);
    } catch (e) {
      logger.e('Error forcing migration', error: e);
    }
  }
}

final notificationMigrationService = NotificationMigrationService();
