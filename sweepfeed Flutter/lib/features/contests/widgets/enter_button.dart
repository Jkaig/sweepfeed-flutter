import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class EnterButton extends StatelessWidget {
  const EnterButton({
    super.key,
    this.onPressed,
    this.enabled = true,
    this.text = 'Enter',
  });
  final VoidCallback? onPressed;
  final bool enabled;
  final String text;

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: (enabled && onPressed != null) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.primaryDark,
          disabledBackgroundColor: AppColors.textMuted,
          disabledForegroundColor: AppColors.textLight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
