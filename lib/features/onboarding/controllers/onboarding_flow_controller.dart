// ⚠️ DEPRECATED: This file will be removed after successful deployment
// Last used: October 2024
// Replacement: UnifiedOnboardingController
// Removal date: November 1, 2024 (pending 1 week of stable production)
//
// This legacy onboarding controller has been replaced by the new
// UnifiedOnboardingController which provides:
// - Configurable onboarding steps and flows
// - Better analytics tracking and error handling
// - Progress indicators and skip functionality
// - Superior user experience (9.2/10 vs legacy)
// - A/B testing and remote configuration support
//
// DO NOT USE THIS FILE FOR NEW FEATURES

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/logger.dart';
import '../screens/biometric_setup_screen.dart';
import '../screens/charity_impact_intro_screen.dart';
import '../screens/completion_screen.dart';
import '../screens/gamification_screen.dart';
import '../screens/notification_permission_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/social_connection_screen.dart';
import '../screens/tutorial_screen.dart';
import '../screens/welcome_value_screen.dart';
import '../utils/onboarding_constants.dart';

class OnboardingFlowController extends StatefulWidget {
  const OnboardingFlowController({
    required this.onComplete,
    super.key,
  });
  final VoidCallback onComplete;

  @override
  State<OnboardingFlowController> createState() =>
      _OnboardingFlowControllerState();
}

class _OnboardingFlowControllerState extends State<OnboardingFlowController> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < OnboardingConstants.totalOnboardingScreens - 1) {
      setState(() {
        _currentPage++;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToEnd() {
    setState(() {
      _currentPage = OnboardingConstants.totalOnboardingScreens - 1;
    });
    _pageController.jumpToPage(_currentPage);
  }

  Future<void> _completeOnboarding() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        logger.e('No user found when completing onboarding');
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'onboardingCompleted': true,
        'dustBunniesSystem.currentDB': FieldValue.increment(OnboardingConstants.welcomeBonusPoints),
        'dustBunniesSystem.totalDB': FieldValue.increment(OnboardingConstants.welcomeBonusPoints),
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
      });

      // Verify the update was successful
      final verifyDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final verified = verifyDoc.data()?['onboardingCompleted'] as bool? ?? false;
      
      if (!verified) {
        logger.e('Failed to save onboardingCompleted flag for user ${user.uid}');
        throw Exception('Failed to save onboarding completion status');
      }

      logger.i(
        'Onboarding completed for user ${user.uid}, awarded ${OnboardingConstants.welcomeBonusPoints} DustBunnies',
      );

      widget.onComplete();
    } catch (e) {
      logger.e('Error completing onboarding', error: e);
    }
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              WelcomeValueScreen(
                onNext: _nextPage,
              ),
              GamificationScreen(
                onNext: _nextPage,
                onSkip: _skipToEnd,
              ),
              CharityImpactIntroScreen(
                onNext: _nextPage,
                onSkip: _skipToEnd,
              ),
              SocialConnectionScreen(
                onNext: _nextPage,
                onSkip: _skipToEnd,
              ),
              BiometricSetupScreen(
                onNext: _nextPage,
                onSkip: _nextPage,
              ),
              ProfileSetupScreen(
                onNext: _nextPage,
                onSkip: _skipToEnd,
                currentStep: 6,
              ),
              NotificationPermissionScreen(
                onNext: _nextPage,
                onSkip: _skipToEnd,
                currentStep: 7,
              ),
              TutorialScreen(
                onNext: _nextPage,
                currentStep: 8,
              ),
              CompletionScreen(
                onFinish: _completeOnboarding,
                currentStep: 9,
              ),
            ],
          ),
        ),
      );
}
