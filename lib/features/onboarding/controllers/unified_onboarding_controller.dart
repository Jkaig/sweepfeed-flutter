import 'dart:io';

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
import '../../../core/widgets/animated_gradient_background.dart';
import '../screens/steps/authentication_step_screen.dart';
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
    ),);
    
    // Restore saved progress if user is already authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreProgress();
    });
    
    _updateProgress();
  }

  Future<void> _restoreProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Ensure we are loading to prevent flicker
      if (mounted) setState(() => _isLoading = true);

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        
        // Check if onboarding is already fully completed
        if (data['onboardingCompleted'] == true) {
          widget.onComplete();
          return;
        }

        // Restore progress index
        if (data.containsKey('onboardingProgress')) {
          final savedStep = data['onboardingProgress'] as int;
          // Ensure index is valid
          if (savedStep > 0 && savedStep < widget.config.totalSteps) {
             setState(() {
               _currentStepIndex = savedStep;
             });
             _updateProgress();
             
             // If we restored to a step past authentication, and we are validly logged in,
             // this is good. 
             // If savedStep points to Authentication step (or before), but we are logged in,
             // we should probably advanced PAST authentication?
             // Let's check if the current restored step is AuthenticationStep.
             // If so, and we are logged in, auto-advance.
             
             final restoredStep = widget.config.steps[_currentStepIndex];
             if (restoredStep == OnboardingStep.authentication) {
               // User is logged in but stuck on Auth step? Move to next.
               _nextStep();
             }
          }
        } else {
             // User is logged in but no progress saved? 
             // Should we skip to at least after Authentication step?
             // Find Authentication step index
             final authIndex = widget.config.steps.indexOf(OnboardingStep.authentication);
             if (authIndex != -1 && _currentStepIndex <= authIndex) {
                 // Advance to step AFTER authentication
                 setState(() {
                   _currentStepIndex = authIndex + 1;
                 });
                 _updateProgress();
             }
        }
      }
    } catch (e) {
      logger.w('Failed to restore onboarding progress: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    if (_isLoading || !mounted) return;

    if (_currentStepIndex < widget.config.totalSteps - 1) {
      // Track step completion for analytics before incrementing
      _trackStepCompleted(_currentStepIndex);

      // Save selections incrementally so they're not lost if user exits
      await _saveSelectionsIncrementally();

      if (!mounted) return;
      
      setState(() {
        _currentStepIndex++;
      });
      _updateProgress();
    } else {
      if (mounted) {
        await _completeOnboarding();
      }
    }
  }

  /// Save user selections incrementally after each step
  /// This ensures selections aren't lost if user exits before completing onboarding
  Future<void> _saveSelectionsIncrementally() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final currentStep = widget.config.steps[_currentStepIndex];
      final updates = <String, dynamic>{
        'onboardingProgress': _currentStepIndex + 1,
        'lastOnboardingStep': currentStep.name,
        'lastOnboardingUpdate': FieldValue.serverTimestamp(),
      };

      // Save interests if on interest selection step
      if (currentStep == OnboardingStep.interestSelection) {
        final selectedInterests = ref.read(selectedInterestsProvider);
        if (selectedInterests.isNotEmpty) {
          updates['pendingInterests'] = selectedInterests;
        }
      }

      // Save charities if on charity selection step
      if (currentStep == OnboardingStep.charitySelection) {
        final selectedCharities = ref.read(selectedCharitiesProvider);
        if (selectedCharities.isNotEmpty) {
          final charityIds = selectedCharities
              .map((c) => (c is Map ? c['id'] : c.id) as String)
              .toList();
          updates['pendingCharities'] = charityIds;
        }
      }

      // Save to Firestore (fire and forget, don't block navigation)
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updates)
          .catchError((e) {
        logger.w('Failed to save incremental onboarding progress: $e');
      });
    } catch (e) {
      logger.w('Error in incremental save: $e');
      // Don't block navigation on save errors
    }
  }

  Future<void> _previousStep() async {
    if (_isLoading || !mounted || !widget.config.allowBackNavigation) return;

    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      _updateProgress();
    }
  }

  Future<void> _skipStep() async {
    if (_isLoading || !mounted) return;

    final currentStep = widget.config.steps[_currentStepIndex];

    // Check if step can be skipped
    if (!widget.config.canSkipSteps || !currentStep.isSkippable) {
      return;
    }

    // Track step skip for analytics
    _trackStepSkipped(_currentStepIndex);

    if (mounted) {
      await _nextStep();
    }
  }

  /// Skip charity selection - user keeps 100% of ad revenue
  Future<void> _skipCharitySelection() async {
    if (_isLoading || !mounted) return;

    // Find the charity selection step and skip past it
    for (var i = _currentStepIndex + 1; i < widget.config.steps.length; i++) {
      if (widget.config.steps[i] == OnboardingStep.charitySelection) {
        // Skip to the step AFTER charity selection
        final targetIndex = i + 1 < widget.config.steps.length ? i + 1 : i;
        if (mounted) {
          setState(() {
            _currentStepIndex = targetIndex;
          });
          _updateProgress();
          _trackStepSkipped(i); // Track charity selection was skipped
        }
        return;
      }
    }
    // If charity selection not found, just go to next step
    if (mounted) {
      await _nextStep();
    }
  }

  Future<void> _skipToEnd() async {
    if (_isLoading || !mounted) return;

    // Find the last required step or completion step
    var targetIndex = widget.config.totalSteps - 1;
    for (var i = widget.config.totalSteps - 1; i >= 0; i--) {
      if (widget.config.steps[i].isRequired) {
        targetIndex = i;
        break;
      }
    }

    if (targetIndex != _currentStepIndex && mounted) {
      setState(() {
        _currentStepIndex = targetIndex;
      });
      _updateProgress();
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isLoading || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        logger.e('No user found when completing onboarding');
        _showErrorSnackBar(
            'Authentication error. Please try logging in again.',);
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

      if (!mounted) return;

      // Save onboarding completion data - use update to ensure field is set
      // First, get current dustBunnies values to properly increment
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final currentDB = (userDoc.data()?['dustBunniesSystem']?['currentDB'] as num?)?.toInt() ?? 0;
      final totalDB = (userDoc.data()?['dustBunniesSystem']?['totalDB'] as num?)?.toInt() ?? 0;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'onboardingCompleted': true,
        'dustBunniesSystem.currentDB': currentDB + widget.config.welcomeBonusPoints,
        'dustBunniesSystem.totalDB': totalDB + widget.config.welcomeBonusPoints,
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
        'onboardingConfig': widget.config.steps.map((s) => s.name).toList(),
        'onboardingDuration': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Verify the update was successful
      final verifyDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final verified = verifyDoc.data()?['onboardingCompleted'] as bool? ?? false;
      
      if (!verified) {
        logger.e('Failed to save onboardingCompleted flag for user ${user.uid}');
        throw Exception('Failed to save onboarding completion status');
      }
      
      logger.i('Successfully saved onboardingCompleted=true for user ${user.uid}');

      // Force refresh auth state to pick up onboarding completion
      // This ensures the app immediately recognizes the user has completed onboarding
      try {
        await ref.read(authServiceProvider).refreshAuthState();
        logger.i('Auth state refreshed after onboarding completion');
      } catch (e) {
        logger.w('Failed to refresh auth state after onboarding: $e');
        // Continue anyway - auth state will update on next app restart
      }

      if (!mounted) return;

      // Save user preferences if collected
      await _saveUserPreferences(user.uid);

      if (!mounted) return;

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
        'Onboarding completed for user ${user.uid}, awarded ${widget.config.welcomeBonusPoints} DustBunnies',
      );

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      logger.e('Error completing onboarding', error: e);

      if (!mounted) return;

      // Track completion error
      final onboardingException = OnboardingExceptionHelper.fromException(e);
      await _analyticsService.trackOnboardingFailed(
        widget.config.type.value,
        onboardingException.runtimeType.toString(),
        onboardingException.message,
      );

      if (mounted) {
        _showErrorSnackBar(_getErrorMessage(e));
      }
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
          // Extract nonprofit slugs for Every.org integration
          final nonprofitSlugs = selectedCharities
              .map((c) => (c is Map ? c['slug'] ?? c['id'] : c.slug) as String)
              .toList();

          // Save all selected charities
          await ref
              .read(profileServiceProvider)
              .updateCharities(userId, nonprofitSlugs);

          // Save the first selected charity as the primary nonprofit for ad donations
          await FirebaseFirestore.instance.collection('users').doc(userId).set(
            {
              'selectedNonprofitSlug': nonprofitSlugs.first,
              'selectedNonprofits': nonprofitSlugs,
            },
            SetOptions(merge: true),
          );

          // Track charities saved
          await _analyticsService.trackPreferencesSaved(
            userId,
            'charities',
            selectedCharities.length,
            nonprofitSlugs,
          );
        }
      }

      // Sync pending profile data if collected during onboarding (before auth)
      if (widget.config.hasStep(OnboardingStep.profileSetup)) {
        await _syncPendingProfileData(userId);
      }
    } catch (e) {
      logger.e('Error saving user preferences', error: e);
      // Re-throw to be caught by parent method
      rethrow;
    }
  }

  /// Sync pending profile data that was collected before user authenticated
  Future<void> _syncPendingProfileData(String userId) async {
    try {
      final pendingData = ref.read(pendingProfileDataProvider);

      if (!pendingData.hasData) {
        logger.d('No pending profile data to sync');
        return;
      }

      logger.i('Syncing pending profile data for user $userId');

      final updates = <String, dynamic>{};

      if (pendingData.displayName != null &&
          pendingData.displayName!.isNotEmpty) {
        updates['name'] = pendingData.displayName;
        updates['displayName'] = pendingData.displayName;
      }

      if (pendingData.bio != null && pendingData.bio!.isNotEmpty) {
        updates['bio'] = pendingData.bio;
      }

      // Upload profile image if path was stored
      if (pendingData.profileImagePath != null) {
        try {
          final imageFile = File(pendingData.profileImagePath!);
          if (await imageFile.exists()) {
            final photoUrl = await ref
                .read(profileServiceProvider)
                .uploadProfilePicture(userId, imageFile);
            updates['profilePictureUrl'] = photoUrl;

            // Award bonus DustBunnies for profile photo
            try {
              await ref.read(dustBunniesServiceProvider).awardDustBunnies(
                    userId: userId,
                    action: 'profile_photo_upload',
                    customAmount: 25,
                  );
            } catch (_) {
              // Ignore DustBunnies award errors
            }
          }
        } catch (e) {
          logger.w('Could not upload pending profile image: $e');
        }
      }

      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update(updates);
        logger.i('Successfully synced pending profile data');
      }

      // Clear pending data after sync
      ref.read(pendingProfileDataProvider.notifier).clear();
    } catch (e) {
      logger.e('Error syncing pending profile data: $e');
      // Don't rethrow - profile sync errors shouldn't block onboarding completion
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

  String _getErrorMessage(error) {
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
          onSkipCharity: _skipCharitySelection,
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
          onSkip: _skipCharitySelection, // Always allow skipping charity selection
        );
      case OnboardingStep.authentication:
        return AuthenticationStepScreen(
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
  Widget build(BuildContext context) => PopScope(
      canPop: false, // Prevent back navigation during onboarding
      child: Scaffold(
        // Remove background color as it will be covered by AnimatedGradientBackground
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Persistent background layer
            const Positioned.fill(
              child: AnimatedGradientBackground(),
            ),
            
            // Main content layer
            SafeArea(
              child: Column(
                children: [
                  // Header with progress and skip button
                  if (widget.config.showProgressIndicator) _buildHeader(),
    
                  // Main content - use Flexible instead of Expanded to allow content to size itself
                  Flexible(
                    child: _buildCurrentStep(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

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
                  color: AppColors.textWhite,
                ),
              ),

              // Skip button
              if (canSkip)
                TextButton(
                  onPressed: _skipStep,
                  child: Text(
                    'Skip',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textWhite,
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
              builder: (context, child) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
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
        (ref) => SelectedInterestsNotifier(),);

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
        (ref) => SelectedCharitiesNotifier(),);

class SelectedCharitiesNotifier extends StateNotifier<List<dynamic>> {
  SelectedCharitiesNotifier() : super([]);

  void toggle(charity) {
    final charityId = charity is Map ? charity['id'] : charity.id;
    final existingIndex =
        state.indexWhere((c) => (c is Map ? c['id'] : c.id) == charityId);

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

/// Model for pending profile data collected during onboarding
class PendingProfileData {
  const PendingProfileData({
    this.displayName,
    this.bio,
    this.profileImagePath,
  });

  final String? displayName;
  final String? bio;
  final String? profileImagePath;

  PendingProfileData copyWith({
    String? displayName,
    String? bio,
    String? profileImagePath,
  }) => PendingProfileData(
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );

  bool get hasData =>
      (displayName != null && displayName!.isNotEmpty) ||
      (bio != null && bio!.isNotEmpty) ||
      profileImagePath != null;
}

/// Provider for storing profile data during onboarding (before auth)
final pendingProfileDataProvider =
    StateNotifierProvider<PendingProfileDataNotifier, PendingProfileData>(
        (ref) => PendingProfileDataNotifier(),);

class PendingProfileDataNotifier extends StateNotifier<PendingProfileData> {
  PendingProfileDataNotifier() : super(const PendingProfileData());

  void setDisplayName(String name) {
    state = state.copyWith(displayName: name);
  }

  void setBio(String bio) {
    state = state.copyWith(bio: bio);
  }

  void setProfileImagePath(String path) {
    state = state.copyWith(profileImagePath: path);
  }

  void clear() {
    state = const PendingProfileData();
  }
}
