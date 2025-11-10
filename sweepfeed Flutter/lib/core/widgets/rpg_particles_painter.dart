import 'dart:math';
import 'package:flutter/material.dart';

class RPGParticlesPainter extends CustomPainter {
  RPGParticlesPainter({
    required this.progress,
    required this.glowIntensity,
    required this.primaryColor,
    required this.secondaryColor,
  });
  final double progress;
  final double glowIntensity;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create epic floating runes and magical effects
    for (var i = 0; i < 25; i++) {
      final x = (i * 60.0 + sin(progress * 2 * pi + i) * 40) % size.width;
      final y =
          (i * 40.0 + cos(progress * 2 * pi + i * 0.8) * 30) % size.height;

      final alpha = 0.2 + sin(progress * 3 * pi + i) * 0.15 * glowIntensity;
      paint.color =
          (i.isEven ? primaryColor : secondaryColor).withValues(alpha: alpha);

      final radius = 3 + sin(progress * 4 * pi + i) * 2;

      // Draw glowing orb
      canvas.drawCircle(Offset(x, y), radius, paint);

      // Draw magical trail
      final trailPaint = Paint()
        ..color = paint.color.withValues(alpha: alpha * 0.3)
        ..style = PaintingStyle.fill;

      for (var j = 1; j <= 3; j++) {
        final trailX = x - (sin(progress * 2 * pi + i) * j * 8);
        final trailY = y - (cos(progress * 2 * pi + i * 0.8) * j * 8);
        canvas.drawCircle(
          Offset(trailX, trailY),
          radius * (1 - j * 0.3),
          trailPaint,
        );
      }
    }

    // Draw magical energy lines
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = primaryColor.withValues(alpha: 0.1 + glowIntensity * 0.1);

    for (var i = 0; i < 8; i++) {
      final path = Path();
      final startX = (i * size.width / 8) + sin(progress * 2 * pi + i) * 20;
      final startY = sin(progress * 3 * pi + i * 0.5) * 30 + size.height * 0.3;

      path.moveTo(startX, startY);

      for (double t = 0; t <= 1; t += 0.1) {
        final x = startX + t * 100 + sin(progress * 4 * pi + i + t) * 15;
        final y = startY + t * 200 + cos(progress * 3 * pi + i + t) * 20;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
