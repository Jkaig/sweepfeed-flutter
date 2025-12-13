import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/models/winner_class.dart';
import '../../../../core/theme/app_text_styles.dart';

class CreateCharacterButton extends StatelessWidget {
  const CreateCharacterButton({
    required this.isCreatingCharacter,
    required this.onPressed,
    required this.selectedClass,
    required this.classSelected,
    super.key,
  });

  final bool isCreatingCharacter;
  final VoidCallback onPressed;
  final WinnerClass selectedClass;
  final bool classSelected;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        child: AnimatedOpacity(
          opacity: classSelected ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: GestureDetector(
            onTap: isCreatingCharacter ? null : onPressed,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    selectedClass.primaryColor,
                    selectedClass.secondaryColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: selectedClass.primaryColor.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCreatingCharacter) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    isCreatingCharacter
                        ? 'Creating Your Legend...'
                        : 'Create My Character',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!isCreatingCharacter) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ],
              ),
            ),
          ),
        )
            .animate()
            .scale(
              duration: 800.ms,
              curve: Curves.elasticOut,
            )
            .then(delay: 500.ms)
            .shimmer(
              duration: 2000.ms,
              color: Colors.white30,
            ),
      );
}
