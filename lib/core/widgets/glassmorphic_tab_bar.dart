import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Glassmorphic tab bar with blur effect and modern design
class GlassmorphicTabBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassmorphicTabBar({
    required this.controller,
    required this.tabs,
    this.onTap,
    super.key,
  });

  final TabController controller;
  final List<Widget> tabs;
  final ValueChanged<int>? onTap;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryMedium.withValues(alpha: 0.7),
                  AppColors.primaryDark.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.brandCyan.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: TabBar(
              controller: controller,
              onTap: onTap,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: [
                    AppColors.brandCyan.withValues(alpha: 0.8),
                    AppColors.electricBlue.withValues(alpha: 0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandCyan.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(6),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textLight,
              labelStyle: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: tabs,
            ),
          ),
        ),
      ),
    );
  }
}
