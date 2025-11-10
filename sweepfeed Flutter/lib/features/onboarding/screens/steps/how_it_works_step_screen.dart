import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_template.dart';

class HowItWorksStepScreen extends StatelessWidget {
  const HowItWorksStepScreen({
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
            Icons.swipe_right,
            size: 100,
            color: AppColors.electricBlue,
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            'Simple to Enter,\nFun to Win',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Steps
          _buildStep(1, 'Browse contests', 'Find prizes you love'),
          const SizedBox(height: 16),
          _buildStep(2, 'Tap to enter', "One tap, you're entered!"),
          const SizedBox(height: 16),
          _buildStep(3, 'Win & celebrate', 'We notify winners instantly'),

          const SizedBox(height: 32),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryMedium,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.refresh,
                  color: AppColors.electricBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'New contests added daily!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Continue button
          OnboardingButton(
            text: 'Got it!',
            onPressed: onNext,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String description) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.electricBlue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
