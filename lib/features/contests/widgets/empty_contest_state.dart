import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class EmptyContestState extends StatelessWidget {
  const EmptyContestState({
    super.key,
    this.message = 'No contests found matching your criteria.',
    this.onReset,
  });

  final String message;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/dustbunnies/dustbunny_sad.png',
              width: 64,
              height: 64,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'No Contests Found',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            if (onReset != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh),
                label: const Text('Clear Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandCyan,
                  side: const BorderSide(color: AppColors.brandCyan),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
}

