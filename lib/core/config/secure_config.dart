import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

/// Secure configuration service for sensitive app credentials
///
/// This service centralizes access to sensitive configuration values,
/// prevents hardcoding of secrets, and provides validation for required values.
class SecureConfig {
  SecureConfig._();

  static bool _initialized = false;

  /// Initialize the configuration service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await dotenv.load();
      _initialized = true;
      logger.i('SecureConfig initialized successfully');

      // Validate critical configuration values
      _validateConfiguration();
    } on Exception catch (e) {
      logger.e('Failed to initialize SecureConfig', error: e);
      rethrow;
    }
  }

  /// Validates that all required configuration values are present
  static void _validateConfiguration() {
    final requiredKeys = [
      'FIREBASE_API_KEY',
      'FIREBASE_APP_ID',
      'FIREBASE_PROJECT_ID',
      'GOOGLE_SIGN_IN_CLIENT_ID',
    ];

    final missingKeys = <String>[];

    for (final key in requiredKeys) {
      if (!dotenv.env.containsKey(key) || dotenv.env[key]?.isEmpty == true) {
        missingKeys.add(key);
      }
    }

    if (missingKeys.isNotEmpty) {
      final error =
          'Missing required configuration keys: ${missingKeys.join(', ')}';
      logger.e(error);
      throw Exception(error);
    }
  }

  /// Get Google Sign-In client ID securely
  static String get googleSignInClientId {
    _ensureInitialized();
    final clientId = dotenv.env['GOOGLE_SIGN_IN_CLIENT_ID'];

    if (clientId == null || clientId.isEmpty) {
      throw Exception('Google Sign-In client ID not configured');
    }

    // Validate client ID format (basic validation)
    if (!_isValidGoogleClientId(clientId)) {
      throw Exception('Invalid Google Sign-In client ID format');
    }

    return clientId;
  }

  /// Get Apple Sign-In client ID securely
  static String get appleSignInClientId {
    _ensureInitialized();
    return dotenv.env['APPLE_SIGN_IN_CLIENT_ID'] ?? '';
  }

  /// Get Firebase API key
  static String get firebaseApiKey {
    _ensureInitialized();
    return dotenv.env['FIREBASE_API_KEY'] ?? '';
  }

  /// Get Firebase project ID
  static String get firebaseProjectId {
    _ensureInitialized();
    return dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  }

  /// Get app environment (dev, staging, prod)
  static String get environment {
    _ensureInitialized();
    return dotenv.env['APP_ENV'] ?? 'dev';
  }

  /// Check if we're in production environment
  static bool get isProduction => environment.toLowerCase() == 'prod';

  /// Check if we're in development environment
  static bool get isDevelopment => environment.toLowerCase() == 'dev';

  /// Get API base URL for backend services
  static String get apiBaseUrl {
    _ensureInitialized();
    final url = dotenv.env['API_BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('API base URL not configured');
    }
    return url;
  }

  /// Get encryption key for sensitive data
  static String get encryptionKey {
    _ensureInitialized();
    final key = dotenv.env['ENCRYPTION_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('Encryption key not configured');
    }
    return key;
  }

  /// Get OpenAI API key for AI features
  static String get openAIApiKey {
    _ensureInitialized();
    return dotenv.env['OPENAI_API_KEY'] ?? '';
  }

  /// Get RevenueCat API key for Android
  static String get revenueCatAndroidApiKey {
    _ensureInitialized();
    final key = dotenv.env['REVENUECAT_ANDROID_API_KEY'];
    if (key == null || key.isEmpty) {
      logger.w('RevenueCat Android API key not configured');
      return 'public_google_sdk_key'; // Fallback for development
    }
    return key;
  }

  /// Get RevenueCat API key for iOS
  static String get revenueCatIosApiKey {
    _ensureInitialized();
    final key = dotenv.env['REVENUECAT_IOS_API_KEY'];
    if (key == null || key.isEmpty) {
      logger.w('RevenueCat iOS API key not configured');
      return 'public_apple_sdk_key'; // Fallback for development
    }
    return key;
  }

  /// Validates Google Client ID format
  static bool _isValidGoogleClientId(String clientId) {
    // Google client IDs typically follow this pattern:
    // numbers-random_string.apps.googleusercontent.com
    final regex = RegExp(r'^\d+-[a-zA-Z0-9]+\.apps\.googleusercontent\.com$');
    return regex.hasMatch(clientId);
  }

  /// Ensures the service has been initialized
  static void _ensureInitialized() {
    if (!_initialized) {
      throw Exception('SecureConfig must be initialized before use');
    }
  }

  /// Get all non-sensitive configuration for debugging
  static Map<String, String> getDebugInfo() {
    _ensureInitialized();

    return {
      'environment': environment,
      'isProduction': isProduction.toString(),
      'firebaseProjectId': firebaseProjectId,
      'hasGoogleClientId':
          dotenv.env.containsKey('GOOGLE_SIGN_IN_CLIENT_ID').toString(),
      'hasAppleClientId':
          dotenv.env.containsKey('APPLE_SIGN_IN_CLIENT_ID').toString(),
      'hasApiBaseUrl': dotenv.env.containsKey('API_BASE_URL').toString(),
      'hasEncryptionKey': dotenv.env.containsKey('ENCRYPTION_KEY').toString(),
    };
  }
}
