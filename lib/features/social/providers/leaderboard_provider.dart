import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_entry.dart';

/// Provider for leaderboard data
class LeaderboardNotifier
    extends StateNotifier<AsyncValue<List<LeaderboardEntry>>> {
  LeaderboardNotifier() : super(const AsyncValue.loading());

  /// Fetch leaderboard entries for a specific type and bracket
  Future<void> fetchLeaderboard(
    LeaderboardType type,
    UserLevelBracket bracket,
  ) async {
    try {
      state = const AsyncValue.loading();

      // In production, this would query Firestore
      // For now, using mock data based on the existing system
      await Future.delayed(const Duration(milliseconds: 800));

      final entries = _generateMockLeaderboardData(type, bracket);
      state = AsyncValue.data(entries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh current leaderboard
  Future<void> refresh() async {
    // Keep current state while refreshing
    final currentData = state.valueOrNull ?? [];

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // In production, would fetch fresh data from Firestore
      if (currentData.isNotEmpty) {
        state = AsyncValue.data(currentData);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Generate mock leaderboard data for development
  List<LeaderboardEntry> _generateMockLeaderboardData(
    LeaderboardType type,
    UserLevelBracket bracket,
  ) {
    final baseScore = type == LeaderboardType.daily
        ? 50
        : type == LeaderboardType.weekly
            ? 200
            : 1000;

    final mockUsers = [
      ('CyberSweeper_23', 'streakmaster'),
      ('NeonHunter', 'contestking'),
      ('QuantumLuck', 'socialbutterfly'),
      ('VoidWalker99', 'rookie'),
      ('ElectricDream', 'veteran'),
      ('ShadowCaster', 'explorer'),
      ('StarGazer_X', 'achiever'),
      ('TechNinja42', 'challenger'),
      ('CosmicRider', 'winner'),
      ('DataMiner88', 'newbie'),
    ];

    return List.generate(mockUsers.length, (index) {
      final user = mockUsers[index];
      final scoreVariation = (baseScore * 0.8) + (index * baseScore * 0.1);

      return LeaderboardEntry(
        userId: 'user_${index + 1}',
        displayName: user.$1,
        avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=${user.$1}',
        rank: index + 1,
        score: (baseScore - scoreVariation).round(),
        badge: user.$2,
        level: _generateLevelForBracket(bracket),
        userLevel: bracket.name,
      );
    });
  }

  /// Generate appropriate level for bracket
  int _generateLevelForBracket(UserLevelBracket bracket) {
    switch (bracket) {
      case UserLevelBracket.bronze:
        return 1 + (DateTime.now().millisecond % 10);
      case UserLevelBracket.silver:
        return 11 + (DateTime.now().millisecond % 15);
      case UserLevelBracket.gold:
        return 26 + (DateTime.now().millisecond % 25);
      case UserLevelBracket.platinum:
        return 51 + (DateTime.now().millisecond % 50);
      case UserLevelBracket.diamond:
        return 101 + (DateTime.now().millisecond % 100);
    }
  }
}

/// Provider for current user's leaderboard position
class UserLeaderboardPositionNotifier
    extends StateNotifier<AsyncValue<LeaderboardEntry?>> {
  UserLeaderboardPositionNotifier() : super(const AsyncValue.loading());

  /// Fetch current user's position in leaderboard
  Future<void> fetchUserPosition(
    String userId,
    LeaderboardType type,
    UserLevelBracket bracket,
  ) async {
    try {
      state = const AsyncValue.loading();

      await Future.delayed(const Duration(milliseconds: 300));

      // Mock current user position - in production, query Firestore
      final userPosition = LeaderboardEntry(
        userId: userId,
        displayName: 'You',
        avatarUrl:
            'https://api.dicebear.com/7.x/avataaars/svg?seed=currentuser',
        rank: 42, // Mock rank
        score: 156, // Mock score based on type
        badge: 'achiever',
        level: 15,
        userLevel: bracket.name,
      );

      state = AsyncValue.data(userPosition);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Providers for different leaderboard types
final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier,
    AsyncValue<List<LeaderboardEntry>>>((ref) => LeaderboardNotifier());

final userLeaderboardPositionProvider = StateNotifierProvider<
    UserLeaderboardPositionNotifier,
    AsyncValue<LeaderboardEntry?>>((ref) => UserLeaderboardPositionNotifier());

/// Provider for leaderboard metadata
final leaderboardMetadataProvider = FutureProvider.family<LeaderboardMetadata,
    (LeaderboardType, UserLevelBracket)>((ref, params) async {
  final (type, bracket) = params;

  await Future.delayed(const Duration(milliseconds: 200));

  return LeaderboardMetadata(
    type: type,
    lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
    totalEntries: 1247, // Mock total
    bracket: bracket,
  );
});

/// Provider for user's current bracket based on level
final userBracketProvider = Provider<UserLevelBracket>((ref) {
  // In production, get from user profile
  // For now, mock based on current time
  const mockLevel = 15; // Replace with actual user level
  return UserLevelBracket.getBracket(mockLevel);
});

/// Provider for daily leaderboard
final dailyLeaderboardProvider =
    Provider<AsyncValue<List<LeaderboardEntry>>>((ref) {
  final leaderboard = ref.watch(leaderboardProvider);
  final bracket = ref.watch(userBracketProvider);

  // Auto-fetch daily leaderboard
  ref
      .read(leaderboardProvider.notifier)
      .fetchLeaderboard(LeaderboardType.daily, bracket);

  return leaderboard;
});

/// Provider for weekly leaderboard
final weeklyLeaderboardProvider =
    Provider<AsyncValue<List<LeaderboardEntry>>>((ref) {
  final leaderboard = ref.watch(leaderboardProvider);
  final bracket = ref.watch(userBracketProvider);

  return leaderboard;
});

/// Provider for all-time leaderboard
final allTimeLeaderboardProvider =
    Provider<AsyncValue<List<LeaderboardEntry>>>((ref) {
  final leaderboard = ref.watch(leaderboardProvider);
  final bracket = ref.watch(userBracketProvider);

  return leaderboard;
});

/// Provider for friends leaderboard
final friendsLeaderboardProvider =
    Provider<AsyncValue<List<LeaderboardEntry>>>((ref) {
  final leaderboard = ref.watch(leaderboardProvider);

  return leaderboard;
});

/// Helper provider to get top 3 entries for home screen display
final topThreeProvider =
    Provider.family<List<LeaderboardEntry>, LeaderboardType>((ref, type) {
  final AsyncValue<List<LeaderboardEntry>> leaderboardAsync;

  switch (type) {
    case LeaderboardType.daily:
      leaderboardAsync = ref.watch(dailyLeaderboardProvider);
      break;
    case LeaderboardType.weekly:
      leaderboardAsync = ref.watch(weeklyLeaderboardProvider);
      break;
    case LeaderboardType.allTime:
      leaderboardAsync = ref.watch(allTimeLeaderboardProvider);
      break;
    case LeaderboardType.friends:
      leaderboardAsync = ref.watch(friendsLeaderboardProvider);
      break;
  }

  return leaderboardAsync.when(
    data: (entries) => entries.take(3).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for leaderboard refresh state
final leaderboardRefreshProvider = StateProvider<bool>((ref) => false);
