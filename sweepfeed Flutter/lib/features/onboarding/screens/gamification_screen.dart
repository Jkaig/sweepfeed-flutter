import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../utils/onboarding_constants.dart';
import '../widgets/common_onboarding_widgets.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({
    required this.onNext,
    required this.onSkip,
    super.key,
    this.currentStep = 2,
  });
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int currentStep;

  @override
  Widget build(BuildContext context) => OnboardingScaffold(
        semanticLabel: OnboardingConstants.semanticGamificationScreen,
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
              Semantics(
                header: true,
                child: Text(
                  'Level Up Your Sweepstakes Game!',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(duration: OnboardingConstants.fadeInDuration)
                    .slideY(),
              ),
              const SizedBox(height: OnboardingConstants.verticalSpacingMedium),
              Text(
                'Earn points, climb leaderboards, and unlock achievements!',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: OnboardingConstants.fadeInDelayShort),
              const SizedBox(
                  height: OnboardingConstants.verticalSpacingXXLarge),
              Semantics(
                label: 'Gamification features: Streaks, Badges, Leaderboards',
                child: Column(
                  children: [
                    _buildFeatureCard(
                      icon: Icons.local_fire_department,
                      iconColor: Colors.orange,
                      title: 'Daily Streaks',
                      description:
                          'Enter daily to build your streak and unlock bonus entries!',
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withValues(alpha: 0.2),
                          Colors.deepOrange.withValues(alpha: 0.1),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayMedium)
                        .slideX()
                        .then()
                        .shimmer(
                          duration: OnboardingConstants.scaleAnimationDuration,
                        ),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingMedium,
                    ),
                    _buildFeatureCard(
                      icon: Icons.military_tech,
                      iconColor: AppColors.brandCyan,
                      title: 'Earn Badges',
                      description:
                          'Complete challenges to collect unique badges and rewards!',
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brandCyan.withValues(alpha: 0.2),
                          AppColors.brandCyan.withValues(alpha: 0.1),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayLong)
                        .slideX()
                        .then()
                        .shimmer(
                          duration: OnboardingConstants.scaleAnimationDuration,
                        ),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingMedium,
                    ),
                    _buildFeatureCard(
                      icon: Icons.leaderboard,
                      iconColor: Colors.amber,
                      title: 'Leaderboard',
                      description:
                          'Compete with friends and see who wins the most!',
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withValues(alpha: 0.2),
                          Colors.amber.withValues(alpha: 0.1),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayXLong)
                        .slideX()
                        .then()
                        .shimmer(
                          duration: OnboardingConstants.scaleAnimationDuration,
                        ),
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

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required Gradient gradient,
  }) =>
      Semantics(
        label: '$title: $description',
        child: Container(
          padding: const EdgeInsets.all(OnboardingConstants.cardPadding),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius:
                BorderRadius.circular(OnboardingConstants.cardBorderRadius),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.3),
              width: OnboardingConstants.cardBorderWidth,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
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
        ),
      );
}
