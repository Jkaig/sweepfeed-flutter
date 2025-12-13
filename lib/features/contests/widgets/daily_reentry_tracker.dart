import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/contest.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

final dailyReentryContestsProvider = StreamProvider<List<Contest>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('dailyReentries')
      .snapshots()
      .asyncMap((snapshot) async {
    if (snapshot.docs.isEmpty) return [];

    final contestIds = snapshot.docs.map((doc) => doc.id).toList();

    final contestsSnapshot = await FirebaseFirestore.instance
        .collection('contests')
        .where(FieldPath.documentId, whereIn: contestIds.take(10).toList())
        .get();

    return contestsSnapshot.docs
        .map((doc) => Contest.fromMap(doc.data(), doc.id))
        .toList();
  });
});

final dailyReentryStatusProvider =
    StreamProvider.family<bool, String>((ref, contestId) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(false);

  final today = DateTime.now();
  final todayStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('dailyReentries')
      .doc(contestId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return false;
    final lastEntry = doc.data()?['lastEntryDate'] as String?;
    return lastEntry == todayStr;
  });
});

class DailyReentryTracker extends ConsumerWidget {
  const DailyReentryTracker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestsAsync = ref.watch(dailyReentryContestsProvider);

    return contestsAsync.when(
      data: (contests) {
        if (contests.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Re-Entries',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${contests.where((c) => _isCompletedToday(ref, c.id)).length}/${contests.length}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.brandCyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: contests.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _DailyReentryCard(contest: contests[index]),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  bool _isCompletedToday(WidgetRef ref, String contestId) {
    final status = ref.watch(dailyReentryStatusProvider(contestId));
    return status.value ?? false;
  }

  Widget _buildEmptyState() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
                color: AppColors.brandCyan, size: 20,),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Save daily contests to track your re-entries here',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      );
}

class _DailyReentryCard extends ConsumerWidget {
  const _DailyReentryCard({required this.contest});
  final Contest contest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(dailyReentryStatusProvider(contest.id));

    return statusAsync.when(
      data: (isCompleted) => GestureDetector(
        onTap: () => _markAsReentered(context, ref),
        child: Container(
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted
                  ? AppColors.brandCyan
                  : AppColors.primary.withValues(alpha: 0.5),
              width: 2,
            ),
            gradient: LinearGradient(
              colors: isCompleted
                  ? [
                      AppColors.brandCyan.withValues(alpha: 0.3),
                      AppColors.primary.withValues(alpha: 0.3),
                    ]
                  : [AppColors.primaryMedium, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: contest.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (_, __) => _buildLoading(),
                  errorWidget: (_, __, ___) => _buildFallback(),
                ),
              ),
              if (isCompleted)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.brandCyan.withValues(alpha: 0.5),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      loading: _buildLoading,
      error: (_, __) => _buildFallback(),
    );
  }

  Widget _buildFallback() => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.card_giftcard, color: Colors.white, size: 32),
        ),
      );

  Widget _buildLoading() => Container(
        width: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primaryMedium,
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  Future<void> _markAsReentered(BuildContext context, WidgetRef ref) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('dailyReentries')
          .doc(contest.id)
          .set(
        {
          'lastEntryDate': todayStr,
          'contestTitle': contest.title,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as re-entered! 🎉'),
            backgroundColor: AppColors.brandCyan,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
