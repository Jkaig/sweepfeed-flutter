import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
  Widget build(BuildContext context) {
    return OnboardingTemplate(
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
          Text(
            'Win Real Prizes,\nCompletely Free!',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            'Enter daily contests for a chance to win amazing prizes – gift cards, electronics, cash, and more!',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Feature pills
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryMedium,
              borderRadius: BorderRadius.circular(12),
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
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(String text, IconData icon) {
    return Column(
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
}
