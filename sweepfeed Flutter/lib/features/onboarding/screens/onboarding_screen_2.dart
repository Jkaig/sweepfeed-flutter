import 'package:flutter/material.dart';
import 'package:sweep_feed/features/onboarding/screens/onboarding_screen_3.dart';
import 'package:sweep_feed/features/onboarding/screens/prize_preferences_screen.dart';
import 'package:sweep_feed/features/onboarding/widgets/onboarding_template.dart';
import 'package:sweep_feed/features/onboarding/widgets/feature_highlight_card.dart'; // Import FeatureHighlightCard

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingTemplate(
      animationWidget: Image.asset('assets/icon/appicon.png', height: 150), // Placeholder
      title: "Track Your Entries",
      subtitle: "Never miss an opportunity with intelligent tracking and reminders.",
      highlights: const [ // Kept existing highlights for bullet points
        "Entry tracking and history.",
        "Smart reminder system.",
        "Progress analytics.",
      ],
      featureHighlightsList: const [ // Added new feature highlights
        FeatureHighlightCard(
          icon: Icons.playlist_add_check_circle_outlined,
          title: "Daily Streaks & Checklist",
          description: "Complete daily tasks to build your streak and earn rewards.",
        ),
        FeatureHighlightCard(
          icon: Icons.star_outline_sharp,
          title: "Save & Track Favorites",
          description: "Easily save sweepstakes you like and track your entries.",
        ),
        FeatureHighlightCard(
          icon: Icons.search_outlined,
          title: "Advanced Search & Filters",
          description: "Quickly find the contests that matter most to you.",
        ),
      ],
      onNext: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen3()),
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
