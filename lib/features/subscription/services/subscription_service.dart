import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/providers/providers.dart';
import '../models/subscription_plan.dart';
import '../models/subscription_tiers.dart';
import 'revenue_cat_service.dart';

class SubscriptionService with ChangeNotifier {
  SubscriptionService(this._ref, this._revenueCatService);

  static const String premiumAnnualId = 'premium_annual';
  static const String premiumMonthlyId = 'premium_monthly';
  static const String basicAnnualId = 'basic_annual';
  static const String basicMonthlyId = 'basic_monthly';

  final Ref _ref;
  final RevenueCatService _revenueCatService;

  List<SubscriptionPlan>? _plans;
  List<SubscriptionPlan> get plans => _plans ?? [];

  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;

  SubscriptionTier _currentTier = SubscriptionTier.free;
  SubscriptionTier get currentTier => _currentTier;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPurchasePending = false;
  bool get isPurchasePending => _isPurchasePending;

  String _error = '';
  String get error => _error;

  bool get hasPremiumAccess => _currentTier == SubscriptionTier.premium;
  bool get hasBasicOrPremiumAccess =>
      _currentTier == SubscriptionTier.basic ||
      _currentTier == SubscriptionTier.premium;

  Future<void> initialize() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Assuming user ID is handled within revenueCatService or not needed for initial load/check
      // If userId is required for init, it should be passed or retrieved from auth provider
      // For now, we'll assume the service handles initialization separately or doesn't need explicit init here
      // await _revenueCatService.init(); 
      await loadProducts();
      await checkSubscriptionStatus();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadProducts() async {
    try {
      final offerings = await _revenueCatService.getOfferings();
      if (offerings == null || offerings.current == null) {
        _error = 'No offerings available';
        return;
      }
      
      final currentOffering = offerings.current!;
      _plans = currentOffering.availablePackages.map((package) => SubscriptionPlan(
          id: package.identifier,
          name: currentOffering.serverDescription,
          description: '',
          price: package.storeProduct.priceString,
          rawPrice: package.storeProduct.price,
          currencyCode: package.storeProduct.currencyCode,
          tier: _tierFromProductId(package.identifier),
          duration: _durationFromProductId(package.identifier),
        ),).toList();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> purchaseSubscription(SubscriptionPlan plan) async {
    _isPurchasePending = true;
    notifyListeners();

    try {
      // Ensure RevenueCat is initialized
      final currentUser = _ref.read(firebaseAuthProvider).currentUser;
      if (currentUser != null) {
        await _revenueCatService.initialize(currentUser.uid);
      } else {
        throw Exception('User must be logged in to purchase subscription');
      }
      
      final offerings = await _revenueCatService.getOfferings();
      if (offerings == null || offerings.current == null) {
        throw Exception('No offerings available');
      }
      final offering = offerings.current!;
      final package = offering.availablePackages.firstWhere((p) => p.identifier == plan.id);
      await _revenueCatService.purchasePackage(package);
      await checkSubscriptionStatus();
      _isPurchasePending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isPurchasePending = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkSubscriptionStatus() async {
    try {
      final customerInfo = await _revenueCatService.getCustomerInfo();
      _isSubscribed = customerInfo.entitlements.active.isNotEmpty;
      if (_isSubscribed) {
        final entitlement = customerInfo.entitlements.active.values.first;
        _currentTier = _tierFromProductId(entitlement.productIdentifier);
      } else {
        _currentTier = SubscriptionTier.free;
      }
      notifyListeners();
      return _isSubscribed;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Purchases.restorePurchases();
      await checkSubscriptionStatus();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  SubscriptionTier _tierFromProductId(String productId) {
    if (productId == premiumAnnualId || productId == premiumMonthlyId) {
      return SubscriptionTier.premium;
    } else {
      return SubscriptionTier.basic;
    }
  }

  String _durationFromProductId(String productId) {
    if (productId == premiumAnnualId || productId == basicAnnualId) {
      return 'Annual';
    } else {
      return 'Monthly';
    }
  }

  // Trial-related getters (delegated to RevenueCatService)
  bool get isInTrialPeriod => _revenueCatService.isInTrialPeriod();
  bool get trialStarted => _revenueCatService.isInTrialPeriod();
  String get trialTimeRemaining {
    final expDate = _revenueCatService.getSubscriptionExpirationDate();
    if (expDate == null) return '';
    final remaining = expDate.difference(DateTime.now());
    if (remaining.inDays > 0) {
      return '${remaining.inDays} days';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} hours';
    }
    return 'Less than an hour';
  }
  
  /// Check if user is eligible for a free trial
  /// A user is eligible if they're not subscribed, not in a trial, and RevenueCat offers a trial package
  Future<bool> isTrialEligible() async {
    if (_isSubscribed || isInTrialPeriod) {
      return false;
    }
    
    try {
      final offerings = await _revenueCatService.getOfferings();
      if (offerings?.current == null) {
        return false;
      }
      
      // Check if any package has a trial period available
      // RevenueCat automatically filters out packages with trials if user has already used one
      final packages = offerings!.current!.availablePackages;
      for (final package in packages) {
        // If RevenueCat offers a package, and user hasn't used trial, it will include trial info
        // We can check if the package's product has an introductory price (trial)
        final product = package.storeProduct;
        if (product.introductoryPrice != null) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      // If we can't determine, assume not eligible to be safe
      return false;
    }
  }
}