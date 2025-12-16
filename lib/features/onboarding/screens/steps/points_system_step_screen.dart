import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_template.dart';

// Placeholder for points system step - similar to gamification but with more detail
class PointsSystemStepScreen extends StatelessWidget {
  const PointsSystemStepScreen({
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dust Bunny mascot image
          Image.asset(
            'assets/images/dustbunnies/dustbunny_excited.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.pets,
              size: 80,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Dustbunnies System',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Earn cute Dust Bunnies by entering contests, daily logins, and completing challenges',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textLight,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Earning methods preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryMedium,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildEarnMethod(Icons.login, 'Daily login', '+10'),
                const SizedBox(height: 8),
                _buildEarnMethod(Icons.share, 'Share contests', '+10'),
                const SizedBox(height: 8),
                _buildEarnMethod(Icons.emoji_events, 'Enter contests', '+5'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Use Dust Bunnies to unlock bonus entries and exclusive rewards!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OnboardingButton(
            text: 'Continue',
            onPressed: onNext,
          ),
        ],
      ),
    );

  Widget _buildEarnMethod(IconData icon, String title, String amount) => Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textWhite,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              amount,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Image.asset(
              'assets/images/dustbunnies/dustbunny_icon_24.png',
              width: 18,
              height: 18,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.pets,
                size: 14,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
}
