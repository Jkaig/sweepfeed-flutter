import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/logger.dart';
import 'every_org_service.dart';

class RewardedAdService {
  factory RewardedAdService() => _instance;
  RewardedAdService._internal();
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  // Singleton pattern
  static final RewardedAdService _instance = RewardedAdService._internal();

  final EveryOrgService _everyOrgService = EveryOrgService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int maxAdsPerDay = 10;
  static const double donationPerAd = 0.004; // 30% of ~0.013 est revenue

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
          logger.i('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          logger.e('RewardedAd failed to load', error: error);
          _isAdLoaded = false;
        },
      ),
    );
  }

  /// Shows a rewarded ad and processes the donation to the user's selected charity.
  /// Returns true if the ad was successfully watched, false otherwise.
  Future<bool> showRewardedAd({
    required String userId,
    String? nonprofitSlug,
  }) async {
    if (!_isAdLoaded || _rewardedAd == null) {
      await loadRewardedAd();
      if (!_isAdLoaded || _rewardedAd == null) {
        logger.w('Ad not available');
        return false;
      }
    }

    final completer = Completer<bool>();

    // Get user's selected nonprofit if not provided
    // If null, user skipped charity selection - 100% goes to developer (no donation)
    final effectiveNonprofitSlug = nonprofitSlug ??
        await _getUserSelectedNonprofit(userId);

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
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
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        try {
          // Only process donation if user has selected a charity
          // If null, user skipped charity selection - 100% goes to developer
          if (effectiveNonprofitSlug != null) {
            // Process the donation through EveryOrgService
            await _everyOrgService.processDonation(
              userId: userId,
              nonprofitSlug: effectiveNonprofitSlug,
              amount: donationPerAd,
              source: 'rewarded_ad',
            );
            logger.i('Ad reward processed: \$${donationPerAd.toStringAsFixed(4)} to $effectiveNonprofitSlug');
          } else {
            logger.i('Ad reward processed: No charity selected - 100% to developer');
          }

          // Always update user stats (points, ad count) even without charity
          await _processAdReward(userId, effectiveNonprofitSlug);

          if (!completer.isCompleted) {
            completer.complete(true);
          }
        } catch (e) {
          logger.e('Error processing ad reward', error: e);
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        }
      },
    );

    return completer.future;
  }

  /// Get user's selected nonprofit from Firestore
  Future<String?> _getUserSelectedNonprofit(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['selectedNonprofitSlug'] as String?;
    } catch (e) {
      logger.e('Error getting user nonprofit', error: e);
      return null;
    }
  }

  Future<bool> canShowAd(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final docId = '${userId}_$today';
      
      final doc = await _firestore.collection('ad_limits').doc(docId).get();
      
      if (!doc.exists) return true;
      
      final count = doc.data()?['count'] ?? 0;
      return count < maxAdsPerDay;
    } catch (e) {
      logger.e('Error checking ad limit', error: e);
      return true; // Fail open if error
    }
  }

  Future<void> _processAdReward(String userId, String? nonprofitSlug) async {
    final batch = _firestore.batch();
    final today = DateTime.now().toIso8601String().split('T')[0];

    // 1. Update daily limit count (always)
    final limitRef = _firestore.collection('ad_limits').doc('${userId}_$today');
    batch.set(
      limitRef,
      {
        'count': FieldValue.increment(1),
        'userId': userId,
        'date': today,
      },
      SetOptions(merge: true),
    );

    // 2. Update user stats - always award points, only track charity if selected
    final userRef = _firestore.collection('users').doc(userId);
    final userStats = <String, dynamic>{
      'totalAdsWatched': FieldValue.increment(1),
      'points': FieldValue.increment(50), // Award 50 SweepDust points regardless
    };

    // Only track charity contribution if user selected a charity
    if (nonprofitSlug != null) {
      userStats['totalCharityContributed'] = FieldValue.increment(donationPerAd);
    }

    batch.set(userRef, userStats, SetOptions(merge: true));

    // 3. Update community stats - always track ads watched
    final communityRef = _firestore.collection('stats').doc('community');
    final communityStats = <String, dynamic>{
      'totalAdsWatched': FieldValue.increment(1),
    };

    // Only track donation stats if user selected a charity
    if (nonprofitSlug != null) {
      communityStats['totalDonated'] = FieldValue.increment(donationPerAd);
      communityStats['donationCount'] = FieldValue.increment(1);
    }

    batch.set(communityRef, communityStats, SetOptions(merge: true));

    await batch.commit();
    logger.i(
      'Ad reward stats updated for user: $userId, nonprofit: ${nonprofitSlug ?? "none (100% to developer)"}',
    );
  }
}

// Singleton instance for global access
final rewardedAdService = RewardedAdService();
