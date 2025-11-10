import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User gamification data model
class UserGamification {
  const UserGamification({
    required this.level,
    required this.currentDB,
    required this.maxDB,
    required this.totalContestsEntered,
    required this.totalPrizesWon,
    required this.streak,
    required this.challenges,
  });
  final int level;
  final int currentDB;
  final int maxDB;
  final int totalContestsEntered;
  final int totalPrizesWon;
  final int streak;
  final List<UserChallenge> challenges;

  @Deprecated('Use currentDB instead. SweepPoints is now DustBunnies (DB).')
  int get currentSP => currentDB;

  @Deprecated('Use currentDB instead. XP is now DustBunnies (DB).')
  int get currentXP => currentDB;

  @Deprecated('Use maxDB instead. SweepPoints is now DustBunnies (DB).')
  int get maxSP => maxDB;

  @Deprecated('Use maxDB instead. XP is now DustBunnies (DB).')
  int get maxXP => maxDB;

  /// Progress percentage (0.0 to 1.0)
  double get progressPercentage => currentDB / maxDB;

  /// DustBunnies needed for next level
  int get dbToNextLevel => maxDB - currentDB;

  @Deprecated('Use dbToNextLevel instead. SweepPoints is now DustBunnies (DB).')
  int get spToNextLevel => dbToNextLevel;

  @Deprecated('Use dbToNextLevel instead. XP is now DustBunnies (DB).')
  int get xpToNextLevel => dbToNextLevel;

  /// Copy with updated values
  UserGamification copyWith({
    int? level,
    int? currentDB,
    int? maxDB,
    int? totalContestsEntered,
    int? totalPrizesWon,
    int? streak,
    List<UserChallenge>? challenges,
  }) =>
      UserGamification(
        level: level ?? this.level,
        currentDB: currentDB ?? this.currentDB,
        maxDB: maxDB ?? this.maxDB,
        totalContestsEntered: totalContestsEntered ?? this.totalContestsEntered,
        totalPrizesWon: totalPrizesWon ?? this.totalPrizesWon,
        streak: streak ?? this.streak,
        challenges: challenges ?? this.challenges,
      );
}

/// Individual challenge model
class UserChallenge {
  const UserChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.currentProgress,
    required this.maxProgress,
    required this.dustBunniesReward,
    required this.isCompleted,
    required this.type,
  });
  final String id;
  final String title;
  final String description;
  final int currentProgress;
  final int maxProgress;
  final int dustBunniesReward;
  final bool isCompleted;
  final ChallengeType type;

  @Deprecated(
      'Use dustBunniesReward instead. SweepPoints is now DustBunnies (DB).')
  int get sweepPointsReward => dustBunniesReward;

  @Deprecated('Use dustBunniesReward instead. XP is now DustBunnies (DB).')
  int get xpReward => dustBunniesReward;

  /// Progress percentage (0.0 to 1.0)
  double get progressPercentage =>
      maxProgress > 0 ? currentProgress / maxProgress : 0.0;

  /// Progress text (e.g., "2/3")
  String get progressText => '$currentProgress/$maxProgress';
}

/// Types of challenges
enum ChallengeType {
  contest,
  share,
  streak,
  weekly,
  bonus;
}

/// Provider for user gamification data
/// In production, this would fetch from Firestore user profile
final gamificationProvider = FutureProvider<UserGamification>((ref) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 500));

  // Mock data - in production, fetch from user's Firestore document
  return const UserGamification(
    level: 3,
    currentDB: 250,
    maxDB: 500,
    totalContestsEntered: 12,
    totalPrizesWon: 2,
    streak: 5,
    challenges: [
      UserChallenge(
        id: 'contest_entry',
        title: 'Enter 3 Contests',
        description: 'Enter 3 contests today to earn bonus DB',
        currentProgress: 1,
        maxProgress: 3,
        dustBunniesReward: 50,
        isCompleted: false,
        type: ChallengeType.contest,
      ),
      UserChallenge(
        id: 'share_contest',
        title: 'Share a Contest',
        description: 'Share a contest with friends',
        currentProgress: 0,
        maxProgress: 1,
        dustBunniesReward: 25,
        isCompleted: false,
        type: ChallengeType.share,
      ),
      UserChallenge(
        id: 'weekly_goal',
        title: 'Weekly Goal',
        description: 'Enter 10 contests this week',
        currentProgress: 7,
        maxProgress: 10,
        dustBunniesReward: 100,
        isCompleted: false,
        type: ChallengeType.weekly,
      ),
    ],
  );
});

/// Provider for daily challenges only
final dailyChallengesProvider = Provider<List<UserChallenge>>((ref) {
  final gamificationAsync = ref.watch(gamificationProvider);

  return gamificationAsync.when(
    data: (gamification) => gamification.challenges
        .where(
          (challenge) =>
              challenge.type == ChallengeType.contest ||
              challenge.type == ChallengeType.share,
        )
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for user level data only
final userLevelProvider = Provider<Map<String, dynamic>>((ref) {
  final gamificationAsync = ref.watch(gamificationProvider);

  return gamificationAsync.when(
    data: (gamification) => {
      'level': gamification.level,
      'currentDB': gamification.currentDB,
      'maxDB': gamification.maxDB,
      'progressPercentage': gamification.progressPercentage,
      'dbToNextLevel': gamification.dbToNextLevel,
    },
    loading: () => {
      'level': 0,
      'currentDB': 0,
      'maxDB': 100,
      'progressPercentage': 0.0,
      'dbToNextLevel': 100,
    },
    error: (_, __) => {
      'level': 1,
      'currentDB': 0,
      'maxDB': 100,
      'progressPercentage': 0.0,
      'dbToNextLevel': 100,
    },
  );
});

/// Mock function to complete a challenge (for button functionality)
Future<void> completeChallenge(String challengeId) async {
  // In production, this would update Firestore
  await Future.delayed(const Duration(milliseconds: 300));
  // Add DustBunnies, update progress, etc.
}

/// Mock function to enter contest (for button functionality)
Future<void> enterContest(String contestId) async {
  // In production, this would:
  // 1. Record contest entry in Firestore
  // 2. Update user's gamification progress
  // 3. Check for challenge completion
  await Future.delayed(const Duration(milliseconds: 500));
}
