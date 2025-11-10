import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// Custom page transitions for premium navigation experience
class PageTransitions {
  /// Fade transition for primary navigation (bottom nav)
  static Route<T> fadeTransition<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
  }) =>
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
          opacity: animation,
          child: child,
        ),
      );

  /// Shared axis transition for drill-down navigation
  static Route<T> sharedAxisTransition<T>({
    required Widget page,
    SharedAxisTransitionType transitionType =
        SharedAxisTransitionType.horizontal,
    Duration duration = const Duration(milliseconds: 300),
  }) =>
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: transitionType,
          child: child,
        ),
      );

  /// Container transform for expanding elements (like cards to detail)
  static Route<T> containerTransform<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 500),
  }) =>
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        ),
      );

  /// Slide up transition for modals and sheets
  static Route<T> slideUpTransition<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 350),
    bool fullscreenDialog = true,
  }) =>
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        fullscreenDialog: fullscreenDialog,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          final tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      );
}

/// Extension on Navigator for easy usage
extension NavigatorExtensions on NavigatorState {
  /// Push with fade transition
  Future<T?> pushFade<T extends Object?>(Widget page) =>
      push(PageTransitions.fadeTransition(page: page));

  /// Push replacement with fade transition
  Future<T?> pushReplacementFade<T extends Object?, TO extends Object?>(
    Widget page, {
    TO? result,
  }) =>
      pushReplacement(
        PageTransitions.fadeTransition(page: page),
        result: result,
      );

  /// Push with shared axis transition
  Future<T?> pushSharedAxis<T extends Object?>(
    Widget page, {
    SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
  }) =>
      push(
        PageTransitions.sharedAxisTransition(
          page: page,
          transitionType: type,
        ),
      );

  /// Push with container transform
  Future<T?> pushContainer<T extends Object?>(Widget page) =>
      push(PageTransitions.containerTransform(page: page));

  /// Push modal with slide up
  Future<T?> pushModal<T extends Object?>(Widget page) =>
      push(PageTransitions.slideUpTransition(page: page));
}
