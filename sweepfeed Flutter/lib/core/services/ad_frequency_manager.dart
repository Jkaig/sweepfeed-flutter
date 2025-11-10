import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/logger.dart';
import '../../features/charity/widgets/charity_impact_card.dart';
import '../../features/charity/widgets/charity_milestone_card.dart';
import 'rewarded_ad_service.dart';

class AdFrequencyManager {
  static const int AD_FREQUENCY = 3; // Show ad every 3rd entry
  static const int MILESTONE_FREQUENCY = 5; // Show milestone every 5 ads

  Future<bool> shouldShowAd(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final data = doc.data();
      if (data == null) return false;

      final entriesSinceLastAd = data['entriesSinceLastAd'] ?? 0;
      return entriesSinceLastAd >=
          AD_FREQUENCY - 1; // Show on 3rd entry (index 2)
    } catch (e) {
      logger.e('Error checking ad frequency', error: e);
      return false;
    }
  }

  Future<void> recordEntry(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {
          'entriesSinceLastAd': FieldValue.increment(1),
          'totalEntries': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      logger.e('Error recording entry', error: e);
      rethrow;
    }
  }

  Future<void> resetAdCounter(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'entriesSinceLastAd': 0,
      });
    } catch (e) {
      logger.e('Error resetting ad counter', error: e);
    }
  }

  Future<void> handleContestEntry({
    required BuildContext context,
    required String contestId,
    required String charityId,
    required Function() onEntryComplete,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to enter contests')),
      );
      return;
    }

    // Record this entry
    await recordEntry(user.uid);

    // Check if we should show ad
    final showAd = await shouldShowAd(user.uid);

    if (showAd) {
      // Show charity reminder dialog first
      if (context.mounted) {
        final shouldWatch = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1F2E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(
                  Icons.volunteer_activism,
                  color: Color(0xFF00D9FF),
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Support Your Charity',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Watch a short ad to donate to your selected nonprofit!',
                  style: TextStyle(color: Color(0xFFB0B8C1), fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D9FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.monetization_on,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '30% of ad revenue goes to charity',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.stars, color: Color(0xFFFFB800), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Earn 50 SweepDust points',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Skip',
                  style: TextStyle(color: Color(0xFFB0B8C1)),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                  foregroundColor: const Color(0xFF0A0E1A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Watch Ad',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );

        if (shouldWatch != true) {
          return; // User declined to watch ad
        }
      }

      // Show rewarded ad
      final adWatched = await rewardedAdService.showRewardedAd(
        charityId: charityId,
        contestId: contestId,
      );

      if (adWatched) {
        try {
          await resetAdCounter(user.uid);

          // Get user stats for impact card
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          final totalAdsWatched = userDoc.data()?['totalAdsWatched'] ?? 0;
          final points = userDoc.data()?['points'] ?? 0;

          // Show charity impact card
          if (context.mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => CharityImpactCard(
                charityId: charityId,
                donationAmount: 0.013 * 0.30, // 30% of $0.013 ad revenue
                pointsEarned: 50,
              ),
            );
          }

          // Check for milestone (every 5 ads) - only show if it's a milestone
          if (totalAdsWatched > 0 &&
              totalAdsWatched % MILESTONE_FREQUENCY == 0 &&
              context.mounted) {
            // Fetch user rank before showing dialog
            final currentRank = await _getUserRank(user.uid);

            if (context.mounted) {
              await showDialog(
                context: context,
                builder: (context) => CharityMilestoneCard(
                  totalAdsWatched: totalAdsWatched,
                  totalDonated: totalAdsWatched * 0.013 * 0.30,
                  currentRank: currentRank,
                ),
              );
            }
          }

          // Check for daily streak bonus
          await _checkDailyStreak(user.uid);
        } catch (e) {
          logger.e('Error processing ad reward', error: e);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Ad watched, but there was an issue processing rewards. Please contact support.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad not available. Entry recorded for free!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } else {
      // Free entry - just show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Entry recorded! ${AD_FREQUENCY - (await _getEntriesSinceLastAd(user.uid)) - 1} more until next charity contribution',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    // Call completion callback
    onEntryComplete();
  }

  Future<int> _getEntriesSinceLastAd(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc.data()?['entriesSinceLastAd'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getUserRank(String userId) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          .limit(100)
          .get();

      final userIndex =
          usersSnapshot.docs.indexWhere((doc) => doc.id == userId);
      return userIndex >= 0 ? userIndex + 1 : 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _checkDailyStreak(String userId) async {
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final streakDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('streaks')
          .doc('adWatch')
          .get();

      if (!streakDoc.exists) {
        // Initialize streak
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('streaks')
            .doc('adWatch')
            .set({
          'lastDate': todayStr,
          'currentStreak': 1,
          'totalAdsToday': 1,
          'multiplierActive': false,
        });
      } else {
        final data = streakDoc.data()!;
        final lastDate = data['lastDate'] as String?;
        final totalAdsToday = data['totalAdsToday'] ?? 0;

        if (lastDate == todayStr) {
          // Same day - increment today's count
          final newTotal = totalAdsToday + 1;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('streaks')
              .doc('adWatch')
              .update({
            'totalAdsToday': newTotal,
          });

          // Activate 2x multiplier if watched 5 ads today
          if (newTotal >= 5 && !data['multiplierActive']) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('streaks')
                .doc('adWatch')
                .update({
              'multiplierActive': true,
              'multiplierExpiresAt': Timestamp.fromDate(
                DateTime.now().add(const Duration(days: 1)),
              ),
            });

            // Award bonus points
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({
              'points': FieldValue.increment(100), // Bonus 100 points
            });
          }
        } else {
          // New day - reset counter
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('streaks')
              .doc('adWatch')
              .update({
            'lastDate': todayStr,
            'totalAdsToday': 1,
            'multiplierActive': false,
          });
        }
      }
    } catch (e) {
      logger.e('Error checking daily streak', error: e);
    }
  }

  Future<Map<String, dynamic>> getAdStats(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final streakDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('streaks')
          .doc('adWatch')
          .get();

      final userData = userDoc.data() ?? {};
      final streakData = streakDoc.data() ?? {};

      return {
        'entriesSinceLastAd': userData['entriesSinceLastAd'] ?? 0,
        'totalAdsWatched': userData['totalAdsWatched'] ?? 0,
        'totalCharityContributed': userData['totalCharityContributed'] ?? 0.0,
        'adsUntilNext': AD_FREQUENCY - (userData['entriesSinceLastAd'] ?? 0),
        'adsWatchedToday': streakData['totalAdsToday'] ?? 0,
        'multiplierActive': streakData['multiplierActive'] ?? false,
        'adsUntilBonus': 5 - (streakData['totalAdsToday'] ?? 0),
      };
    } catch (e) {
      logger.e('Error getting ad stats', error: e);
      return {};
    }
  }
}

final adFrequencyManager = AdFrequencyManager();
