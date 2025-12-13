import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../models/subscription_tiers.dart';
import '../screens/paywall_screen.dart';
import '../services/tier_management_service.dart';

/// Widget that gates features based on subscription tier
class FeatureGateWidget extends ConsumerWidget {
  const FeatureGateWidget({
    required this.child,
    required this.requiredTier,
    super.key,
    this.featureName,
    this.description,
    this.showUpgradePrompt = true,
    this.onUpgradePressed,
  });

  final Widget child;
  final SubscriptionTier requiredTier;
  final String? featureName;
  final String? description;
  final bool showUpgradePrompt;
  final VoidCallback? onUpgradePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierService = ref.watch(tierManagementServiceProvider);
    final currentTier = tierService.getCurrentTier();

    // If user has required tier or higher, show the feature
    if (_hasTierAccess(currentTier, requiredTier)) {
      return child;
    }

    // If no upgrade prompt should be shown, return empty container
    if (!showUpgradePrompt) {
      return const SizedBox.shrink();
    }

    // Show upgrade prompt
    return _buildUpgradePrompt(context, currentTier);
  }

  Widget _buildUpgradePrompt(
      BuildContext context, SubscriptionTier currentTier,) => Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: requiredTier.color.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          colors: [
            requiredTier.color.withValues(alpha: 0.05),
            requiredTier.color.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lock icon
          Icon(
            Icons.lock_outline,
            size: 32,
            color: requiredTier.color,
          ),
          const SizedBox(height: 8),

          // Feature name
          if (featureName != null)
            Text(
              featureName!,
              style: AppTextStyles.titleMedium.copyWith(
                color: requiredTier.color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 4),

          // Required tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: requiredTier.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${requiredTier.displayName} Feature',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            description ??
                'This feature is available with ${requiredTier.displayName} subscription.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Upgrade button
          ElevatedButton(
            onPressed: onUpgradePressed ?? () => _showUpgradeScreen(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: requiredTier.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 36),
            ),
            child: Text(
              'Upgrade to ${requiredTier.displayName}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

  bool _hasTierAccess(SubscriptionTier current, SubscriptionTier required) {
    const tierOrder = [
      SubscriptionTier.free,
      SubscriptionTier.basic,
      SubscriptionTier.premium,
    ];

    final currentIndex = tierOrder.indexOf(current);
    final requiredIndex = tierOrder.indexOf(required);

    return currentIndex >= requiredIndex;
  }

  Future<void> _showUpgradeScreen(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PaywallScreen(),
      ),
    );
  }
}

/// Widget for inline feature promotion (doesn't block content)
class FeaturePromotionWidget extends ConsumerWidget {
  const FeaturePromotionWidget({
    required this.requiredTier,
    super.key,
    this.featureName,
    this.description,
    this.onUpgradePressed,
    this.compact = false,
  });

  final SubscriptionTier requiredTier;
  final String? featureName;
  final String? description;
  final VoidCallback? onUpgradePressed;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierService = ref.watch(tierManagementServiceProvider);
    final currentTier = tierService.getCurrentTier();

    // Don't show if user already has this tier
    if (_hasTierAccess(currentTier, requiredTier)) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return _buildCompactPromotion(context);
    }

    return _buildFullPromotion(context);
  }

  Widget _buildCompactPromotion(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: requiredTier.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: requiredTier.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star,
            size: 16,
            color: requiredTier.color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              featureName ?? 'Unlock ${requiredTier.displayName} features',
              style: TextStyle(
                fontSize: 12,
                color: requiredTier.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onUpgradePressed ?? () => _showUpgradeScreen(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Upgrade',
              style: TextStyle(
                fontSize: 12,
                color: requiredTier.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

  Widget _buildFullPromotion(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            requiredTier.color.withValues(alpha: 0.1),
            requiredTier.color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: requiredTier.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: requiredTier.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.workspace_premium,
              color: requiredTier.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  featureName ?? 'Unlock ${requiredTier.displayName} Features',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: requiredTier.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description ?? requiredTier.tagline,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onUpgradePressed ?? () => _showUpgradeScreen(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: requiredTier.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

  bool _hasTierAccess(SubscriptionTier current, SubscriptionTier required) {
    const tierOrder = [
      SubscriptionTier.free,
      SubscriptionTier.basic,
      SubscriptionTier.premium,
    ];

    final currentIndex = tierOrder.indexOf(current);
    final requiredIndex = tierOrder.indexOf(required);

    return currentIndex >= requiredIndex;
  }

  Future<void> _showUpgradeScreen(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PaywallScreen(),
      ),
    );
  }
}
