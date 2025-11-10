import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';

/// Provider for managing friends list
class FriendsNotifier extends StateNotifier<AsyncValue<List<UserProfile>>> {
  FriendsNotifier() : super(const AsyncValue.loading());

  /// Fetch user's friends list
  Future<void> fetchFriends(String userId) async {
    try {
      state = const AsyncValue.loading();

      // In production, this would query Firestore
      await Future.delayed(const Duration(milliseconds: 600));

      final friends = _generateMockFriends();
      state = AsyncValue.data(friends);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Add a friend
  Future<void> addFriend(String userId, String friendId) async {
    try {
      // In production, update Firestore
      await Future.delayed(const Duration(milliseconds: 300));

      // Optimistically update state
      final currentFriends = state.valueOrNull ?? [];
      final newFriend = _createMockFriend(friendId);
      state = AsyncValue.data([...currentFriends, newFriend]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Remove a friend
  Future<void> removeFriend(String userId, String friendId) async {
    try {
      // In production, update Firestore
      await Future.delayed(const Duration(milliseconds: 300));

      // Optimistically update state
      final currentFriends = state.valueOrNull ?? [];
      final updatedFriends =
          currentFriends.where((friend) => friend.uid != friendId).toList();
      state = AsyncValue.data(updatedFriends);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Generate mock friends for development
  List<UserProfile> _generateMockFriends() {
    final mockFriends = [
      (
        'CyberSweeper_23',
        'Alex Chen',
        12,
        2450,
        5,
        true,
        'Contest strategist & crypto enthusiast 🎯'
      ),
      (
        'NeonHunter',
        'Sarah Kim',
        8,
        1890,
        3,
        false,
        'Daily challenger seeking the next big win! 🏆'
      ),
      (
        'QuantumLuck',
        'Mike Rodriguez',
        15,
        3200,
        12,
        true,
        'Lucky number 7 - contest veteran since 2020 ⭐'
      ),
      (
        'VoidWalker99',
        'Emma Thompson',
        6,
        1200,
        2,
        false,
        'New to sweeps but learning fast! 📚'
      ),
      (
        'ElectricDream',
        'Jordan Liu',
        20,
        4800,
        8,
        true,
        'Automation expert & prize winner extraordinaire 🤖'
      ),
      (
        'ShadowCaster',
        'Taylor Adams',
        9,
        2100,
        4,
        false,
        'Night owl sweeper, timezone advantage! 🌙'
      ),
    ];

    return mockFriends.map((friend) {
      final (username, displayName, level, dustBunnies, prizes, isOnline, bio) =
          friend;
      return UserProfile(
        uid: 'friend_${username.toLowerCase()}',
        displayName: displayName,
        avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=$username',
        level: level,
        dustBunnies: dustBunnies,
        totalContestsEntered: level * 8 + 12,
        challengesCompleted: level * 3 + 5,
        totalPrizesWon: prizes,
        sweepCoins: level * 50 + 100,
        currentStreak: level > 10 ? 7 : 3,
        longestStreak: level * 2 + 5,
        badges: _generateBadges(level, prizes),
        joinedDate: DateTime.now().subtract(Duration(days: level * 30 + 60)),
        lastActiveDate: isOnline
            ? DateTime.now().subtract(const Duration(minutes: 5))
            : DateTime.now().subtract(Duration(hours: level > 10 ? 2 : 8)),
        isOnline: isOnline,
        bio: bio,
        stats: {
          'favoriteCategory': [
            'Tech',
            'Gaming',
            'Travel',
            'Fashion',
          ][level % 4],
          'bestWin': '\$${(prizes * 50) + 100}',
          'winRate': '${(prizes * 2.5).toStringAsFixed(1)}%',
        },
        friends: const [],
        following: const [],
        followers: const [],
      );
    }).toList();
  }

  /// Create a mock friend
  UserProfile _createMockFriend(String friendId) => UserProfile(
        uid: friendId,
        displayName: 'New Friend',
        avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=$friendId',
        level: 5,
        dustBunnies: 850,
        totalContestsEntered: 25,
        challengesCompleted: 12,
        totalPrizesWon: 1,
        sweepCoins: 350,
        currentStreak: 2,
        longestStreak: 8,
        badges: const ['rookie'],
        joinedDate: DateTime.now().subtract(const Duration(days: 30)),
        lastActiveDate: DateTime.now().subtract(const Duration(hours: 1)),
        isOnline: false,
        bio: 'Just joined the SweepFeed community!',
        stats: const {},
        friends: const [],
        following: const [],
        followers: const [],
      );

  /// Generate badges based on level and prizes
  List<String> _generateBadges(int level, int prizes) {
    final badges = <String>[];

    if (level >= 20) badges.add('veteran');
    if (level >= 15) badges.add('achiever');
    if (level >= 10) badges.add('challenger');
    if (prizes >= 10) badges.add('winner');
    if (prizes >= 5) badges.add('contestking');
    if (level <= 5) badges.add('rookie');

    return badges;
  }
}

/// Provider for managing friend requests
class FriendRequestsNotifier
    extends StateNotifier<AsyncValue<List<FriendRequest>>> {
  FriendRequestsNotifier() : super(const AsyncValue.loading());

  /// Fetch pending friend requests
  Future<void> fetchFriendRequests(String userId) async {
    try {
      state = const AsyncValue.loading();

      // In production, query Firestore
      await Future.delayed(const Duration(milliseconds: 400));

      final requests = _generateMockRequests();
      state = AsyncValue.data(requests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Send friend request
  Future<void> sendFriendRequest(
    String fromUserId,
    String toUserId,
    String toUserName,
  ) async {
    try {
      // In production, create Firestore document
      await Future.delayed(const Duration(milliseconds: 300));

      // Success - in production, would show success feedback
    } catch (error) {
      // Handle error
      rethrow;
    }
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      // In production, update Firestore
      await Future.delayed(const Duration(milliseconds: 300));

      // Remove from pending requests
      final currentRequests = state.valueOrNull ?? [];
      final updatedRequests =
          currentRequests.where((req) => req.id != requestId).toList();
      state = AsyncValue.data(updatedRequests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Reject friend request
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      // In production, update Firestore
      await Future.delayed(const Duration(milliseconds: 300));

      // Remove from pending requests
      final currentRequests = state.valueOrNull ?? [];
      final updatedRequests =
          currentRequests.where((req) => req.id != requestId).toList();
      state = AsyncValue.data(updatedRequests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Generate mock friend requests
  List<FriendRequest> _generateMockRequests() => [
        FriendRequest(
          id: 'req_001',
          fromUserId: 'user_cosmic',
          toUserId: 'current_user',
          fromUserName: 'CosmicRider',
          fromUserAvatar:
              'https://api.dicebear.com/7.x/avataaars/svg?seed=cosmic',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          status: FriendRequestStatus.pending,
        ),
        FriendRequest(
          id: 'req_002',
          fromUserId: 'user_data',
          toUserId: 'current_user',
          fromUserName: 'DataMiner88',
          fromUserAvatar:
              'https://api.dicebear.com/7.x/avataaars/svg?seed=data',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          status: FriendRequestStatus.pending,
        ),
      ];
}

/// Provider for searching users
class UserSearchNotifier extends StateNotifier<AsyncValue<List<UserProfile>>> {
  UserSearchNotifier() : super(const AsyncValue.data([]));

  /// Search for users by username or display name
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();

      // In production, query Firestore
      await Future.delayed(const Duration(milliseconds: 500));

      final results = _mockSearchResults(query);
      state = AsyncValue.data(results);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Clear search results
  void clearSearch() {
    state = const AsyncValue.data([]);
  }

  /// Mock search results
  List<UserProfile> _mockSearchResults(String query) {
    final allUsers = [
      ('TestUser_99', 'Test User', 8, 1650),
      ('WinnerCircle', 'Sarah Winner', 18, 4200),
      ('LuckyStrike7', 'Lucky Strike', 11, 2800),
      ('ContestPro', 'Contest Professional', 25, 6500),
      ('NewbieSweeps', 'Newbie Sweeper', 3, 450),
    ];

    return allUsers
        .where(
      (user) =>
          user.$1.toLowerCase().contains(query.toLowerCase()) ||
          user.$2.toLowerCase().contains(query.toLowerCase()),
    )
        .map((user) {
      final (username, displayName, level, dustBunnies) = user;
      return UserProfile(
        uid: 'search_${username.toLowerCase()}',
        displayName: displayName,
        avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=$username',
        level: level,
        dustBunnies: dustBunnies,
        totalContestsEntered: level * 7,
        challengesCompleted: level * 2,
        totalPrizesWon: level > 15
            ? 5
            : level > 10
                ? 2
                : 0,
        sweepCoins: level * 40,
        currentStreak: level > 20 ? 10 : 3,
        longestStreak: level + 5,
        badges: level > 20
            ? ['veteran', 'achiever']
            : level > 10
                ? ['challenger']
                : ['rookie'],
        joinedDate: DateTime.now().subtract(Duration(days: level * 25)),
        lastActiveDate:
            DateTime.now().subtract(Duration(hours: level > 15 ? 1 : 4)),
        isOnline: level > 15,
        bio:
            'SweepFeed member since ${DateTime.now().subtract(Duration(days: level * 25)).year}',
        stats: const {},
        friends: const [],
        following: const [],
        followers: const [],
      );
    }).toList();
  }
}

/// Providers
final friendsProvider =
    StateNotifierProvider<FriendsNotifier, AsyncValue<List<UserProfile>>>(
  (ref) => FriendsNotifier(),
);

final friendRequestsProvider = StateNotifierProvider<FriendRequestsNotifier,
    AsyncValue<List<FriendRequest>>>((ref) => FriendRequestsNotifier());

final userSearchProvider =
    StateNotifierProvider<UserSearchNotifier, AsyncValue<List<UserProfile>>>(
  (ref) => UserSearchNotifier(),
);

/// Provider for friend count
final friendCountProvider = Provider<int>((ref) {
  final friendsAsync = ref.watch(friendsProvider);
  return friendsAsync.when(
    data: (friends) => friends.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for pending friend requests count
final pendingRequestsCountProvider = Provider<int>((ref) {
  final requestsAsync = ref.watch(friendRequestsProvider);
  return requestsAsync.when(
    data: (requests) => requests
        .where((req) => req.status == FriendRequestStatus.pending)
        .length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Provider for online friends
final onlineFriendsProvider = Provider<List<UserProfile>>((ref) {
  final friendsAsync = ref.watch(friendsProvider);
  return friendsAsync.when(
    data: (friends) => friends.where((friend) => friend.isOnline).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
