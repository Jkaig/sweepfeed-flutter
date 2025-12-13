import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_container.dart';

class DayCard extends StatelessWidget {
  const DayCard({
    required this.dayNumber,
    required this.isCompleted,
    required this.isToday,
    required this.rewardAmount,
    required this.isMysteryBox,
    super.key,
  });

  final int dayNumber;
  final bool isCompleted;
  final bool isToday;
  final int rewardAmount;
  final bool isMysteryBox;

  @override
  Widget build(BuildContext context) {
    final isLocked = !isCompleted && !isToday;

    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        color: isCompleted 
            ? AppColors.successGreen.withValues(alpha: 0.2)
            : isToday 
                ? AppColors.accent.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
              ? AppColors.successGreen 
              : isToday 
                  ? AppColors.accent 
                  : Colors.white.withValues(alpha: 0.1),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Day $dayNumber',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (isMysteryBox)
            Icon(
              Icons.card_giftcard,
              color: isLocked ? Colors.grey : AppColors.brandPurple,
              size: 24,
            ).animate(onPlay: (c) => isToday ? c.repeat(reverse: true) : null)
             .scale(duration: 500.ms)
          else if (isCompleted)
            const Icon(Icons.check_circle, color: AppColors.successGreen, size: 24)
                .animate().scale()
          else
            Column(
              children: [
                Icon(
                  Icons.stars, 
                  color: isLocked ? Colors.grey : AppColors.cyberYellow,
                  size: 16
                ),
                Text(
                  '+$rewardAmount',
                  style: TextStyle(
                    color: isLocked ? Colors.grey : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
