import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/config/secure_config.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/utils/logger.dart';
import '../models/subscription_tiers.dart';
import 'tier_management_service.dart';

class RevenueCatService with ChangeNotifier {
  RevenueCatService(this._ref);

  final Ref _ref;
  bool _isConfigured = false;
  CustomerInfo? _customerInfo;

  // Test API key for development (fallback)
  static const String _testApiKey = 'test_FjwLGZTFxntGHdzSbKujLzhbNyx';
  
  static String get _revenueCatApiKeyAndroid =>
      SecureConfig.revenueCatAndroidApiKey;
  static String get _revenueCatApiKeyIOS => SecureConfig.revenueCatIosApiKey;


  // SweepFeed Pro entitlement - single entitlement for all premium features
  static const String entitlementIdPro = 'SweepFeed Pro';
  
  // Legacy entitlements (for backward compatibility)
  static const String entitlementIdBasic = 'basic_access';
  static const String entitlementIdPremium = 'premium_access';

  Future<void> initialize(String userId) async {
    if (_isConfigured) return;

    if (!_validateUserId(userId)) {
      logger.w('Invalid userId format: $userId');
      return;
    }

    try {
      final apiKey = _getApiKey();
      if (apiKey.isEmpty) {
        logger.w('RevenueCat API key not configured');
        return;
      }

      final configuration = PurchasesConfiguration(apiKey)
        ..appUserID = userId;
      // Note: observerMode is not available in this version of purchases_flutter

      await Purchases.configure(configuration);
      _isConfigured = true;

      // Try to update customer info, but don't fail initialization if it fails
      try {
        await _updateCustomerInfo();
      } catch (e) {
        logger.w('Failed to update customer info during initialization (non-critical)', error: e);
        // Still mark as configured - API key might be invalid but we don't want to crash
      }

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _customerInfo = customerInfo;
        _syncWithTierManagement();
        notifyListeners();
      });

      logger.i('RevenueCat initialized for user: $userId');
    } catch (e) {
      // Don't mark as configured if initialization failed
      _isConfigured = false;
      logger.e('Failed to initialize RevenueCat', error: e);
      // If API key is invalid, log warning but don't crash
      if (e.toString().contains('Invalid API Key') || 
          e.toString().contains('credentials issue')) {
        logger.w('RevenueCat API key is invalid or not configured. Subscription features will be unavailable.');
      } else {
        rethrow; // Re-throw other errors
      }
    }
  }

  bool _validateUserId(String userId) {
    if (userId.isEmpty || userId.length > 255) return false;
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(userId);
  }

  Future<Offerings?> getOfferings() async {
    if (!_isConfigured) {
      logger.w('RevenueCat not configured. Cannot get offerings.');
      return null;
    }
    
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        logger.w('No current offering available');
      }
      return offerings;
    } on PlatformException catch (e) {
      logger.e('Error fetching offerings', error: e);
      return null;
    } catch (e) {
      logger.e('Unexpected error fetching offerings', error: e);
      return null;
    }
  }
  
  /// Get the current offering (convenience method)
  Future<Offering?> getCurrentOffering() async {
    final offerings = await getOfferings();
    return offerings?.current;
  }
  
  /// Get packages from current offering
  Future<List<Package>> getPackages() async {
    final offering = await getCurrentOffering();
    if (offering == null) return [];
    return offering.availablePackages;
  }
  
  /// Find package by identifier
  Future<Package?> getPackage(String packageIdentifier) async {
    final packages = await getPackages();
    try {
      return packages.firstWhere(
        (pkg) => pkg.identifier == packageIdentifier,
      );
    } catch (e) {
      logger.w('Package not found: $packageIdentifier');
      return null;
    }
  }
  
  /// Get monthly package
  Future<Package?> getMonthlyPackage() async => getPackage('monthly');
  
  /// Get yearly package
  Future<Package?> getYearlyPackage() async => getPackage('yearly');

  Future<bool> purchasePackage(Package package) async {
    if (!_isConfigured) {
      logger.e('RevenueCat not configured. Cannot purchase package.');
      throw Exception(
        'Subscription service not ready. Please try again in a moment.',
      );
    }
    
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
          'Purchase completed successfully. package_id: ${package.identifier}, product_id: ${package.storeProduct.identifier}',);
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
            rawError: e,);
      } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
        logger.e('Purchase not allowed', error: e);
        throw PaymentError(
            'Purchase not allowed. Please check your payment method.',
            rawError: e,);
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
    if (!_isConfigured) {
      logger.w('RevenueCat not configured. Cannot restore purchases.');
      return false;
    }
    
    try {
      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;

      await _syncWithTierManagement();
      notifyListeners();

      return customerInfo.entitlements.active.isNotEmpty;
    } on PlatformException catch (e) {
      logger.e('Error restoring purchases', error: e);
      return false;
    }
  }

  /// Get current customer info
  Future<CustomerInfo> getCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      notifyListeners();
      return _customerInfo!;
    } catch (e) {
      logger.e('Error getting customer info', error: e);
      rethrow;
    }
  }

  /// Get current customer info synchronously (cached)
  CustomerInfo? get customerInfo => _customerInfo;

  SubscriptionTier getCurrentTier() {
    if (_customerInfo == null) {
      return SubscriptionTier.free;
    }

    final entitlements = _customerInfo!.entitlements.active;

    // Check for SweepFeed Pro entitlement first (primary)
    if (entitlements.containsKey(entitlementIdPro)) {
      return SubscriptionTier.premium;
    }
    
    // Legacy entitlements (backward compatibility)
    if (entitlements.containsKey(entitlementIdPremium)) {
      return SubscriptionTier.premium;
    } else if (entitlements.containsKey(entitlementIdBasic)) {
      return SubscriptionTier.basic;
    }

    return SubscriptionTier.free;
  }
  
  /// Check if user has SweepFeed Pro entitlement
  bool hasProEntitlement() {
    if (_customerInfo == null) return false;
    return _customerInfo!.entitlements.active.containsKey(entitlementIdPro);
  }

  bool hasActiveSubscription() => _customerInfo?.entitlements.active.isNotEmpty ?? false;

  DateTime? getSubscriptionExpirationDate() {
    if (_customerInfo == null) return null;

    final entitlements = _customerInfo!.entitlements.active;

    // Check SweepFeed Pro first
    if (entitlements.containsKey(entitlementIdPro)) {
      final expDate = entitlements[entitlementIdPro]?.expirationDate;
      return expDate != null ? DateTime.tryParse(expDate) : null;
    }
    
    // Legacy entitlements
    if (entitlements.containsKey(entitlementIdPremium)) {
      final expDate = entitlements[entitlementIdPremium]?.expirationDate;
      return expDate != null ? DateTime.tryParse(expDate) : null;
    } else if (entitlements.containsKey(entitlementIdBasic)) {
      final expDate = entitlements[entitlementIdBasic]?.expirationDate;
      return expDate != null ? DateTime.tryParse(expDate) : null;
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
      logger.e('Error updating customer info', error: e);
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
        logger.w(
            'RevenueCat Android API Key missing. Set REVENUECAT_ANDROID_API_KEY in .env',);
      }
      return _revenueCatApiKeyAndroid;
    } else if (Platform.isIOS) {
      if (_revenueCatApiKeyIOS.isEmpty) {
        logger.w(
            'RevenueCat iOS API Key missing. Set REVENUECAT_IOS_API_KEY in .env',);
      }
      return _revenueCatApiKeyIOS;
    }
    logger.w('Unsupported platform for RevenueCat');
    return '';
  }

  @override
  Future<void> dispose() async {
    await Purchases.close();
    super.dispose();
  }
}

// Note: revenueCatServiceProvider is defined in core/providers/providers.dart
// to avoid duplicate provider definitions
