import 'package:flutter/material.dart';
import 'package:sweep_feed/core/theme/app_colors.dart';
import 'package:sweep_feed/core/theme/app_text_styles.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterPressed;

  const HomeSearchBar({
    super.key,
    this.controller,
    this.onSubmitted,
    this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52, // Standard height
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium.withOpacity(0.7), // Slightly transparent
        borderRadius: BorderRadius.circular(26), // Pill shape
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textLight, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textWhite),
              decoration: InputDecoration(
                hintText: 'Search contests, prizes...',
                hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          if (onFilterPressed != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.filter_list_alt, color: AppColors.textLight, size: 22),
              onPressed: onFilterPressed,
              splashRadius: 20,
            ),
          ]
        ],
      ),
    );
  }
}
