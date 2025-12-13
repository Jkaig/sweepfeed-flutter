import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    required this.isFavorite,
    super.key,
    this.onToggle,
    this.color =
        AppColors.textWhite, // Defaulting to textWhite as per new palette
  });
  final bool isFavorite;
  final VoidCallback? onToggle;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        decoration: isFavorite
            ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              )
            : null,
        child: IconButton(
          icon: Icon(
            isFavorite ? Icons.bookmark : Icons.bookmark_border,
            color: isFavorite ? AppColors.accent : color,
          ),
          onPressed: onToggle,
          splashRadius: 24,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      );
}
