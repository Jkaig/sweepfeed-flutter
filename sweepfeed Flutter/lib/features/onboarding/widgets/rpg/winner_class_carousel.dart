import 'package:flutter/material.dart';

import '../../../../core/models/winner_class.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'winner_class_card.dart';

class WinnerClassCarousel extends StatelessWidget {
  const WinnerClassCarousel({
    required this.pageController,
    required this.winnerClasses,
    required this.onPageChanged,
    required this.selectedClassIndex,
    required this.classSelectController,
    super.key,
  });

  final PageController pageController;
  final List<WinnerClass> winnerClasses;
  final void Function(int) onPageChanged;
  final int selectedClassIndex;
  final AnimationController classSelectController;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            'Choose Your Winner Class',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: winnerClasses.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                final winnerClass = winnerClasses[index];
                final isSelected = index == selectedClassIndex;

                return AnimatedBuilder(
                  animation: classSelectController,
                  builder: (context, child) => Transform.scale(
                    scale: isSelected
                        ? Tween<double>(begin: 0.9, end: 1.0)
                            .animate(classSelectController)
                            .value
                        : 0.9,
                    child: WinnerClassCard(
                      winnerClass: winnerClass,
                      isSelected: isSelected,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
}
