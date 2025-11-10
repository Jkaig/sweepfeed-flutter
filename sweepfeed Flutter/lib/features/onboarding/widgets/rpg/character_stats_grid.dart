import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/models/character_stat.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'character_stat_tile.dart';

class CharacterStatsGrid extends StatelessWidget {
  const CharacterStatsGrid({
    required this.statsController,
    required this.characterStats,
    super.key,
  });

  final AnimationController statsController;
  final List<CharacterStat> characterStats;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: statsController,
        builder: (context, child) => Opacity(
          opacity: statsController.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Your Stats',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: characterStats.length,
                    itemBuilder: (context, index) {
                      final stat = characterStats[index];
                      return CharacterStatTile(stat: stat)
                          .animate()
                          .slideY(
                            begin: 0.3,
                            duration:
                                Duration(milliseconds: 400 + (index * 100)),
                            curve: Curves.easeOutBack,
                          )
                          .fadeIn(
                            duration:
                                Duration(milliseconds: 600 + (index * 100)),
                          );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
