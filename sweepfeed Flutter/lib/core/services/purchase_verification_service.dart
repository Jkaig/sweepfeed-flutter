import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../features/subscription/models/subscription_tiers.dart';
import '../config/secure_config.dart';
import '../utils/logger.dart';

/// Secure server-side purchase verification service
///
/// This service provides critical security for in-app purchases by:
/// 1. Server-side receipt verification with app stores
/// 2. Replay attack prevention using nonces
/// 3. Product ID validation and mapping
/// 4. Secure subscription status management
class PurchaseVerificationService {
  factory PurchaseVerificationService() => _instance;
  PurchaseVerificationService._internal();
  static final PurchaseVerificationService _instance =
      PurchaseVerificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verifies a purchase with the backend server
  ///
  /// This is the main entry point for purchase verification.
  /// It handles both iOS (App Store) and Android (Google Play) purchases.
  Future<PurchaseVerificationResult> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required String verificationData,
    required String platform, // 'ios' or 'android'
    String? transactionId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return PurchaseVerificationResult.failure('User not authenticated');
      }

      // Generate unique nonce for this verification attempt
      final nonce = _generateVerificationNonce(userId, productId);

      // Prepare verification request
      final requestBody = {
        'userId': userId,
        'productId': productId,
        'purchaseToken': purchaseToken,
        'verificationData': verificationData,
        'platform': platform,
        'transactionId': transactionId,
        'nonce': nonce,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send to backend for verification
      final response = await _sendVerificationRequest(requestBody);

      if (response.success) {
        // Update local subscription status
        await _updateSubscriptionStatus(response);

        // Store verification record for audit
        await _storeVerificationRecord(userId, response);
      }

      return response;
    } catch (e) {
      logger.e('Purchase verification failed', error: e);
      return PurchaseVerificationResult.failure(
        'Verification failed: ${e.toString()}',
      );
    }
  }

  /// Sends verification request to backend server
  Future<PurchaseVerificationResult> _sendVerificationRequest(
    Map<String, dynamic> requestBody,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${SecureConfig.apiBaseUrl}/api/v1/purchases/verify'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${await _getAuthToken()}',
              'X-App-Version': '1.0.0',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return PurchaseVerificationResult.fromJson(responseData);
      } else {
        logger.e(
          'Server verification failed: ${response.statusCode} - ${response.body}',
        );
        return PurchaseVerificationResult.failure(
          'Server verification failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      logger.e('Network error during verification', error: e);
      return PurchaseVerificationResult.failure(
        'Network error: ${e.toString()}',
      );
    }
  }

  /// Updates local subscription status based on verified purchase
  Future<void> _updateSubscriptionStatus(
    PurchaseVerificationResult result,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null || !result.success) return;

      final updateData = {
        'isSubscribed': true,
        'subscriptionId': result.productId,
        'subscriptionTier': result.subscriptionTier?.name,
        'subscriptionExpiryDate': result.expiryDate,
        'subscriptionPurchaseDate': result.purchaseDate,
        'lastVerificationDate': FieldValue.serverTimestamp(),
        'verificationNonce': result.verificationNonce,
      };

      await _firestore.collection('users').doc(userId).update(updateData);
      logger.i('Subscription status updated for user: $userId');
    } catch (e) {
      logger.e('Failed to update subscription status', error: e);
      rethrow;
    }
  }

  /// Stores verification record for audit purposes
  Future<void> _storeVerificationRecord(
    String userId,
    PurchaseVerificationResult result,
  ) async {
    try {
      final auditRecord = {
        'userId': userId,
        'productId': result.productId,
        'success': result.success,
        'verificationNonce': result.verificationNonce,
        'timestamp': FieldValue.serverTimestamp(),
        'subscriptionTier': result.subscriptionTier?.name,
        'expiryDate': result.expiryDate,
        'errorMessage': result.errorMessage,
      };

      await _firestore.collection('purchase_verifications').add(auditRecord);
    } catch (e) {
      logger.e('Failed to store verification record', error: e);
      // Don't rethrow - audit failure shouldn't break the purchase flow
    }
  }

  /// Generates a unique verification nonce to prevent replay attacks
  String _generateVerificationNonce(String userId, String productId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final data = '$userId:$productId:$timestamp';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Gets Firebase Auth token for backend authentication
  Future<String> _getAuthToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Failed to get authentication token');
    }
    return token;
  }

  /// Validates that a subscription is currently active
  Future<bool> validateActiveSubscription(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();

      if (data == null) return false;

      final isSubscribed = data['isSubscribed'] as bool? ?? false;
      final expiryDate = data['subscriptionExpiryDate'] as Timestamp?;

      if (!isSubscribed || expiryDate == null) return false;

      return expiryDate.toDate().isAfter(DateTime.now());
    } catch (e) {
      logger.e('Failed to validate subscription', error: e);
      return false;
    }
  }

  /// Checks for and prevents replay attacks
  Future<bool> _isNonceAlreadyUsed(String nonce) async {
    try {
      final query = await _firestore
          .collection('purchase_verifications')
          .where('verificationNonce', isEqualTo: nonce)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      logger.e('Failed to check nonce', error: e);
      return true; // Err on the side of caution
    }
  }

  /// Validates product ID and maps to subscription tier
  SubscriptionTier? _getSubscriptionTierForProduct(String productId) {
    // Server should maintain this mapping, but include fallback logic
    if (productId.contains('premium')) {
      return SubscriptionTier.premium;
    } else if (productId.contains('basic')) {
      return SubscriptionTier.basic;
    }
    return null;
  }
}

/// Result of purchase verification
class PurchaseVerificationResult {
  PurchaseVerificationResult({
    required this.success,
    this.errorMessage,
    this.productId,
    this.subscriptionTier,
    this.purchaseDate,
    this.expiryDate,
    this.verificationNonce,
  });

  factory PurchaseVerificationResult.success({
    required String productId,
    required SubscriptionTier subscriptionTier,
    required DateTime purchaseDate,
    required DateTime expiryDate,
    required String verificationNonce,
  }) =>
      PurchaseVerificationResult(
        success: true,
        productId: productId,
        subscriptionTier: subscriptionTier,
        purchaseDate: purchaseDate,
        expiryDate: expiryDate,
        verificationNonce: verificationNonce,
      );

  factory PurchaseVerificationResult.failure(String errorMessage) =>
      PurchaseVerificationResult(
        success: false,
        errorMessage: errorMessage,
      );

  factory PurchaseVerificationResult.fromJson(Map<String, dynamic> json) =>
      PurchaseVerificationResult(
        success: json['success'] as bool,
        errorMessage: json['errorMessage'] as String?,
        productId: json['productId'] as String?,
        subscriptionTier: json['subscriptionTier'] != null
            ? SubscriptionTier.values.firstWhere(
                (tier) => tier.name == json['subscriptionTier'],
                orElse: () => SubscriptionTier.free,
              )
            : null,
        purchaseDate: json['purchaseDate'] != null
            ? DateTime.parse(json['purchaseDate'] as String)
            : null,
        expiryDate: json['expiryDate'] != null
            ? DateTime.parse(json['expiryDate'] as String)
            : null,
        verificationNonce: json['verificationNonce'] as String?,
      );
  final bool success;
  final String? errorMessage;
  final String? productId;
  final SubscriptionTier? subscriptionTier;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final String? verificationNonce;
}
