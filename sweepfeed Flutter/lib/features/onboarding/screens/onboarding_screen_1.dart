import 'package:flutter/material.dart';
import 'package:sweep_feed/features/onboarding/screens/onboarding_screen_2.dart';
import 'package:sweep_feed/features/onboarding/screens/prize_preferences_screen.dart';
import 'package:sweep_feed/features/onboarding/widgets/onboarding_template.dart';

class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingTemplate(
      animationWidget: Image.asset('assets/icon/appicon.png', height: 150), // Placeholder
      title: "Discover Amazing Contests",
      subtitle: "Find thousands of sweepstakes and contests tailored to your interests",
      highlights: const [
        "Daily updated contest catalog",
        "Smart filtering by prize value",
        "Verified and legitimate contests only",
      ],
      onNext: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen2()),
        );
      },
      nextButtonText: "Next",
      onSkip: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PrizePreferencesScreen()),
        );
      },
    );
  }
}
