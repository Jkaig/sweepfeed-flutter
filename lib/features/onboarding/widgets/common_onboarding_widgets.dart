import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../utils/onboarding_constants.dart';

class OnboardingSkipButton extends StatelessWidget {
  const OnboardingSkipButton({required this.onPressed, super.key});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: OnboardingConstants.skipButtonLabel,
        child: TextButton(
          onPressed: onPressed,
          child: const Text(
            'Skip',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}

class OnboardingContinueButton extends StatelessWidget {
  const OnboardingContinueButton({
    required this.onPressed,
    super.key,
    this.label = 'Continue',
    this.enabled = true,
  });
  final VoidCallback onPressed;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: OnboardingConstants.nextButtonLabel,
        enabled: enabled,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: OnboardingConstants.buttonPaddingVertical,
            ),
            backgroundColor: AppColors.brandCyan,
            disabledBackgroundColor: Colors.grey[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                OnboardingConstants.buttonBorderRadius,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.titleMedium.copyWith(
              color: enabled ? AppColors.primaryDark : AppColors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}

class OnboardingProgressIndicator extends StatelessWidget {
  const OnboardingProgressIndicator({
    required this.currentStep,
    super.key,
    this.totalSteps = OnboardingConstants.totalOnboardingScreens,
  });
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Progress: Step $currentStep of $totalSteps',
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: currentStep / totalSteps,
                    backgroundColor: AppColors.primaryLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.brandCyan,),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$currentStep/$totalSteps',
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: OnboardingConstants.verticalSpacingMedium),
          ],
        ),
      );
}

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    required this.semanticLabel,
    required this.child,
    super.key,
    this.skipButton,
    this.currentStep,
  });
  final String semanticLabel;
  final Widget child;
  final Widget? skipButton;
  final int? currentStep;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticLabel,
        child: Scaffold(
          backgroundColor: AppColors.primaryDark,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(OnboardingConstants.screenPadding),
              child: Column(
                children: [
                  if (currentStep != null)
                    OnboardingProgressIndicator(currentStep: currentStep!),
                  if (skipButton != null)
                    Align(
                      alignment: Alignment.topRight,
                      child: skipButton,
                    ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ),
      );
}

class FeaturePill extends StatelessWidget {
  const FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OnboardingConstants.pillPaddingHorizontal,
            vertical: OnboardingConstants.pillPaddingVertical,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color,
              width: OnboardingConstants.borderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: OnboardingConstants.pillIconSize),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
}

class AnimatedLottieOrFallback extends StatelessWidget {
  const AnimatedLottieOrFallback({
    required this.assetPath,
    required this.fallbackIcon,
    required this.fallbackColor,
    super.key,
    this.height = OnboardingConstants.animationHeightLarge,
  });
  final String assetPath;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: FutureBuilder(
          future: DefaultAssetBundle.of(context).load(assetPath),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Container(
                child: Image.asset('assets/icon/appicon.png', height: height),
              );
            } else if (snapshot.hasError) {
              debugPrint('Failed to load Lottie animation: ${snapshot.error}');
              return Icon(
                fallbackIcon,
                size: height * 0.6,
                color: fallbackColor,
              );
            } else {
              return CircularProgressIndicator(
                color: fallbackColor,
              );
            }
          },
        ),
      );
}
