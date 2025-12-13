import 'package:flutter/material.dart';

import '../theme/app_animations.dart';

/// A widget that fades in its child with a configurable delay
class AnimatedFadeIn extends StatelessWidget {
  const AnimatedFadeIn({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.duration = AppAnimations.fast,
    this.curve = AppAnimations.smoothIn,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: curve,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: child,
      ),
      child: child,
    );
}

/// A widget that fades in with a staggered delay based on index
class StaggeredFadeIn extends StatelessWidget {
  const StaggeredFadeIn({
    required this.child,
    required this.index,
    super.key,
    this.delayPerItem = const Duration(milliseconds: 50),
    this.duration = AppAnimations.fast,
    this.curve = AppAnimations.smoothIn,
  });

  final Widget child;
  final int index;
  final Duration delayPerItem;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
      duration: duration + (delayPerItem * index),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: curve,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: child,
      ),
      child: child,
    );
}

