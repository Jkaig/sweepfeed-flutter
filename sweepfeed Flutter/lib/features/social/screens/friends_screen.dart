import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../providers/friends_provider.dart';
import '../widgets/friend_card.dart';
import '../widgets/friend_request_card.dart';
import '../widgets/user_search_card.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendsProvider.notifier).fetchFriends('current_user');
      ref
          .read(friendRequestsProvider.notifier)
          .fetchFriendRequests('current_user');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendCount = ref.watch(friendCountProvider);
    final pendingRequestsCount = ref.watch(pendingRequestsCountProvider);
    final onlineFriends = ref.watch(onlineFriendsProvider);

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
          'Friends',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Online friends indicator
          if (onlineFriends.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${onlineFriends.length}',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Stats row
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.groups,
                      label: 'Friends',
                      value: '$friendCount',
                      color: const Color(0xFF00E5FF),
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.notifications,
                      label: 'Requests',
                      value: '$pendingRequestsCount',
                      color: pendingRequestsCount > 0
                          ? const Color(0xFFFF9800)
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.radio_button_checked,
                      label: 'Online',
                      value: '${onlineFriends.length}',
                      color: const Color(0xFF4CAF50),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.groups, size: 18),
                          const SizedBox(width: 6),
                          const Text('Friends'),
                          if (friendCount > 0) ...[
                            const SizedBox(width: 4),
                            Text('($friendCount)'),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications, size: 18),
                          const SizedBox(width: 6),
                          const Text('Requests'),
                          if (pendingRequestsCount > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5722),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$pendingRequestsCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
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
                          Icon(Icons.search, size: 18),
                          SizedBox(width: 6),
                          Text('Find'),
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
          _buildFriendsTab(),
          _buildRequestsTab(),
          _buildSearchTab(),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );

  Widget _buildFriendsTab() => Consumer(
        builder: (context, ref, child) {
          final friendsAsync = ref.watch(friendsProvider);

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(friendsProvider.notifier).fetchFriends('current_user');
            },
            color: const Color(0xFF00E5FF),
            backgroundColor: const Color(0xFF1A2332),
            child: friendsAsync.when(
              data: (friends) => friends.isEmpty
                  ? _buildEmptyFriendsState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FriendCard(
                            friend: friend,
                            onRemove: () => _removeFriend(friend),
                            onViewProfile: () => _viewProfile(friend),
                          ),
                        );
                      },
                    ),
              loading: _buildLoadingState,
              error: (error, stack) =>
                  _buildErrorState('Failed to load friends', () {
                ref.read(friendsProvider.notifier).fetchFriends('current_user');
              }),
            ),
          );
        },
      );

  Widget _buildRequestsTab() => Consumer(
        builder: (context, ref, child) {
          final requestsAsync = ref.watch(friendRequestsProvider);

          return RefreshIndicator(
            onRefresh: () async {
              ref
                  .read(friendRequestsProvider.notifier)
                  .fetchFriendRequests('current_user');
            },
            color: const Color(0xFF00E5FF),
            backgroundColor: const Color(0xFF1A2332),
            child: requestsAsync.when(
              data: (requests) {
                final pendingRequests = requests
                    .where((req) => req.status == FriendRequestStatus.pending)
                    .toList();

                return pendingRequests.isEmpty
                    ? _buildEmptyRequestsState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: pendingRequests.length,
                        itemBuilder: (context, index) {
                          final request = pendingRequests[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FriendRequestCard(
                              request: request,
                              onAccept: () => _acceptRequest(request.id),
                              onReject: () => _rejectRequest(request.id),
                            ),
                          );
                        },
                      );
              },
              loading: _buildLoadingState,
              error: (error, stack) =>
                  _buildErrorState('Failed to load requests', () {
                ref
                    .read(friendRequestsProvider.notifier)
                    .fetchFriendRequests('current_user');
              }),
            ),
          );
        },
      );

  Widget _buildSearchTab() => Consumer(
        builder: (context, ref, child) {
          final searchAsync = ref.watch(userSearchProvider);

          return Column(
            children: [
              // Search bar
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search users by name or username...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    icon: const Icon(
                      Icons.search,
                      color: Color(0xFF00E5FF),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(userSearchProvider.notifier)
                                  .clearSearch();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {});
                    if (value.trim().isNotEmpty) {
                      ref.read(userSearchProvider.notifier).searchUsers(value);
                    } else {
                      ref.read(userSearchProvider.notifier).clearSearch();
                    }
                  },
                ),
              ),

              // Search results
              Expanded(
                child: searchAsync.when(
                  data: (users) {
                    if (_searchController.text.trim().isEmpty) {
                      return _buildSearchPromptState();
                    }

                    if (users.isEmpty) {
                      return _buildNoResultsState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: UserSearchCard(
                            user: user,
                            onSendRequest: () => _sendFriendRequest(user),
                            onViewProfile: () => _viewProfile(user),
                          ),
                        );
                      },
                    );
                  },
                  loading: _buildLoadingState,
                  error: (error, stack) =>
                      _buildErrorState('Search failed', () {
                    if (_searchController.text.trim().isNotEmpty) {
                      ref
                          .read(userSearchProvider.notifier)
                          .searchUsers(_searchController.text);
                    }
                  }),
                ),
              ),
            ],
          );
        },
      );

  Widget _buildEmptyFriendsState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No Friends Yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add friends to compete and share wins!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(2),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: const Color(0xFF0A1929),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.search),
              label: const Text('Find Friends'),
            ),
          ],
        ),
      );

  Widget _buildEmptyRequestsState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No Friend Requests',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All caught up! Check back later for new requests.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildSearchPromptState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'Find New Friends',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search for friends by username or display name',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildNoResultsState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No Users Found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
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

  void _removeFriend(UserProfile friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2332),
        title: const Text(
          'Remove Friend',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove ${friend.displayName} from your friends?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(friendsProvider.notifier)
                  .removeFriend('current_user', friend.uid);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Color(0xFFF44336)),
            ),
          ),
        ],
      ),
    );
  }

  void _acceptRequest(String requestId) {
    ref.read(friendRequestsProvider.notifier).acceptFriendRequest(requestId);
    // Also refresh friends list
    ref.read(friendsProvider.notifier).fetchFriends('current_user');
  }

  void _rejectRequest(String requestId) {
    ref.read(friendRequestsProvider.notifier).rejectFriendRequest(requestId);
  }

  void _sendFriendRequest(UserProfile user) {
    ref.read(friendRequestsProvider.notifier).sendFriendRequest(
          'current_user',
          user.uid,
          user.displayName,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Friend request sent to ${user.displayName}'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  void _viewProfile(UserProfile user) {
    // Navigate to user profile screen
    // TODO: Implement profile screen navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Viewing ${user.displayName}'s profile"),
        backgroundColor: const Color(0xFF00E5FF),
      ),
    );
  }
}
