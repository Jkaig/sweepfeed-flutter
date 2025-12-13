import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../models/subscription_tiers.dart';
import '../screens/subscription_purchase_screen.dart';

class LockedFeatureCard extends StatelessWidget {
  const LockedFeatureCard({
    required this.featureName,
    required this.featureDescription,
    required this.requiredTier,
    super.key,
    this.icon,
    this.onUpgradeTap,
  });

  final String featureName;
  final String featureDescription;
  final SubscriptionTier requiredTier;
  final IconData? icon;
  final VoidCallback? onUpgradeTap;

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: requiredTier.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        gradient: LinearGradient(
          colors: [
            requiredTier.color.withValues(alpha: 0.05),
            requiredTier.color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onUpgradeTap ?? () => _showUpgradeDialog(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Lock icon with gradient background
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        requiredTier.color,
                        requiredTier.color.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon ?? Icons.lock,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Feature info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              featureName,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTierBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        featureDescription,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Upgrade arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: requiredTier.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );

  Widget _buildTierBadge() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: requiredTier.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        requiredTier.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: requiredTier.color),
            const SizedBox(width: 12),
            const Text('Unlock Feature'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              featureName,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(featureDescription),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: requiredTier.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: requiredTier.color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: requiredTier.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Requires ${requiredTier.displayName} subscription',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SubscriptionPurchaseScreen(
                    preselectedTier: requiredTier,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: requiredTier.color,
              foregroundColor: Colors.white,
            ),
            child: Text('Upgrade to ${requiredTier.displayName}'),
          ),
        ],
      ),
    );
  }
}
