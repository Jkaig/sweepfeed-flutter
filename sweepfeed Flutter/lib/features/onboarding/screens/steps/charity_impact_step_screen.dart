import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_template.dart';

class CharityImpactStepScreen extends StatelessWidget {
  const CharityImpactStepScreen({
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
            Icons.favorite,
            size: 100,
            color: AppColors.successGreen,
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            'Enter to Win &\nSupport Charity',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            'Every contest entry supports verified charities through Every.org',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Impact visualization
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryMedium,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.successGreen.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '30% of ad revenue → Charity',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Revenue split visualization
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.successGreen,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(8),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '30%\nCharity',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.electricBlue,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(8),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '70% Development',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Your participation makes a real difference!',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Continue button
          OnboardingButton(
            text: 'I love this!',
            onPressed: onNext,
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}
