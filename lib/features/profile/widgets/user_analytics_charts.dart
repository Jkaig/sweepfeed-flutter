import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';

/// Provider for user interaction analytics
final userInteractionAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final firestore = FirebaseFirestore.instance;
  
  // Fetch all user data in parallel
  final futures = await Future.wait([
    // User document
    firestore.collection('users').doc(userId).get(),
    // Comments count
    firestore
        .collection('comments')
        .where('userId', isEqualTo: userId)
        .count()
        .get(),
    // Saved contests count
    firestore
        .collection('users')
        .doc(userId)
        .collection('savedContests')
        .count()
        .get(),
    // Entered contests count
    firestore
        .collection('users')
        .doc(userId)
        .collection('enteredContests')
        .count()
        .get(),
    // Donations
    firestore
        .collection('users')
        .doc(userId)
        .collection('donations')
        .get(),
  ]);

  final userDoc = futures[0] as DocumentSnapshot;
  final commentsCount = (futures[1] as AggregateQuerySnapshot).count ?? 0;
  final savedCount = (futures[2] as AggregateQuerySnapshot).count ?? 0;
  final enteredCount = (futures[3] as AggregateQuerySnapshot).count ?? 0;
  final donationsSnapshot = futures[4] as QuerySnapshot;

  final userData = userDoc.data() as Map<String, dynamic>? ?? {};
  
  // Calculate total charity contributions
  var totalCharityContributed = 0.0;
  final charityBreakdown = <String, double>{};
  
  for (final doc in donationsSnapshot.docs) {
    final data = doc.data()! as Map<String, dynamic>;
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final nonprofit = data['nonprofitSlug'] as String? ?? 'Unknown';
    totalCharityContributed += amount;
    charityBreakdown[nonprofit] = (charityBreakdown[nonprofit] ?? 0.0) + amount;
  }

  return {
    'totalEntries': userData['totalEntries'] ?? 0,
    'totalWins': userData['totalWins'] ?? 0,
    'comments': commentsCount,
    'savedContests': savedCount,
    'enteredContests': enteredCount,
    'totalCharityContributed': totalCharityContributed,
    'totalAdsWatched': userData['totalAdsWatched'] ?? 0,
    'charityBreakdown': charityBreakdown,
    'points': userData['points'] ?? 0,
    'streak': userData['streak'] ?? 0,
  };
});

/// Beautiful analytics widget with pie charts for public profiles
class UserAnalyticsCharts extends ConsumerWidget {
  const UserAnalyticsCharts({
    required this.userId,
    super.key,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(userInteractionAnalyticsProvider(userId));

    return analyticsAsync.when(
      data: (data) => _buildAnalyticsContent(context, data),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: LoadingIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Unable to load analytics',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(
    BuildContext context,
    Map<String, dynamic> data,
  ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Activity Breakdown',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Interaction Breakdown Pie Chart
        _buildInteractionPieChart(data),
        const SizedBox(height: 32),
        
        // Charity Contributions Pie Chart
        if ((data['totalCharityContributed'] as num) > 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Charity Impact',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCharityPieChart(data),
        ],
      ],
    );

  Widget _buildInteractionPieChart(Map<String, dynamic> data) {
    final totalEntries = data['totalEntries'] as int;
    final totalWins = data['totalWins'] as int;
    final comments = data['comments'] as int;
    final savedContests = data['savedContests'] as int;
    final enteredContests = data['enteredContests'] as int;

    // Calculate total interactions
    final totalInteractions = totalEntries +
        totalWins +
        comments +
        savedContests +
        enteredContests;

    if (totalInteractions == 0) {
      return _buildEmptyState('No activity data yet');
    }

    // Prepare pie chart data
    final pieData = <PieChartSectionData>[];
    const touchedIndex = -1;

    // Define colors for each interaction type
    final colors = [
      AppColors.brandCyan, // Entries
      AppColors.successGreen, // Wins
      AppColors.electricBlue, // Comments
      AppColors.accentGlow, // Saved
      AppColors.mangoTangoStart, // Entered
    ];

    final labels = [
      'Entries',
      'Wins',
      'Comments',
      'Saved',
      'Entered',
    ];

    final values = [
      totalEntries,
      totalWins,
      comments,
      savedContests,
      enteredContests,
    ];

    // Filter out zero values for cleaner chart
    final nonZeroData = <MapEntry<int, int>>[];
    for (var i = 0; i < values.length; i++) {
      if (values[i] > 0) {
        nonZeroData.add(MapEntry(i, values[i]));
      }
    }

    // Build pie chart sections
    for (final entry in nonZeroData) {
      final i = entry.key;
      final value = entry.value;
      final percentage = (value / totalInteractions) * 100;

      pieData.add(
        PieChartSectionData(
          value: value.toDouble(),
          title: percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          color: colors[i],
          radius: touchedIndex == i ? 110 : 100,
          titleStyle: AppTextStyles.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          badgeWidget: percentage < 5
              ? _buildBadge(labels[i], value, colors[i])
              : null,
          badgePositionPercentageOffset: 1.3,
        ),
      );
    }

    return Container(
      height: 320,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryMedium,
            AppColors.primaryMedium.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.brandCyan.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandCyan.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pie Chart
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: pieData,
                pieTouchData: PieTouchData(
                  touchCallback: (event, pieTouchResponse) {
                    // Handle touch for interactivity
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Legend
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Interactions Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Interactions',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalInteractions.toString(),
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.brandCyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Legend Items
                ...nonZeroData.map((entry) {
                  final index = entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildLegendItem(
                      labels[index],
                      values[index],
                      colors[index],
                      totalInteractions,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharityPieChart(Map<String, dynamic> data) {
    final charityBreakdown = data['charityBreakdown'] as Map<String, double>;
    final totalContributed = data['totalCharityContributed'] as double;

    if (charityBreakdown.isEmpty || totalContributed == 0) {
      return _buildEmptyState('No charity contributions yet');
    }

    // Sort charities by contribution amount
    final sortedCharities = charityBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Prepare pie chart data
    final pieData = <PieChartSectionData>[];
    final charityColors = [
      AppColors.successGreen,
      AppColors.brandCyan,
      AppColors.electricBlue,
      AppColors.accentGlow,
      AppColors.mangoTangoStart,
    ];

    for (var i = 0; i < sortedCharities.length && i < 5; i++) {
      final entry = sortedCharities[i];
      final percentage = (entry.value / totalContributed) * 100;
      final charityName = _formatCharityName(entry.key);

      pieData.add(
        PieChartSectionData(
          value: entry.value,
          title: '\$${entry.value.toStringAsFixed(2)}',
          color: charityColors[i % charityColors.length],
          radius: 100,
          titleStyle: AppTextStyles.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          badgeWidget: _buildCharityBadge(charityName, percentage),
          badgePositionPercentageOffset: 1.3,
        ),
      );
    }

    return Container(
      height: 320,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.successGreen.withValues(alpha: 0.15),
            AppColors.primaryMedium,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.successGreen.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pie Chart
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: pieData,
                pieTouchData: PieTouchData(
                  touchCallback: (event, pieTouchResponse) {
                    // Handle touch for interactivity
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Legend
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Contribution Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Contributed',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${totalContributed.toStringAsFixed(2)}',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Charity Breakdown
                ...List.generate(
                  sortedCharities.length > 5 ? 5 : sortedCharities.length,
                  (index) {
                    final entry = sortedCharities[index];
                    final percentage = (entry.value / totalContributed) * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildCharityLegendItem(
                        _formatCharityName(entry.key),
                        entry.value,
                        charityColors[index % charityColors.length],
                        percentage,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    String label,
    int value,
    Color color,
    int total,
  ) {
    final percentage = (value / total) * 100;
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$value (${percentage.toStringAsFixed(1)}%)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCharityLegendItem(
    String charityName,
    double amount,
    Color color,
    double percentage,
  ) => Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                charityName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '\$${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );

  Widget _buildBadge(String label, int value, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );

  Widget _buildCharityBadge(String charityName, double percentage) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successGreen,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.successGreen.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );

  Widget _buildEmptyState(String message) => Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );

  String _formatCharityName(String slug) {
    if (slug == 'Unknown') return 'Unknown Charity';
    return slug
        .split('-')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1),)
        .join(' ');
  }
}

