import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';

final userImpactStatsProvider =
    StreamProvider.family<Map<String, dynamic>, String>(
  (ref, userId) => FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) {
    final data = doc.data() ?? {};
    return {
      'totalCharityContributed':
          (data['totalCharityContributed'] as num?)?.toDouble() ?? 0.0,
      'totalAdsWatched': data['totalAdsWatched'] ?? 0,
      'contestsEntered': data['contestsEntered'] ?? 0,
      'points': data['points'] ?? 0,
      'streak': data['streak'] ?? 0,
      'level': data['level'] ?? 1,
      'selectedNonprofitName': data['selectedNonprofitName'] as String?,
    };
  }),
);

final userRecentActivityProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) => FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('pointsTransactions')
      .orderBy('timestamp', descending: true)
      .limit(10)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'amount': data['amount'] ?? 0,
            'reason': data['reason'] ?? 'Unknown',
            'timestamp': data['timestamp'] as Timestamp?,
          };
        }).toList(),
      ),
);

class MyImpactScreen extends ConsumerWidget {
  const MyImpactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(firebaseServiceProvider).currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: AppBar(
          title: const Text('My Impact',
              style: TextStyle(color: AppColors.textWhite)),
          backgroundColor: AppColors.primaryMedium,
          iconTheme: const IconThemeData(color: AppColors.textWhite),
        ),
        body: const Center(
          child: Text(
            'Please log in to view your impact',
            style: TextStyle(color: AppColors.textLight),
          ),
        ),
      );
    }

    final impactStatsAsync =
        ref.watch(userImpactStatsProvider(currentUser.uid));
    final recentActivityAsync =
        ref.watch(userRecentActivityProvider(currentUser.uid));

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text(
          'My Impact',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.primaryMedium,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            impactStatsAsync.when(
              data: _buildImpactOverview,
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) =>
                  _buildErrorCard('Failed to load your stats'),
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Activity',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            recentActivityAsync.when(
              data: _buildActivityList,
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) =>
                  _buildErrorCard('Failed to load activity'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactOverview(Map<String, dynamic> stats) {
    final totalDonated = stats['totalCharityContributed'] as double;
    final adsWatched = stats['totalAdsWatched'] as int;
    final contestsEntered = stats['contestsEntered'] as int;
    final points = stats['points'] as int;
    final streak = stats['streak'] as int;
    final level = stats['level'] as int;
    final nonprofitName = stats['selectedNonprofitName'] as String?;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.brandCyan, AppColors.electricBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandCyan.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 60),
              const SizedBox(height: 16),
              Text(
                'Your Contributions',
                style: AppTextStyles.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${totalDonated.toStringAsFixed(2)}',
                style: AppTextStyles.displayLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total charity impact',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              if (nonprofitName != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.volunteer_activism,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Supporting: $nonprofitName',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.emoji_events,
                value: '$contestsEntered',
                label: 'Contests Entered',
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.play_circle_outline,
                value: '$adsWatched',
                label: 'Ads Watched',
                color: AppColors.successGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.stars,
                value: '$points',
                label: 'Total Points',
                color: AppColors.brandCyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department,
                value: '$streak',
                label: 'Day Streak',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryMedium,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.brandCyan.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.trending_up,
                  color: AppColors.brandCyan, size: 28),
              const SizedBox(width: 12),
              Text(
                'Level $level',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.history, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'No recent activity',
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Text(
                'Start entering contests to see your activity!',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: activities.map((activity) {
        final timestamp = activity['timestamp'] as Timestamp?;
        final date = timestamp?.toDate() ?? DateTime.now();
        final amount = activity['amount'] as int;
        final reason = activity['reason'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryMedium,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: amount > 0
                      ? AppColors.successGreen.withValues(alpha: 0.2)
                      : AppColors.errorRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  amount > 0 ? Icons.add : Icons.remove,
                  color:
                      amount > 0 ? AppColors.successGreen : AppColors.errorRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reason,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, y • h:mm a').format(date),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${amount > 0 ? '+' : ''}$amount',
                style: AppTextStyles.titleMedium.copyWith(
                  color:
                      amount > 0 ? AppColors.successGreen : AppColors.errorRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorCard(String message) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.errorRed),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.errorRed),
              ),
            ),
          ],
        ),
      );
}
