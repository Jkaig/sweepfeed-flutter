import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subscription_tiers.dart';
import '../services/upgrade_trigger_service.dart';

class SubscriptionAnalyticsService with ChangeNotifier {
  SubscriptionAnalyticsService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> trackSubscriptionEvent(
    String event, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _analytics.logEvent(
        name: event,
        parameters: {
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
          ...?parameters,
        },
      );

      await _firestore.collection('subscription_analytics').doc().set({
        'userId': userId,
        'event': event,
        'parameters': parameters ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error tracking subscription event: $e');
    }
  }

  Future<void> trackUpgradePromptShown(
    UpgradeTriggerType triggerType,
    SubscriptionTier targetTier,
  ) async {
    await trackSubscriptionEvent('upgrade_prompt_shown', parameters: {
      'trigger_type': triggerType.name,
      'target_tier': targetTier.name,
    },);
  }

  Future<void> trackUpgradePromptClicked(
    UpgradeTriggerType triggerType,
    SubscriptionTier targetTier,
  ) async {
    await trackSubscriptionEvent('upgrade_prompt_clicked', parameters: {
      'trigger_type': triggerType.name,
      'target_tier': targetTier.name,
    },);
  }

  Future<void> trackUpgradePromptDismissed(
    UpgradeTriggerType triggerType,
    SubscriptionTier targetTier,
    String dismissalType,
  ) async {
    await trackSubscriptionEvent('upgrade_prompt_dismissed', parameters: {
      'trigger_type': triggerType.name,
      'target_tier': targetTier.name,
      'dismissal_type': dismissalType,
    },);
  }

  Future<void> trackSubscriptionPurchase(
    SubscriptionTier tier,
    double price,
    String currency,
    bool isAnnual,
  ) async {
    await trackSubscriptionEvent('subscription_purchase', parameters: {
      'tier': tier.name,
      'price': price,
      'currency': currency,
      'billing_period': isAnnual ? 'annual' : 'monthly',
    },);

    await _analytics.logPurchase(
      value: price,
      currency: currency,
      parameters: {
        'tier': tier.name,
        'billing_period': isAnnual ? 'annual' : 'monthly',
      },
    );
  }

  Future<void> trackSubscriptionCancellation(
    SubscriptionTier tier,
    String reason,
  ) async {
    await trackSubscriptionEvent('subscription_cancelled', parameters: {
      'tier': tier.name,
      'reason': reason,
    },);
  }

  Future<void> trackFeatureGateHit(
    String featureName,
    SubscriptionTier currentTier,
    SubscriptionTier requiredTier,
  ) async {
    await trackSubscriptionEvent('feature_gate_hit', parameters: {
      'feature_name': featureName,
      'current_tier': currentTier.name,
      'required_tier': requiredTier.name,
    },);
  }

  Future<void> trackTierUsage(
    SubscriptionTier tier,
    Map<String, dynamic> usageMetrics,
  ) async {
    await trackSubscriptionEvent('tier_usage', parameters: {
      'tier': tier.name,
      ...usageMetrics,
    },);
  }

  Future<SubscriptionAnalytics> getSubscriptionAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final snapshot = await _firestore
          .collection('subscription_analytics')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final events = snapshot.docs.map((doc) => doc.data()).toList();

      return SubscriptionAnalytics.fromEvents(events);
    } catch (e) {
      debugPrint('Error fetching subscription analytics: $e');
      return SubscriptionAnalytics.empty();
    }
  }

  Future<Map<String, dynamic>> getTierDistribution() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('subscriptionTier', isNotEqualTo: null)
          .get();

      final distribution = <String, int>{
        'free': 0,
        'basic': 0,
        'premium': 0,
      };

      for (final doc in snapshot.docs) {
        final tier = doc.data()['subscriptionTier'] as String?;
        if (tier != null && distribution.containsKey(tier)) {
          distribution[tier] = (distribution[tier] ?? 0) + 1;
        }
      }

      return distribution;
    } catch (e) {
      debugPrint('Error fetching tier distribution: $e');
      return {'free': 0, 'basic': 0, 'premium': 0};
    }
  }

  Future<Map<String, dynamic>> getConversionMetrics() async {
    try {
      final analytics = await getSubscriptionAnalytics();

      final promptsShown = analytics.eventCounts['upgrade_prompt_shown'] ?? 0;
      final promptsClicked =
          analytics.eventCounts['upgrade_prompt_clicked'] ?? 0;
      final purchases = analytics.eventCounts['subscription_purchase'] ?? 0;

      final clickThroughRate =
          promptsShown > 0 ? (promptsClicked / promptsShown) * 100 : 0.0;

      final conversionRate =
          promptsClicked > 0 ? (purchases / promptsClicked) * 100 : 0.0;

      return {
        'prompts_shown': promptsShown,
        'prompts_clicked': promptsClicked,
        'purchases': purchases,
        'click_through_rate': clickThroughRate,
        'conversion_rate': conversionRate,
      };
    } catch (e) {
      debugPrint('Error calculating conversion metrics: $e');
      return {
        'prompts_shown': 0,
        'prompts_clicked': 0,
        'purchases': 0,
        'click_through_rate': 0.0,
        'conversion_rate': 0.0,
      };
    }
  }
}

class SubscriptionAnalytics {
  const SubscriptionAnalytics({
    required this.totalEvents,
    required this.eventCounts,
    required this.tierBreakdown,
    required this.triggerTypePerformance,
  });

  factory SubscriptionAnalytics.fromEvents(List<Map<String, dynamic>> events) {
    final eventCounts = <String, int>{};
    final tierBreakdown = <String, int>{};
    final triggerTypePerformance = <String, Map<String, dynamic>>{};

    for (final event in events) {
      final eventName = event['event'] as String?;
      if (eventName != null) {
        eventCounts[eventName] = (eventCounts[eventName] ?? 0) + 1;
      }

      final parameters = event['parameters'] as Map<String, dynamic>?;
      if (parameters != null) {
        final tier = parameters['tier'] as String?;
        if (tier != null) {
          tierBreakdown[tier] = (tierBreakdown[tier] ?? 0) + 1;
        }

        final triggerType = parameters['trigger_type'] as String?;
        if (triggerType != null && eventName != null) {
          if (!triggerTypePerformance.containsKey(triggerType)) {
            triggerTypePerformance[triggerType] = {
              'shown': 0,
              'clicked': 0,
              'dismissed': 0,
              'converted': 0,
            };
          }

          if (eventName == 'upgrade_prompt_shown') {
            triggerTypePerformance[triggerType]!['shown'] =
                (triggerTypePerformance[triggerType]!['shown'] as int) + 1;
          } else if (eventName == 'upgrade_prompt_clicked') {
            triggerTypePerformance[triggerType]!['clicked'] =
                (triggerTypePerformance[triggerType]!['clicked'] as int) + 1;
          } else if (eventName == 'upgrade_prompt_dismissed') {
            triggerTypePerformance[triggerType]!['dismissed'] =
                (triggerTypePerformance[triggerType]!['dismissed'] as int) + 1;
          } else if (eventName == 'subscription_purchase') {
            triggerTypePerformance[triggerType]!['converted'] =
                (triggerTypePerformance[triggerType]!['converted'] as int) + 1;
          }
        }
      }
    }

    return SubscriptionAnalytics(
      totalEvents: events.length,
      eventCounts: eventCounts,
      tierBreakdown: tierBreakdown,
      triggerTypePerformance: triggerTypePerformance,
    );
  }

  factory SubscriptionAnalytics.empty() => const SubscriptionAnalytics(
      totalEvents: 0,
      eventCounts: {},
      tierBreakdown: {},
      triggerTypePerformance: {},
    );

  final int totalEvents;
  final Map<String, int> eventCounts;
  final Map<String, int> tierBreakdown;
  final Map<String, Map<String, dynamic>> triggerTypePerformance;
}

final subscriptionAnalyticsServiceProvider =
    Provider<SubscriptionAnalyticsService>((ref) => SubscriptionAnalyticsService());
