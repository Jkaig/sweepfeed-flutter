import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import 'submit_win_screen.dart';

final winnersProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) => FirebaseFirestore.instance
      .collection('winners')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'userName': data['userName'] ?? 'Anonymous',
            'prizeName': data['prizeName'] ?? 'Prize',
            'prizeValue': (data['prizeValue'] as num?)?.toDouble() ?? 0.0,
            'contestTitle': data['contestTitle'] ?? 'Contest',
            'timestamp': data['timestamp'] as Timestamp?,
            'userAvatar': data['userAvatar'] as String?,
          };
        }).toList(),
      ),
);

final recentWinnersProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) => FirebaseFirestore.instance
      .collection('winners')
      .where('timestamp',
          isGreaterThan: DateTime.now().subtract(const Duration(days: 7)),)
      .orderBy('timestamp', descending: true)
      .limit(10)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'userName': data['userName'] ?? 'Anonymous',
            'prizeName': data['prizeName'] ?? 'Prize',
            'prizeValue': (data['prizeValue'] as num?)?.toDouble() ?? 0.0,
            'timestamp': data['timestamp'] as Timestamp?,
          };
        }).toList(),
      ),
);

class WinnersScreen extends ConsumerStatefulWidget {
  const WinnersScreen({super.key});

  @override
  ConsumerState<WinnersScreen> createState() => _WinnersScreenState();
}

class _WinnersScreenState extends ConsumerState<WinnersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text(
          'Winners Hall of Fame',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.primaryMedium,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Recent Winners'),
            Tab(text: 'All Winners'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SubmitWinScreen(),
            ),
          );
        },
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.emoji_events),
        label: const Text(
          'Submit Win',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecentWinnersTab(),
          _buildAllWinnersTab(),
        ],
      ),
    );

  Widget _buildRecentWinnersTab() {
    final winnersAsync = ref.watch(recentWinnersProvider);

    return winnersAsync.when(
      data: (winners) {
        if (winners.isEmpty) {
          return _buildEmptyState(
              'No recent winners', 'Check back soon for new winners!',);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: winners.length,
          itemBuilder: (context, index) =>
              _buildWinnerCard(winners[index], index),
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => _buildErrorState('Failed to load winners'),
    );
  }

  Widget _buildAllWinnersTab() {
    final winnersAsync = ref.watch(winnersProvider);

    return winnersAsync.when(
      data: (winners) {
        if (winners.isEmpty) {
          return _buildEmptyState(
              'No winners yet', 'Be the first to win a prize!',);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: winners.length,
          itemBuilder: (context, index) =>
              _buildWinnerCard(winners[index], index),
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => _buildErrorState('Failed to load winners'),
    );
  }

  Widget _buildWinnerCard(Map<String, dynamic> winner, int index) {
    final timestamp = winner['timestamp'] as Timestamp?;
    final date = timestamp?.toDate() ?? DateTime.now();
    final userName = winner['userName'] as String;
    final prizeName = winner['prizeName'] as String;
    final prizeValue = winner['prizeValue'] as double;
    final contestTitle = winner['contestTitle'] as String?;

    final isTopWinner = index < 3;
    final trophyColor = index == 0
        ? const Color(0xFFFFD700)
        : index == 1
            ? const Color(0xFFC0C0C0)
            : const Color(0xFFCD7F32);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium,
        borderRadius: BorderRadius.circular(16),
        border: isTopWinner
            ? Border.all(color: trophyColor.withValues(alpha: 0.5), width: 2)
            : Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
        boxShadow: isTopWinner
            ? [
                BoxShadow(
                  color: trophyColor.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isTopWinner
                    ? [
                        trophyColor.withValues(alpha: 0.3),
                        trophyColor.withValues(alpha: 0.1),
                      ]
                    : [
                        AppColors.accent.withValues(alpha: 0.3),
                        AppColors.accent.withValues(alpha: 0.1),
                      ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isTopWinner ? Icons.emoji_events : Icons.celebration,
                color: isTopWinner ? trophyColor : AppColors.accent,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isTopWinner)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4,),
                        decoration: BoxDecoration(
                          color: trophyColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          index == 0
                              ? '1st'
                              : index == 1
                                  ? '2nd'
                                  : '3rd',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: trophyColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  prizeName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (prizeValue > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Value: \$${prizeValue.toStringAsFixed(2)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (contestTitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    contestTitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: AppColors.textMuted,),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, y').format(date),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primaryMedium,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                size: 80,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.search),
              label: const Text('Browse Contests'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildErrorState(String message) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 80, color: AppColors.errorRed,),
            const SizedBox(height: 24),
            Text(
              message,
              style:
                  AppTextStyles.titleMedium.copyWith(color: AppColors.errorRed),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(winnersProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            ),
          ],
        ),
      ),
    );
}
