import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leaderboard_entry.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/leaderboard_entry_card.dart';
import '../widgets/leaderboard_header.dart';
import '../widgets/user_position_card.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userBracket = ref.watch(userBracketProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1929),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5FF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Leaderboards',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: Column(
            children: [
              // Bracket indicator
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(userBracket.color).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(userBracket.color),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.military_tech,
                      color: Color(userBracket.color),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${userBracket.name} League',
                      style: TextStyle(
                        color: Color(userBracket.color),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Levels ${userBracket.minLevel}-${userBracket.maxLevel}',
                      style: TextStyle(
                        color: Color(userBracket.color).withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF00E5FF),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFF0A1929),
                  unselectedLabelColor: const Color(0xFF00E5FF),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(text: LeaderboardType.daily.displayName),
                    Tab(text: LeaderboardType.weekly.displayName),
                    Tab(text: LeaderboardType.allTime.displayName),
                    Tab(text: LeaderboardType.friends.displayName),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardTab(LeaderboardType.daily),
          _buildLeaderboardTab(LeaderboardType.weekly),
          _buildLeaderboardTab(LeaderboardType.allTime),
          _buildLeaderboardTab(LeaderboardType.friends),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(LeaderboardType type) => RefreshIndicator(
        onRefresh: () async {
          ref.read(leaderboardProvider.notifier).refresh();
        },
        color: const Color(0xFF00E5FF),
        backgroundColor: const Color(0xFF1A2332),
        child: Consumer(
          builder: (context, ref, child) {
            final leaderboardAsync = _getLeaderboardProvider(type);
            final userPositionAsync =
                ref.watch(userLeaderboardPositionProvider);
            final metadataAsync = ref.watch(
              leaderboardMetadataProvider(
                (type, ref.watch(userBracketProvider)),
              ),
            );

            return leaderboardAsync.when(
              data: (entries) => _buildLeaderboardContent(
                entries,
                userPositionAsync,
                metadataAsync,
                type,
              ),
              loading: _buildLoadingState,
              error: (error, stack) => _buildErrorState(error, type),
            );
          },
        ),
      );

  AsyncValue<List<LeaderboardEntry>> _getLeaderboardProvider(
    LeaderboardType type,
  ) {
    switch (type) {
      case LeaderboardType.daily:
        return ref.watch(dailyLeaderboardProvider);
      case LeaderboardType.weekly:
        return ref.watch(weeklyLeaderboardProvider);
      case LeaderboardType.allTime:
        return ref.watch(allTimeLeaderboardProvider);
      case LeaderboardType.friends:
        return ref.watch(friendsLeaderboardProvider);
    }
  }

  Widget _buildLeaderboardContent(
    List<LeaderboardEntry> entries,
    AsyncValue<LeaderboardEntry?> userPositionAsync,
    AsyncValue<LeaderboardMetadata> metadataAsync,
    LeaderboardType type,
  ) =>
      CustomScrollView(
        slivers: [
          // Header with metadata
          SliverToBoxAdapter(
            child: metadataAsync.when(
              data: (metadata) => LeaderboardHeader(metadata: metadata),
              loading: () => const SizedBox(height: 20),
              error: (_, __) => const SizedBox(height: 20),
            ),
          ),

          // User position card (if not in top entries)
          SliverToBoxAdapter(
            child: userPositionAsync.when(
              data: (userPosition) {
                if (userPosition != null && userPosition.rank > 10) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: UserPositionCard(entry: userPosition),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Top 3 podium (special display)
          if (entries.length >= 3)
            SliverToBoxAdapter(
              child: _buildPodium(entries.take(3).toList()),
            ),

          // Remaining entries
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final adjustedIndex = index + 3; // Skip top 3
                  if (adjustedIndex >= entries.length) return null;

                  final entry = entries[adjustedIndex];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LeaderboardEntryCard(
                      entry: entry,
                      isCurrentUser: entry.userId ==
                          'current_user_id', // Replace with actual user ID
                    ),
                  );
                },
                childCount: entries.length > 3 ? entries.length - 3 : 0,
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      );

  Widget _buildPodium(List<LeaderboardEntry> topThree) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A2332),
              Color(0xFF0F1A26),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Top Performers',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd place
                if (topThree.length > 1) _buildPodiumPlace(topThree[1], 2, 80),
                // 1st place
                if (topThree.isNotEmpty) _buildPodiumPlace(topThree[0], 1, 100),
                // 3rd place
                if (topThree.length > 2) _buildPodiumPlace(topThree[2], 3, 60),
              ],
            ),
          ],
        ),
      );

  Widget _buildPodiumPlace(LeaderboardEntry entry, int place, double height) {
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];

    return Column(
      children: [
        // Avatar with crown
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors[place - 1],
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: entry.avatarUrl.isNotEmpty
                    ? Image.network(
                        entry.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.person, color: colors[place - 1]),
                      )
                    : Icon(Icons.person, color: colors[place - 1]),
              ),
            ),
            if (place == 1)
              const Icon(
                Icons.emoji_events,
                color: Color(0xFFFFD700),
                size: 20,
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Name
        Text(
          entry.displayName,
          style: TextStyle(
            color: colors[place - 1],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // Score
        Text(
          '${entry.score}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        // Podium
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: colors[place - 1].withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(
              color: colors[place - 1],
            ),
          ),
          child: Center(
            child: Text(
              '$place',
              style: TextStyle(
                color: colors[place - 1],
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading leaderboard...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );

  Widget _buildErrorState(Object error, LeaderboardType type) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFFF9800),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load ${type.displayName.toLowerCase()} leaderboard',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull down to retry',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(leaderboardProvider.notifier).refresh();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: const Color(0xFF0A1929),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}
