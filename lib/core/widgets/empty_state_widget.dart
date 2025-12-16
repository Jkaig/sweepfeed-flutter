import 'package:flutter/material.dart';

import '../services/sensory_feedback_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'dustbunny_icon.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.actionText,
    this.onAction,
    this.semanticLabel,
    this.useDustBunny = false,
    this.dustBunnyImage,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final String? semanticLabel;
  final bool useDustBunny;
  final String? dustBunnyImage;

  @override
  Widget build(BuildContext context) {
    final feedbackService = SensoryFeedbackService();

    return Semantics(
      label: semanticLabel ?? '$title. $message',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'Empty state icon',
                child: useDustBunny || dustBunnyImage != null
                    ? dustBunnyImage != null
                        ? Image.asset(
                            dustBunnyImage!,
                            width: 64,
                            height: 64,
                            errorBuilder: (context, error, stackTrace) {
                              return const DustBunnyIcon(size: 64);
                            },
                          )
                        : const DustBunnyIcon(size: 64)
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.brandCyan.withValues(alpha: 0.2),
                              AppColors.primary.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 48,
                          color: AppColors.brandCyan.withValues(alpha: 0.6),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (actionText != null && onAction != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  label: actionText,
                  button: true,
                  child: ElevatedButton(
                    onPressed: () {
                      feedbackService.trigger(SensoryFeedbackType.buttonTap);
                      onAction!();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandCyan,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: const Size(88, 44), // Minimum touch target
                    ),
                    child: Text(
                      actionText!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
