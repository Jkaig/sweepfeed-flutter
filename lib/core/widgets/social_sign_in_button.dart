import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart'; // Assuming you might want to style the text

class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    required this.providerName,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    super.key,
  });
  final String providerName;
  final Widget icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
        icon: icon,
        label: Text(providerName),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: AppTextStyles.labelLarge
              .copyWith(color: textColor), // Apply text style
        ),
      );
}
