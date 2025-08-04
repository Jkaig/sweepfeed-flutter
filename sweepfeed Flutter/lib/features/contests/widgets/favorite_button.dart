import 'package:flutter/material.dart';
import 'package:sweep_feed/core/theme/app_colors.dart';

class FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback? onToggle;
  final Color color;

  const FavoriteButton({
    super.key,
    required this.isFavorite,
    this.onToggle,
    this.color = AppColors.textWhite, // Defaulting to textWhite as per new palette
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.bookmark : Icons.bookmark_border,
        color: color,
      ),
      onPressed: onToggle,
      splashRadius: 24, // Standard splash radius
      padding: EdgeInsets.zero, // Remove default padding if a specific size is desired
      constraints: const BoxConstraints(), // Remove default constraints for tighter packing if needed
    );
  }
}
