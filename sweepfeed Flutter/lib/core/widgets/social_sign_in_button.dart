import 'package:flutter/material.dart';
import 'package:sweep_feed/core/theme/app_text_styles.dart'; // Assuming you might want to style the text

class SocialSignInButton extends StatelessWidget {
  final String providerName;
  final Widget icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;

  const SocialSignInButton({
    super.key,
    required this.providerName,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTextStyles.labelLarge.copyWith(color: textColor), // Apply text style
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 12),
          Text('Sign in with $providerName'),
        ],
      ),
    );
  }
}
