import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class LevelProgressBar extends StatelessWidget {
  final int currentLevel;
  final int currentDB;
  final int dbToNextLevel;
  final String rank;

  const LevelProgressBar({
    super.key,
    required this.currentLevel,
    required this.currentDB,
    required this.dbToNextLevel,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress (0.0 to 1.0)
    final progress = (currentDB / dbToNextLevel).clamp(0.0, 1.0);
    // Calculate percentage for display
    final percentage = (progress * 100).toInt();

    return Column(
      children: [
        // Level/Rank Info Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level $currentLevel',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.brandCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    rank,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currentDB / $dbToNextLevel DB',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontFamily: 'Monospace', // Or a tabular variant if available
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.brandCyan.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Progress Bar Container
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Animated Fill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.brandCyan,
                          AppColors.electricBlue,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandCyan.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                  
                  // Shine/Glint Effect (Optional animation overlay)
                  if (progress > 0)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0);
  }
}
