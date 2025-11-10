import 'package:flutter/material.dart';

/// UI constants for consistent styling throughout the app
class UIConstants {
  // Font sizes
  static const double kSmallFontSize = 10.0;
  static const double kMediumFontSize = 12.0;
  static const double kDefaultFontSize = 14.0;
  static const double kLargeFontSize = 16.0;
  static const double kExtraLargeFontSize = 18.0;
  static const double kHugeFontSize = 24.0;
  static const double kTitleFontSize = 32.0;
  static const double kHeroFontSize = 48.0;

  // Border radius values
  static const double kSmallBorderRadius = 8.0;
  static const double kMediumBorderRadius = 12.0;
  static const double kDefaultBorderRadius = 16.0;
  static const double kLargeBorderRadius = 20.0;
  static const double kExtraLargeBorderRadius = 30.0;

  // Common border radius objects
  static const Radius kSmallRadius = Radius.circular(kSmallBorderRadius);
  static const Radius kMediumRadius = Radius.circular(kMediumBorderRadius);
  static const Radius kDefaultRadius = Radius.circular(kDefaultBorderRadius);
  static const Radius kLargeRadius = Radius.circular(kLargeBorderRadius);
  static const Radius kExtraLargeRadius =
      Radius.circular(kExtraLargeBorderRadius);

  // Border radius objects for different corners
  static const BorderRadius kSmallBorderRadiusAll =
      BorderRadius.all(kSmallRadius);
  static const BorderRadius kMediumBorderRadiusAll =
      BorderRadius.all(kMediumRadius);
  static const BorderRadius kDefaultBorderRadiusAll =
      BorderRadius.all(kDefaultRadius);
  static const BorderRadius kLargeBorderRadiusAll =
      BorderRadius.all(kLargeRadius);

  // Elevation values
  static const double kLowElevation = 2.0;
  static const double kMediumElevation = 4.0;
  static const double kDefaultElevation = 8.0;
  static const double kHighElevation = 16.0;

  // Opacity values
  static const double kLowOpacity = 0.1;
  static const double kMediumOpacity = 0.5;
  static const double kHighOpacity = 0.8;
  static const double kVeryHighOpacity = 0.9;

  // Shadow blur radius
  static const double kDefaultBlurRadius = 8.0;
  static const double kMediumBlurRadius = 10.0;
  static const double kLargeBlurRadius = 20.0;

  // Progress indicator sizes
  static const double kSmallProgressSize = 16.0;
  static const double kDefaultProgressSize = 24.0;
  static const double kLargeProgressSize = 32.0;

  // Line heights for progress indicators
  static const double kProgressLineHeight = 8.0;
  static const double kThinProgressLineHeight = 4.0;
  static const double kThickProgressLineHeight = 12.0;
}
