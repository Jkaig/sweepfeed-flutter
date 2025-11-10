import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Flexible template for onboarding screens
class OnboardingTemplate extends StatelessWidget {
  const OnboardingTemplate({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
