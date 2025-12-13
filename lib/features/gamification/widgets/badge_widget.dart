import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/badge_model.dart' as model;

class BadgeWidget extends StatelessWidget {
  final model.Badge badge;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const BadgeWidget({
    required this.badge, required this.isUnlocked, super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked 
                  ? AppColors.primaryLight 
                  : AppColors.primaryDark.withValues(alpha: 0.5),
              border: Border.all(
                color: isUnlocked ? AppColors.brandGold : Colors.white10,
                width: isUnlocked ? 2 : 1,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: AppColors.brandGold.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Icon(
              isUnlocked ? badge.icon : Icons.lock_outline,
              size: 40,
              color: isUnlocked ? AppColors.brandGold : Colors.white24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium.copyWith(
              color: isUnlocked ? Colors.white : Colors.white54,
              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
