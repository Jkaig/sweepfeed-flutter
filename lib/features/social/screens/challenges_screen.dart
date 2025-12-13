import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enhanced_challenge.dart';
import '../providers/enhanced_challenge_provider.dart';
import '../widgets/challenge_card.dart';
import '../widgets/challenge_category_filter.dart';
import '../widgets/challenge_stats_header.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  ChallengeCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Fetch challenges on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(enhancedChallengesProvider.notifier)
          .fetchChallenges('current_user');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challengeStats = ref.watch(challengeStatsProvider);
    final unclaimedCount = challengeStats['unclaimed'] ?? 0;

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
          'Challenges',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Unclaimed rewards indicator
          if (unclaimedCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.redeem,
                      color: Color(0xFFFFD700),
                      size: 24,
                    ),
                    onPressed: () =>
                        _tabController.animateTo(1), // Go to rewards tab
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF44336),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unclaimedCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(160),
          child: Column(
            children: [
              // Stats header
              ChallengeStatsHeader(stats: challengeStats),

              const SizedBox(height: 16),

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
                    const Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.whatshot, size: 16),
                          SizedBox(width: 4),
                          Text('Active'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.redeem, size: 16),
                          const SizedBox(width: 4),
                          const Text('Rewards'),
                          if (unclaimedCount > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF44336),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$unclaimedCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, size: 16),
                          SizedBox(width: 4),
                          Text('Special'),
                        ],
                      ),
                    ),
                    const Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 16),
                          SizedBox(width: 4),
                          Text('Archive'),
                        ],
                      ),
                    ),
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
          _buildActiveTab(),
          _buildRewardsTab(),
          _buildSpecialTab(),
          _buildArchiveTab(),
        ],
      ),
    );
  }

  Widget _buildActiveTab() => RefreshIndicator(
        onRefresh: () async {
          ref.read(enhancedChallengesProvider.notifier).refresh();
        },
        color: const Color(0xFF00E5FF),
        backgroundColor: const Color(0xFF1A2332),
        child: Consumer(
          builder: (context, ref, child) {
            final challengesAsync = ref.watch(enhancedChallengesProvider);

            return challengesAsync.when(
              data: (challenges) {
                final activeChallenges = challenges
                    .where((c) => !c.isExpired && !c.isCompleted)
                    .toList();

                if (activeChallenges.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.assignment,
                    title: 'No Active Challenges',
                    subtitle: 'New challenges will appear here soon!',
                  );
                }

                return Column(
                  children: [
                    // Category filter
                    ChallengeCategoryFilter(
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() => _selectedCategory = category);
                      },
                    ),

                    // Challenges list
                    Expanded(
                      child: _buildChallengesList(
                        _filterChallenges(activeChallenges),
                        'No challenges in this category',
                      ),
                    ),
                  ],
                );
              },
              loading: _buildLoadingState,
              error: (error, stack) =>
                  _buildErrorState('Failed to load challenges', () {
                ref.read(enhancedChallengesProvider.notifier).refresh();
              }),
            );
          },
        ),
      );

  Widget _buildRewardsTab() => Consumer(
        builder: (context, ref, child) {
          final challengesAsync = ref.watch(enhancedChallengesProvider);

          return challengesAsync.when(
            data: (challenges) {
              final unclaimedChallenges =
                  challenges.where((c) => c.canClaim).toList();

              if (unclaimedChallenges.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.redeem,
                  title: 'No Rewards to Claim',
                  subtitle: 'Complete challenges to earn rewards!',
                );
              }

              return _buildChallengesList(unclaimedChallenges, null);
            },
            loading: _buildLoadingState,
            error: (error, stack) =>
                _buildErrorState('Failed to load rewards', () {
              ref.read(enhancedChallengesProvider.notifier).refresh();
            }),
          );
        },
      );

  Widget _buildSpecialTab() => Consumer(
        builder: (context, ref, child) {
          final specialChallenges = ref.watch(specialChallengesProvider);

          if (specialChallenges.isEmpty) {
            return _buildEmptyState(
              icon: Icons.star,
              title: 'No Special Challenges',
              subtitle:
                  'Limited-time challenges will appear here during special events!',
            );
          }

          return _buildChallengesList(specialChallenges, null);
        },
      );

  Widget _buildArchiveTab() => Consumer(
        builder: (context, ref, child) {
          final challengesAsync = ref.watch(enhancedChallengesProvider);

          return challengesAsync.when(
            data: (challenges) {
              final completedChallenges =
                  challenges.where((c) => c.isClaimed || c.isExpired).toList();

              if (completedChallenges.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.history,
                  title: 'No Completed Challenges',
                  subtitle: 'Your challenge history will appear here',
                );
              }

              return _buildChallengesList(completedChallenges, null);
            },
            loading: _buildLoadingState,
            error: (error, stack) =>
                _buildErrorState('Failed to load archive', () {
              ref.read(enhancedChallengesProvider.notifier).refresh();
            }),
          );
        },
      );

  Widget _buildChallengesList(
    List<EnhancedChallenge> challenges,
    String? emptyMessage,
  ) {
    if (challenges.isEmpty && emptyMessage != null) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ChallengeCard(
            challenge: challenge,
            onClaim:
                challenge.canClaim ? () => _claimReward(challenge.id) : null,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildLoadingState() => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
        ),
      );

  Widget _buildErrorState(String message, VoidCallback onRetry) => Center(
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
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: const Color(0xFF0A1929),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  List<EnhancedChallenge> _filterChallenges(
    List<EnhancedChallenge> challenges,
  ) {
    if (_selectedCategory == null) {
      return challenges;
    }
    return challenges.where((c) => c.category == _selectedCategory).toList();
  }

  Future<void> _claimReward(String challengeId) async {
    try {
      await ref
          .read(enhancedChallengesProvider.notifier)
          .claimReward(challengeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.celebration,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text('Reward claimed successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim reward: ${error.toString()}'),
            backgroundColor: const Color(0xFFF44336),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
