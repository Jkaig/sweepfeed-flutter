import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import 'nonprofit_selection_screen.dart';

final userCharityStatsProvider =
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
      'selectedNonprofit': data['selectedNonprofit'] as String?,
      'selectedNonprofitName': data['selectedNonprofitName'] as String?,
      'selectedNonprofitDescription':
          data['selectedNonprofitDescription'] as String?,
      'selectedNonprofitLogo': data['selectedNonprofitLogo'] as String?,
      'selectedNonprofitEin': data['selectedNonprofitEin'] as String?,
      'selectedNonprofitIsVerified':
          data['selectedNonprofitIsVerified'] as bool?,
    };
  }),
);

final communityStatsProvider = StreamProvider<Map<String, dynamic>>(
  (ref) => FirebaseFirestore.instance
      .collection('stats')
      .doc('community')
      .snapshots()
      .map((doc) {
    if (!doc.exists) {
      return {
        'totalDonated': 0.0,
        'totalAdsWatched': 0,
        'donationCount': 0,
      };
    }
    final data = doc.data() ?? {};
    return {
      'totalDonated': (data['totalDonated'] as num?)?.toDouble() ?? 0.0,
      'totalAdsWatched': data['totalAdsWatched'] ?? 0,
      'donationCount': data['donationCount'] ?? 0,
    };
  }),
);

final userDonationsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
  (ref, userId) => FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('donations')
      .orderBy('timestamp', descending: true)
      .limit(20)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'nonprofitSlug': data['nonprofitSlug'] ?? '',
            'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
            'source': data['source'] ?? 'unknown',
            'timestamp': data['timestamp'] as Timestamp?,
          };
        }).toList(),
      ),
);

class CharityImpactScreen extends ConsumerWidget {
  const CharityImpactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(firebaseServiceProvider).currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: AppBar(
          title: const Text(
            'Charity Impact',
            style: TextStyle(color: AppColors.textWhite),
          ),
          backgroundColor: AppColors.primaryMedium,
          iconTheme: const IconThemeData(color: AppColors.textWhite),
        ),
        body: const Center(
          child: Text(
            'Please log in to view your charity impact',
            style: TextStyle(color: AppColors.textLight),
          ),
        ),
      );
    }

    final userStatsAsync = ref.watch(userCharityStatsProvider(currentUser.uid));
    final communityStatsAsync = ref.watch(communityStatsProvider);
    final donationsAsync = ref.watch(userDonationsProvider(currentUser.uid));

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text(
          'Your Charity Impact',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.primaryMedium,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.accent),
            tooltip: 'Change Nonprofit',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NonprofitSelectionScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCharityExplanationCard(),
            const SizedBox(height: 24),
            userStatsAsync.when(
              data: _buildYourImpactCard,
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) =>
                  _buildErrorCard('Failed to load your stats'),
            ),
            const SizedBox(height: 24),
            communityStatsAsync.when(
              data: _buildCommunityImpactCard,
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) =>
                  _buildErrorCard('Failed to load community stats'),
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Donations',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            donationsAsync.when(
              data: _buildDonationsList,
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) =>
                  _buildErrorCard('Failed to load donations'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharityExplanationCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.successGreen.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.successGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'How SweepFeed Gives Back',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '30% of ALL ad revenue goes directly to charity',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Every time you watch a rewarded ad, 30% of the revenue is donated to your selected Every.org verified nonprofit. You're making a real difference!",
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Ad Revenue Breakdown',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.successGreen,
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '30%\nCharity',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: Container(
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.electricBlue,
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '70% App Development & Prizes',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We estimate ~\$0.013 per ad view • 30% = ~\$0.004 to charity per ad',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildYourImpactCard(Map<String, dynamic> stats) {
    final totalDonated = stats['totalCharityContributed'] as double;
    final adsWatched = stats['totalAdsWatched'] as int;
    final nonprofit = stats['selectedNonprofit'] as String?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.electricBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                'Your Impact',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '\$${totalDonated.toStringAsFixed(2)}',
            style: AppTextStyles.displayMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total contributed to charity',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.play_circle_outline,
                  value: '$adsWatched',
                  label: 'Ads Watched',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.water_drop,
                  value: '${(totalDonated / 0.01).round()}',
                  label: 'Liters of Clean Water',
                ),
              ),
            ],
          ),
          if (nonprofit != null) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.volunteer_activism,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Supporting: ${stats['selectedNonprofitName'] ?? _formatNonprofitName(nonprofit)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (stats['selectedNonprofitIsVerified'] == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (stats['selectedNonprofitEin'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'EIN: ${stats['selectedNonprofitEin']} • 501(c)(3) Tax-Exempt',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      );

  Widget _buildCommunityImpactCard(Map<String, dynamic> stats) {
    final totalDonated = stats['totalDonated'] as double;
    final adsWatched = stats['totalAdsWatched'] as int;
    final donationCount = stats['donationCount'] as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups, color: AppColors.successGreen, size: 28),
              const SizedBox(width: 12),
              Text(
                'Community Impact',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$${totalDonated.toStringAsFixed(2)}',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.successGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total raised by SweepFeed users',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCommunityStatColumn(
                value: NumberFormat.compact().format(adsWatched),
                label: 'Ads Watched',
              ),
              Container(width: 1, height: 40, color: AppColors.primaryLight),
              _buildCommunityStatColumn(
                value: NumberFormat.compact().format(donationCount),
                label: 'Donations',
              ),
              Container(width: 1, height: 40, color: AppColors.primaryLight),
              _buildCommunityStatColumn(
                value: '${(totalDonated / 0.01).round()}L',
                label: 'Water Provided',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityStatColumn({
    required String value,
    required String label,
  }) =>
      Column(
        children: [
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _buildDonationsList(List<Map<String, dynamic>> donations) {
    if (donations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.volunteer_activism_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'No donations yet',
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Text(
                'Watch rewarded ads to start contributing!',
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
      children: donations.map((donation) {
        final timestamp = donation['timestamp'] as Timestamp?;
        final date = timestamp?.toDate() ?? DateTime.now();
        final nonprofit = donation['nonprofitSlug'] as String;
        final amount = donation['amount'] as double;
        final source = donation['source'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryMedium,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryLight.withAlpha(51)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: AppColors.successGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatNonprofitName(nonprofit),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatSource(source)} • ${DateFormat('MMM d, y').format(date)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.successGreen,
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

  String _formatNonprofitName(String slug) => slug
      .split('-')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');

  String _formatSource(String source) {
    switch (source) {
      case 'rewarded_ad':
        return 'Rewarded Ad';
      case 'direct_donation':
        return 'Direct Donation';
      default:
        return source;
    }
  }
}
