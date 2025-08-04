import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweepstakes/features/ads/services/ad_service.dart';
import 'package:sweepstakes/features/subscription/services/subscription_service.dart';

import 'ad_service_test.mocks.dart';

@GenerateMocks([SubscriptionService])
void main() {
  late AdService adService;
  late MockSubscriptionService mockSubscriptionService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockSubscriptionService = MockSubscriptionService();
    adService = AdService();
    adService._subscriptionService = mockSubscriptionService;
    await adService.initialize();
  });

  tearDown(() {
    adService._lastAdShownTime = null;
  });

  group('AdService', () {
    test('shouldShowAds returns true when user is not subscribed', () {
      when(mockSubscriptionService.isSubscribed).thenReturn(false);
      expect(adService.shouldShowAds, true);
    });

    test('shouldShowAds returns false when user is subscribed', () {
      when(mockSubscriptionService.isSubscribed).thenReturn(true);
      expect(adService.shouldShowAds, false);
    });

    test('isAdLoading returns correct value', () async {
      expect(adService.isAdLoading, false);
      adService.loadAd();
      expect(adService.isAdLoading, true);
      await Future.delayed(const Duration(milliseconds: 2000));
      expect(adService.isAdLoading, false);
    });

     test('isInterstitialAdLoading returns correct value', () async {
      expect(adService.isInterstitialAdLoading, false);
      adService.loadInterstitialAd();
      expect(adService.isInterstitialAdLoading, true);
      await Future.delayed(const Duration(milliseconds: 2000));
      expect(adService.isInterstitialAdLoading, false);
    });

    test('minTimeBetweenAdsSeconds returns correct value', () {
      expect(adService.minTimeBetweenAdsSeconds, 60);
    });

    test('initialize sets lastAdShownTime from SharedPreferences', () async {
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_ad_shown_time', now.toIso8601String());

      await adService.initialize();

      expect(adService._lastAdShownTime?.toIso8601String(), now.toIso8601String());
    });

    test('canShowAdNow returns true if last ad shown time is null', () {
      adService._lastAdShownTime = null;
      when(mockSubscriptionService.isSubscribed).thenReturn(false);
      expect(adService.canShowAdNow(), true);
    });

    test('canShowAdNow returns false if user is subscribed', () {
      when(mockSubscriptionService.isSubscribed).thenReturn(true);
      expect(adService.canShowAdNow(), false);
    });

    test('canShowAdNow returns true if enough time has passed', () async {
      final now = DateTime.now();
      adService._lastAdShownTime = now.subtract(const Duration(seconds: 61));
      when(mockSubscriptionService.isSubscribed).thenReturn(false);
      expect(adService.canShowAdNow(), true);
    });

    test('canShowAdNow returns false if not enough time has passed', () {
      final now = DateTime.now();
      adService._lastAdShownTime = now.subtract(const Duration(seconds: 30));
      when(mockSubscriptionService.isSubscribed).thenReturn(false);
      expect(adService.canShowAdNow(), false);
    });

    test('loadAd returns true when ad can be shown', () async {
      when(mockSubscriptionService.isSubscribed).thenReturn(false);
      expect(await adService.loadAd(), true);
    });

     test('loadInterstitialAd returns true when ad can be shown', () async {
      when(mockSubscriptionService.isSubscribed).thenReturn(false);
      expect(await adService.loadInterstitialAd(), true);
    });

    test('loadAd returns false when user is subscribed', () async {
      when(mockSubscriptionService.isSubscribed).thenReturn(true);
      expect(await adService.loadAd(), false);
    });

    test('loadInterstitialAd returns false when user is subscribed', () async {
      when(mockSubscriptionService.isSubscribed).thenReturn(true);
      expect(await adService.loadInterstitialAd(), false);
    });

    test('loadAd returns false when not enough time has passed', () async {
      final now = DateTime.now();
      adService._lastAdShownTime = now;
      when(mockSubscriptionService.isSubscribed).thenReturn(false);
      expect(await adService.loadAd(), false);
    });
    test('loadInterstitialAd returns false when not enough time has passed', () async {
      final now = DateTime.now();
      adService._lastAdShownTime = now;
      when(mockSubscriptionService.isSubscribed).thenReturn(false);
      expect(await adService.loadInterstitialAd(), false);
    });

    test('markAdShown updates lastAdShownTime and saves it to SharedPreferences',
        () async {
      final beforeMark = DateTime.now();
      await adService.markAdShown();
      final afterMark = DateTime.now();

      expect(adService._lastAdShownTime!.isAfter(beforeMark), true);
      expect(adService._lastAdShownTime!.isBefore(afterMark), true);

      final prefs = await SharedPreferences.getInstance();
      final savedTime = prefs.getString('last_ad_shown_time');
      expect(savedTime, adService._lastAdShownTime!.toIso8601String());
    });
     test('showInterstitialAd returns false if not enough time has passed', () async {
      final now = DateTime.now();
      adService._lastAdShownTime = now;
      when(mockSubscriptionService.isSubscribed).thenReturn(false);
      expect(await adService.showInterstitialAd(null), false);
    });
    test('showInterstitialAd returns true if can show ad', () async {
      adService._lastAdShownTime = DateTime.now().subtract(const Duration(seconds: 61));
      when(mockSubscriptionService.isSubscribed).thenReturn(false);
      expect(await adService.showInterstitialAd(null), true);
    });
  });
}