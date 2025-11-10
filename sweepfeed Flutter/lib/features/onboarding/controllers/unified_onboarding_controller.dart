import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/onboarding_constants.dart';
import '../../../core/exceptions/onboarding_exceptions.dart';
import '../../../core/models/onboarding_config.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/logger.dart';
import '../screens/steps/charity_impact_step_screen.dart';
import '../screens/steps/charity_selection_step_screen.dart';
import '../screens/steps/completion_step_screen.dart';
import '../screens/steps/gamification_step_screen.dart';
import '../screens/steps/how_it_works_step_screen.dart';
import '../screens/steps/interest_selection_step_screen.dart';
import '../screens/steps/notification_permission_step_screen.dart';
import '../screens/steps/points_system_step_screen.dart';
import '../screens/steps/profile_setup_step_screen.dart';
import '../screens/steps/tutorial_step_screen.dart';
import '../screens/steps/welcome_step_screen.dart';

/// Unified onboarding controller that manages the configurable onboarding flow
class UnifiedOnboardingController extends ConsumerStatefulWidget {
  const UnifiedOnboardingController({
    required this.config,
    required this.onComplete,
    super.key,
  });

  final OnboardingConfig config;
  final VoidCallback onComplete;

  @override
  ConsumerState<UnifiedOnboardingController> createState() =>
      _UnifiedOnboardingControllerState();
}

class _UnifiedOnboardingControllerState
    extends ConsumerState<UnifiedOnboardingController>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late OnboardingAnalyticsService _analyticsService;
  int _currentStepIndex = 0;
  bool _isLoading = false;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  late DateTime _onboardingStartTime;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _onboardingStartTime = DateTime.now();
    _progressAnimationController = AnimationController(
      duration: OnboardingTimingConstants.progressAnimationDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: OnboardingTimingConstants.progressAnimationCurve,
    ));
    _updateProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _analyticsService = ref.read(onboardingAnalyticsProvider);

    // Track onboarding start
    _analyticsService.trackOnboardingStarted(
      widget.config.type.value,
      widget.config.totalSteps,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    final progress = (_currentStepIndex + 1) / widget.config.totalSteps;
    _progressAnimationController.animateTo(progress);
  }

  Future<void> _nextStep() async {
    if (_isLoading) return;

    if (_currentStepIndex < widget.config.totalSteps - 1) {
      setState(() {
        _currentStepIndex++;
      });
      await _pageController.nextPage(
        duration: OnboardingTimingConstants.stepTransitionDuration,
        curve: OnboardingTimingConstants.stepTransitionCurve,
      );
      _updateProgress();

      // Track step completion for analytics
      _trackStepCompleted(_currentStepIndex - 1);
    } else {
      await _completeOnboarding();
    }
  }

  Future<void> _previousStep() async {
    if (_isLoading || !widget.config.allowBackNavigation) return;

    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateProgress();
    }
  }

  Future<void> _skipStep() async {
    if (_isLoading) return;

    final currentStep = widget.config.steps[_currentStepIndex];

    // Check if step can be skipped
    if (!widget.config.canSkipSteps || !currentStep.isSkippable) {
      return;
    }

    // Track step skip for analytics
    _trackStepSkipped(_currentStepIndex);

    await _nextStep();
  }

  Future<void> _skipToEnd() async {
    if (_isLoading) return;

    // Find the last required step or completion step
    int targetIndex = widget.config.totalSteps - 1;
    for (int i = widget.config.totalSteps - 1; i >= 0; i--) {
      if (widget.config.steps[i].isRequired) {
        targetIndex = i;
        break;
      }
    }

    if (targetIndex != _currentStepIndex) {
      setState(() {
        _currentStepIndex = targetIndex;
      });
      await _pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _updateProgress();
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        logger.e('No user found when completing onboarding');
        _showErrorSnackBar(
            'Authentication error. Please try logging in again.');
        return;
      }

      // Track onboarding completion start
      await _analyticsService.trackOnboardingEvent(
        OnboardingAnalyticsEvents.completionStarted,
        {
          'user_id': user.uid,
          'config_type': widget.config.type.value,
          'total_steps': widget.config.totalSteps,
        },
      );

      // Save onboarding completion data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'onboardingCompleted': true,
        'points': FieldValue.increment(widget.config.welcomeBonusPoints),
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
        'onboardingConfig': widget.config.steps.map((s) => s.name).toList(),
        'onboardingDuration': DateTime.now().millisecondsSinceEpoch,
      });

      // Save user preferences if collected
      await _saveUserPreferences(user.uid);

      // Track successful completion
      final duration = DateTime.now().difference(_onboardingStartTime);
      await _analyticsService.trackOnboardingCompleted(
        user.uid,
        widget.config.type.value,
        widget.config.totalSteps,
        widget.config.welcomeBonusPoints,
        duration,
      );

      logger.i(
        'Onboarding completed for user ${user.uid}, awarded ${widget.config.welcomeBonusPoints} points',
      );

      widget.onComplete();
    } catch (e) {
      logger.e('Error completing onboarding', error: e);

      // Track completion error
      final onboardingException = OnboardingExceptionHelper.fromException(e);
      await _analyticsService.trackOnboardingFailed(
        widget.config.type.value,
        onboardingException.runtimeType.toString(),
        onboardingException.message,
      );

      _showErrorSnackBar(_getErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveUserPreferences(String userId) async {
    try {
      // Save selected interests if step was completed
      if (widget.config.hasStep(OnboardingStep.interestSelection)) {
        final selectedInterests = ref.read(selectedInterestsProvider);
        if (selectedInterests.isNotEmpty) {
          await ref
              .read(profileServiceProvider)
              .updateInterests(userId, selectedInterests);

          // Track interests saved
          await _analyticsService.trackPreferencesSaved(
            userId,
            'interests',
            selectedInterests.length,
            selectedInterests,
          );
        }
      }

      // Save selected charities if step was completed
      if (widget.config.hasStep(OnboardingStep.charitySelection)) {
        final selectedCharities = ref.read(selectedCharitiesProvider);
        if (selectedCharities.isNotEmpty) {
          final charityIds = selectedCharities
              .map((c) => (c.id ?? c['id']) as String)
              .toList();
          await ref
              .read(profileServiceProvider)
              .updateCharities(userId, charityIds);

          // Track charities saved
          await _analyticsService.trackPreferencesSaved(
            userId,
            'charities',
            selectedCharities.length,
            charityIds,
          );
        }
      }
    } catch (e) {
      logger.e('Error saving user preferences', error: e);
      // Re-throw to be caught by parent method
      rethrow;
    }
  }

  // Analytics tracking methods
  void _trackStepCompleted(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < widget.config.steps.length) {
      final step = widget.config.steps[stepIndex];
      _analyticsService.trackStepCompleted(
        step.name,
        stepIndex,
        widget.config.type.value,
      );
    }
  }

  void _trackStepSkipped(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < widget.config.steps.length) {
      final step = widget.config.steps[stepIndex];
      _analyticsService.trackStepSkipped(
        step.name,
        stepIndex,
        widget.config.type.value,
      );
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is OnboardingException) {
      return error.message;
    }

    // Convert common Firebase/Flutter errors to user-friendly messages
    final onboardingException = OnboardingExceptionHelper.fromException(error);
    return onboardingException.message;
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.errorRed,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              // Retry the current operation
              if (_currentStepIndex == widget.config.steps.length - 1) {
                _completeOnboarding();
              }
            },
          ),
        ),
      );
    }
  }

  Widget _buildCurrentStep() {
    final currentStep = widget.config.steps[_currentStepIndex];

    switch (currentStep) {
      case OnboardingStep.welcome:
        return WelcomeStepScreen(
          onNext: _nextStep,
          onSkip: widget.config.canSkipSteps ? _skipStep : null,
        );
      case OnboardingStep.howItWorks:
        return HowItWorksStepScreen(
          onNext: _nextStep,
          onSkip: widget.config.canSkipSteps ? _skipStep : null,
        );
      case OnboardingStep.charityImpact:
        return CharityImpactStepScreen(
          onNext: _nextStep,
          onSkip: widget.config.canSkipSteps ? _skipStep : null,
        );
      case OnboardingStep.gamification:
        return GamificationStepScreen(
          onNext: _nextStep,
          onSkip: widget.config.canSkipSteps ? _skipStep : null,
        );
      case OnboardingStep.pointsSystem:
        return PointsSystemStepScreen(
          onNext: _nextStep,
          onSkip: widget.config.canSkipSteps ? _skipStep : null,
        );
      case OnboardingStep.interestSelection:
        return InterestSelectionStepScreen(
          onNext: _nextStep,
          onSkip: widget.config.canSkipSteps && currentStep.isSkippable
              ? _skipStep
              : null,
        );
      case OnboardingStep.charitySelection:
        return CharitySelectionStepScreen(
          onNext: _nextStep,
          onSkip: widget.config.canSkipSteps && currentStep.isSkippable
              ? _skipStep
              : null,
        );
      case OnboardingStep.profileSetup:
        return ProfileSetupStepScreen(
          onNext: _nextStep,
          onSkip: widget.config.canSkipSteps ? _skipStep : null,
        );
      case OnboardingStep.notificationPermission:
        return NotificationPermissionStepScreen(
          onNext: _nextStep,
          onSkip: widget.config.canSkipSteps ? _skipStep : null,
        );
      case OnboardingStep.tutorial:
        return TutorialStepScreen(
          onNext: _nextStep,
          onSkip: widget.config.canSkipSteps ? _skipStep : null,
        );
      case OnboardingStep.completion:
        return CompletionStepScreen(
          onFinish: _completeOnboarding,
          welcomeBonusPoints: widget.config.welcomeBonusPoints,
        );
      default:
        return Container(); // Fallback for unsupported steps
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation during onboarding
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: SafeArea(
          child: Column(
            children: [
              // Header with progress and skip button
              if (widget.config.showProgressIndicator) _buildHeader(),

              // Main content
              Expanded(
                child: _buildCurrentStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final currentStep = widget.config.steps[_currentStepIndex];
    final canSkip = widget.config.canSkipSteps &&
        currentStep.isSkippable &&
        currentStep != OnboardingStep.completion;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Top row with back button, skip button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              if (widget.config.allowBackNavigation && _currentStepIndex > 0)
                IconButton(
                  onPressed: _previousStep,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textLight,
                  ),
                )
              else
                const SizedBox(width: 48),

              // Step indicator
              Text(
                '${_currentStepIndex + 1} of ${widget.config.totalSteps}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),

              // Skip button
              if (canSkip)
                TextButton(
                  onPressed: _skipStep,
                  child: Text(
                    'Skip',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else
                const SizedBox(width: 48),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Provider for managing selected interests during onboarding
final selectedInterestsProvider =
    StateNotifierProvider<SelectedInterestsNotifier, List<String>>(
        (ref) => SelectedInterestsNotifier());

class SelectedInterestsNotifier extends StateNotifier<List<String>> {
  SelectedInterestsNotifier() : super([]);

  void toggle(String interest) {
    if (state.contains(interest)) {
      state = state.where((item) => item != interest).toList();
    } else {
      state = [...state, interest];
    }
  }

  void clear() {
    state = [];
  }

  void setAll(List<String> interests) {
    state = [...interests];
  }
}

/// Provider for managing selected charities during onboarding
final selectedCharitiesProvider =
    StateNotifierProvider<SelectedCharitiesNotifier, List<dynamic>>(
        (ref) => SelectedCharitiesNotifier());

class SelectedCharitiesNotifier extends StateNotifier<List<dynamic>> {
  SelectedCharitiesNotifier() : super([]);

  void toggle(dynamic charity) {
    final charityId = charity.id ?? charity['id'];
    final existingIndex =
        state.indexWhere((c) => (c.id ?? c['id']) == charityId);

    if (existingIndex >= 0) {
      state = [
        ...state.sublist(0, existingIndex),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, charity];
    }
  }

  void clear() {
    state = [];
  }

  void setAll(List<dynamic> charities) {
    state = [...charities];
  }
}
