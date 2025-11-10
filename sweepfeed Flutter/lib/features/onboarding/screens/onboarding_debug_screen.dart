import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/logger.dart';
import 'adaptive_onboarding_wrapper.dart';

/// Debug screen for testing onboarding system integration
/// Only available in debug builds
class OnboardingDebugScreen extends ConsumerWidget {
  const OnboardingDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useNewOnboarding = ref.watch(useNewOnboardingProvider);
    final metrics = ref.watch(onboardingMetricsProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text(
          'Onboarding Debug',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textLight,
          ),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current System Status
            Card(
              color: AppColors.primaryLight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current System',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          useNewOnboarding ? Icons.new_releases : Icons.history,
                          color: useNewOnboarding
                              ? AppColors.accent
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          useNewOnboarding
                              ? 'New Unified System (9.2/10)'
                              : 'Legacy System (Fallback)',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // System Toggle Controls
            Card(
              color: AppColors.primaryLight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Controls',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.toggleOnboardingSystem();
                          logger
                              .i('Onboarding system toggled via debug screen');
                        },
                        icon: const Icon(Icons.swap_horiz),
                        label: Text(
                          'Switch to ${useNewOnboarding ? "Legacy" : "New"} System',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textDark,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Force New System Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.useNewOnboarding();
                          logger.i(
                              'Forced to new onboarding system via debug screen');
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Force New System'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: BorderSide(color: AppColors.accent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Force Legacy System Button (Emergency)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.useOldOnboarding();
                          logger.w(
                              'Forced to legacy onboarding system via debug screen (emergency fallback)');
                        },
                        icon: const Icon(Icons.warning),
                        label: const Text('Emergency: Force Legacy'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorRed,
                          side: BorderSide(color: AppColors.errorRed),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Metrics Display
            if (metrics.systemUsed.isNotEmpty)
              Card(
                color: AppColors.primaryLight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Session Metrics',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'System Used: ${metrics.systemUsed}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (metrics.duration != null)
                        Text(
                          'Duration: ${metrics.duration!.inSeconds}s',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      Text(
                        'Progress: ${metrics.stepsCompleted}/${metrics.totalSteps} (${(metrics.completionRate * 100).toStringAsFixed(1)}%)',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // Test Onboarding Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdaptiveOnboardingWrapper(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Test Current Onboarding Flow',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Disclaimer
            Text(
              'This debug screen is only available in development builds.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension to add debug utilities to WidgetRef
extension OnboardingDebugUtils on WidgetRef {
  /// Reset all onboarding metrics
  void resetOnboardingMetrics() {
    read(onboardingMetricsProvider.notifier).reset();
    logger.d('Onboarding metrics reset via debug screen');
  }

  /// Get current onboarding system status for debugging
  Map<String, dynamic> getOnboardingStatus() {
    final useNew = read(useNewOnboardingProvider);
    final metrics = read(onboardingMetricsProvider);

    return {
      'useNewOnboarding': useNew,
      'systemUsed': metrics.systemUsed,
      'completionRate': metrics.completionRate,
      'isActive': metrics.startTime != null && metrics.completionTime == null,
    };
  }
}
