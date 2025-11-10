import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../utils/onboarding_constants.dart';

class CompletionScreen extends StatefulWidget {
  const CompletionScreen({
    required this.onFinish,
    super.key,
    this.currentStep = 8,
  });
  final VoidCallback onFinish;
  final int currentStep;

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primaryMedium],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 1.57,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.1,
                colors: const [
                  AppColors.brandCyan,
                  Colors.amber,
                  Colors.pinkAccent,
                  Colors.deepPurple,
                  Colors.green,
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.all(OnboardingConstants.screenPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Semantics(
                      label: 'Celebration icon',
                      child: const Icon(
                        Icons.celebration,
                        size: 100,
                        color: Colors.amber,
                      )
                          .animate()
                          .scale(
                            duration:
                                OnboardingConstants.scaleAnimationDuration,
                          )
                          .then()
                          .shake(),
                    ),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingXLarge,
                    ),
                    Semantics(
                      header: true,
                      child: Text(
                        "You're All Set!",
                        style: AppTextStyles.displayLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: OnboardingConstants.fadeInDelayShort)
                          .slideY(),
                    ),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingMedium,
                    ),
                    Text(
                      'Welcome to the SweepFeed community!',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: OnboardingConstants.fadeInDelayMedium),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingXXLarge,
                    ),
                    Semantics(
                      label:
                          'Welcome bonus. You earned 100 DustBunnies for completing onboarding!',
                      child: Container(
                        padding: const EdgeInsets.all(
                            OnboardingConstants.cardPadding),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.brandCyan.withValues(alpha: 0.3),
                              Colors.deepPurple.withValues(alpha: 0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            OnboardingConstants.cardBorderRadius,
                          ),
                          border: Border.all(
                            color: AppColors.brandCyan,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.stars,
                              size: 60,
                              color: Colors.amber,
                            )
                                .animate()
                                .scale(
                                    delay: OnboardingConstants.fadeInDelayLong)
                                .then()
                                .shimmer(),
                            const SizedBox(
                              height: OnboardingConstants.verticalSpacingMedium,
                            ),
                            Text(
                              'Welcome Bonus!',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              height: OnboardingConstants.verticalSpacingSmall,
                            ),
                            Text(
                              '+${OnboardingConstants.welcomeBonusPoints} Points',
                              style: AppTextStyles.displaySmall.copyWith(
                                color: AppColors.brandCyan,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              height: OnboardingConstants.verticalSpacingSmall,
                            ),
                            Text(
                              'Use points for bonus entries and exclusive prizes!',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: OnboardingConstants.fadeInDelayXLong)
                          .scale(),
                    ),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingXXLarge,
                    ),
                    Semantics(
                      label: 'Quick tips for success',
                      child: Container(
                        padding: const EdgeInsets.all(
                          OnboardingConstants.verticalSpacingMedium,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(
                            OnboardingConstants.buttonBorderRadius,
                          ),
                          border: Border.all(
                            color: AppColors.textMuted.withValues(alpha: 0.3),
                            width: OnboardingConstants.borderWidth,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildTip(
                              icon: Icons.local_fire_department,
                              text: 'Enter daily to build your streak',
                              color: Colors.orange,
                            ),
                            const SizedBox(
                              height: OnboardingConstants.verticalSpacingSmall,
                            ),
                            _buildTip(
                              icon: Icons.favorite,
                              text: 'Support charities with every entry',
                              color: Colors.pinkAccent,
                            ),
                            const SizedBox(
                              height: OnboardingConstants.verticalSpacingSmall,
                            ),
                            _buildTip(
                              icon: Icons.people,
                              text: 'Invite friends for bonus rewards',
                              color: AppColors.brandCyan,
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 1200)),
                    ),
                    const Spacer(),
                    Semantics(
                      label: 'Start using SweepFeed button',
                      button: true,
                      child: ElevatedButton(
                        onPressed: widget.onFinish,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: OnboardingConstants.buttonPaddingVertical,
                          ),
                          backgroundColor: AppColors.brandCyan,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              OnboardingConstants.buttonBorderRadius,
                            ),
                          ),
                        ),
                        child: Text(
                          'Start Winning!',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: const Duration(milliseconds: 1400))
                          .scale(),
                    ),
                    const SizedBox(
                      height: OnboardingConstants.verticalSpacingMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildTip({
    required IconData icon,
    required String text,
    required Color color,
  }) =>
      Semantics(
        label: text,
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ),
          ],
        ),
      );
}
