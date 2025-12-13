import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/providers.dart';
import '../models/subscription_tiers.dart';


/// Service for managing smart upgrade triggers and retention optimization
class UpgradeTriggerService with ChangeNotifier {
  UpgradeTriggerService(this._ref);

  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _lastUpgradePromptKey = 'last_upgrade_prompt';
  static const String _upgradePromptsCountKey = 'upgrade_prompts_count_today';
  static const String _upgradePromptsDateKey = 'upgrade_prompts_date';
  static const String _upgradeCooldownKey = 'upgrade_cooldown_until';
  static const String _featureAccessAttemptsKey = 'feature_access_attempts';

  // Cooldown and limits
  static const Duration upgradeCooldownDuration = Duration(days: 3);
  static const int maxPromptsPerDay = 1;
  static const double usageThresholdPercentage = 0.8;
  static const int consecutiveDaysLimit = 3;
  static const int weeklyUsageDays = 5;

  DateTime? _lastUpgradePrompt;
  DateTime? _upgradeCooldownUntil;
  int _upgradePromptsToday = 0;
  DateTime _upgradePromptsDate = DateTime.now();
  final Map<String, int> _featureAccessAttempts = {};

  /// Initialize the service
  Future<void> initialize() async {
    await _loadCachedData();
    notifyListeners();
  }

  /// Check if user should see an upgrade prompt based on current context
  Future<UpgradeTriggerResult?> checkForUpgradeTrigger() async {
    final tierService = _ref.read(tierManagementServiceProvider);
    final currentTier = tierService.getCurrentTier();

    // Don't show prompts to Premium users
    if (currentTier == SubscriptionTier.premium) {
      return null;
    }

    // Check cooldown and daily limits
    if (!_canShowUpgradePrompt()) {
      return null;
    }

    // Check various trigger conditions in priority order
    final triggers = [
      _checkUsageThresholdTrigger,
      _checkEngagementLevelTrigger,
      _checkTimeBasedTrigger,
      _checkFeatureInterestTrigger,
      _checkValueDemonstrationTrigger,
    ];

    for (final trigger in triggers) {
      final result = await trigger();
      if (result != null) {
        await _recordUpgradePromptShown(result.triggerType);
        return result;
      }
    }

    return null;
  }

  /// Record that user attempted to access a premium feature
  Future<void> recordFeatureAccessAttempt(String featureName) async {
    _featureAccessAttempts[featureName] =
        (_featureAccessAttempts[featureName] ?? 0) + 1;
    await _saveCachedData();
    notifyListeners();
  }

  /// Record that user dismissed an upgrade prompt
  Future<void> recordUpgradePromptDismissed(String triggerType) async {
    _upgradeCooldownUntil = DateTime.now().add(upgradeCooldownDuration);
    await _trackUpgradeEvent('prompt_dismissed', {'trigger_type': triggerType});
    await _saveCachedData();
    notifyListeners();
  }

  /// Record that user clicked on upgrade prompt
  Future<void> recordUpgradePromptClicked(String triggerType) async {
    await _trackUpgradeEvent('prompt_clicked', {'trigger_type': triggerType});
    notifyListeners();
  }

  /// Get personalized upgrade message based on user behavior
  String getPersonalizedUpgradeMessage(
      UpgradeTriggerType triggerType, SubscriptionTier targetTier,) {
    final userName = _ref.read(userProfileProvider).value?.name ?? 'there';

    switch (triggerType) {
      case UpgradeTriggerType.usageThreshold:
        return targetTier == SubscriptionTier.basic
            ? 'Hey $userName! Running low on entries? Upgrade to Basic for unlimited entries and never miss a great contest!'
            : 'Ready for the next level, $userName? Premium gives you auto-entry and exclusive contests!';

      case UpgradeTriggerType.engagementLevel:
        return targetTier == SubscriptionTier.basic
            ? 'Love entering contests, $userName? Basic unlocks unlimited entries, leaderboards, and ad-free browsing!'
            : "You're a contest pro, $userName! Premium adds auto-entry and contest analytics to maximize your wins!";

      case UpgradeTriggerType.timeBased:
        return targetTier == SubscriptionTier.basic
            ? 'Enjoying SweepFeed, $userName? Unlock even more with Basic - no ads and leaderboard access!'
            : 'Ready to dominate, $userName? Premium gives you the ultimate sweepstaking advantage!';

      case UpgradeTriggerType.featureInterest:
        return targetTier == SubscriptionTier.basic
            ? 'Want to unlock this feature? Basic gives you access plus unlimited entries and more!'
            : 'This Premium feature can supercharge your sweepstaking! Upgrade to unlock all exclusive features!';

      case UpgradeTriggerType.valueDemonstration:
        return targetTier == SubscriptionTier.basic
            ? 'Nice wins, $userName! Basic helps you enter more contests and win even bigger prizes!'
            : "Congrats on your success! Premium's auto-entry and analytics can help you win even more!";

      case UpgradeTriggerType.social:
        return targetTier == SubscriptionTier.basic
            ? 'Climb the leaderboard, $userName! Basic unlocks competitive features and more entries!'
            : 'Join the top performers! Premium gives you every advantage to dominate the leaderboards!';
    }
  }

  /// Private methods for checking specific triggers

  Future<UpgradeTriggerResult?> _checkUsageThresholdTrigger() async {
    final tierService = _ref.read(tierManagementServiceProvider);
    final currentTier = tierService.getCurrentTier();

    if (currentTier != SubscriptionTier.free) {
      return null; // Only applies to free users
    }

    final entryLimit = currentTier.dailyEntryLimit!;
    final currentEntries = tierService.todayEntriesCount;
    final usagePercentage = currentEntries / entryLimit;

    // Check if user is consistently hitting 80% of limit
    if (usagePercentage >= usageThresholdPercentage) {
      final consecutiveDays = await _getConsecutiveHighUsageDays();

      if (consecutiveDays >= consecutiveDaysLimit) {
        return UpgradeTriggerResult(
          triggerType: UpgradeTriggerType.usageThreshold,
          targetTier: SubscriptionTier.basic,
          urgency: UpgradeUrgency.high,
          context: {
            'current_entries': currentEntries,
            'entry_limit': entryLimit,
            'usage_percentage': usagePercentage,
            'consecutive_days': consecutiveDays,
          },
        );
      }
    }

    return null;
  }

  Future<UpgradeTriggerResult?> _checkEngagementLevelTrigger() async {
    final userProfile = _ref.read(userProfileProvider).value;
    if (userProfile == null) return null;

    final streak = userProfile.streak ?? 0;
    final points = userProfile.points ?? 0;

    // High engagement indicators
    final isHighlyEngaged = streak >= 7 || points >= 1000;

    if (isHighlyEngaged) {
      final tierService = _ref.read(tierManagementServiceProvider);
      final currentTier = tierService.getCurrentTier();

      final targetTier = currentTier == SubscriptionTier.free
          ? SubscriptionTier.basic
          : SubscriptionTier.premium;

      return UpgradeTriggerResult(
        triggerType: UpgradeTriggerType.engagementLevel,
        targetTier: targetTier,
        urgency: UpgradeUrgency.medium,
        context: {
          'streak': streak,
          'points': points,
          'current_tier': currentTier.name,
        },
      );
    }

    return null;
  }

  Future<UpgradeTriggerResult?> _checkTimeBasedTrigger() async {
    final userProfile = _ref.read(userProfileProvider).value;
    if (userProfile?.createdAt == null) return null;

    final daysSinceJoining =
        DateTime.now().difference(userProfile!.createdAt!.toDate()).inDays;

    // Show upgrade prompt after 7 days of consistent use
    if (daysSinceJoining >= 7 && daysSinceJoining <= 14) {
      final weeklyUsage = await _getWeeklyUsagePattern();

      if (weeklyUsage >= weeklyUsageDays) {
        final tierService = _ref.read(tierManagementServiceProvider);
        final currentTier = tierService.getCurrentTier();

        final targetTier = currentTier == SubscriptionTier.free
            ? SubscriptionTier.basic
            : SubscriptionTier.premium;

        return UpgradeTriggerResult(
          triggerType: UpgradeTriggerType.timeBased,
          targetTier: targetTier,
          urgency: UpgradeUrgency.low,
          context: {
            'days_since_joining': daysSinceJoining,
            'weekly_usage_days': weeklyUsage,
          },
        );
      }
    }

    return null;
  }

  Future<UpgradeTriggerResult?> _checkFeatureInterestTrigger() async {
    // Check if user has attempted to access premium features multiple times
    for (final entry in _featureAccessAttempts.entries) {
      if (entry.value >= 2) {
        // Attempted 2+ times
        final tierService = _ref.read(tierManagementServiceProvider);
        final currentTier = tierService.getCurrentTier();

        final targetTier = _getRequiredTierForFeature(entry.key);

        if (currentTier != targetTier && _hasAccess(currentTier, targetTier)) {
          return UpgradeTriggerResult(
            triggerType: UpgradeTriggerType.featureInterest,
            targetTier: targetTier,
            urgency: UpgradeUrgency.high,
            context: {
              'feature_name': entry.key,
              'access_attempts': entry.value,
            },
          );
        }
      }
    }

    return null;
  }

  Future<UpgradeTriggerResult?> _checkValueDemonstrationTrigger() async {
    // This would check if user has won contests or accumulated savings
    // Implementation depends on how winnings are tracked in the app

    final userProfile = _ref.read(userProfileProvider).value;
    if (userProfile == null) return null;

    final points = userProfile.points ?? 0;

    // If user has accumulated significant points, show value-based upgrade
    if (points >= 500) {
      final tierService = _ref.read(tierManagementServiceProvider);
      final currentTier = tierService.getCurrentTier();

      final targetTier = currentTier == SubscriptionTier.free
          ? SubscriptionTier.basic
          : SubscriptionTier.premium;

      return UpgradeTriggerResult(
        triggerType: UpgradeTriggerType.valueDemonstration,
        targetTier: targetTier,
        urgency: UpgradeUrgency.medium,
        context: {
          'points_earned': points,
          'estimated_value': points * 0.01, // Example calculation
        },
      );
    }

    return null;
  }

  /// Helper methods

  bool _canShowUpgradePrompt() {
    final now = DateTime.now();

    // Check cooldown
    if (_upgradeCooldownUntil != null && now.isBefore(_upgradeCooldownUntil!)) {
      return false;
    }

    // Check daily limit
    if (!_isSameDay(_upgradePromptsDate, now)) {
      _upgradePromptsToday = 0;
      _upgradePromptsDate = now;
    }

    return _upgradePromptsToday < maxPromptsPerDay;
  }

  Future<void> _recordUpgradePromptShown(UpgradeTriggerType triggerType) async {
    _lastUpgradePrompt = DateTime.now();
    _upgradePromptsToday++;

    await _trackUpgradeEvent(
        'prompt_shown', {'trigger_type': triggerType.name},);
    await _saveCachedData();
  }

  SubscriptionTier _getRequiredTierForFeature(String featureName) {
    // Map features to required tiers
    const premiumFeatures = ['auto_entry', 'analytics', 'exclusive_contests'];
    const basicFeatures = [
      'leaderboards',
      'social_challenges',
      'advanced_filters',
    ];

    if (premiumFeatures.contains(featureName)) {
      return SubscriptionTier.premium;
    } else if (basicFeatures.contains(featureName)) {
      return SubscriptionTier.basic;
    }

    return SubscriptionTier.free;
  }

  bool _hasAccess(SubscriptionTier current, SubscriptionTier required) {
    const tierOrder = [
      SubscriptionTier.free,
      SubscriptionTier.basic,
      SubscriptionTier.premium,
    ];
    return tierOrder.indexOf(current) < tierOrder.indexOf(required);
  }

  Future<int> _getConsecutiveHighUsageDays() async {
    // This would query user analytics to check consecutive high usage days
    // For now, return a placeholder
    return Random().nextInt(5);
  }

  Future<int> _getWeeklyUsagePattern() async {
    // This would check how many days in the past week the user was active
    // For now, return a placeholder
    return Random().nextInt(7) + 1;
  }

  bool _isSameDay(DateTime date1, DateTime date2) => date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lastPromptStr = prefs.getString(_lastUpgradePromptKey);
      if (lastPromptStr != null) {
        _lastUpgradePrompt = DateTime.parse(lastPromptStr);
      }

      final cooldownStr = prefs.getString(_upgradeCooldownKey);
      if (cooldownStr != null) {
        _upgradeCooldownUntil = DateTime.parse(cooldownStr);
      }

      _upgradePromptsToday = prefs.getInt(_upgradePromptsCountKey) ?? 0;

      final promptsDateStr = prefs.getString(_upgradePromptsDateKey);
      if (promptsDateStr != null) {
        _upgradePromptsDate = DateTime.parse(promptsDateStr);
      }

      final attemptsJson = prefs.getString(_featureAccessAttemptsKey);
      if (attemptsJson != null) {
        // Would need to implement JSON parsing for Map<String, int>
        // For now, keep empty map
      }
    } catch (e) {
      debugPrint('Error loading upgrade trigger cache: $e');
    }
  }

  Future<void> _saveCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_lastUpgradePrompt != null) {
        await prefs.setString(
            _lastUpgradePromptKey, _lastUpgradePrompt!.toIso8601String(),);
      }

      if (_upgradeCooldownUntil != null) {
        await prefs.setString(
            _upgradeCooldownKey, _upgradeCooldownUntil!.toIso8601String(),);
      }

      await prefs.setInt(_upgradePromptsCountKey, _upgradePromptsToday);
      await prefs.setString(
          _upgradePromptsDateKey, _upgradePromptsDate.toIso8601String(),);

      // Would implement JSON serialization for _featureAccessAttempts
    } catch (e) {
      debugPrint('Error saving upgrade trigger cache: $e');
    }
  }

  Future<void> _trackUpgradeEvent(
      String event, Map<String, dynamic> properties,) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('upgrade_analytics').doc().set({
        'userId': userId,
        'event': event,
        'properties': properties,
        'timestamp': FieldValue.serverTimestamp(),
        'tier': _ref.read(tierManagementServiceProvider).getCurrentTier().name,
      });
    } catch (e) {
      debugPrint('Error tracking upgrade event: $e');
    }
  }
}

/// Data classes for upgrade triggers

class UpgradeTriggerResult {
  const UpgradeTriggerResult({
    required this.triggerType,
    required this.targetTier,
    required this.urgency,
    required this.context,
  });

  final UpgradeTriggerType triggerType;
  final SubscriptionTier targetTier;
  final UpgradeUrgency urgency;
  final Map<String, dynamic> context;
}

enum UpgradeTriggerType {
  usageThreshold,
  engagementLevel,
  timeBased,
  featureInterest,
  valueDemonstration,
  social,
}

enum UpgradeUrgency {
  low,
  medium,
  high,
}

// Provider for UpgradeTriggerService
final upgradeTriggerServiceProvider =
    ChangeNotifierProvider<UpgradeTriggerService>((ref) {
  final service = UpgradeTriggerService(ref);
  service.initialize();
  return service;
});
