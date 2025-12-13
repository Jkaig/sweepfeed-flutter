import 'package:flutter/material.dart';

/// Layout constants for consistent spacing and positioning throughout the app
class LayoutConstants {
  // Padding values
  /// Small padding value: 8.0
  static const double kSmallPadding = 8.0;
  /// Default padding value: 16.0
  static const double kDefaultPadding = 16.0;
  /// Medium padding value: 20.0
  static const double kMediumPadding = 20.0;
  /// Large padding value: 24.0
  static const double kLargePadding = 24.0;
  /// Extra large padding value: 30.0
  static const double kExtraLargePadding = 30.0;

  // Margin values
  /// Small margin value: 8.0
  static const double kSmallMargin = 8.0;
  /// Default margin value: 16.0
  static const double kDefaultMargin = 16.0;
  /// Medium margin value: 20.0
  static const double kMediumMargin = 20.0;
  /// Large margin value: 24.0
  static const double kLargeMargin = 24.0;

  // Spacing widgets for convenience
  /// A vertical spacer with a height of [kSmallPadding].
  static const SizedBox kSmallVerticalSpacer = SizedBox(height: kSmallPadding);
  /// A vertical spacer with a height of [kDefaultPadding].
  static const SizedBox kDefaultVerticalSpacer =
      SizedBox(height: kDefaultPadding);
  /// A vertical spacer with a height of [kMediumPadding].
  static const SizedBox kMediumVerticalSpacer =
      SizedBox(height: kMediumPadding);
  /// A vertical spacer with a height of [kLargePadding].
  static const SizedBox kLargeVerticalSpacer = SizedBox(height: kLargePadding);

  /// A horizontal spacer with a width of [kSmallPadding].
  static const SizedBox kSmallHorizontalSpacer = SizedBox(width: kSmallPadding);
  /// A horizontal spacer with a width of [kDefaultPadding].
  static const SizedBox kDefaultHorizontalSpacer =
      SizedBox(width: kDefaultPadding);
  /// A horizontal spacer with a width of [kMediumPadding].
  static const SizedBox kMediumHorizontalSpacer =
      SizedBox(width: kMediumPadding);
  /// A horizontal spacer with a width of [kLargePadding].
  static const SizedBox kLargeHorizontalSpacer = SizedBox(width: kLargePadding);

  // Common padding edge insets
  /// An [EdgeInsets] with all sides set to [kSmallPadding].
  static const EdgeInsets kSmallPaddingAll = EdgeInsets.all(kSmallPadding);
  /// An [EdgeInsets] with all sides set to [kDefaultPadding].
  static const EdgeInsets kDefaultPaddingAll = EdgeInsets.all(kDefaultPadding);
  /// An [EdgeInsets] with all sides set to [kMediumPadding].
  static const EdgeInsets kMediumPaddingAll = EdgeInsets.all(kMediumPadding);
  /// An [EdgeInsets] with all sides set to [kLargePadding].
  static const EdgeInsets kLargePaddingAll = EdgeInsets.all(kLargePadding);

  /// An [EdgeInsets] with horizontal sides set to [kSmallPadding].
  static const EdgeInsets kSmallPaddingHorizontal =
      EdgeInsets.symmetric(horizontal: kSmallPadding);
  /// An [EdgeInsets] with horizontal sides set to [kDefaultPadding].
  static const EdgeInsets kDefaultPaddingHorizontal =
      EdgeInsets.symmetric(horizontal: kDefaultPadding);
  /// An [EdgeInsets] with horizontal sides set to [kMediumPadding].
  static const EdgeInsets kMediumPaddingHorizontal =
      EdgeInsets.symmetric(horizontal: kMediumPadding);
  /// An [EdgeInsets] with horizontal sides set to [kLargePadding].
  static const EdgeInsets kLargePaddingHorizontal =
      EdgeInsets.symmetric(horizontal: kLargePadding);

  /// An [EdgeInsets] with vertical sides set to [kSmallPadding].
  static const EdgeInsets kSmallPaddingVertical =
      EdgeInsets.symmetric(vertical: kSmallPadding);
  /// An [EdgeInsets] with vertical sides set to [kDefaultPadding].
  static const EdgeInsets kDefaultPaddingVertical =
      EdgeInsets.symmetric(vertical: kDefaultPadding);
  /// An [EdgeInsets] with vertical sides set to [kMediumPadding].
  static const EdgeInsets kMediumPaddingVertical =
      EdgeInsets.symmetric(vertical: kMediumPadding);
  /// An [EdgeInsets] with vertical sides set to [kLargePadding].
  static const EdgeInsets kLargePaddingVertical =
      EdgeInsets.symmetric(vertical: kLargePadding);
}
