import 'package:flutter/material.dart';

import '../../../../core/constants/onboarding_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_template.dart';

class CompletionStepScreen extends StatefulWidget {
  const CompletionStepScreen({
    required this.onFinish,
    required this.welcomeBonusPoints,
    super.key,
  });

  final VoidCallback onFinish;
  final int welcomeBonusPoints;

  @override
  State<CompletionStepScreen> createState() => _CompletionStepScreenState();
}

class _CompletionStepScreenState extends State<CompletionStepScreen> {
  bool _isCompleting = false;

  Future<void> _handleFinish() async {
    setState(() {
      _isCompleting = true;
    });

    // Add a small delay for better UX
    await Future.delayed(OnboardingTimingConstants.completionDelay);

    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) => OnboardingTemplate(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
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
              Icons.rocket_launch,
              size: 60,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            'Ready to Win?',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            "You're all set to start winning!",
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Welcome bonus
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryMedium,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/dustbunnies/dustbunny_icon_24.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.pets,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Welcome Bonus: ${widget.welcomeBonusPoints} Dust Bunnies!',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Collect Dust Bunnies for bonus entries!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Features summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryMedium,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildReadyFeature(
                  Icons.emoji_events,
                  'Browse hundreds of contests',
                ),
                const SizedBox(height: 12),
                _buildReadyFeature(
                  Icons.favorite,
                  'Support verified charities',
                ),
                const SizedBox(height: 12),
                _buildReadyFeature(
                  Icons.pets,
                  'Collect Dust Bunnies',
                ),
                const SizedBox(height: 12),
                _buildReadyFeature(
                  Icons.celebration,
                  'Win amazing prizes!',
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Start button
          OnboardingButton(
            text: 'Start Winning!',
            onPressed: _handleFinish,
            isLoading: _isCompleting,
          ),
        ],
      ),
    );

  Widget _buildReadyFeature(IconData icon, String text) => Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ),
      ],
    );
}
