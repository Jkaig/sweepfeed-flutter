import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_template.dart';

// Placeholder for notification permission step
class NotificationPermissionStepScreen extends StatelessWidget {
  const NotificationPermissionStepScreen({
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
          Text(
            'Stay Updated',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Get notified about new contests and when you win!',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          OnboardingButton(
            text: 'Enable Notifications',
            onPressed: onNext,
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}
