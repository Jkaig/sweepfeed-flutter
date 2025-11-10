class OnboardingConstants {
  static const double screenPadding = 24.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const double iconSize = 80.0;
  static const double smallIconSize = 32.0;
  static const double pillIconSize = 18.0;

  static const double verticalSpacingSmall = 8.0;
  static const double verticalSpacingMedium = 16.0;
  static const double verticalSpacingLarge = 24.0;
  static const double verticalSpacingXLarge = 32.0;
  static const double verticalSpacingXXLarge = 48.0;

  static const double buttonPaddingVertical = 16.0;
  static const double cardPadding = 20.0;
  static const double pillPaddingHorizontal = 16.0;
  static const double pillPaddingVertical = 10.0;

  static const double animationHeightLarge = 200.0;
  static const double featureCardHeight = 120.0;

  static const Duration fadeInDuration = Duration(milliseconds: 500);
  static const Duration fadeInDelayShort = Duration(milliseconds: 200);
  static const Duration fadeInDelayMedium = Duration(milliseconds: 400);
  static const Duration fadeInDelayLong = Duration(milliseconds: 600);
  static const Duration fadeInDelayXLong = Duration(milliseconds: 800);
  static const Duration scaleAnimationDuration = Duration(milliseconds: 600);

  static const double borderWidth = 1.5;
  static const double cardBorderWidth = 1.5;

  static const String lottieWelcomeAnimation =
      'assets/animations/welcome_animation.json';
  static const String lottieLogoAnimation =
      'assets/animations/logo_animation.json';

  static const int totalOnboardingScreens = 9;
  static const int welcomeBonusPoints = 100;

  static const String semanticWelcomeScreen =
      'Welcome screen introducing SweepFeed';
  static const String semanticGamificationScreen =
      'Gamification features explanation';
  static const String semanticCharityScreen = 'Charity impact information';
  static const String semanticSocialScreen = 'Social features overview';
  static const String semanticInterestScreen = 'Select your prize interests';
  static const String semanticCharitySelectionScreen =
      'Choose charities to support';
  static const String semanticProfileScreen = 'Set up your profile';
  static const String semanticNotificationScreen = 'Enable notifications';
  static const String semanticTutorialScreen =
      'Quick tutorial on entering contests';
  static const String semanticCompletionScreen = 'Onboarding completion';

  static const String skipButtonLabel = 'Skip this screen';
  static const String nextButtonLabel = 'Continue to next screen';
  static const String getStartedButtonLabel = 'Start using SweepFeed';
}
