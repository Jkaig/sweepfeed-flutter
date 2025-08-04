import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../subscription/services/subscription_service.dart';

/// Ad service to manage advertisements in the app
/// Note: This is a placeholder service that would be replaced with actual
/// ad network integration (Google AdMob, Facebook Audience Network, etc.)
class AdService with ChangeNotifier {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Configuration
  static const String _lastAdShownTimeKey = 'last_ad_shown_time';
  static const int _minTimeBetweenAdsSeconds = 60; // 1 minute

  final SubscriptionService _subscriptionService = SubscriptionService();
  DateTime? _lastAdShownTime;
  bool _isAdLoading = false;

  /// Check if ads should be shown (only for free users)
  bool get shouldShowAds => !_subscriptionService.isSubscribed;

  /// Check if an ad is currently loading
  bool get isAdLoading => _isAdLoading;

  /// Minimum time between ads in seconds
  int get minTimeBetweenAdsSeconds => _minTimeBetweenAdsSeconds;

  /// Initialize the ad service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAdShownTimeStr = prefs.getString(_lastAdShownTimeKey);

    if (lastAdShownTimeStr != null) {
      _lastAdShownTime = DateTime.parse(lastAdShownTimeStr);
    }

    // In a real implementation, this would initialize the ad network SDK
    if (kDebugMode) {
      print(
          'AdService initialized. Last ad shown: ${_lastAdShownTime?.toString() ?? 'never'}');
    }
  }

  /// Check if enough time has passed to show another ad
  bool canShowAdNow() {
    if (!shouldShowAds) return false;

    if (_lastAdShownTime == null) return true;

    final now = DateTime.now();
    final difference = now.difference(_lastAdShownTime!).inSeconds;

    return difference >= _minTimeBetweenAdsSeconds;
  }

  /// Simulate loading an ad
  Future<bool> loadAd() async {
    if (!shouldShowAds || !canShowAdNow()) {
      return false;
    }

    _isAdLoading = true;
    notifyListeners();

    // Simulate ad loading delay
    await Future.delayed(const Duration(milliseconds: 1500));

    _isAdLoading = false;
    notifyListeners();

    return true;
  }

  /// Mark that an ad was shown
  Future<void> markAdShown() async {
    _lastAdShownTime = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _lastAdShownTimeKey, _lastAdShownTime!.toIso8601String());

    notifyListeners();
  }

  /// Show an interstitial ad if conditions are met
  Future<bool> showInterstitialAd(BuildContext context) async {
    if (!shouldShowAds || !canShowAdNow()) {
      return false;
    }

    // Load the ad first
    final loaded = await loadAd();
    if (!loaded) return false;

    // In a real implementation, this would show the actual ad
    // For now, we'll just mark it as shown
    await markAdShown();

    return true;
  }
}
