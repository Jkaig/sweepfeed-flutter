// ⚠️ DEPRECATED: This file will be removed after successful deployment
// Last used: October 2024
// Replacement: AdaptiveOnboardingWrapper
// Removal date: November 1, 2024 (pending 1 week of stable production)
//
// This legacy onboarding wrapper has been replaced by the new
// AdaptiveOnboardingWrapper system which provides:
// - Feature flag support for safe rollouts
// - Better error handling and analytics
// - A/B testing capabilities
// - Superior user experience (9.2/10 vs legacy)
//
// DO NOT USE THIS FILE FOR NEW FEATURES

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../navigation/screens/main_screen.dart';
import '../controllers/onboarding_flow_controller.dart';

class OnboardingFlowWrapper extends ConsumerWidget {
  const OnboardingFlowWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => OnboardingFlowController(
        onComplete: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        },
      );
}
