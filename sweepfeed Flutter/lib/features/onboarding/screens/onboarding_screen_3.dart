import 'package:flutter/material.dart';
import 'package:sweep_feed/features/onboarding/screens/prize_preferences_screen.dart';
import 'package:sweep_feed/features/onboarding/widgets/onboarding_template.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingTemplate(
      animationWidget: Image.asset('assets/icon/appicon.png', height: 150), // Placeholder
      title: "Unlock Premium Features",
      subtitle: "Get unlimited access and exclusive benefits",
      highlights: const [
        "Unlimited daily entries",
        "Premium contest access",
        "Ad-free experience",
      ],
      showPremiumCTA: true,
      onNext: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PrizePreferencesScreen()),
        );
      },
      nextButtonText: "Get Premium",
      onSkip: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PrizePreferencesScreen()),
        );
      },
    );
  }
}
