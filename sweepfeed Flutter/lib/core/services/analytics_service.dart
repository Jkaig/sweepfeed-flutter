import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';

/// Abstract analytics service interface
abstract class AnalyticsService {
  /// Track an event with optional parameters
  Future<void> trackEvent(String eventName, Map<String, dynamic>? parameters);

  /// Set user properties
  Future<void> setUserProperties(Map<String, dynamic> properties);

  /// Set user ID for tracking
  Future<void> setUserId(String userId);

  /// Track screen views
  Future<void> trackScreenView(
      String screenName, Map<String, dynamic>? parameters);

  /// Track comment posted events
  Future<void> logCommentPosted(String contestId, String comment);

  /// Track comment liked events
  Future<void> logCommentLiked(String commentId);

  /// Track contest sharing events
  Future<void> logShare({required String contestId});

  /// Track generic events with parameters
  Future<void> logEvent(
      {required String eventName, Map<String, dynamic>? parameters});

  /// Track screen view events
  Future<void> logScreenView(
      {required String screenName, Map<String, dynamic>? parameters});

  /// Track contest saved/unsaved events
  Future<void> logContestSaved(
      {required String contestId, required bool isSaved});

  /// Track contest hidden events
  Future<void> logContestHidden({required String contestId});

  /// Track contest view events
  Future<void> logContestView({required String contestId});

  /// Track filter application events
  Future<void> logFilterApplied({required Map<String, dynamic> filters});
}

/// Firebase Analytics implementation
class FirebaseAnalyticsService implements AnalyticsService {
  @override
  Future<void> trackEvent(
      String eventName, Map<String, dynamic>? parameters) async {
    try {
      // TODO: Implement actual Firebase Analytics tracking
      // await FirebaseAnalytics.instance.logEvent(
      //   name: eventName,
      //   parameters: parameters,
      // );

      // For now, log to console
      logger.i('Analytics Event: $eventName - $parameters');
    } catch (e) {
      logger.e('Error tracking analytics event: $eventName', error: e);
    }
  }

  @override
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    try {
      // TODO: Implement actual Firebase Analytics user properties
      // for (final entry in properties.entries) {
      //   await FirebaseAnalytics.instance.setUserProperty(
      //     name: entry.key,
      //     value: entry.value?.toString(),
      //   );
      // }

      logger.i('Analytics User Properties Set - $properties');
    } catch (e) {
      logger.e('Error setting user properties', error: e);
    }
  }

  @override
  Future<void> setUserId(String userId) async {
    try {
      // TODO: Implement actual Firebase Analytics user ID
      // await FirebaseAnalytics.instance.setUserId(id: userId);

      logger.i('Analytics User ID Set: $userId');
    } catch (e) {
      logger.e('Error setting user ID', error: e);
    }
  }

  @override
  Future<void> trackScreenView(
      String screenName, Map<String, dynamic>? parameters) async {
    try {
      // TODO: Implement actual Firebase Analytics screen tracking
      // await FirebaseAnalytics.instance.logScreenView(
      //   screenName: screenName,
      //   parameters: parameters,
      // );

      logger.i('Analytics Screen View: $screenName - $parameters');
    } catch (e) {
      logger.e('Error tracking screen view: $screenName', error: e);
    }
  }

  @override
  Future<void> logCommentPosted(String contestId, String comment) async {
    try {
      await trackEvent('comment_posted', {
        'contest_id': contestId,
        'comment_length': comment.length,
      });
      logger.i('Analytics Comment Posted: $contestId');
    } catch (e) {
      logger.e('Error tracking comment posted: $contestId', error: e);
    }
  }

  @override
  Future<void> logCommentLiked(String commentId) async {
    try {
      await trackEvent('comment_liked', {
        'comment_id': commentId,
      });
      logger.i('Analytics Comment Liked: $commentId');
    } catch (e) {
      logger.e('Error tracking comment liked: $commentId', error: e);
    }
  }

  @override
  Future<void> logShare({required String contestId}) async {
    try {
      await trackEvent('contest_shared', {'contest_id': contestId});
      logger.i('Analytics Contest Shared: $contestId');
    } catch (e) {
      logger.e('Error tracking contest shared: $contestId', error: e);
    }
  }

  @override
  Future<void> logEvent(
      {required String eventName, Map<String, dynamic>? parameters}) async {
    try {
      await trackEvent(eventName, parameters);
      logger.i('Analytics Custom Event: $eventName - $parameters');
    } catch (e) {
      logger.e('Error tracking custom event: $eventName', error: e);
    }
  }

  @override
  Future<void> logScreenView(
      {required String screenName, Map<String, dynamic>? parameters}) async {
    try {
      await trackScreenView(screenName, parameters);
      logger.i('Analytics Screen View: $screenName - $parameters');
    } catch (e) {
      logger.e('Error tracking screen view: $screenName', error: e);
    }
  }

  @override
  Future<void> logContestSaved(
      {required String contestId, required bool isSaved}) async {
    try {
      await trackEvent(
          'contest_saved', {'contest_id': contestId, 'is_saved': isSaved});
      logger.i('Analytics Contest Saved: $contestId (saved: $isSaved)');
    } catch (e) {
      logger.e('Error tracking contest saved: $contestId', error: e);
    }
  }

  @override
  Future<void> logContestHidden({required String contestId}) async {
    try {
      await trackEvent('contest_hidden', {'contest_id': contestId});
      logger.i('Analytics Contest Hidden: $contestId');
    } catch (e) {
      logger.e('Error tracking contest hidden: $contestId', error: e);
    }
  }

  @override
  Future<void> logContestView({required String contestId}) async {
    try {
      await trackEvent('contest_viewed', {'contest_id': contestId});
      logger.i('Analytics Contest Viewed: $contestId');
    } catch (e) {
      logger.e('Error tracking contest viewed: $contestId', error: e);
    }
  }

  @override
  Future<void> logFilterApplied({required Map<String, dynamic> filters}) async {
    try {
      await trackEvent('filter_applied', filters);
      logger.i('Analytics Filter Applied: $filters');
    } catch (e) {
      logger.e('Error tracking filter applied: $filters', error: e);
    }
  }
}

/// Mock analytics service for testing and development
class MockAnalyticsService implements AnalyticsService {
  final List<Map<String, dynamic>> _events = [];
  final Map<String, dynamic> _userProperties = {};
  String? _userId;

  List<Map<String, dynamic>> get events => List.unmodifiable(_events);
  Map<String, dynamic> get userProperties => Map.unmodifiable(_userProperties);
  String? get userId => _userId;

  @override
  Future<void> trackEvent(
      String eventName, Map<String, dynamic>? parameters) async {
    _events.add({
      'eventName': eventName,
      'parameters': parameters ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    });
    logger.d('Mock Analytics Event: $eventName - $parameters');
  }

  @override
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    _userProperties.addAll(properties);
    logger.d('Mock Analytics User Properties Set - $properties');
  }

  @override
  Future<void> setUserId(String userId) async {
    _userId = userId;
    logger.d('Mock Analytics User ID Set: $userId');
  }

  @override
  Future<void> trackScreenView(
      String screenName, Map<String, dynamic>? parameters) async {
    await trackEvent('screen_view', {
      'screen_name': screenName,
      ...?parameters,
    });
  }

  @override
  Future<void> logCommentPosted(String contestId, String comment) async {
    await trackEvent('comment_posted', {
      'contest_id': contestId,
      'comment_length': comment.length,
    });
  }

  @override
  Future<void> logCommentLiked(String commentId) async {
    await trackEvent('comment_liked', {
      'comment_id': commentId,
    });
  }

  @override
  Future<void> logShare({required String contestId}) async {
    await trackEvent('contest_shared', {'contest_id': contestId});
  }

  @override
  Future<void> logEvent(
      {required String eventName, Map<String, dynamic>? parameters}) async {
    await trackEvent(eventName, parameters);
  }

  @override
  Future<void> logScreenView(
      {required String screenName, Map<String, dynamic>? parameters}) async {
    await trackScreenView(screenName, parameters);
  }

  @override
  Future<void> logContestSaved(
      {required String contestId, required bool isSaved}) async {
    await trackEvent(
        'contest_saved', {'contest_id': contestId, 'is_saved': isSaved});
  }

  @override
  Future<void> logContestHidden({required String contestId}) async {
    await trackEvent('contest_hidden', {'contest_id': contestId});
  }

  @override
  Future<void> logContestView({required String contestId}) async {
    await trackEvent('contest_viewed', {'contest_id': contestId});
  }

  @override
  Future<void> logFilterApplied({required Map<String, dynamic> filters}) async {
    await trackEvent('filter_applied', filters);
  }

  /// Clear all tracked data (useful for testing)
  void clear() {
    _events.clear();
    _userProperties.clear();
    _userId = null;
  }
}

/// Onboarding-specific analytics service with predefined events
class OnboardingAnalyticsService {
  OnboardingAnalyticsService(this._analyticsService);

  final AnalyticsService _analyticsService;

  /// Track onboarding events
  Future<void> trackOnboardingEvent(
      String eventName, Map<String, dynamic>? parameters) async {
    await _analyticsService.trackEvent(
      'onboarding_$eventName',
      {
        'context': 'onboarding',
        ...?parameters,
      },
    );
  }

  /// Track step completion
  Future<void> trackStepCompleted(
      String stepName, int stepIndex, String configType) async {
    await trackOnboardingEvent('step_completed', {
      'step_name': stepName,
      'step_index': stepIndex,
      'config_type': configType,
    });
  }

  /// Track step skipped
  Future<void> trackStepSkipped(
      String stepName, int stepIndex, String configType) async {
    await trackOnboardingEvent('step_skipped', {
      'step_name': stepName,
      'step_index': stepIndex,
      'config_type': configType,
    });
  }

  /// Track onboarding started
  Future<void> trackOnboardingStarted(String configType, int totalSteps) async {
    await trackOnboardingEvent('started', {
      'config_type': configType,
      'total_steps': totalSteps,
    });
  }

  /// Track onboarding completed
  Future<void> trackOnboardingCompleted(
    String userId,
    String configType,
    int totalSteps,
    int bonusPoints,
    Duration duration,
  ) async {
    await trackOnboardingEvent('completed', {
      'user_id': userId,
      'config_type': configType,
      'total_steps': totalSteps,
      'bonus_points': bonusPoints,
      'duration_ms': duration.inMilliseconds,
    });
  }

  /// Track onboarding failed
  Future<void> trackOnboardingFailed(
    String configType,
    String errorType,
    String errorMessage,
  ) async {
    await trackOnboardingEvent('failed', {
      'config_type': configType,
      'error_type': errorType,
      'error_message': errorMessage,
    });
  }

  /// Track user preferences saved
  Future<void> trackPreferencesSaved(
    String userId,
    String preferenceType,
    int count,
    List<String> values,
  ) async {
    await trackOnboardingEvent('preferences_saved', {
      'user_id': userId,
      'preference_type': preferenceType,
      'count': count,
      'values': values,
    });
  }
}

/// Provider for the analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  // In production, use FirebaseAnalyticsService
  // In development/testing, you might want to use MockAnalyticsService
  return FirebaseAnalyticsService();
});

/// Provider for the onboarding analytics service
final onboardingAnalyticsProvider = Provider<OnboardingAnalyticsService>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return OnboardingAnalyticsService(analyticsService);
});
