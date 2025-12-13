import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/revenue_cat_api_service.dart';
import '../../../core/utils/logger.dart';

/// Service to programmatically set up RevenueCat configuration
/// 
/// This service uses the RevenueCat REST API to configure:
/// - Entitlements
/// - Products
/// - Offerings
/// 
/// Usage:
/// ```dart
/// final setupService = ref.read(revenueCatSetupServiceProvider);
/// await setupService.setupSweepFeedPro();
/// ```
class RevenueCatSetupService {
  final RevenueCatApiService _apiService = RevenueCatApiService();

  /// Set up complete SweepFeed Pro subscription configuration
  /// 
  /// This creates:
  /// - "SweepFeed Pro" entitlement
  /// - "monthly" and "yearly" products (if store product IDs provided)
  /// - Links products to entitlement
  /// - Creates default offering with packages
  /// 
  /// Note: Store products must be created in Google Play Console and
  /// App Store Connect first. Pass the store product IDs here.
  Future<Map<String, bool>> setupSweepFeedPro({
    String? monthlyStoreProductIdAndroid,
    String? yearlyStoreProductIdAndroid,
    String? monthlyStoreProductIdIOS,
    String? yearlyStoreProductIdIOS,
  }) async {
    try {
      logger.i('Starting RevenueCat setup for SweepFeed Pro...');
      
      final results = await _apiService.setupComplete(
        monthlyStoreProductIdAndroid: monthlyStoreProductIdAndroid,
        yearlyStoreProductIdAndroid: yearlyStoreProductIdAndroid,
        monthlyStoreProductIdIOS: monthlyStoreProductIdIOS,
        yearlyStoreProductIdIOS: yearlyStoreProductIdIOS,
      );

      // Log results
      final successCount = results.values.where((v) => v == true).length;
      final totalCount = results.length;
      
      logger.i(
        'RevenueCat setup completed: $successCount/$totalCount operations succeeded',
      );
      
      for (final entry in results.entries) {
        if (entry.value) {
          logger.d('✅ ${entry.key}');
        } else {
          logger.w('❌ ${entry.key}');
        }
      }

      return results;
    } catch (e) {
      logger.e('Error setting up RevenueCat', error: e);
      rethrow;
    }
  }

  /// Quick setup - just creates the entitlement (no store products)
  /// 
  /// Use this if you haven't created store products yet
  Future<bool> setupEntitlementOnly() async {
    try {
      logger.i('Creating SweepFeed Pro entitlement...');
      final success = await _apiService.createEntitlement(
        identifier: 'SweepFeed Pro',
        displayName: 'SweepFeed Pro',
      );
      
      if (success) {
        logger.i('✅ Entitlement created successfully');
      } else {
        logger.w('⚠️ Entitlement creation may have failed');
      }
      
      return success;
    } catch (e) {
      logger.e('Error creating entitlement', error: e);
      return false;
    }
  }
}

final revenueCatSetupServiceProvider =
    Provider<RevenueCatSetupService>((ref) => RevenueCatSetupService());

