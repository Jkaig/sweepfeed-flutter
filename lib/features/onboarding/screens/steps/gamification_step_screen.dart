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
  Widget build(BuildContext context) => OnboardingTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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

          const SizedBox(height: 16),

          // Title
          Text(
            'Collect Dust Bunnies,\nGet Extra Chances!',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            'Earn cute Dust Bunnies to unlock bonus entries and exclusive rewards',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textWhite,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Dust Bunny earning methods
          _buildEarnMethod(Icons.login, 'Daily login', '+10'),
          _buildEarnMethod(Icons.share, 'Share contests', '+10'),
          _buildEarnMethod(Icons.slideshow, 'Watch ads', '+50'),
          _buildEarnMethod(Icons.person, 'Complete profile', '+50'),

          const SizedBox(height: 16),

          // Continue button
          OnboardingButton(
            text: 'Sounds great!',
            onPressed: onNext,
          ),
        ],
      ),
    );

  Widget _buildEarnMethod(IconData icon, String title, String amount) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          // Amount with small dust bunny icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amount,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Image.asset(
                'assets/images/dustbunnies/dustbunny_icon_24.png',
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.pets,
                  size: 16,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
}
