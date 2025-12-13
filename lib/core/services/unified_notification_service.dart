import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/user_model.dart';
import '../utils/logger.dart';
import 'secure_token_service.dart';

/// Represents the permission status for receiving notifications.
enum NotificationPermissionStatus {
  /// The user has granted permission to send notifications.
  granted,

  /// The user has denied permission to send notifications.
  denied,

  /// The user has not yet been asked for permission.
  notDetermined,

  /// The user has permanently denied permission and cannot be asked again.
  permanentlyDenied,
}

/// Represents the type of notification being sent in the contests app.
enum NotificationType {
  /// Notification for a newly added contests or contest.
  newSweepstakes,

  /// Notification that a contests is ending soon.
  endingSoon,

  /// Notification for high-value contests worth entering.
  highValue,

  /// Notification that the user has won a contests.
  wins,

  /// Daily digest notification summarizing available contests.
  dailyDigest,

  /// Weekly roundup notification with contests highlights.
  weeklyRoundup,

  /// Personalized alerts based on user preferences and behavior.
  personalizedAlerts,

  /// Security alerts for account safety and authentication.
  securityAlerts,

  /// SMS-specific notification type.
  sms,
}

/// Represents the overall notification settings for a user.
///
/// This class encapsulates all notification preferences including push notifications,
/// email, SMS, quiet hours, and user preferences for the contests app.
class NotificationSettings {
  /// Creates a new [NotificationSettings] instance.
  ///
  /// [permissionStatus] The current notification permission status.
  /// [push] Settings for push notifications.
  /// [email] Settings for email notifications.
  /// [sms] Settings for SMS notifications.
  /// [quietHours] Settings for quiet hours when notifications are suppressed.
  /// [preferences] General user preferences for notifications.
  NotificationSettings({
    required this.permissionStatus,
    required this.push,
    required this.email,
    required this.sms,
    required this.quietHours,
    required this.preferences,
  });

  /// Creates a [NotificationSettings] object from Firestore document data.
  ///
  /// Parses the notification settings from the nested 'notificationSettings'
  /// field in the user document.
  factory NotificationSettings.fromFirestore(Map<String, dynamic> data) {
    final notifData =
        data['notificationSettings'] as Map<String, dynamic>? ?? {};

    return NotificationSettings(
      permissionStatus:
          _parsePermissionStatus(notifData['permissionStatus'] as String?),
      push: PushSettings.fromMap(
        notifData['push'] as Map<String, dynamic>? ?? {},
      ),
      email: EmailSettings.fromMap(
        notifData['email'] as Map<String, dynamic>? ?? {},
      ),
      sms: SmsSettings.fromMap(notifData['sms'] as Map<String, dynamic>? ?? {}),
      quietHours: QuietHoursSettings.fromMap(
        notifData['quietHours'] as Map<String, dynamic>? ?? {},
      ),
      preferences: PreferencesSettings.fromMap(
        notifData['preferences'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
  /// The current notification permission status for this user.
  final NotificationPermissionStatus permissionStatus;

  /// Settings specific to push notifications.
  final PushSettings push;

  /// Settings specific to email notifications.
  final EmailSettings email;

  /// Settings specific to SMS notifications.
  final SmsSettings sms;

  /// Settings for quiet hours when notifications should be suppressed.
  final QuietHoursSettings quietHours;

  /// General user preferences for notifications.
  final PreferencesSettings preferences;

  static NotificationPermissionStatus _parsePermissionStatus(String? status) {
    switch (status) {
      case 'granted':
        return NotificationPermissionStatus.granted;
      case 'denied':
        return NotificationPermissionStatus.denied;
      case 'permanentlyDenied':
        return NotificationPermissionStatus.permanentlyDenied;
      default:
        return NotificationPermissionStatus.notDetermined;
    }
  }

  /// Converts this [NotificationSettings] object to a Firestore-compatible map.
  ///
  /// Returns a map with a nested 'notificationSettings' field containing all
  /// notification preferences for storage in a user document.
  Map<String, dynamic> toFirestore() => {
        'notificationSettings': {
          'permissionStatus': permissionStatus.toString().split('.').last,
          'push': push.toMap(),
          'email': email.toMap(),
          'sms': sms.toMap(),
          'quietHours': quietHours.toMap(),
          'preferences': preferences.toMap(),
        },
      };
}

/// Settings specific to push notifications.
///
/// Controls which types of push notifications are enabled for the user.
class PushSettings {
  /// Creates a new [PushSettings] instance.
  ///
  /// [enabled] Whether push notifications are generally enabled.
  /// [types] Map of notification types to their enabled status.
  PushSettings({required this.enabled, required this.types});

  factory PushSettings.fromMap(Map<String, dynamic> map) => PushSettings(
        enabled: map['enabled'] as bool? ?? true,
        types: {
          'newSweepstakes': (map['types']?['newSweepstakes'] as bool?) ?? true,
          'endingSoon': (map['types']?['endingSoon'] as bool?) ?? true,
          'highValue': (map['types']?['highValue'] as bool?) ?? false,
          'wins': (map['types']?['wins'] as bool?) ?? true,
          'dailyDigest': (map['types']?['dailyDigest'] as bool?) ?? false,
          'weeklyRoundup': (map['types']?['weeklyRoundup'] as bool?) ?? false,
          'personalizedAlerts':
              (map['types']?['personalizedAlerts'] as bool?) ?? false,
          'securityAlerts': (map['types']?['securityAlerts'] as bool?) ?? true,
        },
      );
  final bool enabled;
  final Map<String, bool> types;

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'types': types,
      };
}

class EmailSettings {
  EmailSettings({required this.enabled, required this.types});

  factory EmailSettings.fromMap(Map<String, dynamic> map) => EmailSettings(
        enabled: map['enabled'] as bool? ?? true,
        types: {
          'newSweeps': (map['types']?['newSweeps'] as bool?) ?? true,
          'weekly': (map['types']?['weekly'] as bool?) ?? false,
          'winners': (map['types']?['winners'] as bool?) ?? false,
          'promotions': (map['types']?['promotions'] as bool?) ?? false,
        },
      );
  final bool enabled;
  final Map<String, bool> types;

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'types': types,
      };
}

class SmsSettings {
  SmsSettings({required this.enabled, required this.types});

  factory SmsSettings.fromMap(Map<String, dynamic> map) => SmsSettings(
        enabled: map['enabled'] as bool? ?? false,
        types: {
          'highValue': (map['types']?['highValue'] as bool?) ?? false,
          'endingSoon': (map['types']?['endingSoon'] as bool?) ?? false,
        },
      );
  final bool enabled;
  final Map<String, bool> types;

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'types': types,
      };
}

class QuietHoursSettings {
  QuietHoursSettings({
    required this.enabled,
    required this.start,
    required this.end,
  });

  factory QuietHoursSettings.fromMap(Map<String, dynamic> map) =>
      QuietHoursSettings(
        enabled: map['enabled'] as bool? ?? false,
        start: map['start'] as String? ?? '22:00',
        end: map['end'] as String? ?? '08:00',
      );
  final bool enabled;
  final String start;
  final String end;

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'start': start,
        'end': end,
      };
}

class PreferencesSettings {
  PreferencesSettings({
    required this.sound,
    required this.vibration,
    required this.led,
    required this.lockScreen,
    required this.tone,
    required this.priority,
  });

  factory PreferencesSettings.fromMap(Map<String, dynamic> map) =>
      PreferencesSettings(
        sound: map['sound'] as bool? ?? true,
        vibration: map['vibration'] as bool? ?? true,
        led: map['led'] as bool? ?? true,
        lockScreen: map['lockScreen'] as bool? ?? true,
        tone: map['tone'] as String? ?? 'Default',
        priority: map['priority'] as String? ?? 'High',
      );
  final bool sound;
  final bool vibration;
  final bool led;
  final bool lockScreen;
  final String tone;
  final String priority;

  Map<String, dynamic> toMap() => {
        'sound': sound,
        'vibration': vibration,
        'led': led,
        'lockScreen': lockScreen,
        'tone': tone,
        'priority': priority,
      };
}

class UnifiedNotificationService {
  factory UnifiedNotificationService() => _instance;
  UnifiedNotificationService._internal();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SecureTokenService _secureTokenService = secureTokenService;

  static final UnifiedNotificationService _instance =
      UnifiedNotificationService._internal();

  bool _initialized = false;

  Future<void> initialize(String userId) async {
    if (_initialized) return;

    try {
      // Validate userId to prevent path traversal attacks
      if (!_isValidUserId(userId)) {
        throw ArgumentError('Invalid userId format: $userId');
      }

      // Initialize secure token service
      await _secureTokenService.initialize();

      final permissionStatus = await checkPermissions();

      if (permissionStatus == NotificationPermissionStatus.granted) {
        await _saveToken(userId);
      }

      _messaging.onTokenRefresh
          .listen((newToken) => _handleTokenRefresh(userId, newToken));

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      await syncTopicSubscriptions(userId);

      _initialized = true;
      logger.i('UnifiedNotificationService initialized for user: $userId');
    } catch (e) {
      logger.e('Error initializing notification service', error: e);
      rethrow;
    }
  }

  Future<NotificationPermissionStatus> checkPermissions() async {
    try {
      final settings = await _messaging.getNotificationSettings();

      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          return NotificationPermissionStatus.granted;
        case AuthorizationStatus.denied:
          return NotificationPermissionStatus.denied;
        case AuthorizationStatus.notDetermined:
          return NotificationPermissionStatus.notDetermined;
        default:
          return NotificationPermissionStatus.denied;
      }
    } catch (e) {
      logger.e('Error checking notification permissions', error: e);
      return NotificationPermissionStatus.notDetermined;
    }
  }

  Future<NotificationPermissionStatus> requestPermissions() async {
    try {
      final settings = await _messaging.requestPermission();

      final status = _convertAuthStatus(settings.authorizationStatus);

      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _savePermissionStatus(userId, status);

        if (status == NotificationPermissionStatus.granted) {
          await _saveToken(userId);
          await syncTopicSubscriptions(userId);
        }
      }

      return status;
    } catch (e) {
      logger.e('Error requesting notification permissions', error: e);
      return NotificationPermissionStatus.denied;
    }
  }

  NotificationPermissionStatus _convertAuthStatus(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return NotificationPermissionStatus.granted;
      case AuthorizationStatus.denied:
        return NotificationPermissionStatus.denied;
      case AuthorizationStatus.notDetermined:
        return NotificationPermissionStatus.notDetermined;
      default:
        return NotificationPermissionStatus.denied;
    }
  }

  Future<void> _savePermissionStatus(
    String userId,
    NotificationPermissionStatus status,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'notificationSettings': {
            'permissionStatus': status.toString().split('.').last,
          },
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      logger.e('Error saving permission status', error: e);
    }
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      logger.e('Error getting FCM token', error: e);
      return null;
    }
  }

  Future<void> _saveToken(String userId) async {
    try {
      final token = await getToken();
      if (token == null) {
        logger.w('FCM token is null, skipping save');
        return;
      }

      // Use secure token storage instead of plaintext
      await _secureTokenService.storeSecureToken(
        userId: userId,
        fcmToken: token,
      );

      logger.i('FCM token securely saved for user: $userId');
    } catch (e) {
      logger.e('Error saving FCM token', error: e);
      rethrow;
    }
  }

  Future<void> _handleTokenRefresh(String userId, String newToken) async {
    try {
      // Validate inputs
      if (!_isValidUserId(userId)) {
        logger.e('Invalid userId in token refresh: $userId');
        return;
      }

      // Use secure token storage for refresh
      await _secureTokenService.storeSecureToken(
        userId: userId,
        fcmToken: newToken,
      );

      logger.i('FCM token securely refreshed for user: $userId');
    } catch (e) {
      logger.e('Error handling token refresh', error: e);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    logger.d('Foreground message received: ${message.messageId}');
    logger.d('Data: ${message.data}');

    if (message.notification != null) {
      logger.d(
        'Notification: ${message.notification!.title} - ${message.notification!.body}',
      );
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    logger.d('Background message received: ${message.messageId}');
    logger.d('Data: ${message.data}');
  }

  Future<void> deleteToken() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null && _isValidUserId(userId)) {
        // Use secure token deletion
        await _secureTokenService.deleteSecureToken(userId);
      }

      await _messaging.deleteToken();
      logger.i('FCM token securely deleted');
    } catch (e) {
      logger.e('Error deleting FCM token', error: e);
      rethrow;
    }
  }

  Future<NotificationSettings> getSettings(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data() ?? {};
      return NotificationSettings.fromFirestore(data);
    } catch (e) {
      logger.e('Error getting notification settings', error: e);
      return NotificationSettings.fromFirestore({});
    }
  }

  Future<void> updateSettings(
    String userId,
    NotificationSettings settings,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).set(
            settings.toFirestore(),
            SetOptions(merge: true),
          );

      await syncTopicSubscriptions(userId);

      logger.i('Notification settings updated for user: $userId');
    } catch (e) {
      logger.e('Error updating notification settings', error: e);
      rethrow;
    }
  }

  Future<void> syncTopicSubscriptions(String userId) async {
    try {
      final settings = await getSettings(userId);

      if (!settings.push.enabled) {
        await _unsubscribeFromAllTopics();
        return;
      }

      for (final entry in settings.push.types.entries) {
        final topic = entry.key;
        final enabled = entry.value;

        if (enabled) {
          await _messaging.subscribeToTopic(topic);
          logger.d('Subscribed to topic: $topic');
        } else {
          await _messaging.unsubscribeFromTopic(topic);
          logger.d('Unsubscribed from topic: $topic');
        }
      }
    } catch (e) {
      logger.e('Error syncing topic subscriptions', error: e);
    }
  }

  Future<void> _unsubscribeFromAllTopics() async {
    final topics = [
      'newSweepstakes',
      'endingSoon',
      'highValue',
      'wins',
      'dailyDigest',
      'weeklyRoundup',
      'personalizedAlerts',
      'securityAlerts',
    ];

    for (final topic in topics) {
      try {
        await _messaging.unsubscribeFromTopic(topic);
      } catch (e) {
        logger.w('Error unsubscribing from topic $topic: $e');
      }
    }
  }

  Future<bool> canReceiveNotificationType(
    String userId,
    NotificationType type,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData == null) return false;

      final user = UserProfile.fromFirestore(userDoc);
      final isPremium = _isPremiumUser(user);

      final premiumOnlyTypes = [
        NotificationType.highValue,
        NotificationType.dailyDigest,
        NotificationType.weeklyRoundup,
        NotificationType.personalizedAlerts,
        NotificationType.sms,
      ];

      if (premiumOnlyTypes.contains(type) && !isPremium) {
        return false;
      }

      if (!isPremium &&
          (type == NotificationType.newSweepstakes ||
              type == NotificationType.endingSoon)) {
        return await _checkDailyLimit(userId, type);
      }

      return true;
    } catch (e) {
      logger.e('Error checking notification access', error: e);
      return false;
    }
  }

  bool _isPremiumUser(UserProfile user) {
    if (user.tier == 'premium') return true;

    if (user.premiumUntil != null) {
      return user.premiumUntil!.toDate().isAfter(DateTime.now());
    }

    return false;
  }

  Future<bool> _checkDailyLimit(String userId, NotificationType type) async {
    const freeUserDailyLimit = 5;

    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final logDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notification_logs')
          .doc(dateStr)
          .get();

      final count =
          logDoc.data()?[type.toString().split('.').last] as int? ?? 0;
      return count < freeUserDailyLimit;
    } catch (e) {
      logger.e('Error checking daily limit', error: e);
      return true;
    }
  }

  /// Validate user ID format to prevent path traversal attacks
  bool _isValidUserId(String userId) {
    // Firebase Auth UIDs are alphanumeric with specific length
    final regex = RegExp(r'^[a-zA-Z0-9]{20,128}$');
    return regex.hasMatch(userId) &&
        !userId.contains('../') &&
        !userId.contains('./');
  }

  /// Get encrypted FCM token for a user
  Future<String?> getSecureToken(String userId) async {
    try {
      if (!_isValidUserId(userId)) {
        logger.w('Invalid userId format for token retrieval: $userId');
        return null;
      }

      return await _secureTokenService.getSecureToken(userId);
    } catch (e) {
      logger.e('Error retrieving secure token', error: e);
      return null;
    }
  }

  /// Migrate existing plaintext tokens to secure storage
  Future<void> migrateToSecureTokens() async {
    try {
      await _secureTokenService.migrateExistingTokens();
      logger.i('Successfully migrated to secure token storage');
    } catch (e) {
      logger.e('Error migrating to secure tokens', error: e);
      rethrow;
    }
  }

  Future<void> incrementNotificationCount(
    String userId,
    NotificationType type,
  ) async {
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notification_logs')
          .doc(dateStr)
          .set(
        {
          type.toString().split('.').last: FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      logger.e('Error incrementing notification count', error: e);
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      logger.i('Subscribed to topic: $topic');
    } catch (e) {
      logger.e('Error subscribing to topic $topic', error: e);
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      logger.i('Unsubscribed from topic: $topic');
    } catch (e) {
      logger.e('Error unsubscribing from topic $topic', error: e);
    }
  }
}

final unifiedNotificationService = UnifiedNotificationService();
