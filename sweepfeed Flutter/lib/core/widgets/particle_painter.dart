import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated particle/ember effect painter
class ParticlePainter extends CustomPainter {
  ParticlePainter({
    required this.progress,
    required this.color,
    this.particleCount = 50,
    this.maxParticleSize = 4.0,
    this.minParticleSize = 1.0,
  });
  final double progress;
  final Color color;
  final int particleCount;
  final double maxParticleSize;
  final double minParticleSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42); // Fixed seed for consistent particles

    for (var i = 0; i < particleCount; i++) {
      // Generate consistent particle properties
      final particleProgress = (progress + i / particleCount) % 1.0;
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final floatSpeed = 50 + random.nextDouble() * 100;
      final horizontalDrift = (random.nextDouble() - 0.5) * 30;

      // Calculate particle position
      final y = baseY - (particleProgress * floatSpeed);
      final driftX =
          x + (math.sin(particleProgress * math.pi * 2) * horizontalDrift);

      // Fade in and out
      final opacity = particleProgress < 0.1
          ? particleProgress / 0.1
          : particleProgress > 0.9
              ? (1.0 - particleProgress) / 0.1
              : 1.0;

      // Random size
      final particleSize = minParticleSize +
          random.nextDouble() * (maxParticleSize - minParticleSize);

      // Draw particle with glow effect
      paint.color = color.withValues(alpha: opacity * 0.8);

      // Outer glow
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(
        Offset(driftX % size.width, y % size.height),
        particleSize * 1.5,
        paint,
      );

      // Inner core
      paint.maskFilter = null;
      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(
        Offset(driftX % size.width, y % size.height),
        particleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Static particle field for backgrounds
class StaticParticlePainter extends CustomPainter {
  StaticParticlePainter({
    required this.color,
    this.particleCount = 100,
    this.maxSize = 2.0,
    this.minSize = 0.5,
  });
  final Color color;
  final int particleCount;
  final double maxSize;
  final double minSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    final random = math.Random(42);

    for (var i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final particleSize = minSize + random.nextDouble() * (maxSize - minSize);
      final opacity = 0.1 + random.nextDouble() * 0.3;

      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
