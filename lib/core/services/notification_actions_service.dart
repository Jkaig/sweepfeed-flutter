import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/logger.dart';
import 'modern_notification_service.dart';

/// Service for managing modern notification actions and categories
/// Handles iOS notification categories and Android notification actions
class NotificationActionsService {
  NotificationActionsService._internal();
  static final NotificationActionsService _instance =
      NotificationActionsService._internal();
  static NotificationActionsService get instance => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize notification actions and categories
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Platform.isIOS) {
        await _initializeIOSCategories();
      }

      _initialized = true;
      logger.i('Notification actions service initialized');
    } catch (e) {
      logger.e('Error initializing notification actions service', error: e);
      rethrow;
    }
  }

  /// Initialize iOS notification categories with actions
  Future<void> _initializeIOSCategories() async {
    // This would require native iOS implementation
    // For now, we'll define the structure that would be implemented natively
    logger.i('iOS notification categories would be initialized in native code');
  }

  /// Get predefined actions for contest notifications
  List<NotificationAction> getContestActions({
    bool includeRemindLater = true,
    bool includeShare = true,
    bool includeViewDetails = true,
  }) {
    final actions = <NotificationAction>[
      const NotificationAction(
        id: 'enter_contest',
        title: '🎯 Enter Now',
        iconName: 'ic_enter',
      ),
      const NotificationAction(
        id: 'save_contest',
        title: '💾 Save',
        iconName: 'ic_bookmark',
      ),
    ];

    if (includeShare) {
      actions.add(
        const NotificationAction(
          id: 'share_contest',
          title: '📱 Share',
          iconName: 'ic_share',
        ),
      );
    }

    if (includeRemindLater) {
      actions.add(
        const NotificationAction(
          id: 'remind_later',
          title: '⏰ Remind Later',
          iconName: 'ic_reminder',
        ),
      );
    }

    if (includeViewDetails) {
      actions.add(
        const NotificationAction(
          id: 'view_details',
          title: '👁️ View Details',
          iconName: 'ic_details',
        ),
      );
    }

    return actions;
  }

  /// Get predefined actions for social notifications
  List<NotificationAction> getSocialActions({
    bool includeReply = false,
    bool includeViewProfile = true,
    bool includeFollow = false,
  }) {
    final actions = <NotificationAction>[
      const NotificationAction(
        id: 'view_activity',
        title: '👀 View',
        iconName: 'ic_view',
      ),
    ];

    if (includeReply) {
      actions.add(
        const NotificationAction(
          id: 'reply_comment',
          title: '💬 Reply',
          iconName: 'ic_reply',
          isTextInput: true,
          inputPlaceholder: 'Write a reply...',
        ),
      );
    }

    if (includeViewProfile) {
      actions.add(
        const NotificationAction(
          id: 'view_profile',
          title: '👤 Profile',
          iconName: 'ic_profile',
        ),
      );
    }

    if (includeFollow) {
      actions.add(
        const NotificationAction(
          id: 'follow_user',
          title: '➕ Follow',
          iconName: 'ic_follow',
        ),
      );
    }

    return actions;
  }

  /// Get predefined actions for achievement notifications
  List<NotificationAction> getAchievementActions() => [
        const NotificationAction(
          id: 'view_achievement',
          title: '🏆 View Achievement',
          iconName: 'ic_trophy',
        ),
        const NotificationAction(
          id: 'share_achievement',
          title: '📱 Share Success',
          iconName: 'ic_share',
        ),
        const NotificationAction(
          id: 'view_leaderboard',
          title: '📊 Leaderboard',
          iconName: 'ic_leaderboard',
        ),
      ];

  /// Get predefined actions for reminder notifications
  List<NotificationAction> getReminderActions() => [
        const NotificationAction(
          id: 'snooze_5min',
          title: '⏰ 5 minutes',
          iconName: 'ic_snooze',
        ),
        const NotificationAction(
          id: 'snooze_1hour',
          title: '⏰ 1 hour',
          iconName: 'ic_snooze',
        ),
        const NotificationAction(
          id: 'complete_task',
          title: '✅ Done',
          iconName: 'ic_done',
        ),
      ];

  /// Get predefined actions for high priority notifications
  List<NotificationAction> getHighPriorityActions() => [
        const NotificationAction(
          id: 'take_action',
          title: '⚡ Take Action',
          iconName: 'ic_action',
        ),
        const NotificationAction(
          id: 'view_details',
          title: '📋 Details',
          iconName: 'ic_details',
        ),
        const NotificationAction(
          id: 'dismiss_alert',
          title: '✖️ Dismiss',
          iconName: 'ic_dismiss',
        ),
      ];

  /// Create Android notification actions from NotificationAction list
  List<AndroidNotificationAction> createAndroidActions(
    List<NotificationAction> actions,
  ) =>
      actions
          .map(
            (action) => AndroidNotificationAction(
              action.id,
              action.title,
              icon: action.iconName != null
                  ? DrawableResourceAndroidBitmap(action.iconName!)
                  : null,
              showsUserInterface: !action.isTextInput,
              allowGeneratedReplies: action.isTextInput,
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

  /// Create iOS category identifier for notification type
  String getIOSCategoryIdentifier(
    ModernNotificationCategory category, {
    List<NotificationAction>? customActions,
  }) {
    final baseId = _getCategoryBaseId(category);

    if (customActions != null && customActions.isNotEmpty) {
      // Create a hash of action IDs to ensure unique category identifiers
      final actionHash =
          customActions.map((a) => a.id).join('_').hashCode.abs();
      return '${baseId}_$actionHash';
    }

    return baseId;
  }

  String _getCategoryBaseId(ModernNotificationCategory category) {
    switch (category) {
      case ModernNotificationCategory.contestUpdates:
        return 'contest_actions';
      case ModernNotificationCategory.socialActivity:
        return 'social_actions';
      case ModernNotificationCategory.achievements:
        return 'achievement_actions';
      case ModernNotificationCategory.hotSweepstakes:
        return 'hot_sweepstakes_actions';
      case ModernNotificationCategory.reminders:
        return 'reminder_actions';
      case ModernNotificationCategory.highPriority:
        return 'priority_actions';
      case ModernNotificationCategory.gameUpdates:
        return 'game_actions';
      case ModernNotificationCategory.promotions:
        return 'promotion_actions';
      case ModernNotificationCategory.systemMessages:
        return 'system_actions';
    }
  }

  /// Get appropriate notification actions based on type and context
  List<NotificationAction> getActionsForNotification(
    ModernNotificationType type, {
    Map<String, dynamic>? context,
  }) {
    switch (type) {
      // Contest-related notifications
      case ModernNotificationType.newContest:
        return getContestActions(includeRemindLater: false);

      case ModernNotificationType.contestEndingSoon:
        return getContestActions();

      case ModernNotificationType.highValueContest:
        return getContestActions(includeRemindLater: false);

      case ModernNotificationType.contestWinnerAnnouncement:
        return [
          const NotificationAction(
            id: 'view_results',
            title: '🏆 View Results',
          ),
          const NotificationAction(id: 'share_results', title: '📱 Share'),
        ];

      // Social notifications
      case ModernNotificationType.newFollower:
        return getSocialActions();

      case ModernNotificationType.commentOnEntry:
        return getSocialActions(includeReply: true);

      case ModernNotificationType.friendJoined:
        return getSocialActions(includeFollow: true);

      // Achievement notifications
      case ModernNotificationType.badgeUnlocked:
      case ModernNotificationType.levelUp:
      case ModernNotificationType.milestoneReached:
        return getAchievementActions();

      // Reminder notifications
      case ModernNotificationType.dailyEntry:
      case ModernNotificationType.customReminder:
        return getReminderActions();

      // High priority notifications
      case ModernNotificationType.criticalAlert:
      case ModernNotificationType.urgentDeadline:
      case ModernNotificationType.securityAlert:
        return getHighPriorityActions();

      // System and promotional notifications
      case ModernNotificationType.newFeature:
        return [
          const NotificationAction(id: 'try_feature', title: '✨ Try It'),
          const NotificationAction(id: 'learn_more', title: '📖 Learn More'),
        ];

      case ModernNotificationType.specialOffer:
        return [
          const NotificationAction(id: 'view_offer', title: '🎁 View Offer'),
          const NotificationAction(id: 'claim_offer', title: '💎 Claim'),
        ];

      // Default actions
      default:
        return [
          const NotificationAction(id: 'view', title: '👀 View'),
          const NotificationAction(id: 'dismiss', title: '✖️ Dismiss'),
        ];
    }
  }

  /// Handle notification action responses
  Future<void> handleNotificationAction({
    required String actionId,
    required String? payload,
    String? userInput,
  }) async {
    try {
      logger
          .i('Handling notification action: $actionId with payload: $payload');

      switch (actionId) {
        case 'enter_contest':
          await _handleEnterContest(payload);
          break;

        case 'save_contest':
          await _handleSaveContest(payload);
          break;

        case 'share_contest':
          await _handleShareContest(payload);
          break;

        case 'remind_later':
          await _handleRemindLater(payload);
          break;

        case 'view_details':
          await _handleViewDetails(payload);
          break;

        case 'reply_comment':
          await _handleReplyComment(payload, userInput);
          break;

        case 'follow_user':
          await _handleFollowUser(payload);
          break;

        case 'view_achievement':
          await _handleViewAchievement(payload);
          break;

        case 'share_achievement':
          await _handleShareAchievement(payload);
          break;

        case 'snooze_5min':
          await _handleSnooze(payload, const Duration(minutes: 5));
          break;

        case 'snooze_1hour':
          await _handleSnooze(payload, const Duration(hours: 1));
          break;

        case 'complete_task':
          await _handleCompleteTask(payload);
          break;

        case 'take_action':
          await _handleTakeAction(payload);
          break;

        default:
          logger.w('Unknown notification action: $actionId');
      }
    } catch (e) {
      logger.e('Error handling notification action: $actionId', error: e);
    }
  }

  // Action handlers
  Future<void> _handleEnterContest(String? payload) async {
    // Implementation would navigate to contest entry screen
    logger.i('Handling enter contest action');
  }

  Future<void> _handleSaveContest(String? payload) async {
    // Implementation would save contest to user's saved list
    logger.i('Handling save contest action');
  }

  Future<void> _handleShareContest(String? payload) async {
    // Implementation would open share dialog
    logger.i('Handling share contest action');
  }

  Future<void> _handleRemindLater(String? payload) async {
    // Implementation would schedule a reminder
    logger.i('Handling remind later action');
  }

  Future<void> _handleViewDetails(String? payload) async {
    // Implementation would navigate to details screen
    logger.i('Handling view details action');
  }

  Future<void> _handleReplyComment(String? payload, String? userInput) async {
    // Implementation would post reply to comment
    logger.i('Handling reply comment action with input: $userInput');
  }

  Future<void> _handleFollowUser(String? payload) async {
    // Implementation would follow the user
    logger.i('Handling follow user action');
  }

  Future<void> _handleViewAchievement(String? payload) async {
    // Implementation would navigate to achievements screen
    logger.i('Handling view achievement action');
  }

  Future<void> _handleShareAchievement(String? payload) async {
    // Implementation would share achievement
    logger.i('Handling share achievement action');
  }

  Future<void> _handleSnooze(String? payload, Duration duration) async {
    // Implementation would reschedule notification
    logger.i('Handling snooze action for ${duration.inMinutes} minutes');
  }

  Future<void> _handleCompleteTask(String? payload) async {
    // Implementation would mark task as complete
    logger.i('Handling complete task action');
  }

  Future<void> _handleTakeAction(String? payload) async {
    // Implementation would navigate to appropriate action screen
    logger.i('Handling take action');
  }
}

/// Extension to integrate with ModernNotificationService
extension NotificationActionsIntegration on ModernNotificationService {
  /// Create notification with appropriate actions
  Future<void> sendNotificationWithActions({
    required ModernNotificationData notification,
    List<NotificationAction>? customActions,
  }) async {
    // Get appropriate actions for the notification type
    final actions = customActions ??
        NotificationActionsService.instance
            .getActionsForNotification(notification.type);

    // Create updated notification with actions
    final notificationWithActions = ModernNotificationData(
      id: notification.id,
      userId: notification.userId,
      category: notification.category,
      type: notification.type,
      priority: notification.priority,
      style: notification.style,
      title: notification.title,
      body: notification.body,
      imageUrl: notification.imageUrl,
      videoUrl: notification.videoUrl,
      actionData: notification.actionData,
      deepLink: notification.deepLink,
      customData: notification.customData,
      scheduledTime: notification.scheduledTime,
      requiresConsent: notification.requiresConsent,
      actions: actions,
      groupKey: notification.groupKey,
      threadIdentifier: notification.threadIdentifier,
      liveActivityDuration: notification.liveActivityDuration,
    );

    // Send the notification
    await sendNotification(notificationWithActions);
  }
}

/// Global instance
final notificationActionsService = NotificationActionsService.instance;
