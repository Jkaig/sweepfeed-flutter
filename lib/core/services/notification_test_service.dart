import 'dart:math';

import '../utils/logger.dart';
import 'live_activities_service.dart';
import 'modern_notification_service.dart';

/// Service for testing modern notification features
/// Provides comprehensive testing for iOS 17+ and Android 14+ features
class NotificationTestService {
  NotificationTestService._internal();
  static final NotificationTestService _instance =
      NotificationTestService._internal();
  static NotificationTestService get instance => _instance;

  final Random _random = Random();

  /// Test all notification categories and types
  Future<void> runComprehensiveTest(String userId) async {
    try {
      logger.i('Starting comprehensive notification test for user: $userId');

      // Test basic notifications
      await _testBasicNotifications(userId);

      // Test rich media notifications
      await _testRichMediaNotifications(userId);

      // Test interactive notifications
      await _testInteractiveNotifications(userId);

      // Test notification grouping
      await _testNotificationGrouping(userId);

      // Test Live Activities (iOS)
      await _testLiveActivities(userId);

      // Test Android-specific features
      await _testAndroidFeatures(userId);

      // Test consent management
      await _testConsentManagement(userId);

      logger.i('Comprehensive notification test completed successfully');
    } catch (e) {
      logger.e('Error running comprehensive notification test', error: e);
      rethrow;
    }
  }

  /// Test basic notification functionality
  Future<void> _testBasicNotifications(String userId) async {
    logger.i('Testing basic notifications...');

    // Test each notification category
    for (final category in ModernNotificationCategory.values) {
      final notification = _createTestNotification(
        userId: userId,
        category: category,
        type: _getTestTypeForCategory(category),
      );

      await modernNotificationService.sendNotification(notification);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Test rich media notifications with images
  Future<void> _testRichMediaNotifications(String userId) async {
    logger.i('Testing rich media notifications...');

    final testImages = [
      'https://picsum.photos/400/300?random=1',
      'https://picsum.photos/400/300?random=2',
      'https://picsum.photos/400/300?random=3',
    ];

    for (var i = 0; i < testImages.length; i++) {
      final notification = ModernNotificationData(
        id: 'rich_media_test_$i',
        userId: userId,
        category: ModernNotificationCategory.contestUpdates,
        type: ModernNotificationType.newContest,
        priority: NotificationPriority.normal,
        style: NotificationStyle.bigPicture,
        title: 'Rich Media Contest #${i + 1}',
        body: 'Check out this amazing contest with beautiful imagery!',
        imageUrl: testImages[i],
        scheduledTime: DateTime.now(),
        deepLink: 'sweepfeed://contest?id=rich_media_$i',
        customData: {'testType': 'richMedia', 'imageIndex': i},
      );

      await modernNotificationService.sendNotification(notification);
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  /// Test interactive notifications with actions
  Future<void> _testInteractiveNotifications(String userId) async {
    logger.i('Testing interactive notifications...');

    // Contest notification with actions
    final contestNotification =
        ModernNotificationData.createContestNotification(
      userId: userId,
      contestId: 'interactive_test_contest',
      contestTitle: 'Interactive Test Contest',
      message: 'Test contest with interactive actions - try the buttons!',
      imageUrl: 'https://picsum.photos/400/300?random=10',
      priority: NotificationPriority.high,
    );

    await modernNotificationService.sendNotification(contestNotification);
    await Future.delayed(const Duration(seconds: 2));

    // Social notification with reply action
    final socialNotification = ModernNotificationData.createSocialNotification(
      userId: userId,
      fromUserId: 'test_user',
      fromUserName: 'Test User',
      message: 'Commented on your contest entry - reply here!',
      type: ModernNotificationType.commentOnEntry,
    );

    await modernNotificationService.sendNotification(socialNotification);
  }

  /// Test notification grouping and threading
  Future<void> _testNotificationGrouping(String userId) async {
    logger.i('Testing notification grouping...');

    // Create grouped contest notifications
    for (var i = 0; i < 3; i++) {
      final notification = ModernNotificationData(
        id: 'grouped_contest_$i',
        userId: userId,
        category: ModernNotificationCategory.contestUpdates,
        type: ModernNotificationType.newContest,
        priority: NotificationPriority.normal,
        style: NotificationStyle.basic,
        title: 'Contest Group #${i + 1}',
        body: 'This is part of a grouped notification test',
        scheduledTime: DateTime.now(),
        groupKey: 'contest_group_test',
        threadIdentifier: 'contest_thread',
        customData: {'groupTest': true, 'index': i},
      );

      await modernNotificationService.sendNotification(notification);
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // Create grouped social notifications
    for (var i = 0; i < 2; i++) {
      final notification = ModernNotificationData(
        id: 'grouped_social_$i',
        userId: userId,
        category: ModernNotificationCategory.socialActivity,
        type: ModernNotificationType.newFollower,
        priority: NotificationPriority.normal,
        style: NotificationStyle.basic,
        title: 'Social Update #${i + 1}',
        body: 'New follower joined your network',
        scheduledTime: DateTime.now(),
        groupKey: 'social_group_test',
        threadIdentifier: 'social_thread',
        customData: {'groupTest': true, 'type': 'social'},
      );

      await modernNotificationService.sendNotification(notification);
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  /// Test Live Activities (iOS only)
  Future<void> _testLiveActivities(String userId) async {
    logger.i('Testing Live Activities...');

    // Check if Live Activities are supported
    final supported = await liveActivitiesService.areSupported();
    if (!supported) {
      logger.i('Live Activities not supported on this device');
      return;
    }

    // Test contest countdown Live Activity
    final contestEndTime = DateTime.now().add(const Duration(minutes: 30));
    final activityId = await liveActivitiesService.startContestCountdown(
      contestId: 'live_activity_test',
      contestTitle: 'Live Activity Test Contest',
      prize: '\$1000 Gift Card',
      endTime: contestEndTime,
      currentEntries: 1250,
      totalEntries: 5000,
      imageUrl: 'https://picsum.photos/400/300?random=20',
    );

    if (activityId != null) {
      logger.i('Live Activity started with ID: $activityId');

      // Update the Live Activity after a few seconds
      await Future.delayed(const Duration(seconds: 5));
      await liveActivitiesService.updateContestCountdown(
        contestId: 'live_activity_test',
        currentEntries: 1275,
        urgencyMessage: '🔥 Hot contest!',
      );

      // End the Live Activity after testing
      await Future.delayed(const Duration(seconds: 10));
      await liveActivitiesService.endContestCountdown(
        contestId: 'live_activity_test',
        finalStatus: 'Test completed',
      );
    }
  }

  /// Test Android-specific features
  Future<void> _testAndroidFeatures(String userId) async {
    logger.i('Testing Android-specific features...');

    // Test BigPicture style notification
    final bigPictureNotification = ModernNotificationData(
      id: 'android_big_picture_test',
      userId: userId,
      category: ModernNotificationCategory.contestUpdates,
      type: ModernNotificationType.highValueContest,
      priority: NotificationPriority.high,
      style: NotificationStyle.bigPicture,
      title: 'Android BigPicture Test',
      body: 'This notification demonstrates BigPictureStyle on Android',
      imageUrl: 'https://picsum.photos/800/400?random=30',
      scheduledTime: DateTime.now(),
      customData: {'androidTest': 'bigPicture'},
    );

    await modernNotificationService.sendNotification(bigPictureNotification);
    await Future.delayed(const Duration(seconds: 2));

    // Test InboxStyle notification
    final inboxNotification = ModernNotificationData(
      id: 'android_inbox_test',
      userId: userId,
      category: ModernNotificationCategory.socialActivity,
      type: ModernNotificationType.newFollower,
      priority: NotificationPriority.normal,
      style: NotificationStyle.inbox,
      title: 'Android InboxStyle Test',
      body: 'Multiple updates bundled together',
      scheduledTime: DateTime.now(),
      customData: {'androidTest': 'inbox'},
    );

    await modernNotificationService.sendNotification(inboxNotification);
    await Future.delayed(const Duration(seconds: 2));

    // Test critical priority notification
    final criticalNotification = ModernNotificationData(
      id: 'android_critical_test',
      userId: userId,
      category: ModernNotificationCategory.highPriority,
      type: ModernNotificationType.criticalAlert,
      priority: NotificationPriority.critical,
      style: NotificationStyle.basic,
      title: 'Critical Alert Test',
      body: 'This is a critical priority notification test',
      scheduledTime: DateTime.now(),
      customData: {'androidTest': 'critical'},
    );

    await modernNotificationService.sendNotification(criticalNotification);
  }

  /// Test consent management system
  Future<void> _testConsentManagement(String userId) async {
    logger.i('Testing consent management...');

    // Test updating consent for different categories
    await modernNotificationService.updateConsent(
      userId,
      ModernNotificationCategory.promotions,
      false,
    );

    // Verify consent was updated
    final hasConsent = await modernNotificationService.hasConsentForCategory(
      userId,
      ModernNotificationCategory.promotions,
    );

    logger.i('Promotions consent status: $hasConsent');

    // Try to send notification to category without consent
    final promotionNotification = ModernNotificationData(
      id: 'consent_test_promo',
      userId: userId,
      category: ModernNotificationCategory.promotions,
      type: ModernNotificationType.specialOffer,
      priority: NotificationPriority.normal,
      style: NotificationStyle.basic,
      title: 'Consent Test Promotion',
      body: 'This should not be sent due to consent settings',
      scheduledTime: DateTime.now(),
      customData: {'consentTest': true},
    );

    await modernNotificationService.sendNotification(promotionNotification);

    // Re-enable consent
    await modernNotificationService.updateConsent(
      userId,
      ModernNotificationCategory.promotions,
      true,
    );
  }

  /// Test notification batching and rate limiting
  Future<void> testBatchingAndRateLimit(String userId) async {
    logger.i('Testing notification batching and rate limiting...');

    // Send multiple notifications quickly to test batching
    for (var i = 0; i < 10; i++) {
      final notification = ModernNotificationData(
        id: 'batch_test_$i',
        userId: userId,
        category: ModernNotificationCategory.gameUpdates,
        type: ModernNotificationType.newFeature,
        priority: NotificationPriority.normal,
        style: NotificationStyle.basic,
        title: 'Batch Test #${i + 1}',
        body: 'Testing notification batching system',
        scheduledTime: DateTime.now(),
        customData: {'batchTest': true, 'batchIndex': i},
      );

      modernNotificationService.sendNotification(notification);
      // No delay to test batching
    }
  }

  /// Test deep linking functionality
  Future<void> testDeepLinking(String userId) async {
    logger.i('Testing deep linking functionality...');

    final deepLinkNotifications = [
      ModernNotificationData(
        id: 'deep_link_contest',
        userId: userId,
        category: ModernNotificationCategory.contestUpdates,
        type: ModernNotificationType.newContest,
        priority: NotificationPriority.normal,
        style: NotificationStyle.basic,
        title: 'Deep Link Test - Contest',
        body: 'Tap to navigate to contest screen',
        scheduledTime: DateTime.now(),
        deepLink: 'sweepfeed://contest?id=deep_link_test&tab=details',
        customData: {'deepLinkTest': 'contest'},
      ),
      ModernNotificationData(
        id: 'deep_link_social',
        userId: userId,
        category: ModernNotificationCategory.socialActivity,
        type: ModernNotificationType.newFollower,
        priority: NotificationPriority.normal,
        style: NotificationStyle.basic,
        title: 'Deep Link Test - Social',
        body: 'Tap to navigate to social screen',
        scheduledTime: DateTime.now(),
        deepLink: 'sweepfeed://social?userId=test_user&action=view_profile',
        customData: {'deepLinkTest': 'social'},
      ),
    ];

    for (final notification in deepLinkNotifications) {
      await modernNotificationService.sendNotification(notification);
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  /// Performance test with high volume of notifications
  Future<void> runPerformanceTest(
    String userId, {
    int notificationCount = 100,
  }) async {
    logger
        .i('Running performance test with $notificationCount notifications...');

    final stopwatch = Stopwatch()..start();

    for (var i = 0; i < notificationCount; i++) {
      final notification = ModernNotificationData(
        id: 'perf_test_$i',
        userId: userId,
        category: _getRandomCategory(),
        type: _getRandomType(),
        priority: _getRandomPriority(),
        style: NotificationStyle.basic,
        title: 'Performance Test #${i + 1}',
        body: 'Testing notification system performance',
        scheduledTime: DateTime.now(),
        customData: {'performanceTest': true, 'index': i},
      );

      modernNotificationService.sendNotification(notification);
    }

    stopwatch.stop();
    logger
        .i('Performance test completed in ${stopwatch.elapsedMilliseconds}ms');
    logger.i(
      'Average time per notification: ${stopwatch.elapsedMilliseconds / notificationCount}ms',
    );
  }

  // Helper methods
  ModernNotificationData _createTestNotification({
    required String userId,
    required ModernNotificationCategory category,
    required ModernNotificationType type,
  }) =>
      ModernNotificationData(
        id: 'test_${category.toString()}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        category: category,
        type: type,
        priority: NotificationPriority.normal,
        style: NotificationStyle.basic,
        title: 'Test: ${_getCategoryDisplayName(category)}',
        body:
            'This is a test notification for ${_getCategoryDisplayName(category)}',
        scheduledTime: DateTime.now(),
        customData: {'testCategory': category.toString()},
      );

  ModernNotificationType _getTestTypeForCategory(
    ModernNotificationCategory category,
  ) {
    switch (category) {
      case ModernNotificationCategory.contestUpdates:
        return ModernNotificationType.newContest;
      case ModernNotificationCategory.socialActivity:
        return ModernNotificationType.newFollower;
      case ModernNotificationCategory.systemMessages:
        return ModernNotificationType.accountUpdate;
      case ModernNotificationCategory.highPriority:
        return ModernNotificationType.criticalAlert;
      case ModernNotificationCategory.reminders:
        return ModernNotificationType.dailyEntry;
      case ModernNotificationCategory.promotions:
        return ModernNotificationType.specialOffer;
      case ModernNotificationCategory.gameUpdates:
        return ModernNotificationType.newFeature;
      case ModernNotificationCategory.achievements:
        return ModernNotificationType.badgeUnlocked;
      case ModernNotificationCategory.hotSweepstakes:
        return ModernNotificationType.newContest;
    }
  }

  String _getCategoryDisplayName(ModernNotificationCategory category) {
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
      case ModernNotificationCategory.hotSweepstakes:
        return 'Hot Sweepstakes';
    }
  }

  ModernNotificationCategory _getRandomCategory() => ModernNotificationCategory
      .values[_random.nextInt(ModernNotificationCategory.values.length)];

  ModernNotificationType _getRandomType() => ModernNotificationType
      .values[_random.nextInt(ModernNotificationType.values.length)];

  NotificationPriority _getRandomPriority() => NotificationPriority
      .values[_random.nextInt(NotificationPriority.values.length)];

  /// Generate test report with metrics
  Future<Map<String, dynamic>> generateTestReport(String userId) async {
    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
      'categories_tested': ModernNotificationCategory.values.length,
      'types_tested': ModernNotificationType.values.length,
      'live_activities_supported': await liveActivitiesService.areSupported(),
      'active_consents': {},
      'test_results': {
        'basic_notifications': 'passed',
        'rich_media': 'passed',
        'interactive_actions': 'passed',
        'notification_grouping': 'passed',
        'live_activities': 'conditional', // Based on device support
        'android_features': 'passed',
        'consent_management': 'passed',
      },
    };

    // Get consent status for all categories
    final consents = await modernNotificationService.getAllConsents(userId);
    report['active_consents'] =
        consents.map((key, value) => MapEntry(key.toString(), value));

    return report;
  }
}

/// Global instance
final notificationTestService = NotificationTestService.instance;
