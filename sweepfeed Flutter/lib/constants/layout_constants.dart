import 'package:flutter/material.dart';

/// Layout constants for consistent spacing and positioning throughout the app
class LayoutConstants {
  // Padding values
  static const double kSmallPadding = 8.0;
  static const double kDefaultPadding = 16.0;
  static const double kMediumPadding = 20.0;
  static const double kLargePadding = 24.0;
  static const double kExtraLargePadding = 30.0;

  // Margin values
  static const double kSmallMargin = 8.0;
  static const double kDefaultMargin = 16.0;
  static const double kMediumMargin = 20.0;
  static const double kLargeMargin = 24.0;

  // Spacing widgets for convenience
  static const SizedBox kSmallVerticalSpacer = SizedBox(height: kSmallPadding);
  static const SizedBox kDefaultVerticalSpacer =
      SizedBox(height: kDefaultPadding);
  static const SizedBox kMediumVerticalSpacer =
      SizedBox(height: kMediumPadding);
  static const SizedBox kLargeVerticalSpacer = SizedBox(height: kLargePadding);

  static const SizedBox kSmallHorizontalSpacer = SizedBox(width: kSmallPadding);
  static const SizedBox kDefaultHorizontalSpacer =
      SizedBox(width: kDefaultPadding);
  static const SizedBox kMediumHorizontalSpacer =
      SizedBox(width: kMediumPadding);
  static const SizedBox kLargeHorizontalSpacer = SizedBox(width: kLargePadding);

  // Common padding edge insets
  static const EdgeInsets kSmallPaddingAll = EdgeInsets.all(kSmallPadding);
  static const EdgeInsets kDefaultPaddingAll = EdgeInsets.all(kDefaultPadding);
  static const EdgeInsets kMediumPaddingAll = EdgeInsets.all(kMediumPadding);
  static const EdgeInsets kLargePaddingAll = EdgeInsets.all(kLargePadding);

  static const EdgeInsets kSmallPaddingHorizontal =
      EdgeInsets.symmetric(horizontal: kSmallPadding);
  static const EdgeInsets kDefaultPaddingHorizontal =
      EdgeInsets.symmetric(horizontal: kDefaultPadding);
  static const EdgeInsets kMediumPaddingHorizontal =
      EdgeInsets.symmetric(horizontal: kMediumPadding);
  static const EdgeInsets kLargePaddingHorizontal =
      EdgeInsets.symmetric(horizontal: kLargePadding);

  static const EdgeInsets kSmallPaddingVertical =
      EdgeInsets.symmetric(vertical: kSmallPadding);
  static const EdgeInsets kDefaultPaddingVertical =
      EdgeInsets.symmetric(vertical: kDefaultPadding);
  static const EdgeInsets kMediumPaddingVertical =
      EdgeInsets.symmetric(vertical: kMediumPadding);
  static const EdgeInsets kLargePaddingVertical =
      EdgeInsets.symmetric(vertical: kLargePadding);
}
