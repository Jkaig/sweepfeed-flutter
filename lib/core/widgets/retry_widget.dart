import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'primary_button.dart';

/// A widget that displays an error message with a retry button
class RetryWidget extends StatelessWidget {
  const RetryWidget({
    required this.onRetry,
    super.key,
    this.title = 'Something went wrong',
    this.message = 'An error occurred. Please try again.',
    this.icon = Icons.error_outline,
  });

  final VoidCallback onRetry;
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onRetry();
              },
              text: 'Retry',
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
}

