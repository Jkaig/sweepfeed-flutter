import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/contest_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/dust_bunnies_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/logger.dart';
import '../../challenges/models/daily_challenge_model.dart';
import '../../challenges/services/daily_challenge_service.dart';

class ContestShareDialog extends ConsumerStatefulWidget {
  const ContestShareDialog({
    required this.contest,
    super.key,
    this.didWin = false,
  });
  final Contest contest;
  final bool didWin;

  @override
  ConsumerState<ContestShareDialog> createState() => _ContestShareDialogState();
}

class _ContestShareDialogState extends ConsumerState<ContestShareDialog> {
  static const int sharePointsReward = 10;
  static const int maxSharesPerDay = 5;
  final DailyChallengeService _challengeService = DailyChallengeService();

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              widget.didWin ? Icons.emoji_events : Icons.share,
              color: widget.didWin ? AppColors.accent : AppColors.electricBlue,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.didWin ? 'Share Your Win! 🎉' : 'Share This Contest',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.didWin) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.electricBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.celebration,
                        color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Congratulations!',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You won ${widget.contest.prize}!',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              widget.didWin
                  ? 'Let your friends know about your amazing win!'
                  : 'Invite your friends to enter this contest!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              _shareContest(widget.contest, widget.didWin);
              Navigator.pop(context);

              final currentUser = ref.read(firebaseServiceProvider).currentUser;
              if (currentUser != null) {
                final awarded = await _awardSharePoints(currentUser.uid);

                if (awarded && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.stars, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                              'Shared! +$sharePointsReward SweepPoints earned'),
                        ],
                      ),
                      backgroundColor: AppColors.successGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Shared! (Daily share limit reached)'),
                        ],
                      ),
                      backgroundColor: AppColors.electricBlue,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );

  Future<bool> _awardSharePoints(String userId) async {
    try {
      final userDoc = await ref
          .read(firebaseServiceProvider)
          .firestore
          .collection('users')
          .doc(userId)
          .get();

      final data = userDoc.data();
      if (data == null) return false;

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final lastShareDate = data['lastShareDate'] as String?;
      final dailyShareCount = data['dailyShareCount'] as int? ?? 0;

      if (lastShareDate == todayStr && dailyShareCount >= maxSharesPerDay) {
        return false;
      }

      final updates = <String, dynamic>{
        'lastShareDate': todayStr,
      };

      if (lastShareDate == todayStr) {
        updates['dailyShareCount'] = dailyShareCount + 1;
      } else {
        updates['dailyShareCount'] = 1;
      }

      await ref
          .read(firebaseServiceProvider)
          .firestore
          .collection('users')
          .doc(userId)
          .update(updates);

      try {
        await DustBunniesService().awardDustBunnies(
          userId: userId,
          action: 'share_contest',
          customAmount: sharePointsReward,
        );
        logger.i('Awarded $sharePointsReward DustBunnies for sharing contest');
      } catch (e) {
        logger.e('Failed to award share DustBunnies', error: e);
      }

      // Update daily challenge progress for sharing contest
      try {
        await _challengeService.updateChallengeProgress(
          userId: userId,
          actionType: ChallengeType.shareContest,
        );
        logger.i('Updated daily challenge progress for contest share');
      } catch (e) {
        logger.e('Failed to update daily challenge progress for share',
            error: e);
      }

      return true;
    } catch (e) {
      print('Error awarding share points: $e');
      return false;
    }
  }

  void _shareContest(Contest contest, bool didWin) {
    final String message;

    if (didWin) {
      message = '🎉 I just won ${contest.prize} on SweepFeed! '
          'Check out "${contest.title}" and try your luck too!\n\n'
          'Download SweepFeed: https://sweepfeed.com';
    } else {
      message = '🎁 Check out this amazing contest on SweepFeed!\n\n'
          '"${contest.title}"\n'
          'Prize: ${contest.prize}\n\n'
          'Enter now: https://sweepfeed.com/contest/${contest.id}\n'
          'Download SweepFeed: https://sweepfeed.com';
    }

    Share.share(
      message,
      subject: didWin
          ? 'I won ${contest.prize} on SweepFeed!'
          : 'Amazing Contest on SweepFeed',
    );
  }
}

void showContestShareDialog(
  BuildContext context,
  Contest contest, {
  bool didWin = false,
}) {
  showDialog(
    context: context,
    builder: (context) => ContestShareDialog(
      contest: contest,
      didWin: didWin,
    ),
  );
}
