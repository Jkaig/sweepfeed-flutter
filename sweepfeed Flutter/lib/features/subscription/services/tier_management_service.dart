import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/providers.dart';
import '../models/subscription_tiers.dart';

/// Service for managing subscription tier features and feature gates
class TierManagementService with ChangeNotifier {
  TierManagementService(this._ref);

  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _dailyEntriesCountKey = 'daily_entries_count';
  static const String _dailyEntriesDateKey = 'daily_entries_date';
  static const String _dailyNotificationsCountKey = 'daily_notifications_count';
  static const String _dailyNotificationsDateKey = 'daily_notifications_date';

  int _todayEntriesCount = 0;
  int _todayNotificationsCount = 0;
  DateTime _lastEntryDate = DateTime.now();
  DateTime _lastNotificationDate = DateTime.now();

  int get todayEntriesCount => _todayEntriesCount;
  int get todayNotificationsCount => _todayNotificationsCount;

  /// Initialize the service and load cached data
  Future<void> initialize() async {
    await _loadCachedCounts();
    notifyListeners();
  }

  /// Get the current user's subscription tier
  SubscriptionTier getCurrentTier() {
    final subscriptionService = _ref.read(subscriptionServiceProvider);
    return subscriptionService.currentTier;
  }

  /// Update user's subscription tier (called by RevenueCat service)
  Future<void> updateUserTier(SubscriptionTier newTier) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'subscriptionTier': newTier.name,
        'tierUpdatedAt': FieldValue.serverTimestamp(),
      });

      await _trackTierUsage('tier_updated', {
        'new_tier': newTier.name,
        'timestamp': DateTime.now().toIso8601String(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user tier: $e');
    }
  }

  /// Check if user can enter a contest based on their tier limits
  Future<bool> canEnterContest() async {
    final tier = getCurrentTier();
    final limit = tier.dailyEntryLimit;

    if (limit == null) {
      return true; // Unlimited for Basic/Premium
    }

    await _updateDailyCount();
    return _todayEntriesCount < limit;
  }

  /// Record a contest entry and update daily count
  Future<void> recordContestEntry() async {
    await _updateDailyCount();
    _todayEntriesCount++;
    await _saveDailyCount();

    // Track analytics
    await _trackTierUsage('contest_entry', {
      'tier': getCurrentTier().name,
      'entries_today': _todayEntriesCount,
      'limit': getCurrentTier().dailyEntryLimit,
    });

    notifyListeners();
  }

  /// Check if user can save more contests based on their tier
  Future<bool> canSaveContest() async {
    final tier = getCurrentTier();
    final limit = tier.maxSavedContests;

    if (limit == null) {
      return true; // Unlimited for Premium
    }

    // Get current saved count from user profile or Firestore
    final savedCount = await _getCurrentSavedContestsCount();
    return savedCount < limit;
  }

  /// Check if user can send more notifications today
  Future<bool> canSendNotification() async {
    final tier = getCurrentTier();
    final limit = tier.dailyNotificationLimit;

    if (limit == null) {
      return true; // Unlimited for Premium
    }

    await _updateDailyNotificationCount();
    return _todayNotificationsCount < limit;
  }

  /// Record a notification sent and update daily count
  Future<void> recordNotificationSent() async {
    await _updateDailyNotificationCount();
    _todayNotificationsCount++;
    await _saveNotificationCount();
    notifyListeners();
  }

  /// Check if user has access to leaderboards
  bool hasLeaderboardAccess() {
    return getCurrentTier().hasLeaderboardAccess;
  }

  /// Check if user has access to social challenges
  bool hasSocialChallengesAccess() {
    return getCurrentTier().hasSocialChallengesAccess;
  }

  /// Check if user has ad-free experience
  bool hasAdFreeExperience() {
    return getCurrentTier().isAdFree;
  }

  /// Check if user has auto-entry scheduling
  bool hasAutoEntryScheduling() {
    return getCurrentTier().hasAutoEntryScheduling;
  }

  /// Check if user has exclusive partner sweepstakes access
  bool hasExclusivePartnerSweepstakes() {
    return getCurrentTier().hasExclusivePartnerSweepstakes;
  }

  /// Check if user has analytics features
  bool hasAnalytics() {
    return getCurrentTier().hasAnalytics;
  }

  /// Check if user has priority customer support
  bool hasPrioritySupport() {
    return getCurrentTier().hasPrioritySupport;
  }

  /// Get the SweepCoins multiplier for the current tier
  double getSweepCoinsMultiplier() {
    return getCurrentTier().sweepCoinsMultiplier;
  }

  /// Get remaining entries for today
  int getRemainingEntriesToday() {
    final tier = getCurrentTier();
    final limit = tier.dailyEntryLimit;

    if (limit == null) {
      return -1; // Unlimited
    }

    return (limit - _todayEntriesCount).clamp(0, limit);
  }

  /// Get remaining notifications for today
  int getRemainingNotificationsToday() {
    final tier = getCurrentTier();
    final limit = tier.dailyNotificationLimit;

    if (limit == null) {
      return -1; // Unlimited
    }

    return (limit - _todayNotificationsCount).clamp(0, limit);
  }

  /// Check if user should see upgrade prompt based on usage
  bool shouldShowUpgradePrompt() {
    final tier = getCurrentTier();

    switch (tier) {
      case SubscriptionTier.free:
        // Show upgrade if hitting limits frequently
        final entryLimit = tier.dailyEntryLimit!;
        final notificationLimit = tier.dailyNotificationLimit!;

        return _todayEntriesCount >= (entryLimit * 0.8) || // 80% of entry limit
            _todayNotificationsCount >= (notificationLimit * 0.8);

      case SubscriptionTier.basic:
        // Show premium upgrade if interested in exclusive features
        return false; // Will be determined by user behavior analytics

      case SubscriptionTier.premium:
        return false; // No upgrade available
    }
  }

  /// Get upgrade trigger context for the current user
  Map<String, dynamic> getUpgradeTriggerContext() {
    final tier = getCurrentTier();

    return {
      'current_tier': tier.name,
      'entries_today': _todayEntriesCount,
      'entry_limit': tier.dailyEntryLimit,
      'notifications_today': _todayNotificationsCount,
      'notification_limit': tier.dailyNotificationLimit,
      'should_show_prompt': shouldShowUpgradePrompt(),
      'upgrade_triggers': tier.upgradeTrigggers,
    };
  }

  /// Reset daily counts (called at midnight)
  Future<void> resetDailyCounts() async {
    _todayEntriesCount = 0;
    _todayNotificationsCount = 0;
    _lastEntryDate = DateTime.now();
    _lastNotificationDate = DateTime.now();

    await _saveDailyCount();
    await _saveNotificationCount();
    notifyListeners();
  }

  /// Private methods

  Future<void> _loadCachedCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _todayEntriesCount = prefs.getInt(_dailyEntriesCountKey) ?? 0;
      _todayNotificationsCount = prefs.getInt(_dailyNotificationsCountKey) ?? 0;

      final entryDateStr = prefs.getString(_dailyEntriesDateKey);
      if (entryDateStr != null) {
        _lastEntryDate = DateTime.parse(entryDateStr);
      }

      final notificationDateStr = prefs.getString(_dailyNotificationsDateKey);
      if (notificationDateStr != null) {
        _lastNotificationDate = DateTime.parse(notificationDateStr);
      }

      // Reset counts if it's a new day
      final now = DateTime.now();
      if (!_isSameDay(_lastEntryDate, now)) {
        _todayEntriesCount = 0;
        _lastEntryDate = now;
      }

      if (!_isSameDay(_lastNotificationDate, now)) {
        _todayNotificationsCount = 0;
        _lastNotificationDate = now;
      }
    } catch (e) {
      debugPrint('Error loading cached counts: $e');
    }
  }

  Future<void> _updateDailyCount() async {
    final now = DateTime.now();
    if (!_isSameDay(_lastEntryDate, now)) {
      _todayEntriesCount = 0;
      _lastEntryDate = now;
    }
  }

  Future<void> _updateDailyNotificationCount() async {
    final now = DateTime.now();
    if (!_isSameDay(_lastNotificationDate, now)) {
      _todayNotificationsCount = 0;
      _lastNotificationDate = now;
    }
  }

  Future<void> _saveDailyCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dailyEntriesCountKey, _todayEntriesCount);
      await prefs.setString(
          _dailyEntriesDateKey, _lastEntryDate.toIso8601String());
    } catch (e) {
      debugPrint('Error saving daily count: $e');
    }
  }

  Future<void> _saveNotificationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dailyNotificationsCountKey, _todayNotificationsCount);
      await prefs.setString(
          _dailyNotificationsDateKey, _lastNotificationDate.toIso8601String());
    } catch (e) {
      debugPrint('Error saving notification count: $e');
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<int> _getCurrentSavedContestsCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_contests')
          .get();

      return doc.docs.length;
    } catch (e) {
      debugPrint('Error getting saved contests count: $e');
      return 0;
    }
  }

  Future<void> _trackTierUsage(
      String event, Map<String, dynamic> properties) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('analytics').doc().set({
        'userId': userId,
        'event': event,
        'properties': properties,
        'timestamp': FieldValue.serverTimestamp(),
        'tier': getCurrentTier().name,
      });
    } catch (e) {
      debugPrint('Error tracking tier usage: $e');
    }
  }
}

// Provider for TierManagementService
final tierManagementServiceProvider =
    ChangeNotifierProvider<TierManagementService>((ref) {
  final service = TierManagementService(ref);
  service.initialize();
  return service;
});
