import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/dust_bunnies_shop.dart';

/// Tab bar widget for shop categories
class ShopCategoryTabs extends StatelessWidget {
  const ShopCategoryTabs({
    required this.tabController,
    required this.selectedType,
    super.key,
  });

  final TabController tabController;
  final ShopItemType selectedType;

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: AppColors.brandCyan.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.brandCyan,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: AppTextStyles.bodyMedium,
        tabs: ShopItemType.values.map((type) => Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(type.emojiIcon),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    type.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),).toList(),
      ),
    );
}
