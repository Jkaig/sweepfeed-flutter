import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class OnboardingButton extends StatelessWidget {
  const OnboardingButton({
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.isEnabled = true,
    super.key,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isPrimary ? AppColors.accent : AppColors.primaryMedium,
          foregroundColor:
              isPrimary ? AppColors.primaryDark : AppColors.textWhite,
          disabledBackgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isPrimary ? 4 : 0,
          shadowColor:
              isPrimary ? AppColors.accent.withValues(alpha: 0.3) : null,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPrimary ? AppColors.primaryDark : AppColors.textWhite,
                  ),
                ),
              )
            : Text(
                text,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
