import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_constants.dart';
import '../utils/logger.dart';
import 'analytics_service.dart';

/// DustBunnies reward result model - immutable for safety
@immutable
class DustBunniesReward {
  const DustBunniesReward({
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
      'DustBunniesReward(awarded: $pointsAwarded, leveledUp: $leveledUp, '
      'newLevel: $newLevel, rank: $rank)';
}

/// DustBunnies service with improved quality based on Gemini analysis
/// Features:
/// - Dependency injection for testability
/// - Backward compatibility with xpSystem and sweepPointsSystem
/// - Analytics tracking
/// - Rate limiting support
/// - Proper error handling
class DustBunniesService extends ChangeNotifier {
  DustBunniesService(
    this._ref, {
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final Ref _ref;
  final FirebaseFirestore _firestore;

  // REBALANCED DustBunnies economy - validated by Gemini collaboration
  static const Map<String, int> dustBunniesRewards = {
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

  /// Calculate DustBunnies required for a given level
  /// Uses exponential growth to maintain engagement at all levels
  static int getDustBunniesRequiredForLevel(int level) {
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

  /// Helper to safely extract DustBunnies data with backward compatibility
  Map<String, dynamic> _extractDustBunniesData(Map<String, dynamic> data) {
    // Read from new field first, fallback to old fields for migration period
    final dbData = data['dustBunniesSystem'] as Map<String, dynamic>? ??
        data['sweepPointsSystem'] as Map<String, dynamic>? ??
        data['xpSystem'] as Map<String, dynamic>? ??
        {};

    return {
      'currentDB': dbData['currentDB'] ??
          dbData['currentSP'] ??
          dbData['currentXP'] ??
          0,
      'totalDB':
          dbData['totalDB'] ?? dbData['totalSP'] ?? dbData['totalXP'] ?? 0,
      'level': dbData['level'] ?? 1,
      'dbToNextLevel': dbData['dbToNextLevel'] ??
          dbData['spToNextLevel'] ??
          dbData['xpToNextLevel'] ??
          100,
      'rank': dbData['rank'] ?? 'Bronze',
      'multiplier': dbData['multiplier'] ?? 1.0,
      'monthlyEarned': dbData['monthlyEarned'] ?? 0,
    };
  }

  /// Get default DustBunnies data for new users
  Map<String, dynamic> _getDefaultDustBunniesData() => {
      'currentDB': 0,
      'totalDB': 0,
      'level': 1,
      'dbToNextLevel': getDustBunniesRequiredForLevel(1),
      'rank': 'Bronze',
      'multiplier': 1.0,
      'monthlyEarned': 0,
    };

  /// Get user's current DustBunnies data with backward compatibility
  Future<Map<String, dynamic>> getUserDustBunniesData(String userId) async {
    try {
      if (userId.isEmpty) {
        throw ArgumentError('User ID cannot be empty');
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return await _initializeDustBunniesData(userId);
      }

      final data = userDoc.data()!;
      return _extractDustBunniesData(data);
    } catch (e) {
      logger.e('Error getting user DustBunnies data', error: e);
      return _getDefaultDustBunniesData();
    }
  }

  /// Initialize DustBunnies system for new user
  /// Writes to all systems for backward compatibility
  Future<Map<String, dynamic>> _initializeDustBunniesData(String userId) async {
    final defaultData = _getDefaultDustBunniesData();

    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'dustBunniesSystem': {
            'currentDB': defaultData['currentDB'],
            'totalDB': defaultData['totalDB'],
            'level': defaultData['level'],
            'dbToNextLevel': defaultData['dbToNextLevel'],
            'rank': defaultData['rank'],
            'multiplier': defaultData['multiplier'],
            'monthlyEarned': defaultData['monthlyEarned'],
          },
          'sweepPointsSystem': {
            // Backward compatibility
            'currentSP': defaultData['currentDB'],
            'totalSP': defaultData['totalDB'],
            'level': defaultData['level'],
            'spToNextLevel': defaultData['dbToNextLevel'],
            'rank': defaultData['rank'],
            'multiplier': defaultData['multiplier'],
          },
          'xpSystem': {
            // Backward compatibility
            'currentXP': defaultData['currentDB'],
            'totalXP': defaultData['totalDB'],
            'level': defaultData['level'],
            'xpToNextLevel': defaultData['dbToNextLevel'],
            'rank': defaultData['rank'],
            'multiplier': defaultData['multiplier'],
          },
        },
        SetOptions(merge: true),
      );

      _trackAnalytics('dustbunnies_initialized', {
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return defaultData;
    } catch (e) {
      logger.e('Error initializing DustBunnies data', error: e);
      return defaultData;
    }
  }

  /// Award DustBunnies to user with comprehensive validation and analytics
  /// Uses Firestore transaction for atomic updates (prevents race conditions)
  Future<DustBunniesReward> awardDustBunnies({
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

      // Get base DB amount
      final baseDB = customAmount ?? dustBunniesRewards[action] ?? 0;

      if (baseDB == 0) {
        logger.w('No DustBunnies defined for action: $action');
        return const DustBunniesReward(
          pointsAwarded: 0,
          leveledUp: false,
        );
      }

      // Use Firestore transaction for atomic updates
      final userRef = _firestore.collection('users').doc(userId);

      DustBunniesReward? result;

      try {
        await _firestore.runTransaction((transaction) async {
          // Read current data within transaction
          final userDoc = await transaction.get(userRef);

          Map<String, dynamic> currentData;
          if (!userDoc.exists) {
            // Initialize if user doesn't exist
            currentData = _getDefaultDustBunniesData();
          } else {
            final userData = userDoc.data();
            if (userData == null) {
              logger.e('User document exists but has no data: $userId');
              result = const DustBunniesReward(
                pointsAwarded: 0,
                leveledUp: false,
              );
              return;
            }
            currentData = _extractDustBunniesData(userData);
          }

          // Safe type casting with defaults
          var currentDB = (currentData['currentDB'] as int?) ?? 0;
          var totalDB = (currentData['totalDB'] as int?) ?? 0;
          var monthlyEarned = (currentData['monthlyEarned'] as int?) ?? 0;
          final currentLevel = (currentData['level'] as int?) ?? 1;
          final multiplier = (currentData['multiplier'] as double?) ?? 1.0;

          // Validate bonusMultiplier
          if (bonusMultiplier != null && bonusMultiplier! < 0) {
            logger.w('Invalid negative bonusMultiplier: $bonusMultiplier');
            bonusMultiplier = 1.0;
          }

          // Apply multipliers
          final finalMultiplier = multiplier * (bonusMultiplier ?? 1.0);
          var dbGained = (baseDB * finalMultiplier).round();

          // Prevent negative DB
          if (dbGained < 0) {
            logger.w('Attempted to award negative DB: $dbGained');
            result = const DustBunniesReward(
              pointsAwarded: 0,
              leveledUp: false,
            );
            return;
          }

          // Prevent overflow on currentDB
          if (currentDB > ValidationConstants.kMaxIntValue - dbGained) {
            logger.w('DB gain would overflow currentDB, clamping');
            dbGained = ValidationConstants.kMaxIntValue - currentDB;
          }

          // Update DB
          currentDB += dbGained;
          totalDB += dbGained;
          monthlyEarned += dbGained;

          // Prevent integer overflow
          if (totalDB < 0 || totalDB > ValidationConstants.kMaxIntValue) {
            logger.e('Integer overflow detected for user $userId');
            totalDB = ValidationConstants.kMaxIntValue;
            currentDB = currentDB.clamp(0, ValidationConstants.kMaxIntValue);
          }
          
           // Prevent integer overflow for monthly
          if (monthlyEarned < 0 || monthlyEarned > ValidationConstants.kMaxIntValue) {
             monthlyEarned = ValidationConstants.kMaxIntValue;
          }

          // Check for level up(s) - Fixed logic
          var leveledUp = false;
          var newLevel = currentLevel;
          final levelsGained = <int>[];

          // Prevent infinite loop with max level cap
          while (newLevel < DustBunniesConstants.kMaxLevel) {
            final dbRequiredForNextLevel =
                getDustBunniesRequiredForLevel(newLevel + 1);

            if (currentDB >= dbRequiredForNextLevel) {
              // Level up logic: subtract DB for next level from current
              currentDB -= dbRequiredForNextLevel;
              newLevel++;
              leveledUp = true;
              levelsGained.add(newLevel);
            } else {
              break;
            }
          }

          final rank = _getRankForLevel(newLevel);

          // Prepare data structures for Firestore update
          final dustBunniesSystemData = {
            'currentDB': currentDB,
            'totalDB': totalDB,
            'level': newLevel,
            'dbToNextLevel': getDustBunniesRequiredForLevel(newLevel),
            'rank': rank,
            'monthlyEarned': monthlyEarned,
          };

          final sweepPointsSystemData = {
            // Backward compatibility
            'currentSP': currentDB,
            'totalSP': totalDB,
            'level': newLevel,
            'spToNextLevel': getDustBunniesRequiredForLevel(newLevel),
            'rank': rank,
          };

          final xpSystemData = {
            // Backward compatibility
            'currentXP': currentDB,
            'totalXP': totalDB,
            'level': newLevel,
            'xpToNextLevel': getDustBunniesRequiredForLevel(newLevel),
            'rank': rank,
          };

          // Atomic write within transaction
          // MIGRATION NOTE: Backward compatibility writes to sweepPointsSystem and xpSystem
          // will be removed in Phase 2 (Q1 2026) after data migration is complete
          if (!userDoc.exists) {
            transaction.set(userRef, {
              'dustBunniesSystem': dustBunniesSystemData,
              'sweepPointsSystem':
                  sweepPointsSystemData, // DEPRECATED: Remove in Q1 2026
              'xpSystem': xpSystemData, // DEPRECATED: Remove in Q1 2026
              'lastDBGain': FieldValue.serverTimestamp(),
              'lastSPGain':
                  FieldValue.serverTimestamp(), // DEPRECATED: Remove in Q1 2026
              'gamificationServiceMigrated': true, // Migration tracking
              'dustBunniesServiceVersion':
                  1, // Version tracking for future schema changes
            });
          } else {
            transaction.update(userRef, {
              'dustBunniesSystem': dustBunniesSystemData,
              'sweepPointsSystem':
                  sweepPointsSystemData, // DEPRECATED: Remove in Q1 2026
              'xpSystem': xpSystemData, // DEPRECATED: Remove in Q1 2026
              'lastDBGain': FieldValue.serverTimestamp(),
              'lastSPGain':
                  FieldValue.serverTimestamp(), // DEPRECATED: Remove in Q1 2026
              'gamificationServiceMigrated': true, // Migration tracking
              'dustBunniesServiceVersion': 1, // Version tracking
            });
          }

          // Store result to return after transaction
          result = DustBunniesReward(
            pointsAwarded: dbGained,
            leveledUp: leveledUp,
            newLevel: leveledUp ? newLevel : null,
            levelsGained: levelsGained,
            rank: rank,
          );
        });

        // Ensure result is set even if transaction fails
        result ??= const DustBunniesReward(
          pointsAwarded: 0,
          leveledUp: false,
        );
      } catch (e) {
        logger.e('Transaction failed in awardDustBunnies', error: e);
        _trackAnalytics('dustbunnies_error', {
          'userId': userId,
          'action': action,
          'error': e.toString(),
        });
        return const DustBunniesReward(
          pointsAwarded: 0,
          leveledUp: false,
        );
      }

      // Log transaction for history (outside transaction to avoid conflicts)
      try {
        await _logDustBunniesTransaction(
          userId,
          action,
          result!.pointsAwarded,
          result!.newLevel ??
              (await getUserDustBunniesData(userId))['level'] as int,
        );
      } catch (e) {
        logger.e('Failed to log DB transaction', error: e);
      }

      // Award level-up rewards if applicable (outside transaction)
      if (result!.leveledUp && result!.levelsGained.isNotEmpty) {
        await _awardLevelUpRewards(userId, result!.levelsGained);
      }

      // Track analytics
      _trackAnalytics('dustbunnies_earned', {
        'userId': userId,
        'action': action,
        'amount': result!.pointsAwarded,
        'reason': action,
        'level': result!.newLevel,
        'leveledUp': result!.leveledUp,
      });

      notifyListeners();

      return result ??
          const DustBunniesReward(pointsAwarded: 0, leveledUp: false);
    } catch (e) {
      logger.e('Error awarding DustBunnies', error: e);
      // Return failure state with no points awarded
      return const DustBunniesReward(
        pointsAwarded: 0,
        leveledUp: false,
      );
    }
  }

  /// Log DustBunnies transaction for history and auditing
  Future<void> _logDustBunniesTransaction(
    String userId,
    String action,
    int dbGained,
    int newLevel,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('dustBunniesHistory')
          .add({
        'action': action,
        'dustBunniesGained': dbGained,
        'newLevel': newLevel,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Also log to old collection for backward compatibility
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sweepPointsHistory')
          .add({
        'action': action,
        'sweepPointsGained': dbGained, // Keep old field name for compatibility
        'dustBunniesGained': dbGained, // Add new field name
        'newLevel': newLevel,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.e('Error logging DustBunnies transaction', error: e);
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

  /// Get DustBunnies leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard(
      {int limit = DustBunniesConstants.kDefaultLeaderboardLimit,}) async {
    try {
      // Try new field first, fallback to old for backward compatibility
      QuerySnapshot query;
      try {
        query = await _firestore
            .collection('users')
            .orderBy('dustBunniesSystem.totalDB', descending: true)
            .limit(limit)
            .get();
      } catch (e) {
        // Fallback to sweepPointsSystem if dustBunniesSystem doesn't exist yet
        query = await _firestore
            .collection('users')
            .orderBy('sweepPointsSystem.totalSP', descending: true)
            .limit(limit)
            .get();
      }

      final leaderboard = <LeaderboardEntry>[];
      var rank = 1;

      for (final doc in query.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        final dbData = _extractDustBunniesData(data);

        leaderboard.add(
          LeaderboardEntry(
            userId: doc.id,
            displayName: data['displayName'] as String? ?? 'Anonymous',
            photoUrl: data['photoUrl'] as String?,
            totalDB: dbData['totalDB'] as int,
            level: dbData['level'] as int,
            rank: rank++,
            rankTitle: dbData['rank'] as String,
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
      final dbData = _extractDustBunniesData(userData);
      final userTotalDB = dbData['totalDB'] as int;

      // Try new field first, fallback to old
      AggregateQuerySnapshot higherRankedUsers;
      try {
        higherRankedUsers = await _firestore
            .collection('users')
            .where('dustBunniesSystem.totalDB', isGreaterThan: userTotalDB)
            .count()
            .get();
      } catch (e) {
        higherRankedUsers = await _firestore
            .collection('users')
            .where('sweepPointsSystem.totalSP', isGreaterThan: userTotalDB)
            .count()
            .get();
      }

      return (higherRankedUsers.count ?? 0) + 1;
    } catch (e) {
      logger.e('Error getting user rank', error: e);
      return -1;
    }
  }

  /// Apply DustBunnies booster for limited time
  Future<void> applyDustBunniesBooster(
    String userId,
    double multiplier,
    Duration duration,
  ) async {
    try {
      final expiresAt = DateTime.now().add(duration);

      await _firestore.collection('users').doc(userId).update({
        'dustBunniesSystem.multiplier': multiplier,
        'dustBunniesSystem.boosterExpiresAt': Timestamp.fromDate(expiresAt),
        'sweepPointsSystem.multiplier': multiplier, // Backward compatibility
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
          'dustBunniesSystem.multiplier': 1.0,
          'dustBunniesSystem.boosterExpiresAt': FieldValue.delete(),
          'sweepPointsSystem.multiplier': 1.0,
          'sweepPointsSystem.boosterExpiresAt': FieldValue.delete(),
          'xpSystem.multiplier': 1.0,
          'xpSystem.boosterExpiresAt': FieldValue.delete(),
        });
      });
    } catch (e) {
      logger.e('Error applying DustBunnies booster', error: e);
    }
  }

  /// Track analytics if callback provided
  void _trackAnalytics(String event, Map<String, dynamic> parameters) {
    _ref.read(analyticsServiceProvider).logEvent(
          eventName: event,
          parameters: parameters,
        );
  }

  /// Legacy method for backward compatibility - SweepPoints
  @Deprecated(
      'Use awardDustBunnies instead. SweepPoints is now DustBunnies (DB).',)
  Future<DustBunniesReward> awardSweepPoints({
    required String userId,
    required String action,
    int? customAmount,
    double? bonusMultiplier,
  }) async => awardDustBunnies(
      userId: userId,
      action: action,
      customAmount: customAmount,
      bonusMultiplier: bonusMultiplier,
    );

  /// Legacy method for backward compatibility - XP
  @Deprecated('Use awardDustBunnies instead. XP is now DustBunnies (DB).')
  Future<DustBunniesReward> awardXP({
    required String userId,
    required String action,
    int? customAmount,
    double? bonusMultiplier,
  }) async => awardDustBunnies(
      userId: userId,
      action: action,
      customAmount: customAmount,
      bonusMultiplier: bonusMultiplier,
    );

  /// Legacy getter for backward compatibility - SweepPoints data
  @Deprecated(
      'Use getUserDustBunniesData instead. SweepPoints is now DustBunnies (DB).',)
  Future<Map<String, dynamic>> getUserSweepPointsData(String userId) async => getUserDustBunniesData(userId);

  /// Legacy booster method for backward compatibility
  @Deprecated(
      'Use applyDustBunniesBooster instead. SweepPoints is now DustBunnies (DB).',)
  Future<void> applySweepPointsBooster(
    String userId,
    double multiplier,
    Duration duration,
  ) async => applyDustBunniesBooster(userId, multiplier, duration);

  /// Check if user qualifies for Entry Enthusiast achievement and award accordingly
  ///
  /// This method checks if a user has met the criteria for the "Entry Enthusiast"
  /// achievement (e.g., entered a certain number of contests) and awards
  /// appropriate DustBunnies if they qualify.
  ///
  /// @param userId The ID of the user to check and potentially award
  /// @returns DustBunniesReward with details of any points awarded
  Future<DustBunniesReward> checkAndAwardEntryEnthusiast(String userId) async {
    try {
      // Check user's contest entry history to determine if they qualify
      // For now, this is a placeholder implementation
      final userData = await getUserDustBunniesData(userId);
      final totalEntries = userData['totalEntries'] ?? 0;

      // Entry Enthusiast: Award for reaching certain entry milestones
      const entryThreshold = 10; // User needs 10+ entries
      const rewardAmount = 50; // Award 50 DustBunnies

      if (totalEntries >= entryThreshold) {
        // Check if already awarded this achievement
        final achievements =
            userData['achievements'] as Map<String, dynamic>? ?? {};
        if (!achievements.containsKey('entry_enthusiast')) {
          // Award the achievement
          final reward = await awardDustBunnies(
            userId: userId,
            action: 'Entry Enthusiast Achievement',
            customAmount: rewardAmount,
          );

          // Mark achievement as awarded
          await _firestore.collection('users').doc(userId).update({
            'achievements.entry_enthusiast': FieldValue.serverTimestamp(),
          });

          _trackAnalytics('achievement_earned', {
            'achievement': 'entry_enthusiast',
            'user_id': userId,
            'reward_amount': rewardAmount,
          });

          return reward;
        }
      }

      // No reward given
      return const DustBunniesReward(
        pointsAwarded: 0,
        leveledUp: false,
      );
    } catch (e) {
      logger.e('Error checking Entry Enthusiast achievement for $userId',
          error: e,);
      return const DustBunniesReward(
        pointsAwarded: 0,
        leveledUp: false,
      );
    }
  }

  /// Redeem a reward using DustBunnies
  Future<bool> redeemReward(String userId, String rewardId, int cost) async {
    if (cost < 0) throw ArgumentError('Cost cannot be negative');

    try {
      final userRef = _firestore.collection('users').doc(userId);
      
      return await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw Exception('User not found');

        final userData = userDoc.data()!;
        final dbData = _extractDustBunniesData(userData);
        final currentDB = dbData['currentDB'] as int;

        if (currentDB < cost) {
          logger.w('User $userId has insufficient DustBunnies to redeem $rewardId');
          return false;
        }

        // Deduct points
        final newDB = currentDB - cost;
        
        // Update both new and legacy fields
        transaction.update(userRef, {
          'dustBunniesSystem.currentDB': newDB,
          'sweepPointsSystem.currentSP': newDB, // Legacy
          'xpSystem.currentXP': newDB, // Legacy
          'claimedRewards': FieldValue.arrayUnion([rewardId]),
        });

        // Log transaction
        _logDustBunniesTransaction(userId, 'redeem_reward_$rewardId', -cost, dbData['level'] as int);
        
        return true;
      });
    } catch (e) {
      logger.e('Error redeeming reward', error: e);
      return false;
    }
  }

  Future<void> claimReward(String userId, String rewardId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('rewards')
          .doc(rewardId)
          .update({'claimed': true});

      _trackAnalytics('reward_claimed', {
        'userId': userId,
        'rewardId': rewardId,
      });
    } catch (e) {
      logger.e('Error claiming reward', error: e);
      rethrow;
    }
  }
}

/// Leaderboard entry model
@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.totalDB,
    required this.level,
    required this.rank,
    required this.rankTitle,
    this.photoUrl,
  });

  final String userId;
  final String displayName;
  final String? photoUrl;
  final int totalDB;
  final int level;
  final int rank;
  final String rankTitle;

  /// Backward compatibility getter
  @Deprecated('Use totalDB instead. SweepPoints is now DustBunnies (DB).')
  int get totalSP => totalDB;

  @override
  String toString() =>
      'LeaderboardEntry(rank: $rank, name: $displayName, DB: $totalDB, level: $level)';
}