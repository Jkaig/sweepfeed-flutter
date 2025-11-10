import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/logger.dart';

import 'every_org_service.dart';

class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  Function(String charityId, double amount)? onAdCompleted;
  final EveryOrgService _everyOrgService = EveryOrgService();

  static const int maxAdsPerDay = 10;

  // Ad Unit IDs (replace with your actual IDs)
  String get _adUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
          _setupAdCallbacks();
        },
        onAdFailedToLoad: (error) {
          logger.e('RewardedAd failed to load', error: error);
          _isAdLoaded = false;
        },
      ),
    );
  }

  void _setupAdCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isAdLoaded = false;
        loadRewardedAd(); // Preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        logger.e('Failed to show rewarded ad', error: error);
        ad.dispose();
        _isAdLoaded = false;
        loadRewardedAd();
      },
    );
  }

  Future<bool> canShowAd(String userId) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final data = userDoc.data();
      if (data == null) return true;

      final lastAdDate = data['lastAdDate'] as String?;
      final dailyAdCount = data['dailyAdCount'] as int? ?? 0;

      if (lastAdDate != todayStr) {
        return true;
      }

      return dailyAdCount < maxAdsPerDay;
    } catch (e) {
      logger.e('Error checking ad limit', error: e);
      return true;
    }
  }

  Future<bool> showRewardedAd({
    required String charityId,
    required String contestId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final canShow = await canShowAd(user.uid);
    if (!canShow) {
      logger.i('Daily ad limit reached');
      return false;
    }

    if (!_isAdLoaded || _rewardedAd == null) {
      logger.w('Rewarded ad not loaded yet');
      return false;
    }

    var adCompleted = false;

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        adCompleted = true;
        await _processAdReward(charityId, contestId);
      },
    );

    return adCompleted;
  }

  Future<void> _processAdReward(String nonprofitSlug, String contestId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();

    // Ad watch revenue estimate (typical CPM $10-18 = $0.01-0.018 per view)
    const adRevenue = 0.013;
    const charityPercentage = 0.30; // 30% to charity
    const charityDonation = adRevenue * charityPercentage;

    // Award sweep points (higher than typical to incentivize)
    const pointsEarned = 50;

    // Process donation through Every.org
    try {
      await _everyOrgService.processDonation(
        userId: user.uid,
        nonprofitSlug: nonprofitSlug,
        amount: charityDonation,
        source: 'rewarded_ad',
      );
    } catch (e) {
      logger.e('Error processing Every.org donation', error: e);
    }

    // Update user stats and daily ad tracking
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userRef.get();
    final userData = userDoc.data();
    final lastAdDate = userData?['lastAdDate'] as String?;

    final updates = <String, dynamic>{
      'points': FieldValue.increment(pointsEarned),
      'totalAdsWatched': FieldValue.increment(1),
      'totalCharityContributed': FieldValue.increment(charityDonation),
      'lastAdWatchedAt': FieldValue.serverTimestamp(),
      'lastAdDate': todayStr,
    };

    if (lastAdDate == todayStr) {
      updates['dailyAdCount'] = FieldValue.increment(1);
    } else {
      updates['dailyAdCount'] = 1;
    }

    batch.update(userRef, updates);

    // Track ad watch with Every.org nonprofit slug
    final adWatchRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('adWatches')
        .doc();
    batch.set(adWatchRef, {
      'contestId': contestId,
      'nonprofitSlug': nonprofitSlug,
      'charityAmount': charityDonation,
      'pointsEarned': pointsEarned,
      'watchedAt': FieldValue.serverTimestamp(),
      'source': 'rewarded_ad',
    });

    // Update daily streak (reuse existing today/todayStr variables)
    final streakRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('streaks')
        .doc('adWatch');
    batch.set(
      streakRef,
      {
        'lastDate': todayStr,
        'currentStreak': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    try {
      await batch.commit();
      onAdCompleted?.call(nonprofitSlug, charityDonation);
    } catch (e) {
      logger.e('Error processing ad reward', error: e);
    }
  }

  bool get isAdLoaded => _isAdLoaded;

  void dispose() {
    _rewardedAd?.dispose();
    _isAdLoaded = false;
  }
}

// Singleton instance
final rewardedAdService = RewardedAdService();
