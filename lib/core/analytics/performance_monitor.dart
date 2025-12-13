import 'package:firebase_analytics/firebase_analytics.dart';

import '../utils/logger.dart';

/// A singleton class for monitoring app performance and tracking analytics.
class PerformanceMonitor {
  /// Returns the singleton instance of [PerformanceMonitor].
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final Map<String, DateTime> _operationStartTimes = {};

  /// Tracks a screen view event.
  Future<void> trackScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      logger.d('Screen view tracked: $screenName');
    } on Exception catch (e) {
      logger.e('Failed to track screen view', error: e);
    }
  }

  /// Tracks a custom event.
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters?.cast<String, Object>(),
      );
      logger.d('Event tracked: $eventName');
    } on Exception catch (e) {
      logger.e('Failed to track event: $eventName', error: e);
    }
  }

  /// Starts a custom timed operation.
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
    logger.d('Started operation: $operationName');
  }

  /// Ends a custom timed operation and logs the duration.
  Future<void> endOperation(
    String operationName, {
    Map<String, dynamic>? additionalData,
  }) async {
    final startTime = _operationStartTimes.remove(operationName);
    if (startTime == null) {
      logger.w('No start time found for operation: $operationName');
      return;
    }

    final duration = DateTime.now().difference(startTime);
    final durationMs = duration.inMilliseconds;

    try {
      await _analytics.logEvent(
        name: 'operation_completed',
        parameters: {
          'operation_name': operationName,
          'duration_ms': durationMs,
          if (additionalData != null) ...additionalData,
        },
      );

      logger.d('Operation completed: $operationName in ${durationMs}ms');

      if (durationMs > 3000) {
        logger
            .w('Slow operation detected: $operationName took ${durationMs}ms');
        await trackEvent(
          'slow_operation',
          parameters: {
            'operation_name': operationName,
            'duration_ms': durationMs,
          },
        );
      }
    } on Exception catch (e) {
      logger.e('Failed to log operation completion: $operationName', error: e);
    }
  }

  /// Tracks a contest view event.
  Future<void> trackContestView(String contestId) async {
    await trackEvent(
      'contest_viewed',
      parameters: {
        'contest_id': contestId,
      },
    );
  }

  /// Tracks a contest entry event.
  Future<void> trackContestEntry(String contestId, String entryMethod) async {
    await trackEvent(
      'contest_entered',
      parameters: {
        'contest_id': contestId,
        'entry_method': entryMethod,
      },
    );
  }

  /// Tracks a search event.
  Future<void> trackSearch(String query, int resultCount) async {
    await trackEvent(
      'search_performed',
      parameters: {
        'query': query,
        'result_count': resultCount,
      },
    );
  }

  /// Tracks a filter event.
  Future<void> trackFilter(String filterType, String filterValue) async {
    await trackEvent(
      'filter_applied',
      parameters: {
        'filter_type': filterType,
        'filter_value': filterValue,
      },
    );
  }

  /// Tracks an error event.
  Future<void> trackError(
    String errorType,
    String errorMessage, {
    String? stackTrace,
  }) async {
    await trackEvent(
      'error_occurred',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (stackTrace != null) 'stack_trace': stackTrace,
      },
    );
  }

  /// Tracks a data load event.
  Future<void> trackDataLoad(
    String dataType,
    int itemCount,
    int durationMs, {
    bool fromCache = false,
  }) async {
    await trackEvent(
      'data_loaded',
      parameters: {
        'data_type': dataType,
        'item_count': itemCount,
        'duration_ms': durationMs,
        'from_cache': fromCache,
      },
    );
  }

  /// Tracks a user action event.
  Future<void> trackUserAction(
    String actionType, {
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent(
      'user_action',
      parameters: {
        'action_type': actionType,
        if (metadata != null) ...metadata,
      },
    );
  }

  /// Sets a user property.
  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      logger.d('User property set: $name = $value');
    } on Exception catch (e) {
      logger.e('Failed to set user property: $name', error: e);
    }
  }

  /// Sets the user ID for analytics.
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      logger.d('User ID set: $userId');
    } on Exception catch (e) {
      logger.e('Failed to set user ID', error: e);
    }
  }
}

/// The singleton instance of [PerformanceMonitor].
final performanceMonitor = PerformanceMonitor();
