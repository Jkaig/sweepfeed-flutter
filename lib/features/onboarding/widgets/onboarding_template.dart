import 'package:flutter/material.dart';


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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.scaffoldBackgroundColor,
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
