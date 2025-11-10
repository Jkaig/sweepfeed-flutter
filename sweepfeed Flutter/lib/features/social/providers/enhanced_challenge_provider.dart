import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enhanced_challenge.dart';

/// Provider for managing enhanced challenges
class EnhancedChallengeNotifier
    extends StateNotifier<AsyncValue<List<EnhancedChallenge>>> {
  EnhancedChallengeNotifier() : super(const AsyncValue.loading());

  /// Fetch all active challenges for user
  Future<void> fetchChallenges(String userId) async {
    try {
      state = const AsyncValue.loading();

      // In production, this would query Firestore
      await Future.delayed(const Duration(milliseconds: 800));

      final challenges = _generateMockChallenges();
      state = AsyncValue.data(challenges);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update challenge progress
  Future<void> updateProgress(String challengeId, int newProgress) async {
    final currentChallenges = state.valueOrNull ?? [];
    final updatedChallenges = currentChallenges.map((challenge) {
      if (challenge.id == challengeId) {
        final isCompleted = newProgress >= challenge.maxProgress;
        return challenge.copyWith(
          currentProgress: newProgress,
          isCompleted: isCompleted,
        );
      }
      return challenge;
    }).toList();

    state = AsyncValue.data(updatedChallenges);
  }

  /// Claim challenge reward
  Future<void> claimReward(String challengeId) async {
    try {
      // In production, update Firestore and user profile
      await Future.delayed(const Duration(milliseconds: 300));

      final currentChallenges = state.valueOrNull ?? [];
      final updatedChallenges = currentChallenges.map((challenge) {
        if (challenge.id == challengeId && challenge.canClaim) {
          return challenge.copyWith(isClaimed: true);
        }
        return challenge;
      }).toList();

      state = AsyncValue.data(updatedChallenges);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh challenges list
  Future<void> refresh() async {
    const userId = 'current_user'; // Get from auth provider
    await fetchChallenges(userId);
  }

  /// Generate diverse mock challenges for development
  List<EnhancedChallenge> _generateMockChallenges() {
    final now = DateTime.now();

    return [
      // Daily challenges
      EnhancedChallenge(
        id: 'daily_contest_entry',
        title: 'Daily Contest Explorer',
        description:
            'Enter 3 different contests today to discover new opportunities',
        category: ChallengeCategory.contest,
        difficulty: ChallengeDifficulty.easy,
        type: ChallengeType.contest,
        currentProgress: 1,
        maxProgress: 3,
        rewards: const [
          ChallengeReward(
            type: RewardType.dustBunnies,
            amount: 50,
            displayName: '50 DB',
            description: 'DustBunnies',
          ),
          ChallengeReward(
            type: RewardType.sweepCoins,
            amount: 25,
            displayName: '25 SweepCoins',
            description: 'Spending currency',
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.add(const Duration(hours: 10)),
        isCompleted: false,
        isClaimed: false,
        iconCode: '🎯',
        metadata: const {
          'categories': ['tech', 'gaming'],
          'bonus_db': 10,
        },
      ),

      // Social challenge
      EnhancedChallenge(
        id: 'social_butterfly',
        title: 'Social Butterfly',
        description:
            'Share your biggest win with friends and spread the excitement!',
        category: ChallengeCategory.social,
        difficulty: ChallengeDifficulty.easy,
        type: ChallengeType.share,
        currentProgress: 0,
        maxProgress: 1,
        rewards: const [
          ChallengeReward(
            type: RewardType.dustBunnies,
            amount: 75,
            displayName: '75 DB',
            description: 'Social engagement bonus',
          ),
          ChallengeReward(
            type: RewardType.badge,
            amount: 1,
            itemId: 'social_butterfly_badge',
            displayName: 'Social Butterfly Badge',
            description: 'Show off your social spirit',
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 1)),
        expiresAt: now.add(const Duration(hours: 23)),
        isCompleted: false,
        isClaimed: false,
        iconCode: '🦋',
        metadata: const {
          'share_platforms': ['friends', 'social_media'],
        },
      ),

      // Streak challenge
      EnhancedChallenge(
        id: 'fire_streak',
        title: 'Fire Streak Master',
        description: 'Maintain your daily login streak for 7 consecutive days',
        category: ChallengeCategory.streak,
        difficulty: ChallengeDifficulty.medium,
        type: ChallengeType.streak,
        currentProgress: 4,
        maxProgress: 7,
        rewards: const [
          ChallengeReward(
            type: RewardType.dustBunnies,
            amount: 150,
            displayName: '150 DB',
            description: 'Streak mastery reward',
          ),
          ChallengeReward(
            type: RewardType.sweepCoins,
            amount: 100,
            displayName: '100 SweepCoins',
            description: 'Premium currency bonus',
          ),
          ChallengeReward(
            type: RewardType.cosmetic,
            amount: 1,
            itemId: 'fire_avatar_frame',
            displayName: 'Fire Avatar Frame',
            description: 'Blazing hot avatar decoration',
          ),
        ],
        createdAt: now.subtract(const Duration(days: 4)),
        expiresAt: now.add(const Duration(days: 3)),
        isCompleted: false,
        isClaimed: false,
        iconCode: '🔥',
        metadata: const {'streak_type': 'login', 'bonus_multiplier': 1.5},
      ),

      // Discovery challenge
      EnhancedChallenge(
        id: 'category_explorer',
        title: 'Category Explorer',
        description: 'Try contests from 5 different categories this week',
        category: ChallengeCategory.exploration,
        difficulty: ChallengeDifficulty.medium,
        type: ChallengeType.discovery,
        currentProgress: 2,
        maxProgress: 5,
        rewards: const [
          ChallengeReward(
            type: RewardType.dustBunnies,
            amount: 200,
            displayName: '200 DB',
            description: 'Exploration mastery',
          ),
          ChallengeReward(
            type: RewardType.badge,
            amount: 1,
            itemId: 'explorer_badge',
            displayName: 'Explorer Badge',
            description: 'Fearless discoverer',
          ),
        ],
        createdAt: now.subtract(const Duration(days: 2)),
        expiresAt: now.add(const Duration(days: 5)),
        isCompleted: false,
        isClaimed: false,
        iconCode: '🗺️',
        metadata: const {
          'explored_categories': ['tech', 'travel'],
          'required_categories': 5,
        },
      ),

      // Completed challenge ready to claim
      EnhancedChallenge(
        id: 'speed_demon',
        title: 'Speed Demon',
        description: 'Enter 10 contests in under 30 minutes',
        category: ChallengeCategory.achievement,
        difficulty: ChallengeDifficulty.hard,
        type: ChallengeType.achievement,
        currentProgress: 10,
        maxProgress: 10,
        rewards: const [
          ChallengeReward(
            type: RewardType.dustBunnies,
            amount: 300,
            displayName: '300 DB',
            description: 'Speed bonus',
          ),
          ChallengeReward(
            type: RewardType.sweepCoins,
            amount: 150,
            displayName: '150 SweepCoins',
            description: 'Premium reward',
          ),
          ChallengeReward(
            type: RewardType.badge,
            amount: 1,
            itemId: 'speed_demon_badge',
            displayName: 'Speed Demon Badge',
            description: 'Lightning fast entries',
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 3)),
        expiresAt: now.add(const Duration(hours: 21)),
        isCompleted: true,
        isClaimed: false,
        iconCode: '⚡',
        metadata: const {'time_limit_minutes': 30, 'achieved_time': 28},
      ),

      // Weekly challenge
      EnhancedChallenge(
        id: 'weekly_warrior',
        title: 'Weekly Warrior',
        description:
            'Complete 25 contest entries this week to prove your dedication',
        category: ChallengeCategory.contest,
        difficulty: ChallengeDifficulty.hard,
        type: ChallengeType.weekly,
        currentProgress: 18,
        maxProgress: 25,
        rewards: const [
          ChallengeReward(
            type: RewardType.dustBunnies,
            amount: 500,
            displayName: '500 DB',
            description: 'Weekly champion bonus',
          ),
          ChallengeReward(
            type: RewardType.sweepCoins,
            amount: 250,
            displayName: '250 SweepCoins',
            description: 'Elite reward',
          ),
          ChallengeReward(
            type: RewardType.cosmetic,
            amount: 1,
            itemId: 'warrior_crown',
            displayName: 'Warrior Crown',
            description: 'Crown of the dedicated',
          ),
        ],
        createdAt: now.subtract(const Duration(days: 4)),
        expiresAt: now.add(const Duration(days: 3)),
        isCompleted: false,
        isClaimed: false,
        iconCode: '👑',
        metadata: const {'weekly_target': 25, 'bonus_weekend': true},
      ),

      // Special limited-time challenge
      EnhancedChallenge(
        id: 'cyber_monday_special',
        title: 'Cyber Monday Special',
        description:
            'Enter tech contests during Cyber Monday for exclusive rewards!',
        category: ChallengeCategory.special,
        difficulty: ChallengeDifficulty.expert,
        type: ChallengeType.special,
        currentProgress: 1,
        maxProgress: 5,
        rewards: const [
          ChallengeReward(
            type: RewardType.dustBunnies,
            amount: 400,
            displayName: '400 DB',
            description: 'Special event bonus',
          ),
          ChallengeReward(
            type: RewardType.sweepCoins,
            amount: 300,
            displayName: '300 SweepCoins',
            description: 'Limited-time currency',
          ),
          ChallengeReward(
            type: RewardType.special,
            amount: 1,
            itemId: 'cyber_monday_theme',
            displayName: 'Cyber Monday Theme',
            description: 'Exclusive app theme',
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 6)),
        expiresAt: now.add(const Duration(hours: 18)), // Expires soon!
        isCompleted: false,
        isClaimed: false,
        iconCode: '🤖',
        metadata: const {
          'event': 'cyber_monday',
          'categories': ['tech', 'electronics'],
        },
      ),
    ];
  }
}

/// Providers
final enhancedChallengesProvider = StateNotifierProvider<
    EnhancedChallengeNotifier,
    AsyncValue<List<EnhancedChallenge>>>((ref) => EnhancedChallengeNotifier());

/// Provider for active challenges only
final activeChallengesProvider = Provider<List<EnhancedChallenge>>((ref) {
  final challengesAsync = ref.watch(enhancedChallengesProvider);
  return challengesAsync.when(
    data: (challenges) =>
        challenges.where((challenge) => !challenge.isExpired).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for completed but unclaimed challenges
final unclaimedChallengesProvider = Provider<List<EnhancedChallenge>>((ref) {
  final challengesAsync = ref.watch(enhancedChallengesProvider);
  return challengesAsync.when(
    data: (challenges) =>
        challenges.where((challenge) => challenge.canClaim).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for challenges by category
final challengesByCategoryProvider =
    Provider.family<List<EnhancedChallenge>, ChallengeCategory>(
        (ref, category) {
  final challengesAsync = ref.watch(enhancedChallengesProvider);
  return challengesAsync.when(
    data: (challenges) => challenges
        .where((challenge) => challenge.category == category)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for daily challenges
final dailyChallengesProvider = Provider<List<EnhancedChallenge>>((ref) {
  final challengesAsync = ref.watch(enhancedChallengesProvider);
  return challengesAsync.when(
    data: (challenges) {
      final now = DateTime.now();
      return challenges.where((challenge) {
        final createdToday = challenge.createdAt.day == now.day &&
            challenge.createdAt.month == now.month &&
            challenge.createdAt.year == now.year;
        final expiresWithin24h =
            challenge.expiresAt.difference(now).inHours <= 24;
        return createdToday || expiresWithin24h;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for special challenges
final specialChallengesProvider = Provider<List<EnhancedChallenge>>((ref) {
  final challengesAsync = ref.watch(enhancedChallengesProvider);
  return challengesAsync.when(
    data: (challenges) => challenges
        .where(
          (challenge) =>
              challenge.category == ChallengeCategory.special ||
              challenge.type == ChallengeType.special,
        )
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for challenge completion stats
final challengeStatsProvider = Provider<Map<String, int>>((ref) {
  final challengesAsync = ref.watch(enhancedChallengesProvider);
  return challengesAsync.when(
    data: (challenges) {
      final completed = challenges.where((c) => c.isCompleted).length;
      final unclaimed = challenges.where((c) => c.canClaim).length;
      final active =
          challenges.where((c) => !c.isExpired && !c.isCompleted).length;
      final totalDB = challenges
          .where((c) => c.isClaimed)
          .fold(0, (sum, challenge) => sum + challenge.totalDustBunniesReward);
      final totalCoins = challenges
          .where((c) => c.isClaimed)
          .fold(0, (sum, challenge) => sum + challenge.totalSweepCoinsReward);

      return {
        'completed': completed,
        'unclaimed': unclaimed,
        'active': active,
        'totalDB': totalDB,
        'totalCoins': totalCoins,
      };
    },
    loading: () => {},
    error: (_, __) => {},
  );
});
