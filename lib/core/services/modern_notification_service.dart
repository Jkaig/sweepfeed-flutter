import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_links/app_links.dart';

import '../../features/reminders/services/reminder_service.dart';
import '../utils/logger.dart';
import 'unified_notification_service.dart';

/// Modern notification categories for iOS 17+ and Android 14+.
enum ModernNotificationCategory {
  /// Achievements and milestones reached.
  achievements,

  /// Updates about contests.
  contestUpdates,

  /// Updates from games.
  gameUpdates,

  /// High priority, critical alerts.
  highPriority,

  /// Hot sweepstakes.
  hotSweepstakes,

  /// Promotional offers and deals.
  promotions,

  /// Reminders for various tasks.
  reminders,

  /// Activity related to social interactions.
  socialActivity,

  /// Important system messages.
  systemMessages
}

/// Defines the specific type of notification within a category.
enum ModernNotificationType {
  // Contest Updates
  /// A new contest has been created.
  newContest,

  /// A contest is ending soon.
  contestEndingSoon,

  /// Announcement of a contest winner.
  contestWinnerAnnouncement,

  /// A high-value contest available.
  highValueContest,

  // Social Activity
  /// A new user is following.
  newFollower,

  /// Someone commented on an entry.
  commentOnEntry,

  /// A contest was shared.
  contestShared,

  /// A friend joined.
  friendJoined,

  // System Messages
  /// Alert about a security issue.
  securityAlert,

  /// Account update confirmation.
  accountUpdate,

  /// Policy update information.
  policyUpdate,

  /// Notice about maintenance.
  maintenanceNotice,

  // High Priority
  /// A critical alert is triggered.
  criticalAlert,

  /// An urgent deadline is approaching.
  urgentDeadline,

  /// Winner selection notification.
  winnerSelected,

  // Reminders
  /// Reminder for daily entry.
  dailyEntry,

  /// Weekly digest reminder.
  weeklyDigest,

  /// A custom reminder is triggered.
  customReminder,

  // Promotions
  /// A special offer is available.
  specialOffer,

  /// Promotion to premium upgrade.
  premiumUpgrade,

  /// Seasonal event information.
  seasonalEvent,

  // Game Updates
  /// A new feature is available.
  newFeature,

  /// Update on the leaderboard.
  leaderboardUpdate,

  /// Milestone reached in a streak.
  streakMilestone,

  // Achievements
  /// A new badge is unlocked.
  badgeUnlocked,

  /// Level has been increased.
  levelUp,

  /// A milestone has been reached.
  milestoneReached
}

/// Represents the priority of a notification.
enum NotificationPriority {
  /// Lowest priority.
  low,

  /// Normal priority.
  normal,

  /// High priority.
  high,

  /// Critical priority.
  critical
}

/// Represents the visual style of a notification.
enum NotificationStyle {
  /// Basic notification style.
  basic,

  /// Notification with large text content.
  bigText,

  /// Notification with a large picture.
  bigPicture,

  /// Notification to show multiple items.
  inbox,

  /// Messaging style for chat-like notifications.
  messaging,

  /// Notification with media controls.
  media
}

/// Modern notification data model for consistent representation across platforms.
class ModernNotificationData {
  /// Creates a new [ModernNotificationData] instance.
  const ModernNotificationData({
    required this.id,
    required this.userId,
    required this.category,
    required this.type,
    required this.priority,
    required this.style,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.imageUrl,
    this.videoUrl,
    this.actionData,
    this.deepLink,
    this.customData,
    this.requiresConsent = true,
    this.actions,
    this.groupKey,
    this.threadIdentifier,
    this.liveActivityDuration,
  });

  /// Creates a [ModernNotificationData] instance for a contest notification.
  factory ModernNotificationData.createContestNotification({
    required String userId,
    required String contestId,
    required String contestTitle,
    required String message,
    String? imageUrl,
    NotificationPriority priority = NotificationPriority.normal,
  }) => ModernNotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      category: ModernNotificationCategory.contestUpdates,
      type: ModernNotificationType.newContest,
      priority: priority,
      style: imageUrl != null
          ? NotificationStyle.bigPicture
          : NotificationStyle.bigText,
      title: contestTitle,
      body: message,
      scheduledTime: DateTime.now(),
      imageUrl: imageUrl,
      customData: {'contestId': contestId},
    );

  /// Creates a [ModernNotificationData] instance for a social notification.
  factory ModernNotificationData.createSocialNotification({
    required String userId,
    required String fromUserId,
    required String fromUserName,
    required String message,
    required ModernNotificationType type,
  }) => ModernNotificationData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      category: ModernNotificationCategory.socialActivity,
      type: type,
      priority: NotificationPriority.normal,
      style: NotificationStyle.messaging,
      title: fromUserName,
      body: message,
      scheduledTime: DateTime.now(),
      customData: {'fromUserId': fromUserId, 'fromUserName': fromUserName},
    );

  /// Creates a [ModernNotificationData] instance from a JSON map.
  factory ModernNotificationData.fromJson(Map<String, dynamic> json) =>
      ModernNotificationData(
        id: json['id'],
        userId: json['userId'],
        category: ModernNotificationCategory.values.firstWhere(
          (e) => e.toString() == json['category'],
        ),
        type: ModernNotificationType.values.firstWhere(
          (e) => e.toString() == json['type'],
        ),
        priority: NotificationPriority.values.firstWhere(
          (e) => e.toString() == json['priority'],
        ),
        style: NotificationStyle.values.firstWhere(
          (e) => e.toString() == json['style'],
        ),
        title: json['title'],
        body: json['body'],
        imageUrl: json['imageUrl'],
        videoUrl: json['videoUrl'],
        actionData: json['actionData'],
        deepLink: json['deepLink'],
        customData: json['customData'],
        scheduledTime: DateTime.parse(json['scheduledTime']),
        requiresConsent: json['requiresConsent'] ?? true,
        actions: (json['actions'] as List?)
            ?.map((a) => NotificationAction.fromJson(a))
            .toList(),
        groupKey: json['groupKey'],
        threadIdentifier: json['threadIdentifier'],
        liveActivityDuration: json['liveActivityDuration'] != null
            ? Duration(seconds: json['liveActivityDuration'])
            : null,
      );

  /// Unique identifier for the notification.
  final String id;

  /// User ID the notification is intended for.
  final String userId;

  /// Category of the notification (e.g., contest updates, social activity).
  final ModernNotificationCategory category;

  /// Specific type of notification within the category.
  final ModernNotificationType type;

  /// Priority level of the notification.
  final NotificationPriority priority;

  /// Visual style of the notification.
  final NotificationStyle style;

  /// Title of the notification.
  final String title;

  /// Main text content of the notification.
  final String body;

  /// Optional URL for an image to display in the notification.
  final String? imageUrl;

  /// Optional URL for a video to display in the notification.
  final String? videoUrl;

  /// Optional data associated with notification actions.
  final Map<String, dynamic>? actionData;

  /// Optional deep link to open when the notification is tapped.
  final String? deepLink;

  /// Optional custom data for app-specific handling.
  final Map<String, dynamic>? customData;

  /// Time the notification should be displayed.
  final DateTime scheduledTime;

  /// Whether this notification type requires explicit user consent (GDPR compliance).
  final bool requiresConsent;

  /// List of actions to display with the notification.
  final List<NotificationAction>? actions;

  /// Group key used for notification grouping (Android).
  final String? groupKey;

  /// Thread identifier used to group iOS notifications together.
  final String? threadIdentifier;

  /// Duration of the iOS Live Activity.
  final Duration? liveActivityDuration;

  /// Converts a [ModernNotificationData] instance to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'category': category.toString(),
        'type': type.toString(),
        'priority': priority.toString(),
        'style': style.toString(),
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'actionData': actionData,
        'deepLink': deepLink,
        'customData': customData,
        'scheduledTime': scheduledTime.toIso8601String(),
        'requiresConsent': requiresConsent,
        'actions': actions?.map((a) => a.toJson()).toList(),
        'groupKey': groupKey,
        'threadIdentifier': threadIdentifier,
        'liveActivityDuration': liveActivityDuration?.inSeconds,
      };
}

/// Represents an action that can be performed from a notification.
class NotificationAction {
  /// Creates a new [NotificationAction] instance.
  const NotificationAction({
    required this.id,
    required this.title,
    this.iconName,
    this.isTextInput = false,
    this.inputPlaceholder,
  });

  /// Creates a [NotificationAction] instance from a JSON map.
  factory NotificationAction.fromJson(Map<String, dynamic> json) =>
      NotificationAction(
        id: json['id'],
        title: json['title'],
        iconName: json['iconName'],
        isTextInput: json['isTextInput'] ?? false,
        inputPlaceholder: json['inputPlaceholder'],
      );

  /// Unique identifier for the action.
  final String id;

  /// Title of the action button.
  final String title;

  /// Optional name of the icon to display in the action button (Android).
  final String? iconName;

  /// Whether the action requires text input.
  final bool isTextInput;

  /// Optional placeholder text for the text input field.
  final String? inputPlaceholder;

  /// Converts a [NotificationAction] instance to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'iconName': iconName,
        'isTextInput': isTextInput,
        'inputPlaceholder': inputPlaceholder,
      };
}

/// Manages user consent for different notification categories, adhering to GDPR guidelines.
class ConsentManager {
  /// Instance of FirebaseFirestore for data persistence.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks if the user has granted consent for a specific notification category.
  Future<bool> hasConsent(
    String userId,
    ModernNotificationCategory category,
  ) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notification_consent')
          .doc(category.toString())
          .get();

      if (!doc.exists) {
        // Default consent for essential categories
        return _getDefaultConsent(category);
      }

      final data = doc.data()!;
      return data['consented'] == true;
    } catch (e) {
      logger.e('Error checking consent for $userId, $category', error: e);
      return false;
    }
  }

  /// Updates the user's consent status for a specific notification category.
  Future<void> updateConsent(
    String userId,
    ModernNotificationCategory category,
    bool consented,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notification_consent')
          .doc(category.toString())
          .set({
        'consented': consented,
        'timestamp': FieldValue.serverTimestamp(),
        'category': category.toString(),
      });

      // Log consent change for audit
      await _logConsentChange(userId, category, consented);
    } catch (e) {
      logger.e('Error updating consent for $userId, $category', error: e);
      rethrow;
    }
  }

  /// Retrieves all consent statuses for a user.
  Future<Map<ModernNotificationCategory, bool>> getAllConsents(
    String userId,
  ) async {
    try {
      final collection = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notification_consent')
          .get();

      final consents = <ModernNotificationCategory, bool>{};

      for (final category in ModernNotificationCategory.values) {
        final doc = collection.docs
            .where((d) => d.id == category.toString())
            .firstOrNull;
        consents[category] =
            doc?.data()['consented'] ?? _getDefaultConsent(category);
      }

      return consents;
    } catch (e) {
      logger.e('Error getting all consents for $userId', error: e);
      return {};
    }
  }

  /// Returns the default consent value for a given category.
  bool _getDefaultConsent(ModernNotificationCategory category) {
    // Default consent for essential system messages
    switch (category) {
      case ModernNotificationCategory.systemMessages:
      case ModernNotificationCategory.highPriority:
        return true;
      default:
        return false;
    }
  }

  /// Logs a change in user consent for auditing purposes.
  Future<void> _logConsentChange(
    String userId,
    ModernNotificationCategory category,
    bool consented,
  ) async {
    try {
      await _firestore.collection('consent_audit_log').add({
        'userId': userId,
        'category': category.toString(),
        'consented': consented,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': 'mobile_app', // Could get actual IP if needed
      });
    } catch (e) {
      logger.e('Error logging consent change', error: e);
    }
  }
}

/// Manages deep linking functionality for navigating within the app from notifications.
class DeepLinkManager {
  /// The base URL for deep links in this application.
  static const String baseUrl = 'sweepfeed://';

  /// Generates a deep link URL for a specific notification type and data.
  String generateDeepLink(
    ModernNotificationType type,
    Map<String, dynamic>? data,
  ) {
    final path = _getPathForType(type);
    final params = _encodeParams(data ?? {});

    return '$baseUrl$path${params.isNotEmpty ? '?$params' : ''}';
  }

  /// Determines the path for a specific notification type.
  String _getPathForType(ModernNotificationType type) {
    switch (type) {
      case ModernNotificationType.newContest:
      case ModernNotificationType.contestEndingSoon:
      case ModernNotificationType.highValueContest:
        return 'contest';
      case ModernNotificationType.newFollower:
      case ModernNotificationType.commentOnEntry:
      case ModernNotificationType.friendJoined:
        return 'social';
      case ModernNotificationType.newFeature:
      case ModernNotificationType.leaderboardUpdate:
        return 'game';
      case ModernNotificationType.badgeUnlocked:
      case ModernNotificationType.levelUp:
        return 'achievements';
      default:
        return 'home';
    }
  }

  /// Encodes parameters for a deep link URL.
  String _encodeParams(Map<String, dynamic> data) {
    final params = <String, String>{};

    data.forEach((key, value) {
      if (value != null) {
        params[key] = value.toString();
      }
    });

    return Uri(queryParameters: params).query;
  }

  /// Handles a deep link by parsing the URL and navigating to the appropriate screen.
  Future<void> handleDeepLink(String link) async {
    try {
      final uri = Uri.parse(link);
      logger.i('Handling deep link: $link');

      // Extract path and parameters
      final path = uri.path;
      final params = uri.queryParameters;

      // Navigate based on path - this would integrate with your router
      // For now, just log the navigation intent
      logger.i('Deep link navigation: path=$path, params=$params');
    } catch (e) {
      logger.e('Error handling deep link: $link', error: e);
    }
  }
}

/// Queues notifications for batching and processing, helping to reduce server load and improve performance.
class NotificationQueue {
  /// Creates a new [NotificationQueue] instance.
  NotificationQueue({
    this.batchInterval = const Duration(seconds: 5),
    this.maxBatchSize = 50,
  });

  /// Internal queue to store notifications.
  final List<ModernNotificationData> _queue = [];

  /// The interval to wait before processing a batch of notifications.
  final Duration batchInterval;

  /// The maximum number of notifications to include in a single batch.
  final int maxBatchSize;

  /// Timer used to schedule batch processing.
  Timer? _batchTimer;

  /// Adds a notification to the queue.
  void enqueue(ModernNotificationData notification) {
    _queue.add(notification);

    if (_queue.length >= maxBatchSize) {
      _processBatch();
    } else {
      _batchTimer ??= Timer(batchInterval, _processBatch);
    }
  }

  /// Removes all notifications from the queue and returns them as a list.
  List<ModernNotificationData> dequeue() {
    final batch = List<ModernNotificationData>.from(_queue);
    _queue.clear();
    return batch;
  }

  /// Processes the current batch of notifications.
  void _processBatch() {
    _batchTimer?.cancel();
    _batchTimer = null;

    if (_queue.isNotEmpty) {
      // Trigger batch processing in ModernNotificationService
      ModernNotificationService.instance._processBatch();
    }
  }
}

/// The main service for managing and sending modern notifications, supporting platform-specific features and consent management.
class ModernNotificationService {
  ModernNotificationService._internal();

  /// The single instance of the [ModernNotificationService].
  static final ModernNotificationService _instance =
      ModernNotificationService._internal();

  /// Gets the singleton instance of the [ModernNotificationService].
  static ModernNotificationService get instance => _instance;

  /// Unified notification service.
  final UnifiedNotificationService _unifiedService = unifiedNotificationService;

  /// Reminder service.
  final ReminderService _reminderService = ReminderService();

  /// Consent manager for handling user consent for notifications.
  final ConsentManager _consentManager = ConsentManager();

  /// Deep link manager for handling navigation from notifications.
  final DeepLinkManager _deepLinkManager = DeepLinkManager();

  /// Notification queue for batching notifications.
  final NotificationQueue _queue = NotificationQueue();

  /// Instance of the FlutterLocalNotificationsPlugin.
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Flag indicating whether the service has been initialized.
  bool _initialized = false;

  /// Initializes the [ModernNotificationService].
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize local notifications with modern features
      await _initializeLocalNotifications();

      // Initialize reminder service
      await _reminderService.init();

      // Setup deep link handling
      await _setupDeepLinkHandling();

      // Initialize platform-specific features
      if (Platform.isAndroid) {
        await _initializeAndroidFeatures();
      } else if (Platform.isIOS) {
        await _initializeIOSFeatures();
      }

      _initialized = true;
      logger.i('ModernNotificationService initialized successfully');
    } catch (e) {
      logger.e('Error initializing ModernNotificationService', error: e);
      rethrow;
    }
  }

  /// Initializes the Flutter Local Notifications plugin.
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestCriticalPermission: true,
      requestProvisionalPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // Create modern notification channels for Android
    await _createModernNotificationChannels();
  }

  /// Creates modern notification channels for Android (Android 8.0+).
  /// Includes all categories and proper grouping for Android 14+.
  Future<void> _createModernNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Create notification groups first (Android 7.0+)
    await _createNotificationGroups(androidPlugin);

    // High Priority Channel for critical notifications
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'high_priority_channel',
        'High Priority Notifications',
        description: 'Critical alerts and urgent notifications',
        importance: Importance.max,
        enableLights: true,
        ledColor: Color.fromARGB(255, 255, 152, 0),
      ),
    );

    // Contest Updates Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'contest_updates_channel',
        'Contest Updates',
        description: 'New contests, deadlines, and winner announcements',
        importance: Importance.high,
        groupId: 'contests',
        enableLights: true,
      ),
    );

    // Social Activity Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'social_activity_channel',
        'Social Activity',
        description: 'Followers, comments, and social interactions',
        groupId: 'social',
        playSound: false,
        enableVibration: false,
      ),
    );

    // System Messages Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'system_messages_channel',
        'System Messages',
        description: 'Important system updates and security alerts',
        importance: Importance.high,
        groupId: 'system',
        enableLights: true,
      ),
    );

    // Reminders Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'reminders_channel',
        'Reminders',
        description: 'Daily reminders and scheduled notifications',
        groupId: 'reminders',
      ),
    );

    // Promotions Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'promotions_channel',
        'Promotions',
        description: 'Special offers and promotional content',
        importance: Importance.low,
        groupId: 'promotions',
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    );

    // Game Updates Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'game_updates_channel',
        'Game Updates',
        description: 'New features and game-related updates',
        groupId: 'game',
      ),
    );

    // Achievements Channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'achievements_channel',
        'Achievements',
        description: 'Badges, levels, and milestone notifications',
        importance: Importance.high,
        groupId: 'achievements',
        enableLights: true,
      ),
    );

    // Media Rich Channel for image/video notifications
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'media_rich_channel',
        'Rich Media Notifications',
        description: 'Notifications with images and media content',
        importance: Importance.high,
        enableLights: true,
      ),
    );

    logger.i('Modern Android notification channels created');
  }

  /// Creates notification groups for Android (Android 7.0+).
  /// Groups help organize notifications by category.
  Future<void> _createNotificationGroups(
    AndroidFlutterLocalNotificationsPlugin androidPlugin,
  ) async {
    // Contest Updates Group
    await androidPlugin.createNotificationChannelGroup(
      const AndroidNotificationChannelGroup(
        'contests',
        'Contest Updates',
      ),
    );

    // Social Activity Group
    await androidPlugin.createNotificationChannelGroup(
      const AndroidNotificationChannelGroup(
        'social',
        'Social Activity',
      ),
    );

    // System Messages Group
    await androidPlugin.createNotificationChannelGroup(
      const AndroidNotificationChannelGroup(
        'system',
        'System Messages',
      ),
    );

    // Reminders Group
    await androidPlugin.createNotificationChannelGroup(
      const AndroidNotificationChannelGroup(
        'reminders',
        'Reminders',
      ),
    );

    // Promotions Group
    await androidPlugin.createNotificationChannelGroup(
      const AndroidNotificationChannelGroup(
        'promotions',
        'Promotions',
      ),
    );

    // Game Updates Group
    await androidPlugin.createNotificationChannelGroup(
      const AndroidNotificationChannelGroup(
        'game',
        'Game Updates',
      ),
    );

    // Achievements Group
    await androidPlugin.createNotificationChannelGroup(
      const AndroidNotificationChannelGroup(
        'achievements',
        'Achievements',
      ),
    );

    logger.i('Android notification groups created');
  }

  /// Sets up deep link handling using the uni_links package.
  Future<void> _setupDeepLinkHandling() async {
    final _appLinks = AppLinks();

    try {
      // Listen for incoming links when app is already running
      _appLinks.uriLinkStream.listen((uri) {
        if (uri != null) {
          _deepLinkManager.handleDeepLink(uri.toString());
        }
      });

      // Handle link when app is launched
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        _deepLinkManager.handleDeepLink(initialUri.toString());
      }
    } catch (e) {
      logger.e('Error setting up deep link handling', error: e);
    }
  }

  /// Initializes Android-specific features.
  Future<void> _initializeAndroidFeatures() async {
    // Request Android 13+ notification permission
    await _requestAndroidNotificationPermission();
  }

  /// Initializes iOS-specific features.
  Future<void> _initializeIOSFeatures() async {
    // Initialize iOS-specific features like Live Activities
    // This would require native iOS code integration
    logger.i('iOS modern features initialized');
  }

  /// Requests notification permission on Android 13+.
  Future<void> _requestAndroidNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;

      if (status.isDenied) {
        final result = await Permission.notification.request();
        logger.i('Android notification permission result: $result');
      }
    }
  }

  /// Handles notification responses (taps and actions).
  void _handleNotificationResponse(NotificationResponse response) {
    logger.i(
      'Notification response: ${response.actionId}, payload: ${response.payload}',
    );

    // Handle action-specific responses
    if (response.actionId != null) {
      _handleNotificationAction(response.actionId!, response.payload);
    } else {
      // Handle notification tap
      _handleNotificationTap(response.payload);
    }
  }

  /// Handles notification actions based on their ID.
  void _handleNotificationAction(String actionId, String? payload) {
    switch (actionId) {
      case 'enter_contest':
        logger.i('User chose to enter contest');
        // Navigate to contest entry
        break;
      case 'save_contest':
        logger.i('User chose to save contest');
        // Save contest for later
        break;
      case 'share_contest':
        logger.i('User chose to share contest');
        // Open share dialog
        break;
      case 'remind_later':
        logger.i('User chose to be reminded later');
        // Schedule reminder
        break;
      default:
        logger.w('Unknown notification action: $actionId');
    }
  }

  /// Handles notification taps.
  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final deepLink = data['deepLink'] as String?;

        if (deepLink != null) {
          _deepLinkManager.handleDeepLink(deepLink);
        }
      } catch (e) {
        logger.e('Error handling notification tap payload', error: e);
      }
    }
  }

  /// Sends a modern notification.
  Future<void> sendNotification(ModernNotificationData notification) async {
    try {
      // Check user consent if required
      if (notification.requiresConsent) {
        final hasConsent = await _consentManager.hasConsent(
          notification.userId,
          notification.category,
        );

        if (!hasConsent) {
          logger.i(
            'User ${notification.userId} has not consented to ${notification.category} notifications',
          );
          return;
        }
      }

      // Add to queue for batching
      _queue.enqueue(notification);
    } catch (e) {
      logger.e('Error sending notification', error: e);
      rethrow;
    }
  }

  /// Processes a batch of notifications.
  void _processBatch() {
    final batch = _queue.dequeue();
    if (batch.isEmpty) return;

    logger.i('Processing notification batch of ${batch.length} notifications');

    for (final notification in batch) {
      _processIndividualNotification(notification);
    }
  }

  /// Processes an individual notification.
  Future<void> _processIndividualNotification(
    ModernNotificationData notification,
  ) async {
    try {
      if (Platform.isAndroid) {
        await _sendAndroidNotification(notification);
      } else if (Platform.isIOS) {
        await _sendIOSNotification(notification);
      }

      // Log notification sent
      await _logNotificationSent(notification);
    } catch (e) {
      logger.e(
        'Error processing individual notification: ${notification.id}',
        error: e,
      );
    }
  }

  /// Sends a notification on Android.
  Future<void> _sendAndroidNotification(
    ModernNotificationData notification,
  ) async {
    final channelId = _getAndroidChannelId(notification.category);
    final importance = _getAndroidImportance(notification.priority);

    // Download media if present
    String? localImagePath;
    if (notification.imageUrl != null) {
      localImagePath = await _downloadMedia(notification.imageUrl!);
    }

    // Create style information based on notification style
    StyleInformation? styleInfo;
    if (notification.style == NotificationStyle.bigPicture &&
        localImagePath != null) {
      styleInfo = BigPictureStyleInformation(
        FilePathAndroidBitmap(localImagePath),
        contentTitle: notification.title,
        summaryText: notification.body,
        hideExpandedLargeIcon: true,
      );
    } else if (notification.style == NotificationStyle.inbox) {
      styleInfo = InboxStyleInformation(
        [notification.body],
        contentTitle: notification.title,
        summaryText: 'SweepFeed Update',
      );
    } else if (notification.style == NotificationStyle.bigText) {
      styleInfo = BigTextStyleInformation(
        notification.body,
        contentTitle: notification.title,
      );
    }

    // Create notification actions
    final actions = notification.actions
        ?.map(
          (action) => AndroidNotificationAction(
            action.id,
            action.title,
            icon: action.iconName != null
                ? DrawableResourceAndroidBitmap(action.iconName!)
                : null,
            inputs: action.isTextInput
                ? [
                    AndroidNotificationActionInput(
                      label: action.inputPlaceholder ?? 'Enter text...',
                    ),
                  ]
                : [],
          ),
        )
        .toList();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(notification.category),
      channelDescription: _getChannelDescription(notification.category),
      importance: importance,
      priority: _getAndroidPriority(notification.priority),
      styleInformation: styleInfo,
      largeIcon:
          localImagePath != null ? FilePathAndroidBitmap(localImagePath) : null,
      actions: actions,
      groupKey: notification.groupKey,
      ongoing: notification.priority == NotificationPriority.critical,
      fullScreenIntent: notification.priority == NotificationPriority.critical,
      category: AndroidNotificationCategory.recommendation,
    );

    final platformDetails = NotificationDetails(android: androidDetails);

    final payload = jsonEncode(notification.toJson());

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: payload,
    );
  }

  /// Sends a notification on iOS.
  Future<void> _sendIOSNotification(ModernNotificationData notification) async {
    // Download media if present
    final attachments = <DarwinNotificationAttachment>[];
    if (notification.imageUrl != null) {
      final localPath = await _downloadMedia(notification.imageUrl!);
      if (localPath != null) {
        attachments.add(
          DarwinNotificationAttachment(
            localPath,
            identifier: 'image_attachment',
          ),
        );
      }
    }

    final iosDetails = DarwinNotificationDetails(
      categoryIdentifier: _getIOSCategoryId(notification.category),
      threadIdentifier: notification.threadIdentifier ?? notification.groupKey,
      attachments: attachments,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      interruptionLevel: _getIOSInterruptionLevel(notification.priority),
    );

    final platformDetails = NotificationDetails(iOS: iosDetails);

    final payload = jsonEncode(notification.toJson());

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: payload,
    );
  }

  /// Downloads media from a URL and saves it locally.
  Future<String?> _downloadMedia(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = url.split('/').last;
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }
    } catch (e) {
      logger.e('Error downloading media: $url', error: e);
    }
    return null;
  }

  /// Logs a notification that was sent.
  Future<void> _logNotificationSent(ModernNotificationData notification) async {
    try {
      await FirebaseFirestore.instance.collection('notification_logs').add({
        'userId': notification.userId,
        'notificationId': notification.id,
        'category': notification.category.toString(),
        'type': notification.type.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (e) {
      logger.e('Error logging notification', error: e);
    }
  }

  /// Gets the Android channel ID for a notification category.
  String _getAndroidChannelId(ModernNotificationCategory category) {
    switch (category) {
      case ModernNotificationCategory.highPriority:
        return 'high_priority_channel';
      case ModernNotificationCategory.contestUpdates:
        return 'contest_updates_channel';
      case ModernNotificationCategory.socialActivity:
        return 'social_activity_channel';
      default:
        return 'default_channel';
    }
  }

  /// Gets the channel name for a notification category.
  String _getChannelName(ModernNotificationCategory category) {
    switch (category) {
      case ModernNotificationCategory.contestUpdates:
        return 'Contest Updates';
      case ModernNotificationCategory.socialActivity:
        return 'Social Activity';
      case ModernNotificationCategory.systemMessages:
        return 'System Messages';
      case ModernNotificationCategory.highPriority:
        return 'High Priority';
      case ModernNotificationCategory.reminders:
        return 'Reminders';
      case ModernNotificationCategory.promotions:
        return 'Promotions';
      case ModernNotificationCategory.gameUpdates:
        return 'Game Updates';
      case ModernNotificationCategory.achievements:
        return 'Achievements';
    }
  }

  /// Gets the channel description for a notification category.
  String _getChannelDescription(ModernNotificationCategory category) {
    switch (category) {
      case ModernNotificationCategory.contestUpdates:
        return 'New contests, deadlines, and winner announcements';
      case ModernNotificationCategory.socialActivity:
        return 'Followers, comments, and social interactions';
      case ModernNotificationCategory.systemMessages:
        return 'Important system updates and security alerts';
      case ModernNotificationCategory.highPriority:
        return 'Critical alerts requiring immediate attention';
      case ModernNotificationCategory.reminders:
        return 'Daily reminders and scheduled notifications';
      case ModernNotificationCategory.promotions:
        return 'Special offers and promotional content';
      case ModernNotificationCategory.gameUpdates:
        return 'New features and game-related updates';
      case ModernNotificationCategory.achievements:
        return 'Badges, levels, and milestone notifications';
    }
  }

  /// Gets the Android importance level for a notification priority.
  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.critical:
        return Importance.max;
    }
  }

  /// Gets the Android priority level for a notification priority.
  Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.critical:
        return Priority.max;
    }
  }

  /// Gets the iOS category ID for a notification category.
  String _getIOSCategoryId(ModernNotificationCategory category) {
    switch (category) {
      case ModernNotificationCategory.contestUpdates:
        return 'contest_actions';
      case ModernNotificationCategory.socialActivity:
        return 'social_actions';
      case ModernNotificationCategory.highPriority:
        return 'critical_actions';
      default:
        return 'default_actions';
    }
  }

  /// Gets the iOS interruption level for a notification priority.
  InterruptionLevel _getIOSInterruptionLevel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return InterruptionLevel.passive;
      case NotificationPriority.normal:
        return InterruptionLevel.active;
      case NotificationPriority.high:
        return InterruptionLevel.timeSensitive;
      case NotificationPriority.critical:
        return InterruptionLevel.critical;
    }
  }

  /// Checks if the user has granted consent for a specific notification category.
  Future<bool> hasConsentForCategory(
    String userId,
    ModernNotificationCategory category,
  ) =>
      _consentManager.hasConsent(userId, category);

  /// Updates the user's consent status for a specific notification category.
  Future<void> updateConsent(
    String userId,
    ModernNotificationCategory category,
    bool consented,
  ) =>
      _consentManager.updateConsent(userId, category, consented);

  /// Retrieves all consent statuses for a user.
  Future<Map<ModernNotificationCategory, bool>> getAllConsents(String userId) =>
      _consentManager.getAllConsents(userId);

  /// Creates a [ModernNotificationData] instance for a contest notification.
  static ModernNotificationData createContestNotification({
    required String userId,
    required String contestId,
    required String contestTitle,
    required String message,
    String? imageUrl,
    ModernNotificationType type = ModernNotificationType.newContest,
    NotificationPriority priority = NotificationPriority.normal,
    Duration? endingSoon,
  }) {
    final actions = <NotificationAction>[
      const NotificationAction(id: 'enter_contest', title: 'Enter Now'),
      const NotificationAction(id: 'save_contest', title: 'Save'),
      const NotificationAction(id: 'share_contest', title: 'Share'),
    ];

    if (endingSoon != null) {
      actions.add(
        const NotificationAction(id: 'remind_later', title: 'Remind Later'),
      );
    }

    return ModernNotificationData(
      id: 'contest_$contestId${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      category: ModernNotificationCategory.contestUpdates,
      type: type,
      priority: priority,
      style: imageUrl != null
          ? NotificationStyle.bigPicture
          : NotificationStyle.basic,
      title: contestTitle,
      body: message,
      imageUrl: imageUrl,
      scheduledTime: DateTime.now(),
      actions: actions,
      customData: {'contestId': contestId},
      deepLink: 'sweepfeed://contest?id=$contestId',
      groupKey: 'contests',
      liveActivityDuration: endingSoon,
    );
  }

  /// Creates a [ModernNotificationData] instance for a social notification.
  static ModernNotificationData createSocialNotification({
    required String userId,
    required String fromUserId,
    required String fromUserName,
    required String message,
    String? avatarUrl,
    ModernNotificationType type = ModernNotificationType.newFollower,
  }) =>
      ModernNotificationData(
        id: 'social_${fromUserId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        category: ModernNotificationCategory.socialActivity,
        type: type,
        priority: NotificationPriority.normal,
        style: avatarUrl != null
            ? NotificationStyle.bigPicture
            : NotificationStyle.basic,
        title: fromUserName,
        body: message,
        imageUrl: avatarUrl,
        scheduledTime: DateTime.now(),
        customData: {'fromUserId': fromUserId},
        deepLink: 'sweepfeed://social?userId=$fromUserId',
        groupKey: 'social',
        threadIdentifier: 'social_$fromUserId',
      );
}

/// Global instance of the modern notification service.
final modernNotificationService = ModernNotificationService.instance;
