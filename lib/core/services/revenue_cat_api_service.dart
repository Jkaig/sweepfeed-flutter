import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../utils/logger.dart';

/// Service for programmatically configuring RevenueCat via REST API
/// 
/// This service allows you to set up entitlements, products, and offerings
/// without manually using the RevenueCat dashboard.
/// 
/// Requires a RevenueCat Secret API Key (not the public SDK key).
/// Get it from: RevenueCat Dashboard → Settings → API Keys → Secret Keys
class RevenueCatApiService {
  static const String baseUrl = 'https://api.revenuecat.com/v1';
  
  /// Get RevenueCat Secret API Key from environment
  /// This is different from the public SDK keys used in the app
  String? get _secretApiKey {
    final key = dotenv.env['REVENUECAT_SECRET_API_KEY'];
    if (key == null || key.isEmpty) {
      logger.w(
        'RevenueCat Secret API Key not found. '
        'Set REVENUECAT_SECRET_API_KEY in .env to use API setup.',
      );
    }
    return key;
  }

  /// Get authorization header for API requests
  Map<String, String> get _headers {
    final key = _secretApiKey;
    if (key == null) {
      throw Exception('RevenueCat Secret API Key not configured');
    }
    return {
      'Authorization': 'Bearer $key',
      'Content-Type': 'application/json',
      'X-Platform': 'flutter',
    };
  }

  /// Get project ID from environment or use default
  String get _projectId => dotenv.env['REVENUECAT_PROJECT_ID'] ?? 'default';

  /// Create or update an entitlement
  /// 
  /// [identifier] - The entitlement identifier (e.g., "SweepFeed Pro")
  /// [displayName] - Display name for the entitlement
  Future<bool> createEntitlement({
    required String identifier,
    required String displayName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$_projectId/entitlements'),
        headers: _headers,
        body: json.encode({
          'identifier': identifier,
          'display_name': displayName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i('Entitlement created/updated: $identifier');
        return true;
      } else if (response.statusCode == 409) {
        // Already exists, try to update
        logger.i('Entitlement already exists, updating: $identifier');
        return await updateEntitlement(
          identifier: identifier,
          displayName: displayName,
        );
      } else {
        logger.e(
          'Failed to create entitlement: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      logger.e('Error creating entitlement', error: e);
      return false;
    }
  }

  /// Update an existing entitlement
  Future<bool> updateEntitlement({
    required String identifier,
    required String displayName,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/projects/$_projectId/entitlements/$identifier'),
        headers: _headers,
        body: json.encode({
          'display_name': displayName,
        }),
      );

      if (response.statusCode == 200) {
        logger.i('Entitlement updated: $identifier');
        return true;
      } else {
        logger.e(
          'Failed to update entitlement: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      logger.e('Error updating entitlement', error: e);
      return false;
    }
  }

  /// Create a product in RevenueCat
  /// 
  /// Note: Products must first be created in Google Play Console and App Store Connect
  /// This method links those store products to RevenueCat
  /// 
  /// [identifier] - Product identifier (e.g., "monthly", "yearly")
  /// [storeProductId] - The product ID in the store (Google Play / App Store)
  /// [platform] - "android" or "ios"
  Future<bool> createProduct({
    required String identifier,
    required String storeProductId,
    required String platform, // "android" or "ios"
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$_projectId/products'),
        headers: _headers,
        body: json.encode({
          'identifier': identifier,
          'store_product_id': storeProductId,
          'platform': platform,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i('Product created: $identifier for $platform');
        return true;
      } else if (response.statusCode == 409) {
        logger.i('Product already exists: $identifier for $platform');
        return true; // Already exists, consider it success
      } else {
        logger.e(
          'Failed to create product: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      logger.e('Error creating product', error: e);
      return false;
    }
  }

  /// Attach a product to an entitlement
  Future<bool> attachProductToEntitlement({
    required String entitlementIdentifier,
    required String productIdentifier,
    required String platform,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/projects/$_projectId/entitlements/$entitlementIdentifier/products',
        ),
        headers: _headers,
        body: json.encode({
          'product_identifier': productIdentifier,
          'platform': platform,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i(
          'Product $productIdentifier attached to entitlement $entitlementIdentifier',
        );
        return true;
      } else if (response.statusCode == 409) {
        logger.i('Product already attached to entitlement');
        return true;
      } else {
        logger.e(
          'Failed to attach product: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      logger.e('Error attaching product to entitlement', error: e);
      return false;
    }
  }

  /// Create an offering
  /// 
  /// [identifier] - Offering identifier (e.g., "default")
  /// [displayName] - Display name for the offering
  Future<bool> createOffering({
    required String identifier,
    required String displayName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$_projectId/offerings'),
        headers: _headers,
        body: json.encode({
          'identifier': identifier,
          'display_name': displayName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i('Offering created: $identifier');
        return true;
      } else if (response.statusCode == 409) {
        logger.i('Offering already exists: $identifier');
        return true;
      } else {
        logger.e(
          'Failed to create offering: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      logger.e('Error creating offering', error: e);
      return false;
    }
  }

  /// Add a package to an offering
  /// 
  /// [offeringIdentifier] - The offering identifier
  /// [packageIdentifier] - Package identifier (e.g., "monthly", "yearly")
  /// [productIdentifier] - The product identifier to use
  /// [platform] - "android" or "ios"
  Future<bool> addPackageToOffering({
    required String offeringIdentifier,
    required String packageIdentifier,
    required String productIdentifier,
    required String platform,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/projects/$_projectId/offerings/$offeringIdentifier/packages',
        ),
        headers: _headers,
        body: json.encode({
          'identifier': packageIdentifier,
          'product_identifier': productIdentifier,
          'platform': platform,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i(
          'Package $packageIdentifier added to offering $offeringIdentifier',
        );
        return true;
      } else if (response.statusCode == 409) {
        logger.i('Package already exists in offering');
        return true;
      } else {
        logger.e(
          'Failed to add package: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      logger.e('Error adding package to offering', error: e);
      return false;
    }
  }

  /// Set an offering as the default offering
  Future<bool> setDefaultOffering(String offeringIdentifier) async {
    try {
      final response = await http.patch(
        Uri.parse(
          '$baseUrl/projects/$_projectId/offerings/$offeringIdentifier',
        ),
        headers: _headers,
        body: json.encode({
          'is_default': true,
        }),
      );

      if (response.statusCode == 200) {
        logger.i('Offering $offeringIdentifier set as default');
        return true;
      } else {
        logger.e(
          'Failed to set default offering: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      logger.e('Error setting default offering', error: e);
      return false;
    }
  }

  /// Complete setup: Creates entitlement, products, and offering
  /// 
  /// This is a convenience method that sets up everything at once
  /// 
  /// [monthlyStoreProductIdAndroid] - Monthly product ID in Google Play
  /// [yearlyStoreProductIdAndroid] - Yearly product ID in Google Play
  /// [monthlyStoreProductIdIOS] - Monthly product ID in App Store
  /// [yearlyStoreProductIdIOS] - Yearly product ID in App Store
  Future<Map<String, bool>> setupComplete({
    String? monthlyStoreProductIdAndroid,
    String? yearlyStoreProductIdAndroid,
    String? monthlyStoreProductIdIOS,
    String? yearlyStoreProductIdIOS,
  }) async {
    final results = <String, bool>{};

    // 1. Create entitlement
    results['entitlement'] = await createEntitlement(
      identifier: 'SweepFeed Pro',
      displayName: 'SweepFeed Pro',
    );

    // 2. Create products (if store product IDs provided)
    if (monthlyStoreProductIdAndroid != null) {
      results['product_monthly_android'] = await createProduct(
        identifier: 'monthly',
        storeProductId: monthlyStoreProductIdAndroid,
        platform: 'android',
      );
    }

    if (yearlyStoreProductIdAndroid != null) {
      results['product_yearly_android'] = await createProduct(
        identifier: 'yearly',
        storeProductId: yearlyStoreProductIdAndroid,
        platform: 'android',
      );
    }

    if (monthlyStoreProductIdIOS != null) {
      results['product_monthly_ios'] = await createProduct(
        identifier: 'monthly',
        storeProductId: monthlyStoreProductIdIOS,
        platform: 'ios',
      );
    }

    if (yearlyStoreProductIdIOS != null) {
      results['product_yearly_ios'] = await createProduct(
        identifier: 'yearly',
        storeProductId: yearlyStoreProductIdIOS,
        platform: 'ios',
      );
    }

    // 3. Attach products to entitlement
    if (results['product_monthly_android'] == true) {
      results['attach_monthly_android'] = await attachProductToEntitlement(
        entitlementIdentifier: 'SweepFeed Pro',
        productIdentifier: 'monthly',
        platform: 'android',
      );
    }

    if (results['product_yearly_android'] == true) {
      results['attach_yearly_android'] = await attachProductToEntitlement(
        entitlementIdentifier: 'SweepFeed Pro',
        productIdentifier: 'yearly',
        platform: 'android',
      );
    }

    if (results['product_monthly_ios'] == true) {
      results['attach_monthly_ios'] = await attachProductToEntitlement(
        entitlementIdentifier: 'SweepFeed Pro',
        productIdentifier: 'monthly',
        platform: 'ios',
      );
    }

    if (results['product_yearly_ios'] == true) {
      results['attach_yearly_ios'] = await attachProductToEntitlement(
        entitlementIdentifier: 'SweepFeed Pro',
        productIdentifier: 'yearly',
        platform: 'ios',
      );
    }

    // 4. Create offering
    results['offering'] = await createOffering(
      identifier: 'default',
      displayName: 'Default Offering',
    );

    // 5. Add packages to offering
    if (results['product_monthly_android'] == true ||
        results['product_monthly_ios'] == true) {
      // Add monthly package (try both platforms)
      if (results['product_monthly_android'] == true) {
        results['package_monthly_android'] = await addPackageToOffering(
          offeringIdentifier: 'default',
          packageIdentifier: 'monthly',
          productIdentifier: 'monthly',
          platform: 'android',
        );
      }
      if (results['product_monthly_ios'] == true) {
        results['package_monthly_ios'] = await addPackageToOffering(
          offeringIdentifier: 'default',
          packageIdentifier: 'monthly',
          productIdentifier: 'monthly',
          platform: 'ios',
        );
      }
    }

    if (results['product_yearly_android'] == true ||
        results['product_yearly_ios'] == true) {
      // Add yearly package (try both platforms)
      if (results['product_yearly_android'] == true) {
        results['package_yearly_android'] = await addPackageToOffering(
          offeringIdentifier: 'default',
          packageIdentifier: 'yearly',
          productIdentifier: 'yearly',
          platform: 'android',
        );
      }
      if (results['product_yearly_ios'] == true) {
        results['package_yearly_ios'] = await addPackageToOffering(
          offeringIdentifier: 'default',
          packageIdentifier: 'yearly',
          productIdentifier: 'yearly',
          platform: 'ios',
        );
      }
    }

    // 6. Set as default offering
    results['set_default'] = await setDefaultOffering('default');

    return results;
  }
}

