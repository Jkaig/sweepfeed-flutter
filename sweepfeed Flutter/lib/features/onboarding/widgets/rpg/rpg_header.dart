import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/models/winner_class.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class RPGHeader extends StatelessWidget {
  const RPGHeader({
    required this.getCreationTitle,
    required this.getCreationSubtitle,
    required this.selectedClass,
    required this.totalLevel,
    required this.experiencePoints,
    super.key,
  });

  final String Function() getCreationTitle;
  final String Function() getCreationSubtitle;
  final WinnerClass selectedClass;
  final int totalLevel;
  final int experiencePoints;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              getCreationTitle(),
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ).animate().shimmer(
                  duration: 2000.ms,
                  color: selectedClass.primaryColor.withValues(alpha: 0.5),
                ),

            const SizedBox(height: 8),

            Text(
              getCreationSubtitle(),
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Level and SP display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    selectedClass.primaryColor,
                    selectedClass.secondaryColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.military_tech,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Level $totalLevel • $experiencePoints SP',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
