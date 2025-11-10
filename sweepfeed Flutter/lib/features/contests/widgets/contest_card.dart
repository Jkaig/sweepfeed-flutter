import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/models/contest_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/page_transitions.dart';
import '../screens/contest_detail_screen.dart';
import 'contest_badge.dart';
import 'contest_share_dialog.dart';
import 'countdown_timer.dart';
import 'enter_button.dart';
import 'favorite_button.dart';

class ContestCard extends ConsumerWidget {
  const ContestCard({
    required this.contest,
    super.key,
  });
  final Contest contest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedSweepstakesService = ref.watch(savedSweepstakesServiceProvider);
    final contestPreferencesService =
        ref.watch(contestPreferencesServiceProvider);
    final analyticsService = ref.watch(analyticsServiceProvider);
    final currentUser = ref.watch(firebaseServiceProvider).currentUser;
    final entryService = ref.watch(entryServiceProvider);

    final hasEnteredFuture = currentUser != null
        ? entryService.hasEntered(currentUser.uid, contest.id)
        : Future.value(false);

    return Slidable(
      key: ValueKey(contest.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              showContestShareDialog(context, contest);
            },
            backgroundColor: AppColors.electricBlue,
            foregroundColor: Colors.white,
            icon: Icons.share,
            label: 'Share',
          ),
        ],
      ),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) async {
              final result = await ref
                  .read(savedSweepstakesServiceProvider)
                  .toggleSaved(contest.id);

              analyticsService.logContestSaved(
                  contestId: contest.id, isSaved: result == 'saved');

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          result == 'saved'
                              ? 'Saved for later!'
                              : 'Removed from saved',
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.successGreen,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            backgroundColor: AppColors.electricBlue,
            foregroundColor: Colors.white,
            icon: contestPreferencesService.isSavedForLater(contest.id)
                ? Icons.bookmark
                : Icons.bookmark_border,
            label: contestPreferencesService.isSavedForLater(contest.id)
                ? 'Saved'
                : 'Save',
          ),
          SlidableAction(
            onPressed: (context) {
              ref.read(savedSweepstakesServiceProvider).toggleSaved(contest.id);
            },
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.primaryDark,
            icon: savedSweepstakesService.isSaved(contest.id)
                ? Icons.favorite
                : Icons.favorite_border,
            label: 'Favorite',
          ),
          SlidableAction(
            onPressed: (context) async {
              await ref
                  .read(contestPreferencesServiceProvider)
                  .hideContest(contest.id);

              analyticsService.logContestHidden(contestId: contest.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.visibility_off, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Contest hidden'),
                      ],
                    ),
                    backgroundColor: AppColors.errorRed,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: Colors.white,
                      onPressed: () {
                        ref
                            .read(contestPreferencesServiceProvider)
                            .unhideContest(contest.id);
                      },
                    ),
                  ),
                );
              }
            },
            backgroundColor: AppColors.errorRed,
            foregroundColor: Colors.white,
            icon: Icons.visibility_off,
            label: 'Hide',
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          analyticsService.logContestView(contestId: contest.id);
          Navigator.push(
            context,
            PageTransitions.sharedAxisTransition(
              page: ContestDetailScreen(contestId: contest.id),
            ),
          );
        },
        child: FutureBuilder<bool>(
          future: hasEnteredFuture,
          builder: (context, snapshot) {
            final hasEntered = snapshot.data ?? false;

            return Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: hasEntered
                        ? AppColors.primaryMedium.withValues(alpha: 0.6)
                        : AppColors.primaryMedium,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasEntered
                          ? AppColors.successGreen.withValues(alpha: 0.5)
                          : AppColors.primaryLight.withAlpha(128),
                      width: hasEntered ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: hasEntered
                            ? AppColors.successGreen.withAlpha(13)
                            : AppColors.accent.withAlpha(13),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Hero(
                            tag: 'contest-image-${contest.id}',
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: contest.imageUrl,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 180,
                                  color: AppColors.primaryLight,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 180,
                                  color: AppColors.primaryLight,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: AppColors.textMuted,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withAlpha(26),
                                    Colors.black.withAlpha(179),
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
                                ContestBadge(
                                  text: 'SUPPORTS CHARITY',
                                  backgroundColor: AppColors.successGreen
                                      .withValues(alpha: 0.9),
                                  textColor: AppColors.textWhite,
                                  icon: Icons.favorite,
                                ),
                                if (contest.isHot) ...[
                                  const SizedBox(width: 8),
                                  const ContestBadge(
                                    text: 'HOT',
                                    backgroundColor: AppColors.errorRed,
                                    textColor: AppColors.textWhite,
                                    icon: Icons.local_fire_department,
                                  ),
                                ],
                                if (contest.isHot && contest.daysLeft < 7)
                                  const SizedBox(width: 8),
                                if (contest.daysLeft < 7 &&
                                    contest.daysLeft > 0)
                                  const ContestBadge(
                                    text: 'ENDS SOON',
                                    backgroundColor: AppColors.warningOrange,
                                    textColor: AppColors.primaryDark,
                                    icon: Icons.timer_outlined,
                                  ),
                                if (contest.daysLeft == 0 &&
                                    contest.endDate.isAfter(DateTime.now()))
                                  const ContestBadge(
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
                              isFavorite:
                                  savedSweepstakesService.isSaved(contest.id),
                              onToggle: () {
                                ref
                                    .read(savedSweepstakesServiceProvider)
                                    .toggleSaved(contest.id);
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Hero(
                              tag: 'contest-prize-${contest.id}',
                              child: Material(
                                type: MaterialType.transparency,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(64),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    (contest.value != null &&
                                            contest.value! > 0)
                                        ? '\$${contest.value!.toStringAsFixed(0)}'
                                        : contest.prize.length > 15
                                            ? '${contest.prize.substring(0, 15)}...'
                                            : contest.prize,
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
                              style: AppTextStyles.titleLarge
                                  .copyWith(color: AppColors.textWhite),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.people_outline,
                                  size: 16,
                                  color: AppColors.textLight,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${contest.entryCount ?? 0} entries',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: AppColors.textLight),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: AppColors.textLight,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child:
                                      CountdownTimer(endDate: contest.endDate),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (contest.sponsor.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.business_outlined,
                                    size: 16,
                                    color: AppColors.textLight,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      contest.sponsor,
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(color: AppColors.textLight),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ENTRY',
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        contest.entryMethod ?? 'N/A',
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textWhite,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                EnterButton(
                                  text: hasEntered ? 'Entered' : 'Enter',
                                  onPressed: hasEntered
                                      ? null
                                      : () {
                                          HapticFeedback.lightImpact();
                                          Navigator.push(
                                            context,
                                            PageTransitions
                                                .sharedAxisTransition(
                                              page: ContestDetailScreen(
                                                contestId: contest.id,
                                              ),
                                            ),
                                          );
                                        },
                                  enabled: !hasEntered,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasEntered)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.successGreen.withAlpha(77),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ENTERED',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
