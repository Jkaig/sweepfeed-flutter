import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.onNext, super.key});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primaryMedium],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  SizedBox(
                    height: 250,
                    child: Lottie.asset(
                      'assets/animations/welcome_animation.json',
                      height: 250,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 500))
                      .scale(),
                  const SizedBox(height: 48),
                  Text(
                    'Welcome to SweepFeed!',
                    style: AppTextStyles.displaySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 300))
                      .slideY(),
                  const SizedBox(height: 16),
                  Text(
                    "Your ultimate destination for the world's best sweepstakes and giveaways.",
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.textLight),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 500))
                      .slideY(),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.accent,
                    ),
                    child: Text(
                      "Let's Get Started",
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 700))
                      .slideY(),
                ],
              ),
            ),
          ),
        ),
      );
}
