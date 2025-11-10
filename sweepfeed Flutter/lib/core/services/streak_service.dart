import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/logger.dart';
import 'dust_bunnies_service.dart';

// Streak data model
class StreakData {
  StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCheckIns,
    required this.freezesAvailable,
    required this.isStreakFrozen,
    this.lastCheckIn,
    this.frozenUntil,
  });

  factory StreakData.empty() => StreakData(
        currentStreak: 0,
        longestStreak: 0,
        totalCheckIns: 0,
        freezesAvailable: 1,
        isStreakFrozen: false,
      );
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCheckIn;
  final int totalCheckIns;
  final int freezesAvailable;
  final bool isStreakFrozen;
  final DateTime? frozenUntil;
}

// Streak reward model
class StreakReward {
  const StreakReward({
    required this.bonusDB,
    required this.bonusEntries,
    required this.badge,
    this.premiumDays,
    this.lifetimePremium,
  });
  final int bonusDB;

  @Deprecated('Use bonusDB instead. SweepPoints is now DustBunnies (DB).')
  int get bonusSP => bonusDB;

  @Deprecated('Use bonusDB instead. XP is now DustBunnies (DB).')
  int get bonusXP => bonusDB;
  final int bonusEntries;
  final String badge;
  final int? premiumDays;
  final bool? lifetimePremium;
}

// Check-in result model with enhanced features
class CheckInResult {
  CheckInResult({
    required this.success,
    required this.message,
    int? newStreak,
    bool? milestoneReached,
    this.reward,
    bool? streakContinued,
    int? currentStreak,
    this.streakBonus,
    this.milestoneBadge,
  })  : newStreak = newStreak ?? currentStreak ?? 0,
        milestoneReached = milestoneReached ?? false,
        streakContinued = streakContinued ?? false,
        currentStreak = currentStreak ?? newStreak ?? 0;
  final bool success;
  final int newStreak;
  final bool milestoneReached;
  final StreakReward? reward;
  final String message;
  final bool streakContinued;
  final int currentStreak;
  final int? streakBonus;
  final String? milestoneBadge;
}

class StreakService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DustBunniesService _dustBunniesService = DustBunniesService();

  /// @deprecated Use _dustBunniesService instead. SweepPoints is now DustBunnies (DB).
  @Deprecated(
      'Use _dustBunniesService instead. SweepPoints is now DustBunnies (DB).')
  DustBunniesService get _sweepPointsService => _dustBunniesService;

  // Streak milestones and rewards
  static const Map<int, StreakReward> streakMilestones = {
    3: StreakReward(bonusDB: 50, bonusEntries: 1, badge: 'streak_starter'),
    7: StreakReward(bonusDB: 150, bonusEntries: 3, badge: 'week_warrior'),
    14: StreakReward(bonusDB: 300, bonusEntries: 5, badge: 'fortnight_fighter'),
    30: StreakReward(
      bonusDB: 750,
      bonusEntries: 10,
      badge: 'monthly_master',
      premiumDays: 3,
    ),
    60: StreakReward(
      bonusDB: 1500,
      bonusEntries: 20,
      badge: 'dedication_demon',
      premiumDays: 7,
    ),
    100: StreakReward(
      bonusDB: 3000,
      bonusEntries: 50,
      badge: 'century_champion',
      premiumDays: 14,
    ),
    365: StreakReward(
      bonusDB: 10000,
      bonusEntries: 365,
      badge: 'yearly_legend',
      lifetimePremium: true,
    ),
  };

  // Get user's current streak data
  Future<StreakData> getUserStreakData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return await _initializeStreakData(userId);
      }

      final data = userDoc.data()!;
      final streakData = data['streaks'] as Map<String, dynamic>? ?? {};

      return StreakData(
        currentStreak: streakData['current'] ?? 0,
        longestStreak: streakData['longest'] ?? 0,
        lastCheckIn: streakData['lastCheckIn'] != null
            ? (streakData['lastCheckIn'] as Timestamp).toDate()
            : null,
        totalCheckIns: streakData['totalCheckIns'] ?? 0,
        freezesAvailable: streakData['freezesAvailable'] ?? 1,
        isStreakFrozen: streakData['isStreakFrozen'] ?? false,
        frozenUntil: streakData['frozenUntil'] != null
            ? (streakData['frozenUntil'] as Timestamp).toDate()
            : null,
      );
    } catch (e) {
      logger.e('Error getting streak data', error: e);
      return StreakData.empty();
    }
  }

  // Initialize streak data for new user
  Future<StreakData> _initializeStreakData(String userId) async {
    final initialData = {
      'current': 0,
      'longest': 0,
      'lastCheckIn': null,
      'totalCheckIns': 0,
      'freezesAvailable': 1,
      'isStreakFrozen': false,
      'frozenUntil': null,
    };

    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'streaks': initialData,
        },
        SetOptions(merge: true),
      );

      return StreakData.empty();
    } catch (e) {
      logger.e('Error initializing streak data', error: e);
      return StreakData.empty();
    }
  }

  // Check in for daily streak
  Future<CheckInResult> checkIn(String userId) async {
    try {
      final currentData = await getUserStreakData(userId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if already checked in today
      if (currentData.lastCheckIn != null) {
        final lastCheckInDate = DateTime(
          currentData.lastCheckIn!.year,
          currentData.lastCheckIn!.month,
          currentData.lastCheckIn!.day,
        );

        if (lastCheckInDate == today) {
          return CheckInResult(
            success: false,
            message: 'Already checked in today!',
            streakContinued: false,
          );
        }
      }

      // Calculate new streak
      var newStreak = currentData.currentStreak;
      var streakBroken = false;
      var streakContinued = false;

      if (currentData.lastCheckIn != null) {
        final daysSinceLastCheckIn = today
            .difference(
              DateTime(
                currentData.lastCheckIn!.year,
                currentData.lastCheckIn!.month,
                currentData.lastCheckIn!.day,
              ),
            )
            .inDays;

        if (daysSinceLastCheckIn == 1) {
          // Consecutive day - continue streak
          newStreak++;
          streakContinued = true;
        } else if (daysSinceLastCheckIn > 1) {
          // Missed days - check if frozen
          if (currentData.isStreakFrozen &&
              currentData.frozenUntil != null &&
              currentData.frozenUntil!.isAfter(now)) {
            // Streak was frozen, continue it
            newStreak++;
            streakContinued = true;
          } else {
            // Streak broken
            streakBroken = true;
            newStreak = 1;
          }
        }
      } else {
        // First check-in
        newStreak = 1;
      }

      // Update longest streak if necessary
      final newLongestStreak = newStreak > currentData.longestStreak
          ? newStreak
          : currentData.longestStreak;

      // Check for milestone rewards
      StreakReward? milestoneReward;
      String? milestoneBadge;

      if (streakMilestones.containsKey(newStreak)) {
        milestoneReward = streakMilestones[newStreak];
        milestoneBadge = milestoneReward?.badge;

        // Award milestone rewards
        if (milestoneReward != null) {
          await _awardStreakRewards(userId, milestoneReward, newStreak);
        }
      }

      // Award daily streak DustBunnies bonus
      final streakBonus = newStreak * 5; // 5 DB per day of streak
      await _dustBunniesService.awardDustBunnies(
        userId: userId,
        action: 'daily_login',
        bonusMultiplier: 1.0 + (newStreak * 0.01), // 1% bonus per streak day
      );

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'streaks.current': newStreak,
        'streaks.longest': newLongestStreak,
        'streaks.lastCheckIn': Timestamp.fromDate(now),
        'streaks.totalCheckIns': FieldValue.increment(1),
        'streaks.isStreakFrozen': false,
        'streaks.frozenUntil': FieldValue.delete(),
      });

      // Log streak activity
      await _logStreakActivity(userId, newStreak, streakBroken);

      notifyListeners();

      return CheckInResult(
        success: true,
        message: streakBroken
            ? 'Streak broken! Starting fresh at Day 1'
            : 'Day $newStreak streak! Keep it going!',
        streakContinued: streakContinued,
        currentStreak: newStreak,
        streakBonus: streakBonus,
        milestoneReached: milestoneReward != null,
        milestoneBadge: milestoneBadge,
      );
    } catch (e) {
      logger.e('Error checking in', error: e);
      return CheckInResult(
        success: false,
        message: 'Check-in failed. Please try again.',
        streakContinued: false,
      );
    }
  }

  // Freeze streak to protect it
  Future<bool> freezeStreak(String userId, {int days = 1}) async {
    try {
      final currentData = await getUserStreakData(userId);

      if (currentData.freezesAvailable <= 0) {
        logger.w('No freezes available');
        return false;
      }

      if (currentData.isStreakFrozen) {
        logger.w('Streak already frozen');
        return false;
      }

      final frozenUntil = DateTime.now().add(Duration(days: days));

      await _firestore.collection('users').doc(userId).update({
        'streaks.isStreakFrozen': true,
        'streaks.frozenUntil': Timestamp.fromDate(frozenUntil),
        'streaks.freezesAvailable': FieldValue.increment(-1),
      });

      notifyListeners();
      return true;
    } catch (e) {
      logger.e('Error freezing streak', error: e);
      return false;
    }
  }

  // Award streak milestone rewards
  Future<void> _awardStreakRewards(
    String userId,
    StreakReward reward,
    int streakDays,
  ) async {
    try {
      // Award bonus DB
      if (reward.bonusDB > 0) {
        await _dustBunniesService.awardDustBunnies(
          userId: userId,
          action: 'achievement_unlock',
          customAmount: reward.bonusDB,
        );
      }

      // Award bonus entries
      if (reward.bonusEntries > 0) {
        await _firestore.collection('users').doc(userId).update({
          'bonusEntries': FieldValue.increment(reward.bonusEntries),
        });
      }

      // Award premium days
      if (reward.premiumDays != null && reward.premiumDays! > 0) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('rewards')
            .add({
          'type': 'premium_days',
          'days': reward.premiumDays,
          'source': 'streak_milestone_$streakDays',
          'claimed': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Award lifetime premium
      if (reward.lifetimePremium == true) {
        await _firestore.collection('users').doc(userId).update({
          'subscription.lifetimePremium': true,
          'subscription.tier': 'premium',
        });
      }

      // Award badge
      if (reward.badge.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update({
          'gamification.badges.collected':
              FieldValue.arrayUnion([reward.badge]),
        });
      }
    } catch (e) {
      logger.e('Error awarding streak rewards', error: e);
    }
  }

  // Log streak activity for analytics
  Future<void> _logStreakActivity(
    String userId,
    int currentStreak,
    bool streakBroken,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('streakHistory')
          .add({
        'currentStreak': currentStreak,
        'streakBroken': streakBroken,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.e('Error logging streak activity', error: e);
    }
  }

  // Get upcoming streak milestone
  int? getNextMilestone(int currentStreak) {
    for (final milestone in streakMilestones.keys) {
      if (milestone > currentStreak) {
        return milestone;
      }
    }
    return null;
  }

  // Check if user needs to check in today
  Future<bool> needsCheckInToday(String userId) async {
    final data = await getUserStreakData(userId);

    if (data.lastCheckIn == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCheckInDate = DateTime(
      data.lastCheckIn!.year,
      data.lastCheckIn!.month,
      data.lastCheckIn!.day,
    );

    return lastCheckInDate != today;
  }
}
