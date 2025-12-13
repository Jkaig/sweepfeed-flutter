import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../utils/onboarding_constants.dart';
import '../widgets/common_onboarding_widgets.dart';

class CharityImpactIntroScreen extends StatelessWidget {
  const CharityImpactIntroScreen({
    required this.onNext,
    required this.onSkip,
    super.key,
    this.currentStep = 3,
  });
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int currentStep;

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        semanticLabel: OnboardingConstants.semanticCharityScreen,
        currentStep: currentStep,
        skipButton: OnboardingSkipButton(onPressed: onSkip),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primaryMedium],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.favorite,
                  size: OnboardingConstants.iconSize,
                  color: Colors.pinkAccent,
                ),
                Icon(
                  Icons.attach_money,
                  size: OnboardingConstants.iconSize * 0.4,
                  color: Colors.white,
                ),
              ],
            )
                .animate()
                .scale(duration: OnboardingConstants.scaleAnimationDuration)
                .then()
                .shimmer(),
              const SizedBox(height: OnboardingConstants.verticalSpacingLarge),
              Semantics(
                header: true,
                child: Text(
                  'Make a Real Impact',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: OnboardingConstants.fadeInDelayShort)
                    .slideY(),
              ),
              const SizedBox(height: OnboardingConstants.verticalSpacingMedium),
              Text(
                'Every contests entry helps fund the causes you care about',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: OnboardingConstants.fadeInDelayMedium),
              const SizedBox(
                  height: OnboardingConstants.verticalSpacingXXLarge,),
              Semantics(
                label:
                    'Impact process: Watch ads, We donate, You make an impact',
                child: Column(
                  children: [
                    _buildImpactStep(
                      step: '1',
                      title: 'You enter contests',
                      description: 'Short ads help us keep the app free',
                      color: AppColors.brandCyan,
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayLong)
                        .slideX(),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingMedium,
                    ),
                    const Icon(
                      Icons.arrow_downward,
                      color: AppColors.textLight,
                      size: OnboardingConstants.smallIconSize,
                    ),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingMedium,
                    ),
                    _buildImpactStep(
                      step: '2',
                      title: 'We donate',
                      description: 'Ad revenue goes to your selected charities',
                      color: Colors.green,
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayXLong)
                        .slideX(),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingMedium,
                    ),
                    const Icon(
                      Icons.arrow_downward,
                      color: AppColors.textLight,
                      size: OnboardingConstants.smallIconSize,
                    ),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingMedium,
                    ),
                    _buildImpactStep(
                      step: '3',
                      title: 'You make an impact',
                      description: 'Track your charity contributions over time',
                      color: Colors.pinkAccent,
                    )
                        .animate()
                        .fadeIn(delay: const Duration(milliseconds: 1000))
                        .slideX(),
                  ],
                ),
              ),
              const SizedBox(height: OnboardingConstants.verticalSpacingSmall),
              Semantics(
                label:
                    'Impact statistic: Average user contributes 2 to 5 dollars per month to charity',
                child: Container(
                  padding: const EdgeInsets.all(
                    OnboardingConstants.verticalSpacingMedium,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      OnboardingConstants.buttonBorderRadius,
                    ),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                      width: OnboardingConstants.borderWidth,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.green, size: 24,),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Average user contributes \$2-5/month to charity!',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 1200)),
              ),
              const SizedBox(height: OnboardingConstants.verticalSpacingMedium),
              OnboardingContinueButton(
                onPressed: onNext,
              ).animate().fadeIn(delay: const Duration(milliseconds: 1400)),
              const SizedBox(height: OnboardingConstants.verticalSpacingSmall),
            ],
          ),
        ),
      );

  Widget _buildImpactStep({
    required String step,
    required String title,
    required String description,
    required Color color,
  }) =>
      Semantics(
        label: 'Step $step: $title - $description',
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: OnboardingConstants.verticalSpacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: OnboardingConstants.verticalSpacingSmall,
                  ),
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
