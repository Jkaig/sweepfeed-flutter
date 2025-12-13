import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A reusable widget for displaying error messages with consistent styling.
///
/// This widget provides a standardized way to show error messages across
/// the app, ensuring consistent visual design and spacing.
class ErrorDisplay extends StatelessWidget {
  /// Creates an [ErrorDisplay] widget.
  const ErrorDisplay({
    required this.message,
    super.key,
    this.icon,
    this.onRetry,
    this.retryText = 'Try Again',
  });

  /// The error message to display.
  final String message;

  /// Optional icon to display with the error message.
  final IconData? icon;

  /// Optional callback for retry functionality.
  final VoidCallback? onRetry;

  /// Text to display on the retry button.
  final String retryText;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        margin: const EdgeInsets.all(AppSpacing.small),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: AppColors.errorRed.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: AppColors.errorRed,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.small),
            ],
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.errorRed,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.medium),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                    vertical: AppSpacing.small,
                  ),
                ),
                child: Text(
                  retryText,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.errorRed,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

/// A compact error display for inline usage.
class InlineErrorDisplay extends StatelessWidget {
  /// Creates an [InlineErrorDisplay] widget.
  const InlineErrorDisplay({
    required this.message,
    super.key,
  });

  /// The error message to display.
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          border: Border.all(
            color: AppColors.errorRed.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.errorRed,
              size: 16,
            ),
            const SizedBox(width: AppSpacing.small),
            Flexible(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.errorRed,
                ),
              ),
            ),
          ],
        ),
      );
}
