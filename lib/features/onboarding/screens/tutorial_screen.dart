import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../utils/onboarding_constants.dart';
import '../widgets/common_onboarding_widgets.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({
    required this.onNext,
    super.key,
    this.currentStep = 7,
  });
  final VoidCallback onNext;
  final int currentStep;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentTutorialStep = 0;
  final PageController _pageController = PageController();

  final List<_TutorialStep> _tutorialSteps = [
    const _TutorialStep(
      icon: Icons.search,
      iconColor: AppColors.brandCyan,
      title: 'Step 1: Browse Contests',
      description:
          'Swipe through contests or use filters to find prizes you love',
      interactiveHint: 'Try swiping left or right!',
    ),
    const _TutorialStep(
      icon: Icons.touch_app,
      iconColor: Colors.amber,
      title: 'Step 2: Enter to Win',
      description: 'Tap the "Enter Now" button to submit your entry in seconds',
      interactiveHint: "It's that easy!",
    ),
    const _TutorialStep(
      icon: Icons.favorite,
      iconColor: Colors.pinkAccent,
      title: 'Step 3: Watch & Win',
      description:
          'Watch a quick ad to support charity while entering. Then track your entries!',
      interactiveHint: 'Good luck!',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentTutorialStep < _tutorialSteps.length - 1) {
      setState(() {
        _currentTutorialStep++;
      });
      _pageController.animateToPage(
        _currentTutorialStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _tutorialSteps[_currentTutorialStep];

    return OnboardingScaffold(
      semanticLabel: OnboardingConstants.semanticTutorialScreen,
      currentStep: widget.currentStep,
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
                'Quick Tutorial',
                style: AppTextStyles.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: OnboardingConstants.fadeInDuration),
            ),
            const SizedBox(height: OnboardingConstants.verticalSpacingMedium),
            Text(
              'Learn how to win in 3 easy steps!',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: OnboardingConstants.fadeInDelayShort),
            const SizedBox(height: OnboardingConstants.verticalSpacingXXLarge),
            Semantics(
              label:
                  'Tutorial progress indicator. Step ${_currentTutorialStep + 1} of ${_tutorialSteps.length}',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _tutorialSteps.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentTutorialStep == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentTutorialStep == index
                          ? AppColors.brandCyan
                          : AppColors.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: OnboardingConstants.verticalSpacingXLarge),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tutorialSteps.length,
                itemBuilder: (context, index) {
                  final step = _tutorialSteps[index];
                  return _buildTutorialStepContent(step);
                },
              ),
            ),
            const SizedBox(height: OnboardingConstants.verticalSpacingXLarge),
            Semantics(
              label: _currentTutorialStep < _tutorialSteps.length - 1
                  ? 'Next tutorial step button'
                  : 'Finish tutorial button',
              button: true,
              child: OnboardingContinueButton(
                onPressed: _nextStep,
                label: _currentTutorialStep < _tutorialSteps.length - 1
                    ? 'Next'
                    : 'Got It!',
              ),
            ),
            const SizedBox(height: OnboardingConstants.verticalSpacingMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialStepContent(_TutorialStep step) => Semantics(
        label: '${step.title}. ${step.description}. ${step.interactiveHint}',
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OnboardingConstants.screenPadding,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(OnboardingConstants.cardPadding),
                decoration: BoxDecoration(
                  color: step.iconColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: step.iconColor,
                    width: 3,
                  ),
                ),
                child: Icon(
                  step.icon,
                  size: 60,
                  color: step.iconColor,
                ),
              )
                  .animate()
                  .scale(duration: OnboardingConstants.scaleAnimationDuration)
                  .then()
                  .shimmer(),
              const SizedBox(height: OnboardingConstants.verticalSpacingXLarge),
              Text(
                step.title,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: OnboardingConstants.fadeInDelayShort)
                  .slideY(),
              const SizedBox(height: OnboardingConstants.verticalSpacingMedium),
              Text(
                step.description,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: OnboardingConstants.fadeInDelayMedium),
              const SizedBox(height: OnboardingConstants.verticalSpacingLarge),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: OnboardingConstants.pillPaddingHorizontal,
                  vertical: OnboardingConstants.pillPaddingVertical,
                ),
                decoration: BoxDecoration(
                  color: step.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: step.iconColor.withValues(alpha: 0.3),
                    width: OnboardingConstants.borderWidth,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: step.iconColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      step.interactiveHint,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: OnboardingConstants.fadeInDelayLong)
                  .scale(),
            ],
          ),
        ),
      );
}

class _TutorialStep {
  const _TutorialStep({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.interactiveHint,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String interactiveHint;
}
