import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/contest.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/page_transitions.dart';
import '../../contests/screens/contest_detail_screen.dart';

/// Compact horizontal search result tile (72px height)
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    required this.contest,
    super.key,
  });

  final Contest contest;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          PageTransitions.sharedAxisTransition(
            page: ContestDetailScreen(contestId: contest.id),
          ),
        );
      },
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Prize thumbnail (60x60)
            _buildPrizeThumbnail(),
            const SizedBox(width: 12),
            // Middle content (title + sponsor)
            Expanded(child: _buildMiddleContent()),
            const SizedBox(width: 8),
            // Right content (time + value)
            _buildRightContent(),
          ],
        ),
      ),
    );

  Widget _buildPrizeThumbnail() => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: contest.imageUrl,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 60,
          height: 60,
          color: AppColors.primaryLight,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 60,
          height: 60,
          color: AppColors.primaryLight,
          child: const Icon(Icons.image_not_supported, size: 24),
        ),
      ),
    );

  Widget _buildMiddleContent() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title (1 line, ellipsis)
        Text(
          contest.title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Sponsor row with logo
        Row(
          children: [
            _buildSponsorLogo(),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                contest.sponsor,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );

  Widget _buildSponsorLogo() {
    if (contest.sponsorLogoUrl != null && contest.sponsorLogoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: contest.sponsorLogoUrl!,
          width: 18,
          height: 18,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildFallbackIcon(),
          errorWidget: (context, url, error) => _buildFallbackIcon(),
        ),
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() => Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.business,
        size: 12,
        color: AppColors.textMuted,
      ),
    );

  Widget _buildRightContent() {
    final daysLeft = contest.endDate.difference(DateTime.now()).inDays;
    final hoursLeft = contest.endDate.difference(DateTime.now()).inHours % 24;
    final isUrgent = daysLeft < 3;

    String timeText;
    if (daysLeft > 0) {
      timeText = '${daysLeft}d ${hoursLeft}h';
    } else if (hoursLeft > 0) {
      timeText = '${hoursLeft}h';
    } else {
      final minutesLeft = contest.endDate.difference(DateTime.now()).inMinutes;
      timeText = '${minutesLeft}m';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Time remaining
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isUrgent
                ? AppColors.warningOrange.withValues(alpha: 0.2)
                : AppColors.primaryLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 12,
                color: isUrgent ? AppColors.warningOrange : AppColors.textMuted,
              ),
              const SizedBox(width: 3),
              Text(
                timeText,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isUrgent ? AppColors.warningOrange : AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Prize value
        if (contest.prizeValue.isNotEmpty || contest.prizeValueAmount != null)
          Text(
            _formatPrizeValue(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.brandCyan,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  String _formatPrizeValue() {
    final value = contest.prizeValueAmount;
    if (value != null) {
      if (value >= 1000) {
        return '\$${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
      }
      return '\$${value.toStringAsFixed(0)}';
    }
    // Fallback to prizeValue string
    if (contest.prizeValue.isNotEmpty) {
      return contest.prizeValue;
    }
    return '';
  }
}
