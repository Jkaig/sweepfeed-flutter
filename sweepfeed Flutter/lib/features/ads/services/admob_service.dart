import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/utils/logger.dart';

class AdMobService {
  factory AdMobService() => _instance;
  AdMobService._internal();
  static final AdMobService _instance = AdMobService._internal();

  // Test Ad Unit IDs (Replace with your production IDs)
  static const String _androidBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';

  static const String _androidInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  static const String _androidRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  static const String _androidNativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _iosNativeAdUnitId =
      'ca-app-pub-3940256099942544/3986624511';

  // Ad instances
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  NativeAd? _nativeAd;

  // Ad state
  bool _isBannerAdReady = false;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;
  bool _isNativeAdReady = false;

  // Callbacks
  Function? _onRewardedAdComplete;
  Function? _onInterstitialAdClosed;

  // Get platform-specific ad unit IDs
  String get bannerAdUnitId {
    if (kIsWeb) return '';
    return Platform.isAndroid ? _androidBannerAdUnitId : _iosBannerAdUnitId;
  }

  String get interstitialAdUnitId {
    if (kIsWeb) return '';
    return Platform.isAndroid
        ? _androidInterstitialAdUnitId
        : _iosInterstitialAdUnitId;
  }

  String get rewardedAdUnitId {
    if (kIsWeb) return '';
    return Platform.isAndroid ? _androidRewardedAdUnitId : _iosRewardedAdUnitId;
  }

  String get nativeAdUnitId {
    if (kIsWeb) return '';
    return Platform.isAndroid ? _androidNativeAdUnitId : _iosNativeAdUnitId;
  }

  // Initialize Mobile Ads SDK
  Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      await MobileAds.instance.initialize();

      // Configure test device IDs (remove in production)
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: ['YOUR_TEST_DEVICE_ID']),
      );

      logger.i('AdMob SDK initialized successfully');

      // Preload ads
      loadBannerAd();
      loadInterstitialAd();
      loadRewardedAd();
    } catch (e) {
      logger.e('Failed to initialize AdMob SDK', error: e);
    }
  }

  // Banner Ad Methods
  void loadBannerAd() {
    if (kIsWeb) return;

    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isBannerAdReady = true;
          logger.d('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          logger.e('Banner ad failed to load: ${error.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
        onAdOpened: (ad) => logger.d('Banner ad opened'),
        onAdClosed: (ad) => logger.d('Banner ad closed'),
      ),
    );

    _bannerAd?.load();
  }

  BannerAd? getBannerAd() => _isBannerAdReady ? _bannerAd : null;

  // Interstitial Ad Methods
  void loadInterstitialAd() {
    if (kIsWeb) return;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          logger.d('Interstitial ad loaded');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              logger.d('Interstitial ad dismissed');
              _onInterstitialAdClosed?.call();
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd(); // Preload next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              logger.e('Interstitial ad failed to show: ${error.message}');
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          logger.e('Interstitial ad failed to load: ${error.message}');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  Future<void> showInterstitialAd({Function? onAdClosed}) async {
    if (!_isInterstitialAdReady || _interstitialAd == null) {
      logger.w('Interstitial ad not ready');
      onAdClosed?.call();
      return;
    }

    _onInterstitialAdClosed = onAdClosed;
    await _interstitialAd!.show();
  }

  // Rewarded Ad Methods
  void loadRewardedAd() {
    if (kIsWeb) return;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          logger.d('Rewarded ad loaded');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              logger.d('Rewarded ad dismissed');
              ad.dispose();
              _isRewardedAdReady = false;
              loadRewardedAd(); // Preload next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              logger.e('Rewarded ad failed to show: ${error.message}');
              ad.dispose();
              _isRewardedAdReady = false;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          logger.e('Rewarded ad failed to load: ${error.message}');
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  Future<void> showRewardedAd({
    required Function(int amount) onUserEarnedReward,
    Function? onAdClosed,
  }) async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      logger.w('Rewarded ad not ready');
      onAdClosed?.call();
      return;
    }

    _onRewardedAdComplete = onAdClosed;

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        logger.i('User earned reward: ${reward.amount} ${reward.type}');
        onUserEarnedReward(reward.amount.toInt());
      },
    );
  }

  // Native Ad Methods
  void loadNativeAd({required Function onAdLoaded}) {
    if (kIsWeb) return;

    _nativeAd = NativeAd(
      adUnitId: nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _isNativeAdReady = true;
          logger.d('Native ad loaded');
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          logger.e('Native ad failed to load: ${error.message}');
          _isNativeAdReady = false;
          ad.dispose();
        },
        onAdOpened: (ad) => logger.d('Native ad opened'),
        onAdClosed: (ad) => logger.d('Native ad closed'),
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: const Color(0xFF0A1929),
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF64FFDA),
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white60,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
    );

    _nativeAd?.load();
  }

  NativeAd? getNativeAd() => _isNativeAdReady ? _nativeAd : null;

  // Check ad availability
  bool get isBannerAdReady => _isBannerAdReady;
  bool get isInterstitialAdReady => _isInterstitialAdReady;
  bool get isRewardedAdReady => _isRewardedAdReady;
  bool get isNativeAdReady => _isNativeAdReady;

  // Dispose ads
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _nativeAd?.dispose();
  }
}
