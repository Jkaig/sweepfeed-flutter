import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/utils/logger.dart';
import '../models/subscription_tiers.dart';
import 'tier_management_service.dart';

class RevenueCatService with ChangeNotifier {
  RevenueCatService(this._ref);

  final Ref _ref;
  bool _isConfigured = false;
  CustomerInfo? _customerInfo;

  static String get _revenueCatApiKeyAndroid =>
      dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? '';
  static String get _revenueCatApiKeyIOS =>
      dotenv.env['REVENUECAT_IOS_API_KEY'] ?? '';

  static const String entitlementIdBasic = 'basic_access';
  static const String entitlementIdPremium = 'premium_access';

  Future<void> initialize(String userId) async {
    if (_isConfigured) return;

    if (!_validateUserId(userId)) {
      debugPrint('Invalid userId format: $userId');
      return;
    }

    try {
      final apiKey = _getApiKey();
      if (apiKey.isEmpty) {
        debugPrint('RevenueCat API key not configured');
        return;
      }

      final configuration = PurchasesConfiguration(apiKey)
        ..appUserID = userId
        ..observerMode = false;

      await Purchases.configure(configuration);
      _isConfigured = true;

      await _updateCustomerInfo();

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _customerInfo = customerInfo;
        _syncWithTierManagement();
        notifyListeners();
      });

      debugPrint('RevenueCat initialized for user: $userId');
    } catch (e) {
      debugPrint('Failed to initialize RevenueCat: $e');
    }
  }

  bool _validateUserId(String userId) {
    if (userId.isEmpty || userId.length > 255) return false;
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(userId);
  }

  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings;
    } on PlatformException catch (e) {
      debugPrint('Error fetching offerings: ${e.message}');
      return null;
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      _customerInfo = customerInfo;

      // Sync with tier management (with error handling)
      try {
        await _syncWithTierManagement();
      } catch (e) {
        logger.w('Tier management sync failed after purchase', error: e);
        // Continue with purchase success - sync failure shouldn't block purchase
      }

      // Log purchase analytics (with error handling)
      try {
        await FirebaseAnalytics.instance.logPurchase(
          value: package.storeProduct.price,
          currency: package.storeProduct.currencyCode,
          parameters: {
            'package_id': package.identifier,
            'product_id': package.storeProduct.identifier,
          },
        );
      } catch (e) {
        logger.w('Analytics logging failed after purchase', error: e);
        // Continue with purchase success - analytics failure shouldn't block purchase
      }

      notifyListeners();
      logger.i(
          'Purchase completed successfully. package_id: ${package.identifier}, product_id: ${package.storeProduct.identifier}');
      return true;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        logger.i('User cancelled purchase');
        return false; // User action, not an error
      } else if (errorCode == PurchasesErrorCode.storeProblemError) {
        logger.e('Store problem during purchase', error: e);
        throw PaymentError(
            'Store is temporarily unavailable. Please try again later.',
            rawError: e);
      } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
        logger.e('Purchase not allowed', error: e);
        throw PaymentError(
            'Purchase not allowed. Please check your payment method.',
            rawError: e);
      } else if (errorCode == PurchasesErrorCode.purchaseInvalidError) {
        logger.e('Invalid purchase attempt', error: e);
        throw PaymentError('Invalid purchase. Please try again.', rawError: e);
      } else {
        logger.e('Unexpected purchase error', error: e);
        throw PaymentError('Purchase failed. Please try again.', rawError: e);
      }
    } catch (e) {
      logger.e('Unexpected error during purchase', error: e);
      throw AppError.fromException(
        e,
        context: 'purchasePackage',
        customMessage: 'Purchase failed. Please try again.',
      );
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;

      await _syncWithTierManagement();
      notifyListeners();

      return customerInfo.entitlements.active.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint('Error restoring purchases: ${e.message}');
      return false;
    }
  }

  SubscriptionTier getCurrentTier() {
    if (_customerInfo == null) {
      return SubscriptionTier.free;
    }

    final entitlements = _customerInfo!.entitlements.active;

    if (entitlements.containsKey(entitlementIdPremium)) {
      return SubscriptionTier.premium;
    } else if (entitlements.containsKey(entitlementIdBasic)) {
      return SubscriptionTier.basic;
    }

    return SubscriptionTier.free;
  }

  bool hasActiveSubscription() {
    return _customerInfo?.entitlements.active.isNotEmpty ?? false;
  }

  DateTime? getSubscriptionExpirationDate() {
    if (_customerInfo == null) return null;

    final entitlements = _customerInfo!.entitlements.active;

    if (entitlements.containsKey(entitlementIdPremium)) {
      return entitlements[entitlementIdPremium]?.expirationDate;
    } else if (entitlements.containsKey(entitlementIdBasic)) {
      return entitlements[entitlementIdBasic]?.expirationDate;
    }

    return null;
  }

  bool isInTrialPeriod() {
    if (_customerInfo == null) return false;

    final entitlements = _customerInfo!.entitlements.active;

    for (final entitlement in entitlements.values) {
      if (entitlement.periodType == PeriodType.trial) {
        return true;
      }
    }

    return false;
  }

  Future<void> _updateCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      await _syncWithTierManagement();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating customer info: $e');
    }
  }

  Future<void> _syncWithTierManagement() async {
    final tierService = _ref.read(tierManagementServiceProvider);
    final currentTier = getCurrentTier();

    await tierService.updateUserTier(currentTier);

    await FirebaseAnalytics.instance.setUserProperty(
      name: 'subscription_tier',
      value: currentTier.name,
    );
  }

  String _getApiKey() {
    if (Platform.isAndroid) {
      if (_revenueCatApiKeyAndroid.isEmpty) {
        debugPrint(
            'RevenueCat Android API Key missing. Set REVENUECAT_ANDROID_API_KEY in .env');
      }
      return _revenueCatApiKeyAndroid;
    } else if (Platform.isIOS) {
      if (_revenueCatApiKeyIOS.isEmpty) {
        debugPrint(
            'RevenueCat iOS API Key missing. Set REVENUECAT_IOS_API_KEY in .env');
      }
      return _revenueCatApiKeyIOS;
    }
    debugPrint('Unsupported platform for RevenueCat');
    return '';
  }

  Future<void> dispose() async {
    await Purchases.close();
    super.dispose();
  }
}

final revenueCatServiceProvider =
    ChangeNotifierProvider<RevenueCatService>((ref) {
  return RevenueCatService(ref);
});
