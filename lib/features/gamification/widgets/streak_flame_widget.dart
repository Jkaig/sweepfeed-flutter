import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';

class StreakFlameWidget extends StatelessWidget {
  const StreakFlameWidget({
    required this.streakDays,
    this.size = 100,
    super.key,
  });

  final int streakDays;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Calculate intensity based on streak (cap at 30 days for max intensity)
    final intensity = (streakDays / 30).clamp(0.0, 1.0);
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.orange.withValues(alpha: 0.2 + (0.3 * intensity)),
                  Colors.transparent,
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1500.ms),

          // Flame Core
          Icon(
            Icons.local_fire_department_rounded,
            size: size * 0.8,
            color: Color.lerp(Colors.orange, Colors.deepOrange, intensity),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(
             begin: const Offset(1, 1), 
             end: const Offset(1.05, 1.05), 
             duration: 1000.ms,
             curve: Curves.easeInOut,
           )
           .tint(
             color: Colors.yellow,
             duration: 1000.ms,
             curve: Curves.easeInOut,
           ),

          // Streak Count
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: Text(
                '$streakDays Days',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
