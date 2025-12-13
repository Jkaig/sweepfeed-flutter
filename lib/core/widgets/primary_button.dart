import 'package:flutter/material.dart';

import '../services/sensory_feedback_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.text,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.semanticLabel,
    this.enableHaptic = true,
    this.icon,
  });
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? semanticLabel;
  final bool enableHaptic;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final feedbackService = SensoryFeedbackService();

    return Semantics(
      label: semanticLabel ?? text,
      button: true,
      enabled: !isLoading && onPressed != null && !isLoading,
      child: ElevatedButton(
        onPressed: isLoading || onPressed == null
            ? null
            : () {
                if (enableHaptic) {
                  feedbackService.trigger(SensoryFeedbackType.buttonTap);
                }
                onPressed!();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: AppTextStyles.labelLarge,
          minimumSize: const Size(88, 44), // Minimum touch target size
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                ),
              )
            : icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(text),
                      const SizedBox(width: 8),
                      Icon(icon, size: 18),
                    ],
                  )
                : Text(text),
      ),
    );
  }
}
