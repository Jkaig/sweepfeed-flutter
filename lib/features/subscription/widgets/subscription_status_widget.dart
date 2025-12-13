import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../screens/customer_center_screen.dart';
// Note: revenueCatServiceProvider is imported from providers.dart to avoid ambiguous imports

/// Widget to display current subscription status
class SubscriptionStatusWidget extends ConsumerWidget {
  const SubscriptionStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueCatService = ref.watch(revenueCatServiceProvider);
    final hasPro = revenueCatService.hasProEntitlement();
    final expirationDate = revenueCatService.getSubscriptionExpirationDate();
    final currentTier = revenueCatService.getCurrentTier();

    if (!hasPro) {
      return Card(
        color: AppColors.primaryMedium,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free Plan',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textWhite,
                      ),
                    ),
                    Text(
                      'Upgrade to unlock premium features',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: AppColors.brandCyan.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified,
                  color: AppColors.brandCyan,
                ),
                const SizedBox(width: 12),
                Text(
                  'SweepFeed Pro',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.brandCyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (expirationDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Expires: ${DateFormat('MMM d, yyyy').format(expirationDate)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerCenterScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandCyan,
                foregroundColor: AppColors.primaryDark,
              ),
              child: const Text('Manage Subscription'),
            ),
          ],
        ),
      ),
    );
  }
}

