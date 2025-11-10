import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/onboarding_config.dart';
import '../../navigation/screens/main_screen.dart';
import '../controllers/unified_onboarding_controller.dart';

/// Wrapper that uses the new unified onboarding system
class NewOnboardingWrapper extends ConsumerWidget {
  const NewOnboardingWrapper({
    this.config = OnboardingConfig.defaultConfig,
    super.key,
  });

  final OnboardingConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UnifiedOnboardingController(
      config: config,
      onComplete: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
        );
      },
    );
  }
}

/// Provider to determine which onboarding config to use
/// This could be based on user segment, A/B testing, etc.
final onboardingConfigProvider = Provider<OnboardingConfig>((ref) {
  // For now, return default config
  // In production, this could be determined by:
  // - User type (new vs returning)
  // - A/B testing flags
  // - Feature flags from Firebase Remote Config
  // - User preferences
  return OnboardingConfig.defaultConfig;
});

/// Provider-aware wrapper that selects the appropriate config
class AdaptiveOnboardingWrapper extends ConsumerWidget {
  const AdaptiveOnboardingWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(onboardingConfigProvider);

    return NewOnboardingWrapper(config: config);
  }
}
