import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/models/winner_class.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class WinnerClassCard extends StatelessWidget {
  const WinnerClassCard({
    required this.winnerClass,
    required this.isSelected,
    super.key,
  });

  final WinnerClass winnerClass;
  final bool isSelected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              winnerClass.primaryColor
                  .withValues(alpha: isSelected ? 0.5 : 0.3),
              winnerClass.secondaryColor
                  .withValues(alpha: isSelected ? 0.4 : 0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? winnerClass.primaryColor
                : winnerClass.primaryColor.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: winnerClass.primaryColor.withValues(alpha: 0.6),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: winnerClass.secondaryColor.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: -5,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Class icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      winnerClass.primaryColor,
                      winnerClass.secondaryColor,
                    ],
                  ),
                ),
                child: Icon(
                  winnerClass.icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Class name and title
              Text(
                winnerClass.name,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              Text(
                winnerClass.title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: winnerClass.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Description
              Expanded(
                child: Text(
                  winnerClass.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Abilities preview
              const SizedBox(height: 16),
              Text(
                'Special Abilities:',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              ...winnerClass.abilities.take(2).map(
                    (ability) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 12,
                            color: winnerClass.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ability,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      )
          .animate(target: isSelected ? 1 : 0)
          .scale(
            duration: 300.ms,
            curve: Curves.easeInOut,
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
          )
          .fadeIn(duration: 300.ms);
}
