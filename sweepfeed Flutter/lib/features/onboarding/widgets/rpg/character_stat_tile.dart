import 'package:flutter/material.dart';

import '../../../../core/models/character_stat.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class CharacterStatTile extends StatelessWidget {
  const CharacterStatTile({
    required this.stat,
    super.key,
  });

  final CharacterStat stat;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              stat.color.withValues(alpha: 0.2),
              stat.color.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: stat.color.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                stat.icon,
                color: stat.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${stat.value}/${stat.maxValue}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: stat.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
