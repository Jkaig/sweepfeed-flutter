import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// ANR-free loading screen that shows while background initialization completes
class ANRFreeLoadingScreen extends ConsumerWidget {
  const ANRFreeLoadingScreen({
    required this.child,
    super.key,
  });
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final criticalServicesReady = ref.watch(criticalServicesReadyProvider);
    final initProgress = ref.watch(initializationProgressProvider);

    // Show loading screen only if critical services aren't ready
    if (!criticalServicesReady) {
      return _buildLoadingScreen(context, initProgress);
    }

    // Critical services are ready, show the app
    return child;
  }

  Widget _buildLoadingScreen(BuildContext context, double progress) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.cyberYellow,
                      AppColors.mangoTangoStart,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyberYellow.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.star,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 40),

              // App title
              Text(
                'SWEEPFEED',
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.cyberYellow,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'YOUR DAILY SHOT AT GLORY',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textLight,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 60),

              // Progress indicator
              Container(
                width: 250,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primaryMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.cyberYellow,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Initializing... ${(progress * 100).toInt()}%',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
              ),

              const SizedBox(height: 40),

              // Loading tips or messages
              _buildLoadingTip(),
            ],
          ),
        ),
      );

  Widget _buildLoadingTip() {
    const tips = [
      '💡 Tip: Enter contests early for better chances!',
      '🏆 Daily entries increase your winning odds',
      '⚡ Check ending soon contests for quick wins',
      '🎯 Filter by category to find your favorites',
      '💫 Save contests you love for later',
    ];

    // Show different tips based on time to keep it interesting
    final tipIndex =
        (DateTime.now().millisecondsSinceEpoch ~/ 3000) % tips.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyberYellow.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        tips[tipIndex],
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textWhite,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Wrapper widget that handles the transition from loading to app
class ANRFreeAppWrapper extends ConsumerWidget {
  const ANRFreeAppWrapper({
    required this.app,
    super.key,
  });
  final Widget app;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ANRFreeLoadingScreen(
        child: app,
      );
}

/// Progress indicator for async operations
class AsyncProgressIndicator extends ConsumerWidget {
  const AsyncProgressIndicator({
    super.key,
    this.message = 'Loading...',
  });
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataLoadingComplete = ref.watch(dataLoadingCompleteProvider);

    if (dataLoadingComplete) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.cyberYellow,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
