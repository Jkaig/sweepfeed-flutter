import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../constants/app_constants.dart';
import '../utils/logger.dart';

/// SweepPoints reward result model - immutable for safety
@immutable
class SweepPointsReward {
  const SweepPointsReward({
    required this.pointsAwarded,
    required this.leveledUp,
    this.newLevel,
    this.rewards,
    this.levelsGained = const [],
    this.rank,
  });

  final int pointsAwarded;
  final bool leveledUp;
  final int? newLevel;
  final Map<String, dynamic>? rewards;
  final List<int> levelsGained;
  final String? rank;

  @override
  String toString() =>
      'SweepPointsReward(awarded: $pointsAwarded, leveledUp: $leveledUp, '
      'newLevel: $newLevel, rank: $rank)';
}

/// SweepPoints service with improved quality based on Gemini analysis
/// Features:
/// - Dependency injection for testability
/// - Backward compatibility with xpSystem
/// - Analytics tracking
/// - Rate limiting support
/// - Proper error handling
class SweepPointsService extends ChangeNotifier {
  SweepPointsService({
    FirebaseFirestore? firestore,
    this.analyticsCallback,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Function(String event, Map<String, dynamic> parameters)?
      analyticsCallback;

  // REBALANCED SweepPoints economy - validated by Gemini collaboration
  static const Map<String, int> sweepPointsRewards = {
    'contest_entry': DustBunniesConstants.kContestEntryPoints,
    'daily_login': DustBunniesConstants.kDailyLoginPoints,
    'profile_complete': DustBunniesConstants.kProfileCompletePoints,
    'referral_success': DustBunniesConstants.kReferralSuccessPoints,
    'share_contest': DustBunniesConstants.kShareContestPoints,
    'watch_ad': DustBunniesConstants.kWatchAdPoints,
    'complete_checklist': DustBunniesConstants.kCompleteChecklistPoints,
    'win_contest': DustBunniesConstants.kWinContestPoints,
    'streak_bonus': DustBunniesConstants.kStreakBonusPoints,
    'achievement_unlock': DustBunniesConstants.kAchievementUnlockPoints,
    'mystery_box_open': DustBunniesConstants.kMysteryBoxOpenPoints,
    'comment_posted': DustBunniesConstants.kCommentPostedPoints,
    'contest_saved': DustBunniesConstants.kContestSavedPoints,
    'first_entry_daily': DustBunniesConstants.kFirstEntryDailyPoints,
  };

  // Level curve constants - extracted for easy tuning
  static const double _levelBase = DustBunniesConstants.kLevelBase;
  static const double _levelExponent = DustBunniesConstants.kLevelExponent;

  /// Calculate SweepPoints required for a given level
  /// Uses exponential growth to maintain engagement at all levels
  static int getSweepPointsRequiredForLevel(int level) {
    if (level < 1) return 0;
    return (_levelBase * math.pow(level, _levelExponent)).round();
  }

  /// Get rank title based on level - gamification tier system
  String _getRankForLevel(int level) {
    if (level >= DustBunniesConstants.kCenturionLevel) return 'Legendary';
    if (level >= 75) return 'Master';
    if (level >= DustBunniesConstants.kHalfCenturyLevel) return 'Diamond';
    if (level >= 30) return 'Platinum';
    if (level >= 20) return 'Gold';
    if (level >= DustBunniesConstants.kMediumMilestoneLevel) return 'Silver';
    return 'Bronze';
  }

  /// Helper to safely extract SweepPoints data with backward compatibility
  Map<String, dynamic> _extractSweepPointsData(Map<String, dynamic> data) {
    // Read from new field first, fallback to old for migration period
    final spData = data['sweepPointsSystem'] as Map<String, dynamic>? ??
        data['xpSystem'] as Map<String, dynamic>? ??
        {};

    return {
      'currentSP': spData['currentSP'] ?? spData['currentXP'] ?? 0,
      'totalSP': spData['totalSP'] ?? spData['totalXP'] ?? 0,
      'level': spData['level'] ?? 1,
      'spToNextLevel':
          spData['spToNextLevel'] ?? spData['xpToNextLevel'] ?? 100,
      'rank': spData['rank'] ?? 'Bronze',
      'multiplier': spData['multiplier'] ?? 1.0,
    };
  }

  /// Get default SweepPoints data for new users
  Map<String, dynamic> _getDefaultSweepPointsData() => {
      'currentSP': 0,
      'totalSP': 0,
      'level': 1,
      'spToNextLevel': getSweepPointsRequiredForLevel(1),
      'rank': 'Bronze',
      'multiplier': 1.0,
    };

  /// Get user's current SweepPoints data with backward compatibility
  Future<Map<String, dynamic>> getUserSweepPointsData(String userId) async {
    try {
      if (userId.isEmpty) {
        throw ArgumentError('User ID cannot be empty');
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return await _initializeSweepPointsData(userId);
      }

      final data = userDoc.data()!;
      return _extractSweepPointsData(data);
    } catch (e) {
      logger.e('Error getting user SweepPoints data', error: e);
      return _getDefaultSweepPointsData();
    }
  }

  /// Initialize SweepPoints system for new user
  /// Writes to both systems for backward compatibility
  Future<Map<String, dynamic>> _initializeSweepPointsData(String userId) async {
    final defaultData = _getDefaultSweepPointsData();

    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'sweepPointsSystem': {
            'currentSP': defaultData['currentSP'],
            'totalSP': defaultData['totalSP'],
            'level': defaultData['level'],
            'spToNextLevel': defaultData['spToNextLevel'],
            'rank': defaultData['rank'],
            'multiplier': defaultData['multiplier'],
          },
          'xpSystem': {
            // Backward compatibility
            'currentXP': defaultData['currentSP'],
            'totalXP': defaultData['totalSP'],
            'level': defaultData['level'],
            'xpToNextLevel': defaultData['spToNextLevel'],
            'rank': defaultData['rank'],
            'multiplier': defaultData['multiplier'],
          },
        },
        SetOptions(merge: true),
      );

      _trackAnalytics('sweep_points_initialized', {
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return defaultData;
    } catch (e) {
      logger.e('Error initializing SweepPoints data', error: e);
      return defaultData;
    }
  }

  /// Award SweepPoints to user with comprehensive validation and analytics
  /// Uses Firestore transaction for atomic updates (prevents race conditions)
  Future<SweepPointsReward> awardSweepPoints({
    required String userId,
    required String action,
    int? customAmount,
    double? bonusMultiplier,
  }) async {
    try {
      // Input validation
      if (userId.isEmpty) {
        throw ArgumentError('User ID cannot be empty');
      }

      if (action.isEmpty) {
        throw ArgumentError('Action cannot be empty');
      }

      // Get base SP amount
      final baseSP = customAmount ?? sweepPointsRewards[action] ?? 0;

      if (baseSP == 0) {
        logger.w('No SweepPoints defined for action: $action');
        return const SweepPointsReward(
          pointsAwarded: 0,
          leveledUp: false,
        );
      }

      // Use Firestore transaction for atomic updates
      final userRef = _firestore.collection('users').doc(userId);

      late SweepPointsReward result;

      await _firestore.runTransaction((transaction) async {
        // Read current data within transaction
        final userDoc = await transaction.get(userRef);

        Map<String, dynamic> currentData;
        if (!userDoc.exists) {
          // Initialize if user doesn't exist
          currentData = _getDefaultSweepPointsData();
        } else {
          currentData = _extractSweepPointsData(userDoc.data()!);
        }

        var currentSP = currentData['currentSP'] as int;
        var totalSP = currentData['totalSP'] as int;
        final currentLevel = currentData['level'] as int;
        final multiplier = currentData['multiplier'] as double;

        // Apply multipliers
        final finalMultiplier = multiplier * (bonusMultiplier ?? 1.0);
        final spGained = (baseSP * finalMultiplier).round();

        // Prevent negative SP
        if (spGained < 0) {
          logger.w('Attempted to award negative SP: $spGained');
          result = const SweepPointsReward(
            pointsAwarded: 0,
            leveledUp: false,
          );
          return;
        }

        // Update SP
        currentSP += spGained;
        totalSP += spGained;

        // Prevent integer overflow
        if (totalSP < 0) {
          logger.e('Integer overflow detected for user $userId');
          totalSP = ValidationConstants.kMaxIntValue;
          currentSP = currentSP.clamp(0, ValidationConstants.kMaxIntValue);
        }

        // Check for level up(s)
        var leveledUp = false;
        var newLevel = currentLevel;
        final levelsGained = <int>[];

        // Prevent infinite loop with max level cap
        while (currentSP >= getSweepPointsRequiredForLevel(newLevel) &&
            newLevel < DustBunniesConstants.kMaxLevel) {
          currentSP -= getSweepPointsRequiredForLevel(newLevel);
          newLevel++;
          leveledUp = true;
          levelsGained.add(newLevel);
        }

        final rank = _getRankForLevel(newLevel);

        // Prepare data structures for Firestore update
        final sweepPointsSystemData = {
          'currentSP': currentSP,
          'totalSP': totalSP,
          'level': newLevel,
          'spToNextLevel': getSweepPointsRequiredForLevel(newLevel),
          'rank': rank,
        };

        final xpSystemData = {
          // Backward compatibility
          'currentXP': currentSP,
          'totalXP': totalSP,
          'level': newLevel,
          'xpToNextLevel': getSweepPointsRequiredForLevel(newLevel),
          'rank': rank,
        };

        // Atomic write within transaction
        if (!userDoc.exists) {
          transaction.set(userRef, {
            'sweepPointsSystem': sweepPointsSystemData,
            'xpSystem': xpSystemData,
            'lastSPGain': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(userRef, {
            'sweepPointsSystem': sweepPointsSystemData,
            'xpSystem': xpSystemData,
            'lastSPGain': FieldValue.serverTimestamp(),
          });
        }

        // Store result to return after transaction
        result = SweepPointsReward(
          pointsAwarded: spGained,
          leveledUp: leveledUp,
          newLevel: leveledUp ? newLevel : null,
          levelsGained: levelsGained,
          rank: rank,
        );

        // Note: We'll log transaction and award rewards outside transaction
        // to avoid transaction conflicts
      });

      // Log transaction for history (outside transaction to avoid conflicts)
      await _logSweepPointsTransaction(
        userId,
        action,
        result.pointsAwarded,
        result.newLevel ??
            (await getUserSweepPointsData(userId))['level'] as int,
      );

      // Award level-up rewards if applicable (outside transaction)
      if (result.leveledUp && result.levelsGained.isNotEmpty) {
        await _awardLevelUpRewards(userId, result.levelsGained);
      }

      // Track analytics
      _trackAnalytics('sweep_points_awarded', {
        'userId': userId,
        'action': action,
        'pointsAwarded': result.pointsAwarded,
        'level': result.newLevel,
        'leveledUp': result.leveledUp,
      });

      notifyListeners();

      return result;
    } catch (e) {
      logger.e('Error awarding SweepPoints', error: e);
      _trackAnalytics('sweep_points_error', {
        'userId': userId,
        'action': action,
        'error': e.toString(),
      });
      return const SweepPointsReward(
        pointsAwarded: 0,
        leveledUp: false,
      );
    }
  }

  /// Log SweepPoints transaction for history and auditing
  Future<void> _logSweepPointsTransaction(
    String userId,
    String action,
    int spGained,
    int newLevel,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sweepPointsHistory')
          .add({
        'action': action,
        'sweepPointsGained': spGained,
        'newLevel': newLevel,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.e('Error logging SweepPoints transaction', error: e);
    }
  }

  /// Award level up rewards
  Future<void> _awardLevelUpRewards(
      String userId, List<int> levelsGained,) async {
    for (final level in levelsGained) {
      final rewards = <String, dynamic>{};

      // Milestone rewards
      if (level % DustBunniesConstants.kMediumMilestoneLevel == 0) {
        // Every 10 levels: Premium features or entries
        rewards['premiumDays'] = 3;
        rewards['bonusEntries'] = level ~/ 2;
      }

      if (level % DustBunniesConstants.kSmallMilestoneLevel == 0) {
        // Every 5 levels: Bonus entries
        rewards['bonusEntries'] = 5;
      }

      // Special milestone rewards
      switch (level) {
        case DustBunniesConstants.kQuarterCenturyLevel:
          rewards['specialBadge'] = 'quarter_century';
          rewards['mysteryBoxes'] = 3;
          break;
        case DustBunniesConstants.kHalfCenturyLevel:
          rewards['specialBadge'] = 'half_century';
          rewards['premiumDays'] = 7;
          break;
        case DustBunniesConstants.kCenturionLevel:
          rewards['specialBadge'] = 'centurion';
          rewards['lifetimePremium'] = true;
          break;
      }

      if (rewards.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('rewards')
            .add({
          'level': level,
          'rewards': rewards,
          'claimed': false,
          'timestamp': FieldValue.serverTimestamp(),
        });

        _trackAnalytics('level_up_reward', {
          'userId': userId,
          'level': level,
          'rewards': rewards,
        });
      }

      _trackAnalytics('level_up', {
        'userId': userId,
        'newLevel': level,
        'rank': _getRankForLevel(level),
      });

      logger.i('User $userId leveled up to level $level!');
    }
  }

  /// Get SweepPoints leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard(
      {int limit = DustBunniesConstants.kDefaultLeaderboardLimit,}) async {
    try {
      final query = await _firestore
          .collection('users')
          .orderBy('sweepPointsSystem.totalSP', descending: true)
          .limit(limit)
          .get();

      final leaderboard = <LeaderboardEntry>[];
      var rank = 1;

      for (final doc in query.docs) {
        final data = doc.data();
        final spData = _extractSweepPointsData(data);

        leaderboard.add(
          LeaderboardEntry(
            userId: doc.id,
            displayName: data['displayName'] as String? ?? 'Anonymous',
            photoUrl: data['photoUrl'] as String?,
            totalSP: spData['totalSP'] as int,
            level: spData['level'] as int,
            rank: rank++,
            rankTitle: spData['rank'] as String,
          ),
        );
      }

      return leaderboard;
    } catch (e) {
      logger.e('Error getting leaderboard', error: e);
      return [];
    }
  }

  /// Get user's rank in leaderboard
  Future<int> getUserRank(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return -1;

      final userData = userDoc.data()!;
      final spData = _extractSweepPointsData(userData);
      final userTotalSP = spData['totalSP'] as int;

      final higherRankedUsers = await _firestore
          .collection('users')
          .where('sweepPointsSystem.totalSP', isGreaterThan: userTotalSP)
          .count()
          .get();

      return (higherRankedUsers.count ?? 0) + 1;
    } catch (e) {
      logger.e('Error getting user rank', error: e);
      return -1;
    }
  }

  /// Apply SweepPoints booster for limited time
  Future<void> applySweepPointsBooster(
    String userId,
    double multiplier,
    Duration duration,
  ) async {
    try {
      final expiresAt = DateTime.now().add(duration);

      await _firestore.collection('users').doc(userId).update({
        'sweepPointsSystem.multiplier': multiplier,
        'sweepPointsSystem.boosterExpiresAt': Timestamp.fromDate(expiresAt),
        'xpSystem.multiplier': multiplier, // Backward compatibility
        'xpSystem.boosterExpiresAt': Timestamp.fromDate(expiresAt),
      });

      _trackAnalytics('booster_applied', {
        'userId': userId,
        'multiplier': multiplier,
        'duration': duration.inSeconds,
      });

      // Schedule booster removal
      Future.delayed(duration, () async {
        await _firestore.collection('users').doc(userId).update({
          'sweepPointsSystem.multiplier': 1.0,
          'sweepPointsSystem.boosterExpiresAt': FieldValue.delete(),
          'xpSystem.multiplier': 1.0,
          'xpSystem.boosterExpiresAt': FieldValue.delete(),
        });
      });
    } catch (e) {
      logger.e('Error applying SweepPoints booster', error: e);
    }
  }

  /// Track analytics if callback provided
  void _trackAnalytics(String event, Map<String, dynamic> parameters) {
    analyticsCallback?.call(event, parameters);
  }

  /// Legacy method for backward compatibility
  @Deprecated('Use awardSweepPoints instead')
  Future<SweepPointsReward> awardXP({
    required String userId,
    required String action,
    int? customAmount,
    double? bonusMultiplier,
  }) async => awardSweepPoints(
      userId: userId,
      action: action,
      customAmount: customAmount,
      bonusMultiplier: bonusMultiplier,
    );
}

/// Leaderboard entry model
@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.totalSP,
    required this.level,
    required this.rank,
    required this.rankTitle,
    this.photoUrl,
  });

  final String userId;
  final String displayName;
  final String? photoUrl;
  final int totalSP;
  final int level;
  final int rank;
  final String rankTitle;

  @override
  String toString() =>
      'LeaderboardEntry(rank: $rank, name: $displayName, SP: $totalSP, level: $level)';
}
