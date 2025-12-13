import 'package:flutter/material.dart';

/// UI constants for consistent styling throughout the app
class UIConstants {
  // Font sizes
  /// Small font size: 10.0
  static const double kSmallFontSize = 10.0;
  /// Medium font size: 12.0
  static const double kMediumFontSize = 12.0;
  /// Default font size: 14.0
  static const double kDefaultFontSize = 14.0;
  /// Large font size: 16.0
  static const double kLargeFontSize = 16.0;
  /// Extra large font size: 18.0
  static const double kExtraLargeFontSize = 18.0;
  /// Huge font size: 24.0
  static const double kHugeFontSize = 24.0;
  /// Title font size: 32.0
  static const double kTitleFontSize = 32.0;
  /// Hero font size: 48.0
  static const double kHeroFontSize = 48.0;

  // Border radius values
  /// Small border radius: 8.0
  static const double kSmallBorderRadius = 8.0;
  /// Medium border radius: 12.0
  static const double kMediumBorderRadius = 12.0;
  /// Default border radius: 16.0
  static const double kDefaultBorderRadius = 16.0;
  /// Large border radius: 20.0
  static const double kLargeBorderRadius = 20.0;
  /// Extra large border radius: 30.0
  static const double kExtraLargeBorderRadius = 30.0;

  // Common border radius objects
  /// A [Radius] with a circular radius of [kSmallBorderRadius].
  static const Radius kSmallRadius = Radius.circular(kSmallBorderRadius);
  /// A [Radius] with a circular radius of [kMediumBorderRadius].
  static const Radius kMediumRadius = Radius.circular(kMediumBorderRadius);
  /// A [Radius] with a circular radius of [kDefaultBorderRadius].
  static const Radius kDefaultRadius = Radius.circular(kDefaultBorderRadius);
  /// A [Radius] with a circular radius of [kLargeBorderRadius].
  static const Radius kLargeRadius = Radius.circular(kLargeBorderRadius);
  /// A [Radius] with a circular radius of [kExtraLargeBorderRadius].
  static const Radius kExtraLargeRadius =
      Radius.circular(kExtraLargeBorderRadius);

  // Border radius objects for different corners
  /// A [BorderRadius] with all corners set to [kSmallRadius].
  static const BorderRadius kSmallBorderRadiusAll =
      BorderRadius.all(kSmallRadius);
  /// A [BorderRadius] with all corners set to [kMediumRadius].
  static const BorderRadius kMediumBorderRadiusAll =
      BorderRadius.all(kMediumRadius);
  /// A [BorderRadius] with all corners set to [kDefaultRadius].
  static const BorderRadius kDefaultBorderRadiusAll =
      BorderRadius.all(kDefaultRadius);
  /// A [BorderRadius] with all corners set to [kLargeRadius].
  static const BorderRadius kLargeBorderRadiusAll =
      BorderRadius.all(kLargeRadius);

  // Elevation values
  /// Low elevation value: 2.0
  static const double kLowElevation = 2.0;
  /// Medium elevation value: 4.0
  static const double kMediumElevation = 4.0;
  /// Default elevation value: 8.0
  static const double kDefaultElevation = 8.0;
  /// High elevation value: 16.0
  static const double kHighElevation = 16.0;

  // Opacity values
  /// Low opacity value: 0.1
  static const double kLowOpacity = 0.1;
  /// Medium opacity value: 0.5
  static const double kMediumOpacity = 0.5;
  /// High opacity value: 0.8
  static const double kHighOpacity = 0.8;
  /// Very high opacity value: 0.9
  static const double kVeryHighOpacity = 0.9;

  // Shadow blur radius
  /// Default blur radius for shadows: 8.0
  static const double kDefaultBlurRadius = 8.0;
  /// Medium blur radius for shadows: 10.0
  static const double kMediumBlurRadius = 10.0;
  /// Large blur radius for shadows: 20.0
  static const double kLargeBlurRadius = 20.0;

  // Progress indicator sizes
  /// Small progress indicator size: 16.0
  static const double kSmallProgressSize = 16.0;
  /// Default progress indicator size: 24.0
  static const double kDefaultProgressSize = 24.0;
  /// Large progress indicator size: 32.0
  static const double kLargeProgressSize = 32.0;

  // Line heights for progress indicators
  /// Default line height for progress indicators: 8.0
  static const double kProgressLineHeight = 8.0;
  /// Thin line height for progress indicators: 4.0
  static const double kThinProgressLineHeight = 4.0;
  /// Thick line height for progress indicators: 12.0
  static const double kThickProgressLineHeight = 12.0;
}
