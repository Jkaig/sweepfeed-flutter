import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'onboarding_flow.dart';

class OnboardingIntroScreen extends StatelessWidget {
  const OnboardingIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.scaffoldBackgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Create Your Winner Profile!',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .then(delay: 200.ms)
                  .slideY(duration: 400.ms, begin: 0.2, end: 0),
              const SizedBox(height: 20),
              Text(
                'Get personalized contest recommendations and increase your chances of winning!',
                style: textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 400.ms)
                  .then(delay: 200.ms)
                  .slideY(duration: 400.ms, begin: 0.2, end: 0),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const OnboardingFlow(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Get Started',
                  style: textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 800.ms)
                  .then(delay: 200.ms)
                  .scale(duration: 400.ms, begin: const Offset(0.8, 0.8)),
            ],
          ),
        ),
      ),
    );
  }
  }

