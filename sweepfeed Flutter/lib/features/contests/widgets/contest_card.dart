import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:sweep_feed/core/models/contest_model.dart';
import 'package:sweep_feed/core/theme/app_colors.dart';
import 'package:sweep_feed/core/theme/app_text_styles.dart';
import 'package:sweep_feed/features/contests/screens/contest_detail_screen.dart';
import 'package:sweep_feed/features/contests/widgets/contest_badge.dart';
import 'package:sweep_feed/features/contests/widgets/enter_button.dart';
import 'package:sweep_feed/features/contests/widgets/favorite_button.dart';
import 'package:sweep_feed/features/saved/services/saved_sweepstakes_service.dart';
import 'package:sweep_feed/core/models/contest_model.dart';
import 'package:sweep_feed/features/saved/services/saved_sweepstakes_service.dart';
import 'package:sweep_feed/features/contests/widgets/contest_badge.dart';
import 'package:sweep_feed/features/contests/widgets/favorite_button.dart';
import 'package:sweep_feed/features/contests/widgets/enter_button.dart';
import 'package:sweep_feed/features/contests/screens/contest_detail_screen.dart';

class ContestCard extends StatelessWidget {
  final Contest contest;
  
  const ContestCard({
    super.key,
    required this.contest,
  });

  @override
  Widget build(BuildContext context) {
    final savedSweepstakesService = Provider.of<SavedSweepstakesService>(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContestDetailScreen(contestId: contest.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryLight.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: contest.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 180,
                      color: AppColors.primaryLight,
                      child: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: AppColors.primaryLight,
                      child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 48),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.5, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      if (contest.isHot)
                        ContestBadge(
                          text: 'HOT',
                          backgroundColor: AppColors.errorRed,
                          textColor: AppColors.textWhite,
                          icon: Icons.local_fire_department,
                        ),
                      if (contest.isHot && contest.daysLeft < 7) const SizedBox(width: 8),
                      if (contest.daysLeft < 7 && contest.daysLeft > 0)
                        ContestBadge(
                          text: 'ENDS SOON',
                          backgroundColor: AppColors.warningOrange,
                          textColor: AppColors.primaryDark,
                          icon: Icons.timer_outlined,
                        ),
                       if (contest.daysLeft == 0 && contest.endDate.isAfter(DateTime.now()))
                         ContestBadge(
                           text: 'ENDS TODAY',
                           backgroundColor: AppColors.warningOrange,
                           textColor: AppColors.primaryDark,
                           icon: Icons.timer_outlined,
                         ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: FavoriteButton(
                    isFavorite: savedSweepstakesService.isSaved(contest.id),
                    onToggle: () {
                      savedSweepstakesService.toggleSaved(contest.id);
                    },
                    color: AppColors.textWhite,
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0,2),
                        )
                      ]
                    ),
                    child: Text(
                      (contest.prizeValue != null && contest.prizeValue! > 0)
                          ? '\$${contest.prizeValue!.toStringAsFixed(0)}'
                          : contest.prize.length > 15 ? contest.prize.substring(0,15) + "..." : contest.prize,
                      style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contest.title,
                    style: AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (contest.sponsor != null && contest.sponsor!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.business_outlined, size: 16, color: AppColors.textLight),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            contest.sponsor!,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ENTRY',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              contest.entryMethod ?? 'N/A',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      EnterButton(
                        onPressed: () {
                           Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ContestDetailScreen(contestId: contest.id),
                              ),
                            );
                        },
                        enabled: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

