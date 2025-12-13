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
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isPrimary ? AppColors.accent : Colors.transparent,
          foregroundColor:
              isPrimary ? const Color(0xFF000000) : AppColors.textWhite,
          disabledBackgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(color: AppColors.textLight, width: 2),
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
                    isPrimary ? const Color(0xFF000000) : AppColors.textWhite,
                  ),
                ),
              )
            : Text(
                text,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? const Color(0xFF000000) : AppColors.textWhite,
                ),
              ),
      ),
    );
}
