import 'package:flutter/animation.dart';

/// Constants for onboarding flow timing and behavior
class OnboardingTimingConstants {
  /// Duration for page transitions between steps
  static const Duration stepTransitionDuration = Duration(milliseconds: 300);

  /// Duration for progress bar animation
  static const Duration progressAnimationDuration = Duration(milliseconds: 300);

  /// Delay before completing onboarding for better UX
  static const Duration completionDelay = Duration(milliseconds: 500);

  /// Animation curve for step transitions
  static const Curve stepTransitionCurve = Curves.easeInOut;

  /// Animation curve for progress bar
  static const Curve progressAnimationCurve = Curves.easeInOut;
}

/// Configuration types for analytics tracking
enum OnboardingConfigType {
  quick('quick'),
  core('core'),
  defaultConfig('default'),
  custom('custom');

  const OnboardingConfigType(this.value);
  final String value;
}

/// Onboarding screen dimensions and spacing
class OnboardingDimensionConstants {
  /// Screen padding for all onboarding screens
  static const double screenPadding = 24.0;

  /// Icon size for main step icons
  static const double mainIconSize = 100.0;

  /// Small icon size for feature pills
  static const double smallIconSize = 32.0;

  /// Progress bar height
  static const double progressBarHeight = 4.0;

  /// Button height
  static const double buttonHeight = 56.0;

  /// Border radius for cards and buttons
  static const double borderRadius = 12.0;

  /// Spacing between major sections
  static const double sectionSpacing = 32.0;

  /// Spacing between minor elements
  static const double elementSpacing = 16.0;
}

/// Analytics event names for onboarding
class OnboardingAnalyticsEvents {
  static const String started = 'started';
  static const String stepCompleted = 'step_completed';
  static const String stepSkipped = 'step_skipped';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String interestsSaved = 'interests_saved';
  static const String charitiesSaved = 'charities_saved';
  static const String completionStarted = 'completion_started';
}

/// Default configuration values
class OnboardingDefaults {
  /// Default welcome bonus points
  static const int welcomeBonusPoints = 100;

  /// Quick config bonus points
  static const int quickBonusPoints = 50;

  /// Core config bonus points
  static const int coreBonusPoints = 75;

  /// Maximum number of interests a user can select
  static const int maxInterests = 10;

  /// Maximum number of charities a user can select
  static const int maxCharities = 5;

  /// Minimum number of interests required
  static const int minInterests = 1;

  /// Minimum number of charities required
  static const int minCharities = 1;
}

/// Error messages for onboarding failures
class OnboardingErrorMessages {
  static const String networkError =
      'Network connection failed. Please check your internet connection and try again.';
  static const String authError =
      'Authentication failed. Please try logging in again.';
  static const String permissionError =
      'Permission denied. Please ensure you have the necessary permissions.';
  static const String validationError =
      'Invalid data provided. Please check your input and try again.';
  static const String storageError = 'Failed to save data. Please try again.';
  static const String configError =
      'Invalid onboarding configuration. Please contact support.';
  static const String genericError =
      'An unexpected error occurred. Please try again.';
}

/// Semantic labels for accessibility
class OnboardingSemanticLabels {
  static const String progressIndicator = 'Onboarding progress indicator';
  static const String skipButton = 'Skip this step';
  static const String backButton = 'Go back to previous step';
  static const String nextButton = 'Continue to next step';
  static const String completeButton = 'Complete onboarding';
  static const String retryButton = 'Retry operation';
  static const String interestTile = 'Interest selection tile';
  static const String charityTile = 'Charity selection tile';
}
