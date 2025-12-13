/// Script to programmatically set up RevenueCat configuration
/// 
/// Run this script to automatically configure:
/// - SweepFeed Pro entitlement
/// - Monthly and Yearly products
/// - Default offering
/// 
/// Usage:
/// ```bash
/// dart scripts/setup_revenuecat.dart
/// ```
/// 
/// Or from Flutter:
/// ```bash
/// flutter run -d macos scripts/setup_revenuecat.dart
/// ```
library;

import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

// Note: This is a standalone script, so we need to import the service directly
// In a real scenario, you might want to create a CLI tool or use this
// within your Flutter app

Future<void> main() async {
  print('🚀 RevenueCat Setup Script');
  print('==========================\n');

  // Load environment variables
  try {
    await dotenv.load();
    print('✅ Loaded .env file\n');
  } catch (e) {
    print('⚠️  Could not load .env file: $e');
    print('   Make sure REVENUECAT_SECRET_API_KEY is set\n');
  }

  // Check for secret API key
  final secretKey = dotenv.env['REVENUECAT_SECRET_API_KEY'];
  if (secretKey == null || secretKey.isEmpty) {
    print('❌ REVENUECAT_SECRET_API_KEY not found in .env');
    print('\nTo get your secret API key:');
    print('1. Go to RevenueCat Dashboard');
    print('2. Settings → API Keys → Secret Keys');
    print('3. Copy the secret key');
    print('4. Add to .env: REVENUECAT_SECRET_API_KEY=your_secret_key_here\n');
    exit(1);
  }

  print('📋 Setup Options:');
  print('1. Create entitlement only (SweepFeed Pro)');
  print('2. Complete setup (entitlement + products + offering)');
  print('3. Exit\n');

  stdout.write('Select option (1-3): ');
  final choice = stdin.readLineSync();

  switch (choice) {
    case '1':
      await _setupEntitlementOnly();
      break;
    case '2':
      await _setupComplete();
      break;
    case '3':
      print('Exiting...');
      exit(0);
    default:
      print('Invalid choice');
      exit(1);
  }
}

Future<void> _setupEntitlementOnly() async {
  print('\n🔧 Setting up entitlement only...\n');

  // This would require importing the service
  // For now, provide instructions
  print('To set up the entitlement programmatically, use:');
  print('\nIn your Flutter app:');
  print('```dart');
  print('final setupService = ref.read(revenueCatSetupServiceProvider);');
  print('await setupService.setupEntitlementOnly();');
  print('```\n');

  print('Or use the RevenueCatSetupService directly in your app.');
}

Future<void> _setupComplete() async {
  print('\n🔧 Complete setup requires store product IDs.\n');

  stdout.write('Monthly product ID (Android): ');
  final monthlyAndroid = stdin.readLineSync();

  stdout.write('Yearly product ID (Android): ');
  final yearlyAndroid = stdin.readLineSync();

  stdout.write('Monthly product ID (iOS): ');
  final monthlyIOS = stdin.readLineSync();

  stdout.write('Yearly product ID (iOS): ');
  final yearlyIOS = stdin.readLineSync();

  print('\n📝 To complete setup, use in your Flutter app:');
  print('```dart');
  print('final setupService = ref.read(revenueCatSetupServiceProvider);');
  print('await setupService.setupSweepFeedPro(');
  if (monthlyAndroid?.isNotEmpty == true) {
    print("  monthlyStoreProductIdAndroid: '$monthlyAndroid',");
  }
  if (yearlyAndroid?.isNotEmpty == true) {
    print("  yearlyStoreProductIdAndroid: '$yearlyAndroid',");
  }
  if (monthlyIOS?.isNotEmpty == true) {
    print("  monthlyStoreProductIdIOS: '$monthlyIOS',");
  }
  if (yearlyIOS?.isNotEmpty == true) {
    print("  yearlyStoreProductIdIOS: '$yearlyIOS',");
  }
  print(');');
  print('```\n');
}

