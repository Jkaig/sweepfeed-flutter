import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class FeatureHighlightCard extends StatelessWidget {
  const FeatureHighlightCard({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium
              .withValues(alpha: 0.5), // Or AppColors.primaryLight
          borderRadius: BorderRadius.circular(8.0),
          // border: Border.all(color: AppColors.primaryLight, width: 0.5), // Optional border
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accent, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ), // AppTextStyles.bodyLarge is not nullable
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ), // AppTextStyles.bodyMedium is not nullable
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
