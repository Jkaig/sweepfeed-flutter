import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/email_message.dart';
import '../services/email_service.dart';

/// Custom tab widget for email categories with unread count badges
class EmailCategoryTab extends ConsumerWidget {
  const EmailCategoryTab({
    super.key,
    required this.category,
    required this.label,
    required this.icon,
    this.isSelected = false,
  });

  final EmailCategory? category; // null for "All" tab
  final String label;
  final IconData icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadCountProvider(category));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.brandCyan.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(
                color: AppColors.brandCyan.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppColors.brandCyan : AppColors.textLight,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? AppColors.brandCyan : AppColors.textLight,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          unreadCountAsync.when(
            data: (unreadCount) {
              if (unreadCount > 0) {
                return Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandCyan,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Custom tab bar for email categories
class EmailCategoryTabBar extends StatelessWidget {
  const EmailCategoryTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.tabs = const [
      EmailCategoryTabData(
        category: null,
        label: 'All',
        icon: Icons.all_inbox,
      ),
      EmailCategoryTabData(
        category: EmailCategory.promo,
        label: 'Promos',
        icon: Icons.local_offer,
      ),
      EmailCategoryTabData(
        category: EmailCategory.winner,
        label: 'Winners',
        icon: Icons.emoji_events,
      ),
    ],
  });

  final int selectedIndex;
  final Function(int) onTabSelected;
  final List<EmailCategoryTabData> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onTabSelected(i),
                child: EmailCategoryTab(
                  category: tabs[i].category,
                  label: tabs[i].label,
                  icon: tabs[i].icon,
                  isSelected: selectedIndex == i,
                ),
              ),
            ),
            if (i < tabs.length - 1)
              Container(
                width: 1,
                height: 20,
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
          ],
        ],
      ),
    );
  }
}

/// Data class for email category tab configuration
class EmailCategoryTabData {
  const EmailCategoryTabData({
    required this.category,
    required this.label,
    required this.icon,
  });

  final EmailCategory? category;
  final String label;
  final IconData icon;
}

/// Animated tab indicator for custom tab bar
class AnimatedTabIndicator extends StatelessWidget {
  const AnimatedTabIndicator({
    super.key,
    required this.selectedIndex,
    required this.tabCount,
    this.animationDuration = const Duration(milliseconds: 250),
  });

  final int selectedIndex;
  final int tabCount;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: animationDuration,
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(
        left: (MediaQuery.of(context).size.width / tabCount) * selectedIndex,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width / tabCount,
        height: 3,
        decoration: BoxDecoration(
          color: AppColors.brandCyan,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Scrollable tab bar for when there are many categories
class ScrollableEmailCategoryTabBar extends StatelessWidget {
  const ScrollableEmailCategoryTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.tabs,
  });

  final int selectedIndex;
  final Function(int) onTabSelected;
  final List<EmailCategoryTabData> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primaryMedium.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: EmailCategoryTab(
              category: tabs[index].category,
              label: tabs[index].label,
              icon: tabs[index].icon,
              isSelected: selectedIndex == index,
            ),
          );
        },
      ),
    );
  }
}

/// Filter chip for additional email filtering options
class EmailFilterChip extends StatelessWidget {
  const EmailFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandCyan.withValues(alpha: 0.15)
              : AppColors.primaryMedium.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.brandCyan.withValues(alpha: 0.5)
                : AppColors.primaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.brandCyan : AppColors.textLight,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.brandCyan : AppColors.textLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandCyan : AppColors.textMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.textWhite,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
