import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    super.key,
    this.controller,
    this.onSubmitted,
    this.onChanged,
    this.onFilterPressed,
  });
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterPressed;

  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primaryMedium.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: AppColors.brandCyan.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16, right: 12),
              child: Icon(Icons.search, color: AppColors.brandCyan, size: 22),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textWhite),
                decoration: InputDecoration(
                  hintText: 'Search contests, prizes...',
                  hintStyle: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                cursorColor: AppColors.brandCyan,
                onSubmitted: onSubmitted,
                onChanged: onChanged,
              ),
            ),
            if (onFilterPressed != null) ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.tune,
                    color: AppColors.brandCyan,
                    size: 22,
                  ),
                  onPressed: onFilterPressed,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ],
        ),
      );
}
