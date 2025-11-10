import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/subscription_tiers.dart';
import '../services/tier_management_service.dart';

/// Widget that displays a detailed comparison of subscription tiers
class TierComparisonCard extends ConsumerWidget {
  const TierComparisonCard({
    required this.tier,
    required this.isSelected,
    required this.onSelect,
    super.key,
    this.isAnnual = false,
    this.showPopularBadge = false,
    this.showSavingsBadge = false,
  });

  final SubscriptionTier tier;
  final bool isSelected;
  final VoidCallback onSelect;
  final bool isAnnual;
  final bool showPopularBadge;
  final bool showSavingsBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierService = ref.watch(tierManagementServiceProvider);
    final currentTier = tierService.getCurrentTier();
    final isCurrentTier = currentTier == tier;

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? tier.color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: tier.color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
          color: isSelected ? tier.color.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Stack(
          children: [
            // Main card content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with tier name and price
                  _buildHeader(context, isCurrentTier),

                  const SizedBox(height: 16),

                  // Tagline
                  Text(
                    tier.tagline,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Features list
                  _buildFeaturesList(context),

                  if (tier != SubscriptionTier.free) ...[
                    const SizedBox(height: 20),
                    _buildValueProposition(context),
                  ],
                ],
              ),
            ),

            // Popular badge
            if (showPopularBadge)
              Positioned(
                top: -1,
                left: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Savings badge
            if (showSavingsBadge && isAnnual)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Save 17%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Selection indicator
            if (isSelected)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tier.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),

            // Current plan indicator
            if (isCurrentTier && !isSelected)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text(
                    'Current',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isCurrentTier) {
    final price = isAnnual ? tier.annualPrice : tier.price;
    final originalMonthlyPrice = isAnnual ? tier.price : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tier icon and name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getTierIcon(),
                    size: 24,
                    color: tier.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tier.displayName,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: tier.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (tier != SubscriptionTier.free) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isAnnual ? '/year' : '/month',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (isAnnual && originalMonthlyPrice != null)
                  Text(
                    'Normally \$${(originalMonthlyPrice * 12).toStringAsFixed(2)}/year',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[500],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features & Benefits',
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...tier.features.map((feature) => _buildFeatureItem(feature)),
      ],
    );
  }

  Widget _buildFeatureItem(String feature) {
    final isHighlight = feature.contains('Unlimited') ||
        feature.contains('Exclusive') ||
        feature.contains('Premium') ||
        feature.contains('Ad-free');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle,
              size: 16,
              color: isHighlight ? tier.color : Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
                color: isHighlight ? tier.color : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueProposition(BuildContext context) {
    final monthlyPrice = tier.price;
    final dailyPrice = monthlyPrice / 30;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tier.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tier.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate,
                size: 16,
                color: tier.color,
              ),
              const SizedBox(width: 6),
              Text(
                'Value Breakdown',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: tier.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Just \$${dailyPrice.toStringAsFixed(2)} per day',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (tier == SubscriptionTier.basic)
            Text(
              '• Save time with unlimited entries\n• Remove all ads\n• Compete on leaderboards',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
            )
          else if (tier == SubscriptionTier.premium)
            Text(
              '• Auto-entry saves hours weekly\n• Exclusive contests = better odds\n• Analytics optimize your strategy',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getTierIcon() {
    switch (tier) {
      case SubscriptionTier.free:
        return Icons.person;
      case SubscriptionTier.basic:
        return Icons.star;
      case SubscriptionTier.premium:
        return Icons.workspace_premium;
    }
  }
}

/// Widget that shows tier limits comparison
class TierLimitsComparisonWidget extends StatelessWidget {
  const TierLimitsComparisonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Comparison',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Table header
            Row(
              children: [
                const SizedBox(width: 120),
                _buildTableHeader('Free', SubscriptionTier.free.color),
                _buildTableHeader('Basic', SubscriptionTier.basic.color),
                _buildTableHeader('Premium', SubscriptionTier.premium.color),
              ],
            ),

            const Divider(height: 24),

            // Feature rows
            _buildFeatureRow('Daily Entries', '15', 'Unlimited', 'Unlimited'),
            _buildFeatureRow('Saved Contests', '5', '50', 'Unlimited'),
            _buildFeatureRow('Notifications/Day', '3', '15', 'Unlimited'),
            _buildFeatureRow('Filter Presets', '3', '10', '50'),
            _buildFeatureRow('Entry History', '30 days', '90 days', 'Forever'),
            _buildFeatureRow('SweepCoins Rate', '1x', '2x', '3x'),
            _buildFeatureRow('Ads', 'Yes', 'No', 'No'),
            _buildFeatureRow('Leaderboards', 'No', 'Yes', 'Yes'),
            _buildFeatureRow('Auto-Entry', 'No', 'No', 'Yes'),
            _buildFeatureRow('Analytics', 'No', 'No', 'Yes'),

            const Divider(height: 24),

            // Price row
            Row(
              children: [
                const SizedBox(
                  width: 120,
                  child: Text(
                    'Monthly Price',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildTableCell('Free', isPrimary: true),
                _buildTableCell(_getBasicPrice(ref), isPrimary: true),
                _buildTableCell(_getPremiumPrice(ref), isPrimary: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text, Color color) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
      String feature, String free, String basic, String premium) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              feature,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          _buildTableCell(free),
          _buildTableCell(basic),
          _buildTableCell(premium),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isPrimary = false}) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            fontSize: isPrimary ? 14 : 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Get dynamic basic plan price from subscription service
  String _getBasicPrice(WidgetRef ref) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final plans = subscriptionService.plans;

    // Look for basic monthly plan first, then any basic plan
    final basicPlan = plans.firstWhere(
      (plan) => plan.id.contains('basic') && plan.id.contains('monthly'),
      orElse: () => plans.firstWhere(
        (plan) => plan.id.contains('basic'),
        orElse: () => plans.isNotEmpty ? plans.first : null,
      ),
    );

    return basicPlan?.price ?? '\$4.99'; // Fallback price
  }

  /// Get dynamic premium plan price from subscription service
  String _getPremiumPrice(WidgetRef ref) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final plans = subscriptionService.plans;

    // Look for premium monthly plan first, then any premium plan
    final premiumPlan = plans.firstWhere(
      (plan) => plan.id.contains('premium') && plan.id.contains('monthly'),
      orElse: () => plans.firstWhere(
        (plan) => plan.id.contains('premium'),
        orElse: () => plans.length > 1 ? plans[1] : null,
      ),
    );

    return premiumPlan?.price ?? '\$9.99'; // Fallback price
  }
}
