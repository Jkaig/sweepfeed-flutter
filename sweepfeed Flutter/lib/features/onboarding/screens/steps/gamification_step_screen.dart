import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_template.dart';

class GamificationStepScreen extends StatelessWidget {
  const GamificationStepScreen({
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
          const Icon(
            Icons.stars,
            size: 100,
            color: AppColors.accent,
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            'Earn Points,\nGet Extra Chances!',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            'Collect SweepPoints to unlock bonus entries and exclusive rewards',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Points earning methods
          _buildPointsWay(Icons.login, 'Daily login', '+10 points'),
          _buildPointsWay(Icons.share, 'Share contests', '+10 points'),
          _buildPointsWay(Icons.slideshow, 'Watch ads', '+50 points'),
          _buildPointsWay(Icons.person, 'Complete profile', '+50 points'),

          const SizedBox(height: 48),

          // Continue button
          OnboardingButton(
            text: 'Sounds great!',
            onPressed: onNext,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPointsWay(IconData icon, String title, String points) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textWhite,
              ),
            ),
          ),
          Text(
            points,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
