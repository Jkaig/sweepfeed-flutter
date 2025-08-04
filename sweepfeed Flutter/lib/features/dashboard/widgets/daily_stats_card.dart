import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sweep_feed/core/theme/app_colors.dart';
import 'package:sweep_feed/core/theme/app_text_styles.dart';

class DailyStatsCard extends StatelessWidget {
  final int entriesUsed;
  final int entriesLimit;
  final int userLevel;
  final double todaysBestPrize;

  const DailyStatsCard({
    super.key,
    required this.entriesUsed,
    required this.entriesLimit,
    required this.userLevel,
    required this.todaysBestPrize,
  });

  @override
  Widget build(BuildContext context) {
    double progress = entriesLimit > 0 ? entriesUsed / entriesLimit : 0.0;
    String bestPrizeFormatted = todaysBestPrize > 0 ? '\$${todaysBestPrize.toStringAsFixed(0)}' : 'N/A';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryMedium, AppColors.primaryDark.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Progress",
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Level $userLevel",
                      style: AppTextStyles.headlineSmall.copyWith(color: AppColors.accent),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Best Prize Today: $bestPrizeFormatted",
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: CircularPercentIndicator(
                  radius: 45.0, // Adjust radius for desired size
                  lineWidth: 8.0,
                  animation: true,
                  percent: progress,
                  center: Text(
                    "${(progress * 100).toStringAsFixed(0)}%",
                    style: AppTextStyles.titleSmall.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.bold),
                  ),
                  footer: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "$entriesUsed / $entriesLimit Entries",
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                  progressColor: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
