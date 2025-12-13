import 'dart:ui';

import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final List<Color> colors;
  final Border? border;

  const GlassmorphicContainer({
    required this.child, super.key,
    this.borderRadius = 20,
    this.blur = 10,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.colors = const [
      Colors.white,
      Colors.white,
    ],
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}
