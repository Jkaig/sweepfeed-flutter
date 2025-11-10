import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// Service for managing iOS Live Activities for contest countdowns
/// Provides integration with iOS 17+ Live Activities and Dynamic Island
class LiveActivitiesService {
  LiveActivitiesService._internal();
  static const MethodChannel _channel =
      MethodChannel('sweepfeed/live_activities');

  static final LiveActivitiesService _instance =
      LiveActivitiesService._internal();
  static LiveActivitiesService get instance => _instance;

  bool _initialized = false;
  final Map<String, String> _activeActivities = {};

  /// Initialize the Live Activities service
  Future<void> initialize() async {
    if (_initialized || !Platform.isIOS) return;

    try {
      await _channel.invokeMethod('initialize');
      _initialized = true;
      logger.i('Live Activities service initialized');
    } catch (e) {
      logger.e('Error initializing Live Activities service', error: e);
      // Don't rethrow - graceful degradation
    }
  }

  /// Check if Live Activities are supported on this device
  Future<bool> areSupported() async {
    if (!Platform.isIOS || !_initialized) return false;

    try {
      final supported =
          await _channel.invokeMethod<bool>('areSupported') ?? false;
      return supported;
    } catch (e) {
      logger.e('Error checking Live Activities support', error: e);
      return false;
    }
  }

  /// Start a Live Activity for a contest countdown
  Future<String?> startContestCountdown({
    required String contestId,
    required String contestTitle,
    required String prize,
    required DateTime endTime,
    required int currentEntries,
    required int totalEntries,
    String? imageUrl,
    String? backgroundColor,
  }) async {
    if (!Platform.isIOS || !_initialized) return null;

    try {
      final activityData = {
        'contestId': contestId,
        'contestTitle': contestTitle,
        'prize': prize,
        'endTime': endTime.toIso8601String(),
        'currentEntries': currentEntries,
        'totalEntries': totalEntries,
        'imageUrl': imageUrl,
        'backgroundColor': backgroundColor ?? '#0A1929', // Dark theme default
      };

      final activityId = await _channel.invokeMethod<String>(
        'startContestCountdown',
        activityData,
      );

      if (activityId != null) {
        _activeActivities[contestId] = activityId;
        logger.i('Started Live Activity for contest: $contestId');
      }

      return activityId;
    } catch (e) {
      logger.e('Error starting contest countdown Live Activity', error: e);
      return null;
    }
  }

  /// Update an existing Live Activity with new contest data
  Future<bool> updateContestCountdown({
    required String contestId,
    int? currentEntries,
    int? totalEntries,
    String? status,
    String? urgencyMessage,
  }) async {
    if (!Platform.isIOS || !_initialized) return false;

    final activityId = _activeActivities[contestId];
    if (activityId == null) {
      logger.w('No active Live Activity found for contest: $contestId');
      return false;
    }

    try {
      final updateData = {
        'activityId': activityId,
        'currentEntries': currentEntries,
        'totalEntries': totalEntries,
        'status': status,
        'urgencyMessage': urgencyMessage,
        'updateTime': DateTime.now().toIso8601String(),
      };

      final success = await _channel.invokeMethod<bool>(
            'updateContestCountdown',
            updateData,
          ) ??
          false;

      if (success) {
        logger.i('Updated Live Activity for contest: $contestId');
      }

      return success;
    } catch (e) {
      logger.e('Error updating contest countdown Live Activity', error: e);
      return false;
    }
  }

  /// End a Live Activity
  Future<bool> endContestCountdown({
    required String contestId,
    String? finalStatus,
    bool isWinner = false,
  }) async {
    if (!Platform.isIOS || !_initialized) return false;

    final activityId = _activeActivities[contestId];
    if (activityId == null) {
      logger.w('No active Live Activity found for contest: $contestId');
      return false;
    }

    try {
      final endData = {
        'activityId': activityId,
        'finalStatus': finalStatus ?? 'Contest Ended',
        'isWinner': isWinner,
        'endTime': DateTime.now().toIso8601String(),
      };

      final success = await _channel.invokeMethod<bool>(
            'endContestCountdown',
            endData,
          ) ??
          false;

      if (success) {
        _activeActivities.remove(contestId);
        logger.i('Ended Live Activity for contest: $contestId');
      }

      return success;
    } catch (e) {
      logger.e('Error ending contest countdown Live Activity', error: e);
      return false;
    }
  }

  /// Start a Live Activity for winner announcement
  Future<String?> startWinnerAnnouncement({
    required String contestId,
    required String contestTitle,
    required String prize,
    required bool isWinner,
    String? winnerName,
    String? celebrationMessage,
    String? imageUrl,
  }) async {
    if (!Platform.isIOS || !_initialized) return null;

    try {
      final activityData = {
        'contestId': contestId,
        'contestTitle': contestTitle,
        'prize': prize,
        'isWinner': isWinner,
        'winnerName': winnerName,
        'celebrationMessage': celebrationMessage ??
            (isWinner ? 'Congratulations!' : 'Better luck next time!'),
        'imageUrl': imageUrl,
        'announcementTime': DateTime.now().toIso8601String(),
      };

      final activityId = await _channel.invokeMethod<String>(
        'startWinnerAnnouncement',
        activityData,
      );

      if (activityId != null) {
        _activeActivities['winner_$contestId'] = activityId;
        logger.i(
          'Started winner announcement Live Activity for contest: $contestId',
        );
      }

      return activityId;
    } catch (e) {
      logger.e('Error starting winner announcement Live Activity', error: e);
      return null;
    }
  }

  /// Start a Live Activity for daily contest digest
  Future<String?> startDailyDigest({
    required List<Map<String, dynamic>> contests,
    required String digestTitle,
    int? totalNewContests,
    int? totalEndingSoon,
    String? highlightedContest,
  }) async {
    if (!Platform.isIOS || !_initialized) return null;

    try {
      final activityData = {
        'contests': contests,
        'digestTitle': digestTitle,
        'totalNewContests': totalNewContests ?? contests.length,
        'totalEndingSoon': totalEndingSoon ?? 0,
        'highlightedContest': highlightedContest,
        'digestDate': DateTime.now().toIso8601String(),
      };

      final activityId = await _channel.invokeMethod<String>(
        'startDailyDigest',
        activityData,
      );

      if (activityId != null) {
        _activeActivities['daily_digest'] = activityId;
        logger.i('Started daily digest Live Activity');
      }

      return activityId;
    } catch (e) {
      logger.e('Error starting daily digest Live Activity', error: e);
      return null;
    }
  }

  /// Get all active Live Activities
  Future<List<String>> getActiveActivities() async {
    if (!Platform.isIOS || !_initialized) return [];

    try {
      final activities =
          await _channel.invokeMethod<List<String>>('getActiveActivities') ??
              [];
      return activities;
    } catch (e) {
      logger.e('Error getting active Live Activities', error: e);
      return [];
    }
  }

  /// End all active Live Activities
  Future<void> endAllActivities() async {
    if (!Platform.isIOS || !_initialized) return;

    try {
      await _channel.invokeMethod('endAllActivities');
      _activeActivities.clear();
      logger.i('Ended all Live Activities');
    } catch (e) {
      logger.e('Error ending all Live Activities', error: e);
    }
  }

  /// Check if a specific contest has an active Live Activity
  bool hasActiveActivity(String contestId) =>
      _activeActivities.containsKey(contestId);

  /// Get the activity ID for a specific contest
  String? getActivityId(String contestId) => _activeActivities[contestId];

  /// Clean up expired activities
  Future<void> cleanupExpiredActivities() async {
    if (!Platform.isIOS || !_initialized) return;

    try {
      final expiredIds =
          await _channel.invokeMethod<List<String>>('getExpiredActivities') ??
              [];

      for (final expiredId in expiredIds) {
        // Remove from our tracking
        _activeActivities.removeWhere((key, value) => value == expiredId);
      }

      if (expiredIds.isNotEmpty) {
        logger.i('Cleaned up ${expiredIds.length} expired Live Activities');
      }
    } catch (e) {
      logger.e('Error cleaning up expired Live Activities', error: e);
    }
  }
}

/// Data models for Live Activities
class ContestLiveActivityData {
  const ContestLiveActivityData({
    required this.contestId,
    required this.contestTitle,
    required this.prize,
    required this.endTime,
    required this.currentEntries,
    required this.totalEntries,
    this.imageUrl,
    this.status,
    this.urgencyMessage,
  });

  factory ContestLiveActivityData.fromJson(Map<String, dynamic> json) =>
      ContestLiveActivityData(
        contestId: json['contestId'],
        contestTitle: json['contestTitle'],
        prize: json['prize'],
        endTime: DateTime.parse(json['endTime']),
        currentEntries: json['currentEntries'],
        totalEntries: json['totalEntries'],
        imageUrl: json['imageUrl'],
        status: json['status'],
        urgencyMessage: json['urgencyMessage'],
      );
  final String contestId;
  final String contestTitle;
  final String prize;
  final DateTime endTime;
  final int currentEntries;
  final int totalEntries;
  final String? imageUrl;
  final String? status;
  final String? urgencyMessage;

  Map<String, dynamic> toJson() => {
        'contestId': contestId,
        'contestTitle': contestTitle,
        'prize': prize,
        'endTime': endTime.toIso8601String(),
        'currentEntries': currentEntries,
        'totalEntries': totalEntries,
        'imageUrl': imageUrl,
        'status': status,
        'urgencyMessage': urgencyMessage,
      };
}

class WinnerAnnouncementData {
  const WinnerAnnouncementData({
    required this.contestId,
    required this.contestTitle,
    required this.prize,
    required this.isWinner,
    required this.celebrationMessage,
    required this.announcementTime,
    this.winnerName,
    this.imageUrl,
  });
  final String contestId;
  final String contestTitle;
  final String prize;
  final bool isWinner;
  final String? winnerName;
  final String celebrationMessage;
  final String? imageUrl;
  final DateTime announcementTime;

  Map<String, dynamic> toJson() => {
        'contestId': contestId,
        'contestTitle': contestTitle,
        'prize': prize,
        'isWinner': isWinner,
        'winnerName': winnerName,
        'celebrationMessage': celebrationMessage,
        'imageUrl': imageUrl,
        'announcementTime': announcementTime.toIso8601String(),
      };
}

/// Helper methods for integrating Live Activities with ModernNotificationService
extension LiveActivitiesIntegration on LiveActivitiesService {
  /// Automatically start Live Activity based on notification type
  Future<void> handleNotificationWithLiveActivity({
    required String contestId,
    required String contestTitle,
    required String prize,
    required DateTime endTime,
    String? imageUrl,
    String? notificationType,
  }) async {
    // Only create Live Activities for time-sensitive contest notifications
    if (notificationType == 'contestEndingSoon' ||
        notificationType == 'highValueContest') {
      final timeUntilEnd = endTime.difference(DateTime.now());

      // Only create if there's meaningful time left (more than 10 minutes)
      if (timeUntilEnd.inMinutes > 10) {
        await startContestCountdown(
          contestId: contestId,
          contestTitle: contestTitle,
          prize: prize,
          endTime: endTime,
          currentEntries: 0, // Would be populated from actual data
          totalEntries: 1000, // Would be populated from actual data
          imageUrl: imageUrl,
        );
      }
    }
  }

  /// Update Live Activity when user enters contest
  Future<void> updateOnContestEntry(String contestId, int newEntryCount) async {
    if (hasActiveActivity(contestId)) {
      await updateContestCountdown(
        contestId: contestId,
        currentEntries: newEntryCount,
        status: 'You entered this contest!',
      );
    }
  }

  /// Create urgency Live Activity when contest is ending soon
  Future<void> createUrgencyActivity({
    required String contestId,
    required String contestTitle,
    required String prize,
    required DateTime endTime,
    required Duration timeRemaining,
  }) async {
    String urgencyMessage;

    if (timeRemaining.inHours < 1) {
      urgencyMessage = '🔥 Less than 1 hour left!';
    } else if (timeRemaining.inHours < 24) {
      urgencyMessage = '⏰ Ending today!';
    } else {
      urgencyMessage = '📅 ${timeRemaining.inDays} days remaining';
    }

    if (hasActiveActivity(contestId)) {
      await updateContestCountdown(
        contestId: contestId,
        urgencyMessage: urgencyMessage,
        status: 'Hurry up!',
      );
    } else {
      await startContestCountdown(
        contestId: contestId,
        contestTitle: contestTitle,
        prize: prize,
        endTime: endTime,
        currentEntries: 0,
        totalEntries: 1000,
      );
    }
  }
}

/// Global instance
final liveActivitiesService = LiveActivitiesService.instance;
