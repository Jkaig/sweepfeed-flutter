import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';

class ActiveTrialBanner extends ConsumerWidget {
  const ActiveTrialBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    if (!subscriptionService.isInTrialPeriod) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.successGreen.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.timer_outlined,
            color: AppColors.successGreen,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Trial Active: ${subscriptionService.trialTimeRemaining} remaining',
            style: const TextStyle(
              color: AppColors.successGreen,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
