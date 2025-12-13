import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/onboarding_config.dart';
import '../../../core/utils/logger.dart';
import '../../navigation/screens/main_screen.dart';
import '../controllers/onboarding_flow_controller.dart';
import '../controllers/unified_onboarding_controller.dart';

/// Feature flag provider for onboarding system selection
/// This allows for staged rollout and A/B testing
final useNewOnboardingProvider = StateProvider<bool>((ref) {
  // Start with new onboarding enabled since it has 9.2/10 rating
  // In production, this could be controlled by:
  // - Firebase Remote Config
  // - A/B testing service
  // - User segmentation
  // - Environment variables
  return true;
});

/// Provider for determining onboarding configuration
/// Can be extended for user-specific configurations
final adaptiveOnboardingConfigProvider = Provider<OnboardingConfig>((ref) {
  // For now, return default config
  // Future enhancements could include:
  // - User type (new vs returning)
  // - A/B testing variations
  // - Feature flags from Firebase Remote Config
  // - Geographic or demographic segmentation
  return OnboardingConfig.defaultConfig;
});

/// Adaptive onboarding wrapper that safely transitions between old and new systems.
/// Supports feature flags for staged rollout and A/B testing.
class AdaptiveOnboardingWrapper extends ConsumerWidget {
  const AdaptiveOnboardingWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useNewOnboarding = ref.watch(useNewOnboardingProvider);
    final config = ref.watch(adaptiveOnboardingConfigProvider);
    final navigator = Navigator.of(context);

    logger.i('AdaptiveOnboardingWrapper: useNewOnboarding=$useNewOnboarding');

    // Define the navigation function. This is passed down to avoid tight coupling
    // with the MainScreen and improve testability
    void navigateToMainScreen() {
      logger.i('Onboarding completed, navigating to MainScreen');
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    }

    if (useNewOnboarding) {
      // Use the new unified onboarding system
      return NewOnboarding(
        config: config,
        onComplete: navigateToMainScreen,
      );
    } else {
      // Fallback to old onboarding system
      return LegacyOnboarding(
        onComplete: navigateToMainScreen,
      );
    }
  }
}

/// Wrapper for the new unified onboarding system
class NewOnboarding extends StatelessWidget {
  const NewOnboarding({
    required this.config,
    required this.onComplete,
    super.key,
  });

  final OnboardingConfig config;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    logger.d('Using new UnifiedOnboardingController');

    return UnifiedOnboardingController(
      config: config,
      onComplete: onComplete,
    );
  }
}

/// Wrapper for the old onboarding system (fallback)
class LegacyOnboarding extends StatelessWidget {
  const LegacyOnboarding({
    required this.onComplete,
    super.key,
  });

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    logger.d('Using legacy OnboardingFlowController as fallback');

    return OnboardingFlowController(
      onComplete: onComplete,
    );
  }
}

/// Provider for onboarding system metrics and monitoring
final onboardingMetricsProvider =
    StateNotifierProvider<OnboardingMetricsNotifier, OnboardingMetrics>(
  (ref) => OnboardingMetricsNotifier(),
);

class OnboardingMetrics {
  const OnboardingMetrics({
    this.systemUsed = '',
    this.startTime,
    this.completionTime,
    this.stepsCompleted = 0,
    this.totalSteps = 0,
  });

  final String systemUsed;
  final DateTime? startTime;
  final DateTime? completionTime;
  final int stepsCompleted;
  final int totalSteps;

  OnboardingMetrics copyWith({
    String? systemUsed,
    DateTime? startTime,
    DateTime? completionTime,
    int? stepsCompleted,
    int? totalSteps,
  }) => OnboardingMetrics(
      systemUsed: systemUsed ?? this.systemUsed,
      startTime: startTime ?? this.startTime,
      completionTime: completionTime ?? this.completionTime,
      stepsCompleted: stepsCompleted ?? this.stepsCompleted,
      totalSteps: totalSteps ?? this.totalSteps,
    );

  Duration? get duration {
    if (startTime != null && completionTime != null) {
      return completionTime!.difference(startTime!);
    }
    return null;
  }

  double get completionRate {
    if (totalSteps == 0) return 0.0;
    return stepsCompleted / totalSteps;
  }
}

class OnboardingMetricsNotifier extends StateNotifier<OnboardingMetrics> {
  OnboardingMetricsNotifier() : super(const OnboardingMetrics());

  void setSystemUsed(String system) {
    state = state.copyWith(
      systemUsed: system,
      startTime: DateTime.now(),
    );
  }

  void updateProgress(int stepsCompleted, int totalSteps) {
    state = state.copyWith(
      stepsCompleted: stepsCompleted,
      totalSteps: totalSteps,
    );
  }

  void markComplete() {
    state = state.copyWith(
      completionTime: DateTime.now(),
    );

    // Log completion metrics for analysis
    logger.i(
      'Onboarding completed: '
      'system=${state.systemUsed}, '
      'duration=${state.duration?.inSeconds}s, '
      'completion_rate=${(state.completionRate * 100).toStringAsFixed(1)}%',
    );
  }

  void reset() {
    state = const OnboardingMetrics();
  }
}

/// Utility extension for easy feature flag management
extension OnboardingFeatureFlags on WidgetRef {
  /// Toggle the onboarding system (useful for testing)
  void toggleOnboardingSystem() {
    final current = read(useNewOnboardingProvider.notifier).state;
    read(useNewOnboardingProvider.notifier).state = !current;
    logger.i('Toggled onboarding system to: ${!current ? "new" : "old"}');
  }

  /// Force use of new onboarding system
  void useNewOnboarding() {
    read(useNewOnboardingProvider.notifier).state = true;
    logger.i('Forced to use new onboarding system');
  }

  /// Force use of old onboarding system (emergency fallback)
  void useOldOnboarding() {
    read(useNewOnboardingProvider.notifier).state = false;
    logger.i('Forced to use old onboarding system (fallback)');
  }
}
