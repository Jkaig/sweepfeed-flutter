import 'dart:ui';
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
    this.activeFilterCount = 0,
  });
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterPressed;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryMedium.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.brandCyan.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 12),
                  child: Icon(
                    Icons.search,
                    color: AppColors.brandCyan.withValues(alpha: 0.8),
                    size: 22,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.textWhite),
                    decoration: InputDecoration(
                      hintText: 'Search contests, prizes...',
                      hintStyle: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.textMuted.withOpacity(0.7)),
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
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onFilterPressed,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: activeFilterCount > 0
                                    ? AppColors.brandCyan.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: activeFilterCount > 0
                                    ? Border.all(
                                        color: AppColors.brandCyan
                                            .withValues(alpha: 0.5))
                                    : Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.1)),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.tune,
                                color: activeFilterCount > 0
                                    ? AppColors.brandCyan
                                    : AppColors.textLight,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        if (activeFilterCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.brandCyan,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                activeFilterCount > 9
                                    ? '9+'
                                    : '$activeFilterCount',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
