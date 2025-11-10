import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../profile/widgets/profile_picture_avatar.dart';

final leaderboardSearchQueryProvider = StateProvider<String>((ref) => '');
final sentFriendRequestsProvider = StateProvider<Set<String>>((ref) => {});

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
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
        appBar: AppBar(
          title: const Text('Leaderboard'),
          backgroundColor: AppColors.primaryMedium,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Global'),
              Tab(text: 'Friends'),
            ],
            indicatorColor: AppColors.accent,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textLight,
          ),
        ),
        backgroundColor: AppColors.primaryDark,
        body: TabBarView(
          controller: _tabController,
          children: const [
            _GlobalLeaderboardView(),
            _FriendsLeaderboardView(),
          ],
        ),
      );
}

class _GlobalLeaderboardView extends ConsumerWidget {
  const _GlobalLeaderboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final searchQuery = ref.watch(leaderboardSearchQueryProvider);

    return leaderboard.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Failed to load leaderboard: $error',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      data: (users) {
        final filteredUsers = users.where((user) {
          final name = user.name?.toLowerCase() ?? '';
          return name.contains(searchQuery.toLowerCase());
        }).toList();

        final currentUserRank =
            users.indexWhere((user) => user.id == currentUserId);

        return Column(
          children: [
            _buildSearchBar(ref),
            _buildRewardBanner(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  final rank = users.indexOf(user) + 1; // Get original rank
                  final isCurrentUser = user.id == currentUserId;
                  final isInRewardZone = rank <= 15;

                  return _buildLeaderboardTile(
                    user: user,
                    rank: rank,
                    isCurrentUser: isCurrentUser,
                    isInRewardZone: isInRewardZone,
                  );
                },
              ),
            ),
            if (currentUserRank >= 15 && searchQuery.isEmpty)
              _buildCurrentUserRankFooter(
                users[currentUserRank],
                currentUserRank + 1,
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(WidgetRef ref) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          onChanged: (query) {
            ref.read(leaderboardSearchQueryProvider.notifier).state = query;
          },
          decoration: InputDecoration(
            hintText: 'Search for users...',
            hintStyle: const TextStyle(color: AppColors.textLight),
            prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
            filled: true,
            fillColor: AppColors.primaryMedium,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      );

  Widget _buildRewardBanner() => Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.primaryMedium,
        child: const Row(
          children: [
            Icon(Icons.emoji_events, color: AppColors.accent, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Top 15 players at the end of the month get a FREE Pro subscription!',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

  Widget _buildLeaderboardTile({
    required UserProfile user,
    required int rank,
    required bool isCurrentUser,
    required bool isInRewardZone,
  }) =>
      Consumer(
        builder: (context, ref, _) {
          final sentRequests = ref.watch(sentFriendRequestsProvider);
          final hasSentRequest = sentRequests.contains(user.id);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isInRewardZone
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : (isCurrentUser
                      ? AppColors.primaryLight.withValues(alpha: 0.5)
                      : AppColors.primaryMedium),
              borderRadius: BorderRadius.circular(12),
              border:
                  isInRewardZone ? Border.all(color: AppColors.accent) : null,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildRankIndicator(rank, isInRewardZone),
                      const SizedBox(width: 8),
                      ProfilePictureAvatar(user: user, radius: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name ?? 'Anonymous User',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Level ${user.level}',
                            style: const TextStyle(color: AppColors.textLight),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '${user.points} pts',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                          fontSize: 16,
                        ),
                      ),
                      if (!isCurrentUser) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            hasSentRequest
                                ? Icons.check
                                : Icons.person_add_alt_1,
                            color: hasSentRequest
                                ? Colors.green
                                : AppColors.textLight,
                          ),
                          onPressed: hasSentRequest
                              ? null
                              : () async {
                                  final result = await ref
                                      .read(friendServiceProvider)
                                      .sendFriendRequest(user.id);
                                  ref
                                      .read(sentFriendRequestsProvider.notifier)
                                      .update((state) => {...state, user.id});

                                  if (result == 'success' && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Friend request sent!'),
                                          ],
                                        ),
                                        backgroundColor: AppColors.successGreen,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.location_on_outlined,
                        user.location ?? 'N/A',
                      ),
                      _buildStatItem(
                        Icons.confirmation_number_outlined,
                        '${user.monthlyEntries}',
                      ),
                      _buildStatItem(
                          Icons.emoji_events_outlined, '${user.wins}'),
                      _buildStatItem(
                        Icons.local_fire_department_outlined,
                        '${user.streak}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(
                  duration: 300.ms, delay: (100 * (rank < 10 ? rank : 10)).ms)
              .slideX(begin: 0.2);
        },
      );

  Widget _buildStatItem(IconData icon, String value) => Row(
        children: [
          Icon(icon, color: AppColors.textLight, size: 16),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );

  Widget _buildRankIndicator(int rank, bool isInRewardZone) {
    if (isInRewardZone) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            rank == 1
                ? Icons.emoji_events
                : (rank <= 3 ? Icons.military_tech : Icons.star),
            color: AppColors.accent,
            size: 20,
          ),
          Text(
            '$rank',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ],
      );
    }
    return Text(
      '$rank',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textLight,
      ),
    );
  }

  Widget _buildCurrentUserRankFooter(UserProfile user, int rank) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.primaryMedium,
          border: Border(top: BorderSide(color: AppColors.primaryLight)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '$rank',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ProfilePictureAvatar(user: user, radius: 20),
                  const SizedBox(width: 12),
                  Text(
                    user.name ?? 'You',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '${user.points} pts',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
}

class _FriendsLeaderboardView extends ConsumerWidget {
  const _FriendsLeaderboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsLeaderboard = ref.watch(friendsLeaderboardProvider);
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;

    return friendsLeaderboard.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Failed to load friends leaderboard: $error',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      data: (users) {
        if (users.length <= 1) {
          return const Center(
            child: Text(
              'Add some friends to see your personal leaderboard!',
              style: TextStyle(color: AppColors.textLight),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final rank = index + 1;
            final isCurrentUser = user.id == currentUserId;

            return _buildLeaderboardTile(
              user: user,
              rank: rank,
              isCurrentUser: isCurrentUser,
              isInRewardZone: false, // No reward zone for friends leaderboard
            );
          },
        );
      },
    );
  }

  Widget _buildLeaderboardTile({
    required UserProfile user,
    required int rank,
    required bool isCurrentUser,
    required bool isInRewardZone,
  }) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? AppColors.primaryLight.withValues(alpha: 0.5)
              : AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Row(
            children: [
              Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(width: 12),
              ProfilePictureAvatar(user: user, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name ?? 'Anonymous User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Level ${user.level}',
                      style: const TextStyle(color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              Text(
                '${user.points} pts',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
}
