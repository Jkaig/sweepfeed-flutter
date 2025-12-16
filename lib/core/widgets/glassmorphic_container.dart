import 'dart:ui';

import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final AlignmentGeometry? alignment;
  final double? border;
  final Gradient? linearGradient;
  final Gradient? borderGradient;
  final List<Color>? colors;

  const GlassmorphicContainer({
    required this.child, super.key,
    this.borderRadius = 20,
    this.blur = 10,
    this.alignment,
    this.border,
    this.linearGradient,
    this.borderGradient,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: linearGradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors ?? [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
            border: Border.all(
              width: border ?? 1.0,
              color: Colors.transparent, // Gradient border needs CustomPainter or other approach, simplifying for now or relying on container border
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(borderRadius),
               border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: border ?? 1.0), // Simple border fallback
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
