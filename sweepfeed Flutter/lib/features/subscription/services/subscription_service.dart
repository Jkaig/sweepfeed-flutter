import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_plan.dart';
import '../models/subscription_tiers.dart';

class SubscriptionService with ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  final _subscriptionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get subscriptionStatus => _subscriptionStatusController.stream;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String monthlyProductId = 'com.sweepfeed.app.monthly';
  static const String annualProductId = 'com.sweepfeed.app.annual';
  static const String basicMonthlyProductId = 'com.sweepfeed.app.basic.monthly';
  static const String basicAnnualProductId = 'com.sweepfeed.app.basic.annual';
  static const String premiumMonthlyProductId =
      'com.sweepfeed.app.premium.monthly';
  static const String premiumAnnualProductId =
      'com.sweepfeed.app.premium.annual';

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

  bool get hasPremiumAccess =>
      _isSubscribed && _currentTier == SubscriptionTier.premium;

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

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      if (kIsWeb) {
        _plans = [
          SubscriptionPlan(
            id: basicMonthlyProductId,
            name: 'Basic Monthly',
            description: 'Basic plan - Ad-free for 1 month',
            price: '\$4.99',
            rawPrice: 4.99,
            currencyCode: 'USD',
            tier: SubscriptionTier.basic,
            duration: 'Monthly',
            productDetails: null,
          ),
          SubscriptionPlan(
            id: basicAnnualProductId,
            name: 'Basic Annual',
            description: 'Basic plan - Ad-free for 12 months',
            price: '\$49.99',
            rawPrice: 49.99,
            currencyCode: 'USD',
             tier: SubscriptionTier.basic,
            duration: 'Annual',
            productDetails: null,
          ),
          SubscriptionPlan(
            id: premiumMonthlyProductId,
            name: 'Premium Monthly',
            description: 'Premium plan - All features for 1 month',
            price: '\$9.99',
            rawPrice: 9.99,
            currencyCode: 'USD',
             tier: SubscriptionTier.premium,
            duration: 'Monthly',
            productDetails: null,
          ),
          SubscriptionPlan(
            id: premiumAnnualProductId,
            name: 'Premium Annual',
            description: 'Premium plan - All features for 12 months',
            price: '\$99.99',
            rawPrice: 99.99,
            currencyCode: 'USD',
             tier: SubscriptionTier.premium,
            duration: 'Annual',
            productDetails: null,
          ),
        ];
        _productsLoaded = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(_productIds.toSet());

      if (response.notFoundIDs.isNotEmpty) {
        _error = 'Some products not found: ${response.notFoundIDs.join(', ')}';
        notifyListeners();
      }

      _plans = response.productDetails.map((product) {
        final bool isBasic = product.id.contains('basic');
        final bool isPremium = product.id.contains('premium');
        final bool isAnnual = product.id.contains('annual');

        return SubscriptionPlan(
          id: product.id,
          name: product.title,
          description: product.description,
          price: product.price,
          rawPrice: product.rawPrice,
          currencyCode: product.currencyCode,
          tier: isPremium ? SubscriptionTier.premium : SubscriptionTier.basic,
          duration: isAnnual ? 'Annual' : 'Monthly',
          productDetails: product,
        );
      }).toList();

      if (_plans!.isEmpty) {
        _plans = [
           SubscriptionPlan(
            id: basicMonthlyProductId,
            name: 'Basic Monthly',
            description: 'Basic plan - Ad-free for 1 month',
            price: '\$4.99',
            rawPrice: 4.99,
            currencyCode: 'USD',
            tier: SubscriptionTier.basic,
            duration: 'Monthly',
            productDetails: null,
          ),
          SubscriptionPlan(
            id: basicAnnualProductId,
            name: 'Basic Annual',
            description: 'Basic plan - Ad-free for 12 months',
            price: '\$49.99',
            rawPrice: 49.99,
            currencyCode: 'USD',
             tier: SubscriptionTier.basic,
            duration: 'Annual',
            productDetails: null,
          ),
          SubscriptionPlan(
            id: premiumMonthlyProductId,
            name: 'Premium Monthly',
            description: 'Premium plan - All features for 1 month',
            price: '\$9.99',
            rawPrice: 9.99,
            currencyCode: 'USD',
             tier: SubscriptionTier.premium,
            duration: 'Monthly',
            productDetails: null,
          ),
          SubscriptionPlan(
            id: premiumAnnualProductId,
            name: 'Premium Annual',
            description: 'Premium plan - All features for 12 months',
            price: '\$99.99',
            rawPrice: 99.99,
            currencyCode: 'USD',
             tier: SubscriptionTier.premium,
            duration: 'Annual',
            productDetails: null,
          ),
        ];
      }

      _productsLoaded = true;
    } catch (e) {
      _error = 'Error loading products: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

      final PurchaseParam purchaseParam = PurchaseParam(
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

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('Purchase pending: ${purchaseDetails.productID}');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchaseDetails.error}');
          _error = purchaseDetails.error?.message ?? 'Unknown error occurred';
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _handleSuccessfulPurchase(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          debugPrint('Purchase canceled: ${purchaseDetails.productID}');
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
    String productId = purchase.productID;
    bool isPremium = productId.contains('premium') ||
        productId == monthlyProductId ||
        productId == annualProductId;
    bool isAnnual = productId.contains('annual');

      final DateTime now = DateTime.now();
      final DateTime expiryDate = isAnnual
          ? DateTime(now.year + 1, now.month, now.day)
          : DateTime(now.year, now.month + 1, now.day);

      final tier =
          isPremium ? SubscriptionTier.premium : SubscriptionTier.basic;

      try {
        final String? userId = _auth.currentUser?.uid;
        if (userId != null) {
          await _firestore.collection('users').doc(userId).update({
            'isSubscribed': true,
            'subscriptionId': purchase.productID,
            'subscriptionPurchaseDate': now,
            'subscriptionExpiryDate': expiryDate,
            'subscriptionTier': tier.name,
            'subscriptionReceipt':
                purchase.verificationData.serverVerificationData,
          });

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
        }
      } catch (e) {
        debugPrint('Error updating subscription in Firestore: $e');
        _error = 'Error updating subscription in Firestore: $e';
      }

    _isPurchasePending = false;
    notifyListeners();
  }

  Future<bool> checkSubscriptionStatus() async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        _subscriptionStatusController.add(false);
        return false;
      }

      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        _subscriptionStatusController.add(false);
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final bool isSubscribed = data['isSubscribed'] ?? false;

      if (isSubscribed && data['subscriptionExpiryDate'] != null) {
        final DateTime expiryDate =
            (data['subscriptionExpiryDate'] as Timestamp).toDate();
        final bool isActive = expiryDate.isAfter(DateTime.now());

        _isSubscribed = isActive;
        if (isActive) {
          _subscriptionExpiryDate = expiryDate;
          _currentSubscriptionPlan =
              data['subscriptionId']?.contains('annual') == true
                  ? 'Annual'
                  : 'Monthly';

          String tierStr = data['subscriptionTier'] ?? '';
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
      debugPrint('Error checking subscription status: $e');
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
      debugPrint('Error restoring purchases: $e');
      _error = 'Error restoring purchases: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startFreeTrial() async {
    if (_trialStarted || _isSubscribed) {
      return false;
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: trialPeriodDays));

      await _firestore.collection('users').doc(userId).update({
        'trialStarted': true,
        'trialStartDate': now,
        'trialExpiryDate': expiryDate,
      });

      _trialStarted = true;
      _trialExpiryDate = expiryDate;
      await _saveTrialStatus();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error starting trial: $e');
      _error = 'Error starting trial: $e';
      return false;
    }
  }

  Future<void> cancelSubscription() async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'cancellationRequested': true,
        });
      }
    } catch (e) {
      debugPrint('Error canceling subscription: $e');
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
      await prefs.setString(_userSubscriptionExpiryKey,
          _subscriptionExpiryDate!.toIso8601String());
    }

    if (_currentSubscriptionPlan != null) {
      await prefs.setString(
          'current_subscription_plan', _currentSubscriptionPlan!);
    }

    await prefs.setString(_userSubscriptionTierKey, _currentTier.name);
  }

  Future<void> _saveTrialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userTrialStartedKey, _trialStarted);

    if (_trialExpiryDate != null) {
      await prefs.setString(
          _userTrialExpiryKey, _trialExpiryDate!.toIso8601String());
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isSubscribed = prefs.getBool(_userSubscriptionStatusKey) ?? false;

    final expiryDateStr = prefs.getString(_userSubscriptionExpiryKey);
    if (expiryDateStr != null) {
      _subscriptionExpiryDate = DateTime.parse(expiryDateStr);

      if (_subscriptionExpiryDate!.isBefore(DateTime.now())) {
        _isSubscribed = false;
        await _saveSubscriptionStatus();
      }
    }

    _currentSubscriptionPlan = prefs.getString('current_subscription_plan');

    final tierStr = prefs.getString(_userSubscriptionTierKey);
    if (tierStr != null) {
      if (tierStr.toLowerCase() == 'premium') {
        _currentTier = SubscriptionTier.premium;
      } else if (tierStr.toLowerCase() == 'basic') {
        _currentTier = SubscriptionTier.basic;
      } else {
        _currentTier = SubscriptionTier.free;
      }
    }

    _trialStarted = prefs.getBool(_userTrialStartedKey) ?? false;

    final trialExpiryDateStr = prefs.getString(_userTrialExpiryKey);
    if (trialExpiryDateStr != null) {
      _trialExpiryDate = DateTime.parse(trialExpiryDateStr);

      if (_trialExpiryDate!.isBefore(DateTime.now())) {
        _trialStarted = false;
        await _saveTrialStatus();
      }
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
}
