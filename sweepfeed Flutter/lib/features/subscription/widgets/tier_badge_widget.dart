import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../models/subscription_tiers.dart';
import '../services/tier_management_service.dart';

/// Widget that displays the user's current subscription tier as a badge
class TierBadgeWidget extends ConsumerWidget {
  const TierBadgeWidget({
    super.key,
    this.showTierName = true,
    this.size = TierBadgeSize.medium,
    this.style = TierBadgeStyle.filled,
    this.onTap,
  });

  final bool showTierName;
  final TierBadgeSize size;
  final TierBadgeStyle style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierService = ref.watch(tierManagementServiceProvider);
    final currentTier = tierService.getCurrentTier();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: _getPadding(),
        decoration: _getDecoration(currentTier),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTierIcon(currentTier),
              size: _getIconSize(),
              color: _getIconColor(currentTier),
            ),
            if (showTierName) ...[
              SizedBox(width: _getSpacing()),
              Text(
                currentTier.displayName,
                style: _getTextStyle(currentTier),
              ),
            ],
          ],
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case TierBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
      case TierBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case TierBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }

  double _getIconSize() {
    switch (size) {
      case TierBadgeSize.small:
        return 12;
      case TierBadgeSize.medium:
        return 16;
      case TierBadgeSize.large:
        return 20;
    }
  }

  double _getSpacing() {
    switch (size) {
      case TierBadgeSize.small:
        return 4;
      case TierBadgeSize.medium:
        return 6;
      case TierBadgeSize.large:
        return 8;
    }
  }

  BoxDecoration _getDecoration(SubscriptionTier tier) {
    switch (style) {
      case TierBadgeStyle.filled:
        return BoxDecoration(
          color: tier.color,
          borderRadius: BorderRadius.circular(12),
        );
      case TierBadgeStyle.outlined:
        return BoxDecoration(
          border: Border.all(color: tier.color, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        );
      case TierBadgeStyle.subtle:
        return BoxDecoration(
          color: tier.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        );
    }
  }

  Color _getIconColor(SubscriptionTier tier) {
    switch (style) {
      case TierBadgeStyle.filled:
        return Colors.white;
      case TierBadgeStyle.outlined:
      case TierBadgeStyle.subtle:
        return tier.color;
    }
  }

  TextStyle _getTextStyle(SubscriptionTier tier) {
    final baseStyle = switch (size) {
      TierBadgeSize.small => AppTextStyles.bodySmall,
      TierBadgeSize.medium => AppTextStyles.bodyMedium,
      TierBadgeSize.large => AppTextStyles.titleSmall,
    };

    final color = switch (style) {
      TierBadgeStyle.filled => Colors.white,
      TierBadgeStyle.outlined => tier.color,
      TierBadgeStyle.subtle => tier.color,
    };

    return baseStyle.copyWith(
      color: color,
      fontWeight: FontWeight.bold,
    );
  }

  IconData _getTierIcon(SubscriptionTier tier) {
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

/// Widget that shows tier status with additional context
class TierStatusWidget extends ConsumerWidget {
  const TierStatusWidget({
    super.key,
    this.showBenefits = true,
    this.showUpgradeAction = true,
  });

  final bool showBenefits;
  final bool showUpgradeAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierService = ref.watch(tierManagementServiceProvider);
    final currentTier = tierService.getCurrentTier();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with tier badge and tagline
            Row(
              children: [
                TierBadgeWidget(
                  size: TierBadgeSize.large,
                  style: TierBadgeStyle.filled,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTier.tagline,
                        style: AppTextStyles.titleMedium,
                      ),
                      if (currentTier != SubscriptionTier.premium &&
                          showUpgradeAction)
                        TextButton(
                          onPressed: () => _showUpgradeOptions(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Upgrade your plan',
                                style: TextStyle(
                                  color: currentTier.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: currentTier.color,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            if (showBenefits) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Current tier benefits
              Text(
                'Your ${currentTier.displayName} Benefits',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              ...currentTier.features.take(3).map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: currentTier.color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

              if (currentTier.features.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${currentTier.features.length - 3} more benefits',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _showUpgradeOptions(BuildContext context) {
    // Navigate to subscription screen or show upgrade modal
    // This would be implemented based on the app's navigation pattern
  }
}

/// Widget that shows usage limits and remaining quotas
class TierUsageWidget extends ConsumerWidget {
  const TierUsageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierService = ref.watch(tierManagementServiceProvider);
    final currentTier = tierService.getCurrentTier();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Usage',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Entry usage
            _buildUsageItem(
              context,
              'Contest Entries',
              tierService.todayEntriesCount,
              currentTier.dailyEntryLimit,
              Icons.exit_to_app,
            ),

            const SizedBox(height: 8),

            // Notification usage
            _buildUsageItem(
              context,
              'Notifications',
              tierService.todayNotificationsCount,
              currentTier.dailyNotificationLimit,
              Icons.notifications,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageItem(
    BuildContext context,
    String label,
    int used,
    int? limit,
    IconData icon,
  ) {
    final isUnlimited = limit == null;
    final progress = isUnlimited ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final color = progress > 0.8 ? Colors.orange : Colors.blue;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium,
                  ),
                  Text(
                    isUnlimited ? '$used (unlimited)' : '$used / $limit',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (!isUnlimited) ...[
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

enum TierBadgeSize { small, medium, large }

enum TierBadgeStyle { filled, outlined, subtle }
