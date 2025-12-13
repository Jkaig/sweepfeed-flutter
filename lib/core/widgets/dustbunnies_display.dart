import 'package:flutter/material.dart';
import 'dustbunny_icon.dart';

/// A widget that displays DustBunnies amount with the cute bunny icon
///
/// This widget standardizes how DustBunnies (DB) currency is shown throughout the app.
/// It combines the DustBunny character icon with the numerical amount and "DB" text.
class DustBunniesDisplay extends StatelessWidget {
  const DustBunniesDisplay({
    required this.amount, super.key,
    this.iconSize = 20.0,
    this.textStyle,
    this.showPlus = false,
    this.spacing = 4.0,
    this.iconTintColor,
    this.animated = false,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
  });

  /// Amount of DustBunnies to display
  final int amount;

  /// Size of the DustBunny icon
  final double iconSize;

  /// Text style for the amount and "DB" text
  final TextStyle? textStyle;

  /// Whether to show a plus sign before the amount (e.g., "+50 DB" vs "50 DB")
  final bool showPlus;

  /// Spacing between icon and text
  final double spacing;

  /// Optional color to tint the icon
  final Color? iconTintColor;

  /// Whether to animate the icon (for rewards/gains)
  final bool animated;

  /// How to align the icon and text horizontally
  final MainAxisAlignment mainAxisAlignment;

  /// How to align the icon and text vertically
  final CrossAxisAlignment crossAxisAlignment;

  /// Direction of the layout (null = default LTR)
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final effectiveTextStyle = textStyle ?? defaultTextStyle;

    // Determine icon tint color - use text color if not specified
    final iconColor = iconTintColor ?? effectiveTextStyle.color;

    final children = [
      // DustBunny icon
      if (animated) AnimatedDustBunnyIcon(
              size: iconSize,
              tintColor: iconColor,
            ) else DustBunnyIcon(
              size: iconSize,
              tintColor: iconColor,
            ),

      SizedBox(width: spacing),

      // Amount and DB text
      Text(
        '${showPlus ? '+' : ''}$amount DB',
        style: effectiveTextStyle,
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      children: children,
    );
  }
}

/// A compact variant for small spaces (like cards and lists)
class CompactDustBunniesDisplay extends StatelessWidget {
  const CompactDustBunniesDisplay({
    required this.amount, super.key,
    this.showPlus = false,
    this.color,
    this.fontSize = 12.0,
  });

  /// Amount of DustBunnies to display
  final int amount;

  /// Whether to show a plus sign before the amount
  final bool showPlus;

  /// Color for both icon and text
  final Color? color;

  /// Font size for the text
  final double fontSize;

  @override
  Widget build(BuildContext context) => DustBunniesDisplay(
      amount: amount,
      iconSize: fontSize * 1.2, // Icon slightly larger than text
      textStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      showPlus: showPlus,
      spacing: 3.0,
      iconTintColor: color,
    );
}

/// A large variant for prominent displays (like rewards and achievements)
class LargeDustBunniesDisplay extends StatelessWidget {
  const LargeDustBunniesDisplay({
    required this.amount, super.key,
    this.showPlus = false,
    this.color,
    this.animated = true,
  });

  /// Amount of DustBunnies to display
  final int amount;

  /// Whether to show a plus sign before the amount
  final bool showPlus;

  /// Color for both icon and text
  final Color? color;

  /// Whether to animate the icon
  final bool animated;

  @override
  Widget build(BuildContext context) => DustBunniesDisplay(
      amount: amount,
      iconSize: 32.0,
      textStyle: TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      showPlus: showPlus,
      spacing: 8.0,
      iconTintColor: color,
      animated: animated,
    );
}

/// A widget specifically for showing DustBunnies gains/rewards
class DustBunniesRewardDisplay extends StatelessWidget {
  const DustBunniesRewardDisplay({
    required this.amount, super.key,
    this.size = DustBunniesRewardSize.medium,
    this.color,
    this.glowEffect = false,
  });

  /// Amount of DustBunnies gained
  final int amount;

  /// Size variant
  final DustBunniesRewardSize size;

  /// Color theme
  final Color? color;

  /// Whether to add a glow effect
  final bool glowEffect;

  @override
  Widget build(BuildContext context) {
    late double iconSize;
    late double fontSize;
    late FontWeight fontWeight;
    late double spacing;

    switch (size) {
      case DustBunniesRewardSize.small:
        iconSize = 16.0;
        fontSize = 12.0;
        fontWeight = FontWeight.w600;
        spacing = 3.0;
        break;
      case DustBunniesRewardSize.medium:
        iconSize = 24.0;
        fontSize = 16.0;
        fontWeight = FontWeight.bold;
        spacing = 6.0;
        break;
      case DustBunniesRewardSize.large:
        iconSize = 32.0;
        fontSize = 20.0;
        fontWeight = FontWeight.w800;
        spacing = 8.0;
        break;
    }

    Widget display = DustBunniesDisplay(
      amount: amount,
      iconSize: iconSize,
      textStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? Colors.white,
      ),
      showPlus: true,
      spacing: spacing,
      iconTintColor: color ?? Colors.white,
      animated: true,
    );

    if (glowEffect && color != null) {
      display = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color!.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: display,
      );
    }

    return display;
  }
}

/// Size variants for DustBunnies reward displays
enum DustBunniesRewardSize { small, medium, large }
