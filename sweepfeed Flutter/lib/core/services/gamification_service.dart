import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // For IconData

import '../../features/auth/services/auth_service.dart'; // To call awardBadge
import '../models/reward_model.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

// --- DEPRECATED: DustBunniesService ---
// This service is deprecated in favor of DustBunniesService.
// Migration Timeline:
// - Phase 1 (Current): Service marked as @Deprecated, writes disabled
// - Phase 2 (Q1 2026): Data migration Cloud Function deployed
// - Phase 3 (Q2 2026): Reads disabled, service removed entirely
//
// DO NOT USE THIS SERVICE FOR NEW FEATURES.
// Use DustBunniesService instead: lib/core/services/dust_bunnies_service.dart
//
// Migration Guide: See GAMIFICATION_MIGRATION.md

// --- Daily Challenge Definition ---
@Deprecated(
    'Use DustBunniesService reward system instead. This class will be removed in Q2 2026.')
class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.goal,
    required this.reward,
  });
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int goal;
  final int reward;
}

// --- Point Constants ---
@Deprecated(
    'Use DustBunniesConstants instead. This class will be removed in Q2 2026.')
class Points {
  static const int dailyLogin = 10;
  static const int contestEntry = 5;
  static const int profileCompletion = 50;
  static const int successfulReferral = 100;
}

// --- Level Thresholds ---
// A simple linear progression for demonstration.
// This could be replaced with a more complex curve.
@Deprecated(
    'Use DustBunniesService.getDustBunniesRequiredForLevel() instead. This function will be removed in Q2 2026.')
int pointsForLevel(int level) => level * 100;

// --- Badge Definition ---
@Deprecated(
    'Use DustBunniesService badge system instead. This class will be removed in Q2 2026.')
class Badge {
  // Using IconData for placeholder icons

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
  final String id;
  final String name;
  final String description;
  final IconData icon;
}

// --- Badge Definitions ---
// It's good practice to define badge IDs as constants as well.
@Deprecated(
    'Use DustBunniesService badge system instead. This class will be removed in Q2 2026.')
class BadgeIds {
  static const String welcomeAboard = 'welcome_aboard';
  static const String entryEnthusiast = 'entry_enthusiast';
  static const String referralRockstar = 'referral_rockstar';
  static const String sharpshooter = 'sharpshooter';
  // Add more badge IDs here if needed, e.g., dailyDedication
}

@Deprecated(
    'Use DustBunniesService instead. This service will be removed in Q2 2026. See GAMIFICATION_MIGRATION.md for migration guide.')
class GamificationService {
  GamificationService(this._authService);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Assuming AuthService is a singleton or provided via DI.
  // For simplicity, creating an instance here, but DI is preferred in larger apps.
  final AuthService _authService;

  // --- Point and Level Management ---

  /// Checks if user has claimed daily login bonus today (UTC-based)
  Future<bool> hasClaimedDailyLoginToday(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data();
      final lastLoginDateStr = data?['lastDailyLoginClaim'] as String?;

      if (lastLoginDateStr == null) return false;

      DateTime? lastLoginDate;
      try {
        lastLoginDate = DateTime.parse(lastLoginDateStr);
      } catch (e) {
        logger.e('Error parsing lastDailyLoginClaim date', error: e);
        return false;
      }

      final now = DateTime.now().toUtc();
      final lastLoginDateUtc = lastLoginDate.toUtc();

      return lastLoginDateUtc.year == now.year &&
          lastLoginDateUtc.month == now.month &&
          lastLoginDateUtc.day == now.day;
    } catch (e) {
      logger.e('Error checking daily login claim', error: e);
      return false;
    }
  }

  /// Awards daily login bonus if not already claimed today (UTC-based)
  Future<bool> awardDailyLoginBonus(String userId) async {
    final hasClaimedToday = await hasClaimedDailyLoginToday(userId);
    if (hasClaimedToday) return false;

    final now = DateTime.now().toUtc();
    final todayStr = now.toIso8601String();

    try {
      await _firestore.collection('users').doc(userId).update({
        'lastDailyLoginClaim': todayStr,
      });

      await awardPoints(userId, Points.dailyLogin, 'Daily Login Bonus');
      logger.i('Awarded daily login bonus to user: $userId');
      return true;
    } catch (e) {
      logger.e('Error awarding daily login bonus', error: e);
      return false;
    }
  }

  /// Awards DustBunnies to a user for a specific action and checks for level ups.
  /// This is the unified method for all DB awards.
  Future<void> awardPoints(String userId, int points, String reason) async {
    final userRef = _firestore.collection('users').doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) return;

        final userProfile = UserProfile.fromFirestore(userDoc);

        // Use FieldValue.increment to prevent race conditions
        transaction.update(userRef, {
          'points': FieldValue.increment(points),
        });

        // Log the transaction for user history
        final pointsTransactionRef =
            userRef.collection('pointsTransactions').doc();
        transaction.set(pointsTransactionRef, {
          'amount': points,
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Calculate new points for level check
        final newPoints = userProfile.points + points;
        await _checkForLevelUp(
          transaction,
          userRef,
          userProfile.level,
          newPoints,
        );
      });
      logger.i('Awarded $points DustBunnies to user: $userId for: $reason');
    } catch (e) {
      logger.e('Error awarding DustBunnies to user: $userId', error: e);
    }
  }

  /// Checks if the user's new point total qualifies for a level up.
  /// Handles multiple level-ups if user gains enough points at once.
  Future<void> _checkForLevelUp(
    Transaction transaction,
    DocumentReference userRef,
    int currentLevel,
    int newPoints,
  ) async {
    int nextLevel = currentLevel + 1;

    while (newPoints >= pointsForLevel(nextLevel)) {
      transaction.update(userRef, {'level': nextLevel});
      logger.i('User ${userRef.id} leveled up to level $nextLevel!');
      nextLevel++;
    }
  }

  // --- Badge Management ---

  static final List<Reward> allRewards = [
    Reward(
      id: 'extra_entries_1',
      name: '5 Extra Daily Entries',
      description: 'Get 5 bonus entries every day.',
      pointsRequired: 500,
      imageUrl: '', // Add image URL later
    ),
    Reward(
      id: 'power_user_badge',
      name: 'Power User Badge',
      description: 'Show off your status with a special profile badge.',
      pointsRequired: 1000,
      imageUrl: '', // Add image URL later
    ),
  ];

  static final List<DailyChallenge> allDailyChallenges = [
    const DailyChallenge(
      id: 'enter_3_sweepstakes',
      name: 'Enter 3 Sweepstakes',
      description:
          'Dive into the fun and enter any three sweepstakes to complete this challenge.',
      icon: Icons.star_border,
      goal: 3,
      reward: 50,
    ),
    const DailyChallenge(
      id: 'share_a_sweepstake',
      name: 'Share a Sweepstake',
      description: 'Spread the word! Share a sweepstake with a friend.',
      icon: Icons.share_outlined,
      goal: 1,
      reward: 25,
    ),
    const DailyChallenge(
      id: 'watch_a_video_ad',
      name: 'Watch a Video Ad',
      description: 'Watch a short video ad to earn a quick reward.',
      icon: Icons.slideshow,
      goal: 1,
      reward: 15,
    ),
  ];

  // List of all available badges in the app
  static final List<Badge> allBadges = [
    const Badge(
      id: BadgeIds.welcomeAboard,
      name: 'Welcome Aboard!',
      description: 'Awarded for successfully creating your SweepFeed account.',
      icon: Icons.sailing_outlined,
    ),
    const Badge(
      id: BadgeIds.entryEnthusiast,
      name: 'Entry Enthusiast',
      description: 'Awarded for entering 10 contests.',
      icon: Icons.star_outline,
    ),
    const Badge(
      id: BadgeIds.referralRockstar,
      name: 'Referral Rockstar',
      description: 'Awarded for successfully referring 5 friends.',
      icon: Icons.people_alt_outlined,
    ),
    const Badge(
      id: BadgeIds.sharpshooter,
      name: 'Sharpshooter',
      description: 'Awarded for completely filling out your user profile.',
      icon: Icons.person_pin_circle_outlined,
    ),
    // Example for a daily check-in badge (if feature existed)
    // const Badge(
    //   id: 'daily_dedication',
    //   name: 'Daily Dedication',
    //   description: 'Awarded for 7 consecutive daily check-ins.',
    //   icon: Icons.calendar_today_outlined,
    // ),
  ];

  // Helper to get badge metadata by ID
  static Badge? getBadgeById(String badgeId) {
    try {
      return allBadges.firstWhere((badge) => badge.id == badgeId);
    } catch (e) {
      return null; // Badge ID not found
    }
  }

  Future<List<DailyChallenge>> getDailyChallengesForUser(String userId) async {
    // For now, returning the static list.
    // Later, this can be extended to fetch user-specific progress.
    return allDailyChallenges;
  }

  Future<void> claimChallengeReward(String userId, String challengeId) async {
    final challenge = allDailyChallenges.firstWhere((c) => c.id == challengeId);
    await awardPoints(
      userId,
      challenge.reward,
      'Daily Challenge: ${challenge.name}',
    );
    // Here you would also mark the challenge as claimed for the user in Firestore.
  }

  /// @deprecated Use awardPoints() instead - this is kept for backward compatibility
  Future<void> awardSweepDust(String userId, int amount, String reason) async {
    await awardPoints(userId, amount, reason);
  }

  Future<DocumentSnapshot?> _getUserDocument(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc : null;
    } catch (e) {
      logger.e('Error fetching user document for gamification', error: e);
      return null;
    }
  }

  Future<List<String>> _getCollectedBadges(String userId) async {
    final userDoc = await _getUserDocument(userId);
    if (userDoc != null && userDoc.data() != null) {
      final data = userDoc.data()! as Map<String, dynamic>;
      // Path to badges: gamification -> badges -> collected
      final gamificationData = data['gamification'] as Map<String, dynamic>?;
      final badgesData = gamificationData?['badges'] as Map<String, dynamic>?;
      final collected = badgesData?['collected'] as List<dynamic>?;
      return collected?.map((item) => item.toString()).toList() ?? [];
    }
    return [];
  }

  Future<void> _checkAndAward(
    String userId,
    String badgeId,
    bool criteriaMet,
  ) async {
    if (!criteriaMet) return;

    final collectedBadges = await _getCollectedBadges(userId);
    if (!collectedBadges.contains(badgeId)) {
      // User hasn't collected this badge yet, award it.
      // AuthService.awardBadge also handles adding points.
      await _authService.awardBadge(badgeId);
      logger.i('Awarded badge: $badgeId to user: $userId');
      // Optionally, show an in-app notification here.
    }
  }

  // --- Specific Badge Checking Methods ---

  Future<void> checkAndAwardWelcomeAboard(String userId) async {
    // This badge is typically awarded right after account creation.
    // The criteria is simply that the user exists.
    await _checkAndAward(userId, BadgeIds.welcomeAboard, true);
  }

  Future<void> checkAndAwardEntryEnthusiast(String userId) async {
    final userDoc = await _getUserDocument(userId);
    if (userDoc == null) return;
    final data = userDoc.data()! as Map<String, dynamic>;
    final totalEntries = data['stats']?['totalEntries'] as int? ?? 0;
    await _checkAndAward(userId, BadgeIds.entryEnthusiast, totalEntries >= 10);
  }

  Future<void> checkAndAwardReferralRockstar(String userId) async {
    // This check should ideally be triggered when a referral is confirmed and count is updated.
    final userDoc = await _getUserDocument(userId);
    if (userDoc == null) return;
    final data = userDoc.data()! as Map<String, dynamic>;
    final referralCount = data['referralCount'] as int? ??
        0; // Assuming 'referralCount' is at the root
    await _checkAndAward(userId, BadgeIds.referralRockstar, referralCount >= 5);
  }

  /// Checks if profile is complete and awards bonus if not already claimed
  Future<bool> checkAndAwardProfileCompletionBonus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      final hasClaimedBonus =
          userData?['profileCompletionBonusClaimed'] as bool? ?? false;

      if (hasClaimedBonus) return false;

      // Check if profile is complete
      final name = userData?['name'] as String?;
      final profilePictureUrl = userData?['profilePictureUrl'] as String?;
      final bio = userData?['bio'] as String?;

      final isComplete = (name != null && name.isNotEmpty) &&
          (profilePictureUrl != null && profilePictureUrl.isNotEmpty) &&
          (bio != null && bio.isNotEmpty);

      if (!isComplete) return false;

      // Profile is complete and bonus not claimed - award it!
      await _firestore.collection('users').doc(userId).update({
        'profileCompletionBonusClaimed': true,
      });

      await awardPoints(
        userId,
        Points.profileCompletion,
        'Profile Completion Bonus',
      );
      logger.i('Awarded profile completion bonus to user: $userId');
      return true;
    } catch (e) {
      logger.e('Error checking profile completion bonus', error: e);
      return false;
    }
  }

  Future<void> checkAndAwardSharpshooter(String userId) async {
    // This requires fetching the user's profile data to check for completeness.
    // The definition of "complete" needs to be established.
    // Let's assume it means having a bio, location, and at least one interest.
    // This would use the 'userProfiles' collection, not the 'users' collection directly for these fields.

    // For 'userProfiles' data:
    final userProfileDoc =
        await _firestore.collection('userProfiles').doc(userId).get();
    var isProfileComplete = false;
    if (userProfileDoc.exists) {
      final profileData = userProfileDoc.data()!;
      final bio = profileData['bio'] as String?;
      final location = profileData['location'] as String?;
      final interests = profileData['interests'] as List<dynamic>?;

      isProfileComplete = (bio != null && bio.isNotEmpty) &&
          (location != null && location.isNotEmpty) &&
          (interests != null && interests.isNotEmpty);
    }

    // Now, check and award the badge based on this completeness.
    // The badge itself is stored in the 'users' collection under 'gamification.badges.collected'.
    await _checkAndAward(userId, BadgeIds.sharpshooter, isProfileComplete);
  }

  // Example for Daily Dedication (if such a feature existed)
  // Future<void> checkAndAwardDailyDedication(String userId, int consecutiveCheckIns) async {
  //   await _checkAndAward(userId, 'daily_dedication', consecutiveCheckIns >= 7);
  // }

  /// Claims a reward for the user by deducting cost from their points
  Future<bool> claimReward(String userId, String rewardId, int cost) async {
    try {
      logger.i(
          'Attempting to claim reward: $rewardId for user: $userId with cost: $cost');

      // 1. Get user document
      final userDocRef = _firestore.collection('users').doc(userId);
      final userDocSnapshot = await userDocRef.get();

      if (!userDocSnapshot.exists) {
        logger.e('User document does not exist for user: $userId');
        return false; // User doesn't exist
      }

      final userData = userDocSnapshot.data() as Map<String, dynamic>?;
      if (userData == null) {
        logger.e('User document data is null for user: $userId');
        return false;
      }

      // Ensure 'points' field exists, otherwise initialize it to 0
      final currentPoints = (userData['points'] as int?) ?? 0;

      // 2. Check if user has enough points
      if (currentPoints < cost) {
        logger.w(
            'User $userId does not have enough points to claim reward $rewardId. Required: $cost, Current: $currentPoints');
        return false; // Not enough points
      }

      // 3. Deduct cost from user's points and mark reward as claimed in a transaction
      return await _firestore.runTransaction((transaction) async {
        // Refresh user data within the transaction to prevent conflicts
        final transactionUserDocSnapshot = await transaction.get(userDocRef);
        final transactionUserData =
            transactionUserDocSnapshot.data() as Map<String, dynamic>?;

        if (transactionUserData == null) {
          logger.e(
              'User document data is null within transaction for user: $userId');
          return false;
        }

        // Refresh points within the transaction
        final transactionCurrentPoints =
            (transactionUserData['points'] as int?) ?? 0;

        // Double check enough points within transaction for concurrency safety
        if (transactionCurrentPoints < cost) {
          logger.w(
              'User $userId does not have enough points to claim reward $rewardId inside transaction. Required: $cost, Current: $transactionCurrentPoints');
          return false;
        }

        final newPoints = transactionCurrentPoints - cost;

        // Update user points and add reward to claimed rewards array
        transaction.update(userDocRef, {
          'points': newPoints,
          'claimedRewards': FieldValue.arrayUnion([rewardId])
        });

        return true; // Transaction succeeded
      }).then((result) {
        if (result == true) {
          logger.i(
              'Reward $rewardId claimed successfully by user $userId. New points: ${currentPoints - cost}');
          return true;
        } else {
          logger.w(
              'Reward $rewardId claim failed for user $userId within transaction.');
          return false;
        }
      }).catchError((error) {
        logger.e(
            'Transaction failed when claiming Reward $rewardId for user $userId: $error');
        return false;
      });
    } catch (e) {
      logger.e('Error claiming reward $rewardId for user $userId: $e');
      return false;
    }
  }
}
