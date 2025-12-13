import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Widget shown when free users hit their daily entry limit
/// Shows sad dustbunny and encourages upgrade
class EntryLimitReachedCard extends StatelessWidget {
  const EntryLimitReachedCard({
    required this.onUpgradePressed,
    super.key,
  });

  final VoidCallback onUpgradePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryMedium.withOpacity(0.8),
            AppColors.primaryDark.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.warningOrange.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warningOrange.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sad Dustbunny Image
          Image.asset(
            'assets/images/dustbunnies/dustbunny_sad.png',
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image not found
              return Icon(
                Icons.sentiment_very_dissatisfied,
                size: 120,
                color: AppColors.warningOrange,
              );
            },
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            'Come Back Tomorrow!',
            style: AppTextStyles.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Message
          Text(
            "You've used all 10 free entries today. Keep browsing to see what's popular, or upgrade to enter unlimited contests!",
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Upgrade Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUpgradePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandCyan,
                foregroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Upgrade to Unlimited',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary CTA
          TextButton(
            onPressed: () {
              // Just dismiss - they can keep scrolling
              Navigator.of(context).pop();
            },
            child: Text(
              'Keep Browsing',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.brandCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
