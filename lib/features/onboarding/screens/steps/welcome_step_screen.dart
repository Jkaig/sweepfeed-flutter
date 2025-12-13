import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glassmorphic_container.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_template.dart';

class WelcomeStepScreen extends StatelessWidget {
  const WelcomeStepScreen({
    required this.onNext,
    this.onSkip,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) => OnboardingTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main icon
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.electricBlue],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 60,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 32),

          // Welcome title
          // Welcome title
          GlassmorphicContainer(
            borderRadius: 16,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.1),
            ],
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    'Win Real Prizes,\nCompletely Free!',
                    style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Enter daily contests for a chance to win amazing prizes – gift cards, electronics, cash, and more!',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textWhite.withValues(alpha: 0.95),
                      height: 1.5,
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Feature pills
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryMedium.withValues(alpha: 0.6), // Make semi-transparent
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFeaturePill('100% Free', Icons.check_circle),
                _buildFeaturePill('Daily Prizes', Icons.calendar_today),
                _buildFeaturePill('Easy Entry', Icons.touch_app),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Continue button
          OnboardingButton(
            text: 'Get Started',
            onPressed: onNext,
          ),
        ],
      ),
    );

  Widget _buildFeaturePill(String text, IconData icon) => Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 32),
        const SizedBox(height: 8),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
}
