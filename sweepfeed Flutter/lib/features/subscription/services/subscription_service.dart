import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/providers.dart';
import '../models/subscription_plan.dart';
import '../models/subscription_tiers.dart';

class SubscriptionService with ChangeNotifier {
  SubscriptionService(this._ref);
  final Ref _ref;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  final _subscriptionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get subscriptionStatus => _subscriptionStatusController.stream;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static const String monthlyProductId = 'com.sweepfeed.app.monthly';
  static const String annualProductId = 'com.sweepfeed.app.annual';
  static const String basicMonthlyProductId = 'com.sweepfeed.app.basic.monthly';
  static const String basicAnnualProductId = 'com.sweepfeed.app.basic.annual';
  static const String premiumMonthlyProductId =
      'com.sweepfeed.app.premium.monthly';
  static const String premiumAnnualProductId =
      'com.sweepfeed.app.premium.annual';

  // Price caching constants
  static const String _priceCacheKey = 'subscription_price_cache';
  static const String _cacheTimestampKey = 'subscription_cache_timestamp';
  static const Duration _cacheValidDuration = Duration(hours: 24);

  // Fallback prices with improved structure
  static final Map<String, Map<String, dynamic>> _fallbackPriceData = {
    basicMonthlyProductId: {
      'price': 4.99,
      'currency': 'USD',
      'symbol': '\$',
      'locale': 'en_US',
    },
    basicAnnualProductId: {
      'price': 49.99,
      'currency': 'USD',
      'symbol': '\$',
      'locale': 'en_US',
    },
    premiumMonthlyProductId: {
      'price': 9.99,
      'currency': 'USD',
      'symbol': '\$',
      'locale': 'en_US',
    },
    premiumAnnualProductId: {
      'price': 99.99,
      'currency': 'USD',
      'symbol': '\$',
      'locale': 'en_US',
    },
    monthlyProductId: {
      'price': 4.99,
      'currency': 'USD',
      'symbol': '\$',
      'locale': 'en_US',
    },
    annualProductId: {
      'price': 49.99,
      'currency': 'USD',
      'symbol': '\$',
      'locale': 'en_US',
    },
  };

  List<String> get _productIds => [
        basicMonthlyProductId,
        basicAnnualProductId,
        premiumMonthlyProductId,
        premiumAnnualProductId,
        monthlyProductId,
        annualProductId,
      ];

  List<SubscriptionPlan>? _plans;
  List<SubscriptionPlan> get plans => _plans ?? [];
  List<SubscriptionPlan> get subscriptionPlans => _plans ?? [];

  bool _productsLoaded = false;
  bool get productsLoaded => _productsLoaded;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const String _userSubscriptionStatusKey = 'user_subscription_status';
  static const String _userSubscriptionExpiryKey = 'user_subscription_expiry';
  static const String _userSubscriptionTierKey = 'user_subscription_tier';
  static const String _userTrialStartedKey = 'user_trial_started';
  static const String _userTrialExpiryKey = 'user_trial_expiry';

  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed || isInTrialPeriod;

  DateTime? _subscriptionExpiryDate;
  DateTime? get subscriptionExpiryDate => _subscriptionExpiryDate;

  String? _currentSubscriptionPlan;
  String? get currentSubscriptionPlan => _currentSubscriptionPlan;

  SubscriptionTier _currentTier = SubscriptionTier.free;
  SubscriptionTier get currentTier => _isSubscribed
      ? _currentTier
      : (isInTrialPeriod ? SubscriptionTier.basic : SubscriptionTier.free);

  bool _isLoading = false;
  bool _isPurchasePending = false;

  bool _trialStarted = false;
  DateTime? _trialExpiryDate;
  bool get trialStarted => _trialStarted;
  DateTime? get trialExpiryDate => _trialExpiryDate;
  bool get isInTrialPeriod =>
      _trialStarted &&
      _trialExpiryDate != null &&
      _trialExpiryDate!.isAfter(DateTime.now());

  static const int trialPeriodDays = 3;

  String _error = '';
  String get error => _error;

  bool get hasBasicOrPremiumAccess =>
      _isSubscribed ||
      _currentTier == SubscriptionTier.basic ||
      _currentTier == SubscriptionTier.premium ||
      isInTrialPeriod;

  bool get isPremium {
    final userProfile = _ref.read(userProfileProvider).value;
    final premiumUntil = userProfile?.premiumUntil;

    if (_isSubscribed && _currentTier == SubscriptionTier.premium) {
      return true;
    }
    if (premiumUntil != null && premiumUntil.toDate().isAfter(DateTime.now())) {
      return true;
    }
    return false;
  }

  bool get hasPremiumAccess => isPremium;

  Future<void> initialize() async {
    await _loadSubscriptionStatus();

    if (kIsWeb) {
      _plans = [];
      _productsLoaded = true;
      notifyListeners();
      return;
    }

    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );

    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      _plans = [];
      _error = 'Store is not available';
      notifyListeners();
      return;
    }

    await loadProducts();

    await checkSubscriptionStatus();
  }

  /// Enhanced loadProducts with caching and improved dynamic pricing
  /// Implements strategy: Cache -> Store API -> Fallback
  Future<void> loadProducts() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Step 1: Try to load from cache first (performance optimization)
      final cachedPlans = await _loadFromCache();
      if (cachedPlans != null && cachedPlans.isNotEmpty) {
        if (kDebugMode) {
          print(
              '✅ SubscriptionService: Loaded ${cachedPlans.length} plans from cache');
        }
        _plans = cachedPlans;
        _productsLoaded = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (kDebugMode) {
        print(
            '🔄 SubscriptionService: No valid cache found, fetching from store...');
      }

      // Step 2: For web, use enhanced fallback with proper formatting
      if (kIsWeb) {
        _plans = _createWebFallbackPlans();
        _productsLoaded = true;
        _isLoading = false;
        notifyListeners();
        await _saveToCache(_plans!); // Cache web fallback plans
        return;
      }

      // Step 3: Fetch from IAP store with improved error handling
      final response =
          await _inAppPurchase.queryProductDetails(_productIds.toSet());

      if (response.error != null) {
        throw Exception('Store query failed: ${response.error!.message}');
      }

      if (response.notFoundIDs.isNotEmpty) {
        if (kDebugMode) {
          print(
              '⚠️ Some IAP products not found: ${response.notFoundIDs.join(', ')}');
        }
      }

      // Step 4: Process store products with improved data extraction
      if (response.productDetails.isNotEmpty) {
        _plans = response.productDetails.map((product) {
          return _createPlanFromProduct(product);
        }).toList();

        if (kDebugMode) {
          print(
              '✅ SubscriptionService: Loaded ${_plans!.length} plans from store');
        }

        // Cache the successful store fetch
        await _saveToCache(_plans!);
      }

      // Step 5: Use fallback if no products from store
      if (_plans == null || _plans!.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No products from store, using fallback plans');
        }
        _plans = _createFallbackPlans();
      }

      _productsLoaded = true;
      _error = ''; // Clear any errors since we have plans
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading IAP products: $e');
      }

      // Use fallback plans on any exception
      _plans = _createFallbackPlans();
      _productsLoaded = true;
      _error = 'Using offline prices: ${e.toString()}';

      // Track fallback usage for analytics
      if (kDebugMode) {
        print(
            '📊 Analytics: Subscription pricing fallback used - ${e.runtimeType}');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> purchaseSubscription(SubscriptionPlan plan) async {
    if (_isPurchasePending) return false;
    if (plan.productDetails == null && !kIsWeb) return false;

    _isPurchasePending = true;
    notifyListeners();

    try {
      if (kIsWeb) {
        _error =
            'In-app purchases are not available on web. Please use the mobile app to make purchases.';
        _isPurchasePending = false;
        notifyListeners();
        return false;
      }

      final purchaseParam = PurchaseParam(
        productDetails: plan.productDetails!,
        applicationUserName: _auth.currentUser?.uid,
      );

      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return true;
    } catch (e) {
      _isPurchasePending = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _error = purchaseDetails.error?.message ?? 'Unknown error occurred';
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _handleSuccessfulPurchase(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          _isPurchasePending = false;
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }

    notifyListeners();
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    final productId = purchase.productID;
    final isPremium = productId.contains('premium') ||
        productId == monthlyProductId ||
        productId == annualProductId;
    final isAnnual = productId.contains('annual');

    final tier = isPremium ? SubscriptionTier.premium : SubscriptionTier.basic;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final verificationData = await _verifyPurchaseWithServer(purchase);

      if (verificationData['valid'] == true) {
        final expiryTimeMillis = verificationData['expiryTimeMillis'] as int;
        final expiryDate =
            DateTime.fromMillisecondsSinceEpoch(expiryTimeMillis);

        _subscriptionStatusController.add(true);
        _isSubscribed = true;
        _subscriptionExpiryDate = expiryDate;
        _currentSubscriptionPlan = isAnnual ? 'Annual' : 'Monthly';
        _currentTier = tier;

        if (_trialStarted) {
          _trialStarted = false;
          _trialExpiryDate = null;
        }

        await _saveSubscriptionStatus();
      } else {
        throw Exception('Purchase verification failed');
      }
    } catch (e) {
      _error = 'Failed to verify purchase: $e';
      _isPurchasePending = false;
      notifyListeners();
      rethrow;
    }

    _isPurchasePending = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> _verifyPurchaseWithServer(
      PurchaseDetails purchase) async {
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';

      Map<String, dynamic> purchaseData;

      if (Platform.isAndroid) {
        purchaseData = {
          'packageName': 'com.sweepfeed.app',
          'productId': purchase.productID,
          'purchaseToken': purchase.verificationData.serverVerificationData,
        };
      } else {
        purchaseData = {
          'receiptData': purchase.verificationData.serverVerificationData,
          'isProduction': true,
        };
      }

      final callable = _functions.httpsCallable('verifyPurchase');
      final result = await callable.call({
        'platform': platform,
        'purchaseData': purchaseData,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      print('Server verification error: $e');
      rethrow;
    }
  }

  Future<bool> checkSubscriptionStatus() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _subscriptionStatusController.add(false);
        return false;
      }

      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        _subscriptionStatusController.add(false);
        return false;
      }

      final data = doc.data()!;

      final subscriptionData = data['subscription'] as Map<String, dynamic>?;
      if (subscriptionData == null) {
        _subscriptionStatusController.add(false);
        return false;
      }

      final bool isSubscribed = subscriptionData['active'] ?? false;

      if (isSubscribed && subscriptionData['expiryDate'] != null) {
        final expiryDate =
            (subscriptionData['expiryDate'] as Timestamp).toDate();
        final isActive = expiryDate.isAfter(DateTime.now());

        _isSubscribed = isActive;
        if (isActive) {
          _subscriptionExpiryDate = expiryDate;
          _currentSubscriptionPlan = subscriptionData['platform'] ==
                      'android' &&
                  subscriptionData['orderId']?.toString().contains('annual') ==
                      true
              ? 'Annual'
              : 'Monthly';

          final String tierStr = data['subscriptionTier'] ?? '';
          if (tierStr.toLowerCase() == 'premium') {
            _currentTier = SubscriptionTier.premium;
          } else if (tierStr.toLowerCase() == 'basic') {
            _currentTier = SubscriptionTier.basic;
          } else {
            _currentTier = SubscriptionTier.basic;
          }
        } else {
          _currentTier = SubscriptionTier.free;
        }

        _subscriptionStatusController.add(isActive);
        await _saveSubscriptionStatus();
        return isActive;
      }

      _isSubscribed = isSubscribed;
      _subscriptionStatusController.add(isSubscribed);
      return isSubscribed;
    } catch (e) {
      _error = 'Error checking subscription status: $e';
      _subscriptionStatusController.add(false);
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _inAppPurchase.restorePurchases(
        applicationUserName: _auth.currentUser?.uid,
      );
      return true;
    } catch (e) {
      _error = 'Error restoring purchases: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startFreeTrial() async {
    if (_isSubscribed) {
      return false;
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();

      if (data?['trialStarted'] == true) {
        return false;
      }

      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: trialPeriodDays));

      await _firestore.collection('users').doc(userId).update({
        'trialStarted': true,
        'trialStartDate': now,
        'trialExpiryDate': expiryDate,
      });

      _trialStarted = true;
      _trialExpiryDate = expiryDate;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Unable to start trial. Please try again later.';
      return false;
    }
  }

  Future<void> cancelSubscription() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'cancellationRequested': true,
        });
      }
    } catch (e) {
      _error = 'Error canceling subscription: $e';
    }
  }

  @override
  void dispose() {
    super.dispose();

    _subscription?.cancel();
    _subscriptionStatusController.close();
  }

  Future<void> _saveSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userSubscriptionStatusKey, _isSubscribed);

    if (_subscriptionExpiryDate != null) {
      await prefs.setString(
        _userSubscriptionExpiryKey,
        _subscriptionExpiryDate!.toIso8601String(),
      );
    }

    if (_currentSubscriptionPlan != null) {
      await prefs.setString(
        'current_subscription_plan',
        _currentSubscriptionPlan!,
      );
    }

    await prefs.setString(_userSubscriptionTierKey, _currentTier.name);
  }

  Future<void> _loadSubscriptionStatus() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();

      if (data == null) return;

      final subscriptionData = data['subscription'] as Map<String, dynamic>?;
      if (subscriptionData != null) {
        _isSubscribed = subscriptionData['active'] ?? false;

        if (subscriptionData['expiryDate'] != null) {
          _subscriptionExpiryDate =
              (subscriptionData['expiryDate'] as Timestamp).toDate();

          if (_subscriptionExpiryDate!.isBefore(DateTime.now())) {
            _isSubscribed = false;
          }
        }
      }

      final String tierStr = data['subscriptionTier'] ?? '';
      if (tierStr.toLowerCase() == 'premium') {
        _currentTier = SubscriptionTier.premium;
      } else if (tierStr.toLowerCase() == 'basic') {
        _currentTier = SubscriptionTier.basic;
      } else {
        _currentTier = SubscriptionTier.free;
      }

      _trialStarted = data['trialStarted'] ?? false;

      if (data['trialExpiryDate'] != null) {
        _trialExpiryDate = (data['trialExpiryDate'] as Timestamp).toDate();

        if (_trialExpiryDate!.isBefore(DateTime.now())) {
          _trialStarted = false;
        }
      }

      await _saveSubscriptionStatus();
    } catch (e) {
      print('Error loading subscription status: $e');
    }

    notifyListeners();
  }

  bool get isLoading => _isLoading;
  bool get isPurchasePending => _isPurchasePending;

  String get trialTimeRemaining {
    if (!isInTrialPeriod || _trialExpiryDate == null) {
      return 'Trial expired';
    }

    final now = DateTime.now();
    final difference = _trialExpiryDate!.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} remaining';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} remaining';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} remaining';
    }
  }

  // Additional missing properties and methods
  Stream<bool> get isSubscribedStream => subscriptionStatus;

  /// Create subscription plan from store product with enhanced data processing
  SubscriptionPlan _createPlanFromProduct(ProductDetails product) {
    final isPremium = product.id.contains('premium');
    final isAnnual = product.id.contains('annual');

    // Use store's localized price or format manually if needed
    String formattedPrice = product.price;
    if (formattedPrice.isEmpty && product.rawPrice > 0) {
      try {
        final format = NumberFormat.simpleCurrency(
          locale: 'en_US', // Could be dynamic based on user locale
          name: product.currencyCode,
        );
        formattedPrice = format.format(product.rawPrice);
      } catch (e) {
        // Fallback to simple formatting
        formattedPrice =
            '${product.currencyCode} ${product.rawPrice.toStringAsFixed(2)}';
      }
    }

    return SubscriptionPlan(
      id: product.id,
      name: product.title.isNotEmpty
          ? product.title
          : _generatePlanName(product.id),
      description: product.description.isNotEmpty
          ? product.description
          : _generatePlanDescription(product.id),
      price: formattedPrice,
      rawPrice: product.rawPrice,
      currencyCode: product.currencyCode,
      tier: isPremium ? SubscriptionTier.premium : SubscriptionTier.basic,
      duration: isAnnual ? 'Annual' : 'Monthly',
      productDetails: product,
    );
  }

  /// Create enhanced web fallback plans with proper localization
  List<SubscriptionPlan> _createWebFallbackPlans() {
    return _fallbackPriceData.entries.map((entry) {
      final productId = entry.key;
      final priceData = entry.value;
      final isPremium = productId.contains('premium');
      final isAnnual = productId.contains('annual');

      final formattedPrice = _formatFallbackPrice(
        priceData['price'],
        priceData['currency'],
        priceData['symbol'],
        priceData['locale'],
      );

      return SubscriptionPlan(
        id: productId,
        name: _generatePlanName(productId),
        description: _generatePlanDescription(productId),
        price: formattedPrice,
        rawPrice: priceData['price'],
        currencyCode: priceData['currency'],
        tier: isPremium ? SubscriptionTier.premium : SubscriptionTier.basic,
        duration: isAnnual ? 'Annual' : 'Monthly',
      );
    }).toList();
  }

  /// Create fallback plans with enhanced formatting
  List<SubscriptionPlan> _createFallbackPlans() {
    return _fallbackPriceData.entries.map((entry) {
      final productId = entry.key;
      final priceData = entry.value;
      final isPremium = productId.contains('premium');
      final isAnnual = productId.contains('annual');

      final formattedPrice = _formatFallbackPrice(
        priceData['price'],
        priceData['currency'],
        priceData['symbol'],
        priceData['locale'],
      );

      return SubscriptionPlan(
        id: productId,
        name: _generatePlanName(productId),
        description: _generatePlanDescription(productId),
        price: formattedPrice,
        rawPrice: priceData['price'],
        currencyCode: priceData['currency'],
        tier: isPremium ? SubscriptionTier.premium : SubscriptionTier.basic,
        duration: isAnnual ? 'Annual' : 'Monthly',
      );
    }).toList();
  }

  /// Format fallback price with proper localization
  String _formatFallbackPrice(
      double price, String currency, String symbol, String locale) {
    try {
      final format =
          NumberFormat.simpleCurrency(locale: locale, name: currency);
      return format.format(price);
    } catch (e) {
      // Fallback to simple symbol + price formatting
      return '$symbol${price.toStringAsFixed(2)}';
    }
  }

  /// Generate user-friendly plan names
  String _generatePlanName(String productId) {
    if (productId.contains('premium')) {
      return productId.contains('annual')
          ? 'Premium Annual'
          : 'Premium Monthly';
    } else {
      return productId.contains('annual') ? 'Basic Annual' : 'Basic Monthly';
    }
  }

  /// Generate plan descriptions
  String _generatePlanDescription(String productId) {
    final isPremium = productId.contains('premium');
    final isAnnual = productId.contains('annual');
    final duration = isAnnual ? '12 months' : '1 month';
    final features = isPremium ? 'All premium features' : 'Ad-free experience';
    return '$features for $duration';
  }

  /// Load cached subscription plans with expiration check
  Future<List<SubscriptionPlan>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey) ?? 0;
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

      // Check if cache is still valid (within 24 hours)
      if (DateTime.now().difference(cacheTime) > _cacheValidDuration) {
        if (kDebugMode) {
          print('💾 SubscriptionService: Cache expired, clearing...');
        }
        await clearPriceCache();
        return null;
      }

      final cachedData = prefs.getString(_priceCacheKey);
      if (cachedData == null) return null;

      final Map<String, dynamic> decodedData = jsonDecode(cachedData);
      final List<SubscriptionPlan> plans = [];

      for (final entry in decodedData.entries) {
        final planData = entry.value as Map<String, dynamic>;
        plans.add(SubscriptionPlan(
          id: planData['id'],
          name: planData['name'],
          description: planData['description'],
          price: planData['price'],
          rawPrice: planData['rawPrice'],
          currencyCode: planData['currencyCode'],
          tier: SubscriptionTier.values.firstWhere(
            (tier) => tier.name == planData['tier'],
            orElse: () => SubscriptionTier.basic,
          ),
          duration: planData['duration'],
        ));
      }

      return plans;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading from cache: $e');
      }
      // Clear corrupted cache
      await clearPriceCache();
      return null;
    }
  }

  /// Save subscription plans to cache with timestamp
  Future<void> _saveToCache(List<SubscriptionPlan> plans) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> dataToCache = {};

      for (final plan in plans) {
        dataToCache[plan.id] = {
          'id': plan.id,
          'name': plan.name,
          'description': plan.description,
          'price': plan.price,
          'rawPrice': plan.rawPrice,
          'currencyCode': plan.currencyCode,
          'tier': plan.tier.name,
          'duration': plan.duration,
        };
      }

      await prefs.setString(_priceCacheKey, jsonEncode(dataToCache));
      await prefs.setInt(
          _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

      if (kDebugMode) {
        print('💾 SubscriptionService: Cached ${plans.length} plans');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving to cache: $e');
      }
    }
  }

  /// Clear the price cache (useful for debugging or forced refresh)
  Future<void> clearPriceCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_priceCacheKey);
      await prefs.remove(_cacheTimestampKey);

      if (kDebugMode) {
        print('🧹 SubscriptionService: Price cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing cache: $e');
      }
    }
  }

  /// Force refresh prices from store (bypasses cache)
  Future<void> refreshPrices() async {
    await clearPriceCache();
    await loadProducts();
  }
}
