import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sweep_feed/core/models/contest_model.dart';
import 'package:sweep_feed/core/theme/app_colors.dart';
import 'package:sweep_feed/core/theme/app_text_styles.dart';

class InteractiveDailyChecklistItem extends StatelessWidget {
  final Contest contest;
  final bool isCompleted;
  final Function(String contestId) onToggleComplete;
  final Function(String contestId) onHide;
  final Function(Contest contest) onViewDetails;

  const InteractiveDailyChecklistItem({
    Key? key,
    required this.contest,
    required this.isCompleted,
    required this.onToggleComplete,
    required this.onHide,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTextStyles.bodyMedium.copyWith(
      color: isCompleted ? AppColors.textMuted : AppColors.textWhite,
      decoration: isCompleted ? TextDecoration.lineThrough : null,
    );
    final subtitleStyle = AppTextStyles.bodySmall.copyWith(
      color: isCompleted ? AppColors.textMuted.withOpacity(0.7) : AppColors.textLight,
      decoration: isCompleted ? TextDecoration.lineThrough : null,
    );

    return Card(
      color: AppColors.primaryMedium,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => onViewDetails(contest),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Checkbox(
                value: isCompleted,
                onChanged: (bool? value) => onToggleComplete(contest.id),
                activeColor: AppColors.accent,
                checkColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.accent), // Added const
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6.0),
                child: CachedNetworkImage(
                  imageUrl: contest.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: AppColors.primaryLight, width: 50, height: 50),
                  errorWidget: (context, url, error) => Container(color: AppColors.primaryLight, width: 50, height: 50, child: const Icon(Icons.image_not_supported, color: AppColors.textMuted)), // Added const
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contest.title, style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(contest.prize, style: subtitleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.visibility_off_outlined, color: AppColors.textMuted.withOpacity(0.7), size: 20),
                tooltip: 'Hide for today',
                onPressed: () => onHide(contest.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
