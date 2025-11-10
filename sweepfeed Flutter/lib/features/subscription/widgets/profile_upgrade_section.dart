import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../models/subscription_tiers.dart';
import '../screens/subscription_purchase_screen.dart';
import '../services/tier_management_service.dart';
import 'locked_feature_card.dart';

class ProfileUpgradeSection extends ConsumerWidget {
  const ProfileUpgradeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierService = ref.watch(tierManagementServiceProvider);
    final currentTier = tierService.getCurrentTier();

    if (currentTier == SubscriptionTier.premium) {
      return const SizedBox.shrink();
    }

    final missingFeatures = _getMissingFeatures(currentTier);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: _getUpgradeTier(currentTier).color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  "What You're Missing",
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currentTier == SubscriptionTier.free
                  ? 'Unlock powerful features to maximize your sweepstakes wins!'
                  : 'Take your sweepstaking to the next level with Premium!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ...missingFeatures.map((feature) => LockedFeatureCard(
                  featureName: feature['name'] as String,
                  featureDescription: feature['description'] as String,
                  requiredTier: feature['tier'] as SubscriptionTier,
                  icon: feature['icon'] as IconData,
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SubscriptionPurchaseScreen(
                        preselectedTier: _getUpgradeTier(currentTier),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getUpgradeTier(currentTier).color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Upgrade to ${_getUpgradeTier(currentTier).displayName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SubscriptionTier _getUpgradeTier(SubscriptionTier currentTier) {
    switch (currentTier) {
      case SubscriptionTier.free:
        return SubscriptionTier.basic;
      case SubscriptionTier.basic:
        return SubscriptionTier.premium;
      case SubscriptionTier.premium:
        return SubscriptionTier.premium;
    }
  }

  List<Map<String, dynamic>> _getMissingFeatures(SubscriptionTier currentTier) {
    if (currentTier == SubscriptionTier.free) {
      return [
        {
          'name': 'Unlimited Daily Entries',
          'description': 'Enter as many contests as you want every day',
          'tier': SubscriptionTier.basic,
          'icon': Icons.all_inclusive,
        },
        {
          'name': 'Leaderboard Access',
          'description': 'Compete with other users and climb the rankings',
          'tier': SubscriptionTier.basic,
          'icon': Icons.leaderboard,
        },
        {
          'name': 'Ad-Free Experience',
          'description': 'Enjoy SweepFeed without any advertisements',
          'tier': SubscriptionTier.basic,
          'icon': Icons.block,
        },
        {
          'name': 'Auto-Entry Scheduling',
          'description': 'Automatically enter contests at optimal times',
          'tier': SubscriptionTier.premium,
          'icon': Icons.schedule,
        },
        {
          'name': 'Advanced Analytics',
          'description': 'Track your winning patterns and optimize strategy',
          'tier': SubscriptionTier.premium,
          'icon': Icons.analytics,
        },
      ];
    } else if (currentTier == SubscriptionTier.basic) {
      return [
        {
          'name': 'Auto-Entry Scheduling',
          'description': 'Automatically enter contests at optimal times',
          'tier': SubscriptionTier.premium,
          'icon': Icons.schedule,
        },
        {
          'name': 'Exclusive Partner Sweepstakes',
          'description': 'Access to special contests with better odds',
          'tier': SubscriptionTier.premium,
          'icon': Icons.workspace_premium,
        },
        {
          'name': 'Advanced Analytics',
          'description': 'Track your winning patterns and optimize strategy',
          'tier': SubscriptionTier.premium,
          'icon': Icons.analytics,
        },
        {
          'name': 'Priority Customer Support',
          'description': 'Get help faster when you need it',
          'tier': SubscriptionTier.premium,
          'icon': Icons.support_agent,
        },
      ];
    }

    return [];
  }
}
