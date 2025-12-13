import 'package:flutter/material.dart';

/// Animation configurations for the app
class AppAnimations {
  // Duration configurations
  static const Duration ultraFast = Duration(milliseconds: 100);
  static const Duration veryFast = Duration(milliseconds: 200);
  static const Duration fast = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration slow = Duration(milliseconds: 700);
  static const Duration verySlow = Duration(milliseconds: 1000);
  static const Duration superSlow = Duration(milliseconds: 1500);

  // Curves for different animations
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticIn = Curves.elasticIn;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve smoothIn = Curves.easeIn;
  static const Curve smoothOut = Curves.easeOut;
  static const Curve smoothInOut = Curves.easeInOut;
  static const Curve springIn = Curves.easeInBack;
  static const Curve springOut = Curves.easeOutBack;
  static const Curve sharp = Curves.easeInOutCubic;

  // Page transition configurations
  static const Duration pageTransition = Duration(milliseconds: 400);
  static const Curve pageTransitionCurve = Curves.easeInOutCubic;

  // Button animation configurations
  static const Duration buttonPress = Duration(milliseconds: 150);
  static const Duration buttonRelease = Duration(milliseconds: 200);
  static const double buttonScalePressed = 0.95;
  static const double buttonScaleHover = 1.05;

  // Card animation configurations
  static const Duration cardAppear = Duration(milliseconds: 400);
  static const Duration cardHover = Duration(milliseconds: 200);
  static const double cardHoverElevation = 12.0;
  static const double cardNormalElevation = 4.0;

  // Loading and shimmer configurations
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  static const Duration loadingPulse = Duration(milliseconds: 1000);

  // Celebration and reward animations
  static const Duration celebrationDuration = Duration(seconds: 3);
  static const Duration coinCollectDuration = Duration(milliseconds: 800);
  static const Duration xpGainDuration = Duration(milliseconds: 1200);

  // Stagger animation delays
  static const Duration staggerDelay = Duration(milliseconds: 50);
  static const Duration staggerDelayLong = Duration(milliseconds: 100);

  // Custom animation builders
  static Widget fadeIn({
    required Widget child,
    Duration duration = fast,
    Curve curve = smoothIn,
  }) =>
      TweenAnimationBuilder<double>(
        duration: duration,
        tween: Tween(begin: 0.0, end: 1.0),
        curve: curve,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: child,
        ),
        child: child,
      );

  static Widget slideIn({
    required Widget child,
    Duration duration = medium,
    Curve curve = smoothOut,
    Offset begin = const Offset(0, 0.3),
    Offset end = Offset.zero,
  }) =>
      TweenAnimationBuilder<Offset>(
        duration: duration,
        tween: Tween(begin: begin, end: end),
        curve: curve,
        builder: (context, value, child) => Transform.translate(
          offset: value,
          child: child,
        ),
        child: child,
      );

  static Widget scaleIn({
    required Widget child,
    Duration duration = medium,
    Curve curve = elasticOut,
    double begin = 0.0,
    double end = 1.0,
  }) =>
      TweenAnimationBuilder<double>(
        duration: duration,
        tween: Tween(begin: begin, end: end),
        curve: curve,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: child,
        ),
        child: child,
      );

  static Widget rotateIn({
    required Widget child,
    Duration duration = medium,
    Curve curve = smoothOut,
    double begin = 0.5,
    double end = 0.0,
  }) =>
      TweenAnimationBuilder<double>(
        duration: duration,
        tween: Tween(begin: begin, end: end),
        curve: curve,
        builder: (context, value, child) => Transform.rotate(
          angle: value * 3.14159,
          child: child,
        ),
        child: child,
      );
}

/// Stagger animation helper
class StaggerAnimation extends StatelessWidget {
  const StaggerAnimation({
    required this.itemCount,
    required this.itemBuilder,
    super.key,
    this.delay = AppAnimations.staggerDelay,
    this.direction = Axis.vertical,
  });
  final int itemCount;
  final Duration delay;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Axis direction;

  @override
  Widget build(BuildContext context) => direction == Axis.vertical
      ? Column(
          children: List.generate(
            itemCount,
            (index) => TweenAnimationBuilder<double>(
              duration: AppAnimations.medium,
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, (1 - value) * 20),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              ),
              child: itemBuilder(context, index),
            ),
          ),
        )
      : Row(
          children: List.generate(
            itemCount,
            (index) => TweenAnimationBuilder<double>(
              duration: AppAnimations.medium,
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Transform.translate(
                offset: Offset((1 - value) * 20, 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              ),
              child: itemBuilder(context, index),
            ),
          ),
        );
}
