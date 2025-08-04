import 'package:flutter/material.dart';
import 'package:sweep_feed/core/models/category_model.dart'; // Updated path
import 'package:sweep_feed/core/theme/app_colors.dart';
import 'package:sweep_feed/core/theme/app_text_styles.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110, // Adjusted width
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryLight.withOpacity(0.5), width: 1),
           boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(2, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 36, // Increased icon size
              color: AppColors.accent,
            ),
            const SizedBox(height: 10), // Increased spacing
            Text(
              category.name,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
