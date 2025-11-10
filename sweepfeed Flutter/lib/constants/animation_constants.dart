import 'package:flutter/animation.dart';

/// Animation constants for consistent timing and transitions throughout the app.
class AnimationConstants {
  /// Fast animation duration (150ms) for quick transitions.
  static const Duration kFastAnimationDuration = Duration(milliseconds: 150);

  /// Default animation duration (300ms) for standard UI transitions.
  static const Duration kDefaultAnimationDuration = Duration(milliseconds: 300);

  /// Medium animation duration (500ms) for moderate transitions.
  static const Duration kMediumAnimationDuration = Duration(milliseconds: 500);

  /// Long animation duration (1000ms) for extended transitions.
  static const Duration kLongAnimationDuration = Duration(milliseconds: 1000);

  /// Extra long animation duration (1500ms) for special effects.
  static const Duration kExtraLongAnimationDuration =
      Duration(milliseconds: 1500);

  /// Animation duration for button interactions.
  static const Duration kButtonAnimationDuration = kFastAnimationDuration;

  /// Animation duration for page transitions.
  static const Duration kPageTransitionDuration = kDefaultAnimationDuration;

  /// Animation duration for modal dialogs.
  static const Duration kModalAnimationDuration = kMediumAnimationDuration;

  /// Animation duration for loading indicators.
  static const Duration kLoadingAnimationDuration = kLongAnimationDuration;

  /// Animation duration for level up celebrations.
  static const Duration kLevelUpAnimationDuration = kExtraLongAnimationDuration;

  /// Short delay (100ms) for staggered animations.
  static const Duration kShortDelay = Duration(milliseconds: 100);

  /// Medium delay (200ms) for staggered animations.
  static const Duration kMediumDelay = Duration(milliseconds: 200);

  /// Long delay (500ms) for staggered animations.
  static const Duration kLongDelay = Duration(milliseconds: 500);

  /// Default easing curve for smooth animations.
  static const Curve curve = Curves.easeInOut;

  /// Fast easing curve for quick animations.
  static const Curve fastCurve = Curves.easeOut;

  /// Bouncy easing curve for playful animations.
  static const Curve bounceCurve = Curves.elasticOut;
}
