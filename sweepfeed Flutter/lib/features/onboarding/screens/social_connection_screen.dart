import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../utils/onboarding_constants.dart';
import '../widgets/common_onboarding_widgets.dart';

class SocialConnectionScreen extends StatelessWidget {
  const SocialConnectionScreen({
    required this.onNext,
    required this.onSkip,
    super.key,
    this.currentStep = 4,
  });
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int currentStep;

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        semanticLabel: OnboardingConstants.semanticSocialScreen,
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
              const Icon(
                Icons.people,
                size: OnboardingConstants.iconSize,
                color: Colors.deepPurple,
              )
                  .animate()
                  .scale(duration: OnboardingConstants.scaleAnimationDuration)
                  .then()
                  .shimmer(),
              const SizedBox(height: OnboardingConstants.verticalSpacingLarge),
              Semantics(
                header: true,
                child: Text(
                  'Connect with Friends',
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
                'Compete, share wins, and motivate each other!',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: OnboardingConstants.fadeInDelayMedium),
              const SizedBox(
                  height: OnboardingConstants.verticalSpacingXXLarge),
              Semantics(
                label:
                    'Social features: Leaderboards, Friend Challenges, Shared Wins',
                child: Column(
                  children: [
                    _buildSocialFeature(
                      icon: Icons.emoji_events,
                      iconColor: Colors.amber,
                      title: 'Leaderboards',
                      description: 'See how you stack up against friends',
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayMedium)
                        .slideX(),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingLarge,
                    ),
                    _buildSocialFeature(
                      icon: Icons.groups,
                      iconColor: Colors.deepPurple,
                      title: 'Friend Challenges',
                      description: 'Create competitions and earn bonus rewards',
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayLong)
                        .slideX(),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingLarge,
                    ),
                    _buildSocialFeature(
                      icon: Icons.celebration,
                      iconColor: AppColors.brandCyan,
                      title: 'Shared Wins',
                      description: 'Celebrate victories together!',
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayXLong)
                        .slideX(),
                  ],
                ),
              ),
              const Spacer(),
              OnboardingContinueButton(
                onPressed: onNext,
              ).animate().fadeIn(delay: const Duration(milliseconds: 1000)),
              const SizedBox(height: OnboardingConstants.verticalSpacingMedium),
            ],
          ),
        ),
      );

  Widget _buildSocialFeature({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) =>
      Semantics(
        label: '$title: $description',
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.5),
                  width: OnboardingConstants.borderWidth,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: OnboardingConstants.smallIconSize,
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
