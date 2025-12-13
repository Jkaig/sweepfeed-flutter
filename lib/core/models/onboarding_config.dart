import '../constants/onboarding_constants.dart';

/// Configuration model for the onboarding flow
/// Allows for customizable onboarding experiences based on user segments
class OnboardingConfig {
  const OnboardingConfig({
    required this.steps,
    required this.type,
    this.canSkipSteps = true,
    this.showProgressIndicator = true,
    this.welcomeBonusPoints = OnboardingDefaults.welcomeBonusPoints,
    this.allowBackNavigation = false,
  }) : assert(welcomeBonusPoints >= 0,
            'Welcome bonus points must be non-negative',);

  /// List of onboarding steps to show
  final List<OnboardingStep> steps;

  /// Type of configuration for analytics tracking
  final OnboardingConfigType type;

  /// Whether users can skip individual steps
  final bool canSkipSteps;

  /// Whether to show progress indicators
  final bool showProgressIndicator;

  /// Points awarded on completion
  final int welcomeBonusPoints;

  /// Whether users can navigate backwards
  final bool allowBackNavigation;

  /// Default configuration with all steps for new users
  static const OnboardingConfig defaultConfig = OnboardingConfig(
    type: OnboardingConfigType.defaultConfig,
    steps: [
      OnboardingStep.welcome,
      OnboardingStep.howItWorks,
      OnboardingStep.charityImpact,
      OnboardingStep.gamification,
      OnboardingStep.interestSelection,
      OnboardingStep.charitySelection,
      OnboardingStep.authentication, // Login/signup BEFORE profile setup
      OnboardingStep.profileSetup,
      OnboardingStep.notificationPermission,
      OnboardingStep.tutorial,
      OnboardingStep.completion,
    ],
  );

  /// Minimal configuration for quick onboarding
  static const OnboardingConfig quickConfig = OnboardingConfig(
    type: OnboardingConfigType.quick,
    steps: [
      OnboardingStep.welcome,
      OnboardingStep.interestSelection,
      OnboardingStep.charitySelection,
      OnboardingStep.completion,
    ],
    canSkipSteps: false,
    welcomeBonusPoints: OnboardingDefaults.quickBonusPoints,
    allowBackNavigation: true,
  );

  /// Configuration focused on core features only
  static const OnboardingConfig coreConfig = OnboardingConfig(
    type: OnboardingConfigType.core,
    steps: [
      OnboardingStep.welcome,
      OnboardingStep.howItWorks,
      OnboardingStep.interestSelection,
      OnboardingStep.profileSetup,
      OnboardingStep.completion,
    ],
    welcomeBonusPoints: OnboardingDefaults.coreBonusPoints,
  );

  /// Get the total number of steps in this configuration
  int get totalSteps => steps.length;

  /// Check if a specific step is enabled
  bool hasStep(OnboardingStep step) => steps.contains(step);

  /// Get the index of a step (returns -1 if not found)
  int getStepIndex(OnboardingStep step) => steps.indexOf(step);
}

/// Enum defining all possible onboarding steps
enum OnboardingStep {
  welcome,
  howItWorks,
  charityImpact,
  gamification,
  pointsSystem,
  interestSelection,
  charitySelection,
  socialConnection,
  biometricSetup,
  authentication, // Login/signup step - should come before profileSetup
  profileSetup,
  notificationPermission,
  tutorial,
  completion,
}

/// Extension to get display information for each step
extension OnboardingStepExtension on OnboardingStep {
  String get title {
    switch (this) {
      case OnboardingStep.welcome:
        return 'Welcome to SweepFeed';
      case OnboardingStep.howItWorks:
        return 'How It Works';
      case OnboardingStep.charityImpact:
        return 'Support Charity';
      case OnboardingStep.gamification:
        return 'Gamification Features';
      case OnboardingStep.pointsSystem:
        return 'Points System';
      case OnboardingStep.interestSelection:
        return 'Select Interests';
      case OnboardingStep.charitySelection:
        return 'Choose Charities';
      case OnboardingStep.socialConnection:
        return 'Social Features';
      case OnboardingStep.biometricSetup:
        return 'Biometric Setup';
      case OnboardingStep.authentication:
        return 'Create Your Account';
      case OnboardingStep.profileSetup:
        return 'Profile Setup';
      case OnboardingStep.notificationPermission:
        return 'Notifications';
      case OnboardingStep.tutorial:
        return 'Quick Tutorial';
      case OnboardingStep.completion:
        return 'Ready to Win!';
    }
  }

  String get description {
    switch (this) {
      case OnboardingStep.welcome:
        return 'Win real prizes, completely free!';
      case OnboardingStep.howItWorks:
        return 'Simple to enter, fun to win';
      case OnboardingStep.charityImpact:
        return 'Every entry supports verified charities';
      case OnboardingStep.gamification:
        return 'Discover fun ways to engage';
      case OnboardingStep.pointsSystem:
        return 'Earn points, get extra chances';
      case OnboardingStep.interestSelection:
        return 'Tell us what prizes you love';
      case OnboardingStep.charitySelection:
        return 'Choose charities you want to support';
      case OnboardingStep.socialConnection:
        return 'Connect with friends and share wins';
      case OnboardingStep.biometricSetup:
        return 'Secure your account';
      case OnboardingStep.authentication:
        return 'Sign in to save your progress';
      case OnboardingStep.profileSetup:
        return 'Complete your profile';
      case OnboardingStep.notificationPermission:
        return 'Get notified about new contests';
      case OnboardingStep.tutorial:
        return 'Learn how to enter contests';
      case OnboardingStep.completion:
        return "You're all set to start winning!";
    }
  }

  bool get isSkippable {
    switch (this) {
      case OnboardingStep.welcome:
      case OnboardingStep.interestSelection:
      case OnboardingStep.authentication: // Required for profile setup to work
      case OnboardingStep.completion:
        return false; // Core steps that shouldn't be skipped
      default:
        return true; // Optional steps
    }
  }

  bool get isRequired {
    switch (this) {
      case OnboardingStep.welcome:
      case OnboardingStep.interestSelection:
      case OnboardingStep.charitySelection:
      case OnboardingStep.authentication: // Required for profile setup & data sync
      case OnboardingStep.completion:
        return true; // Required for basic app functionality
      default:
        return false; // Enhancement steps
    }
  }
}
