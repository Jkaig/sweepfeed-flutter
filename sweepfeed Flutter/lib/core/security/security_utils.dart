import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/logger.dart';

/// Utility class for security-related operations including input sanitization,
/// secure storage, and data validation.
class SecurityUtils {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Sanitizes user input to prevent XSS and injection attacks
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    // Remove/escape potentially dangerous characters
    var sanitized = input
        .replaceAll('<script', '&lt;script')
        .replaceAll('</script>', '&lt;/script&gt;')
        .replaceAll('<iframe', '&lt;iframe')
        .replaceAll('javascript:', 'js:')
        .replaceAll('data:', 'data-url:')
        .replaceAll('vbscript:', 'vbs:')
        .replaceAll('onload=', 'on-load=')
        .replaceAll('onerror=', 'on-error=')
        .replaceAll('onclick=', 'on-click=');

    // Remove potentially dangerous SQL characters
    sanitized = sanitized
        .replaceAll("'", '&#39;')
        .replaceAll('"', '&quot;')
        .replaceAll('--', '&#45;&#45;')
        .replaceAll(';', '&#59;');

    // Limit length to prevent buffer overflow attacks
    if (sanitized.length > 1000) {
      sanitized = sanitized.substring(0, 1000);
      logger.w('Input truncated due to length: ${sanitized.length}');
    }

    return sanitized.trim();
  }

  /// Validates URL to ensure it's safe for navigation
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);

      // Only allow https and http schemes
      if (!['https', 'http'].contains(uri.scheme.toLowerCase())) {
        return false;
      }

      // Validate domain format
      if (uri.host.isEmpty || !uri.host.contains('.')) {
        return false;
      }

      // Block localhost and private IPs for security
      if (uri.host.toLowerCase().contains('localhost') ||
          uri.host.startsWith('127.') ||
          uri.host.startsWith('192.168.') ||
          uri.host.startsWith('10.') ||
          uri.host.startsWith('172.')) {
        return false;
      }

      // Block suspicious TLDs or patterns
      final suspiciousDomains = [
        '.tk',
        '.ml',
        '.ga',
        '.cf',
        'bit.ly',
        'tinyurl.com',
        'malicious.example',
      ];

      for (final suspicious in suspiciousDomains) {
        if (uri.host.toLowerCase().contains(suspicious)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      logger.w('Invalid URL format: $url', error: e);
      return false;
    }
  }

  /// Validates email format and checks for security issues
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    // Basic email regex
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (!emailRegex.hasMatch(email)) {
      return false;
    }

    // Check for suspicious patterns
    final suspiciousPatterns = [
      r'\+.*script',
      r'\.\./',
      '<.*>',
      'javascript:',
    ];

    for (final pattern in suspiciousPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(email)) {
        return false;
      }
    }

    return true;
  }

  /// Generates a secure random token
  static String generateSecureToken([int length = 32]) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(bytes).substring(0, length);
  }

  /// Hashes a string using SHA-256
  static String hashString(String input, [String? salt]) {
    final bytes = utf8.encode(input + (salt ?? ''));
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Securely stores sensitive data
  static Future<void> securelyStore(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      logger.d('Securely stored data for key: $key');
    } catch (e) {
      logger.e('Failed to securely store data for key: $key', error: e);
      rethrow;
    }
  }

  /// Retrieves securely stored data
  static Future<String?> securelyRetrieve(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value != null) {
        logger.d('Successfully retrieved secure data for key: $key');
      }
      return value;
    } catch (e) {
      logger.e('Failed to retrieve secure data for key: $key', error: e);
      return null;
    }
  }

  /// Deletes securely stored data
  static Future<void> securelyDelete(String key) async {
    try {
      await _secureStorage.delete(key: key);
      logger.d('Successfully deleted secure data for key: $key');
    } catch (e) {
      logger.e('Failed to delete secure data for key: $key', error: e);
      rethrow;
    }
  }

  /// Clears all securely stored data
  static Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
      logger.i('All secure data cleared');
    } catch (e) {
      logger.e('Failed to clear all secure data', error: e);
      rethrow;
    }
  }

  /// Validates contest data for potential security issues
  static bool validateContestData(Map<String, dynamic> data) {
    try {
      // Check required fields exist
      final requiredFields = [
        'title',
        'sponsor',
        'value',
        'entryUrl',
        'termsUrl',
      ];
      for (final field in requiredFields) {
        if (!data.containsKey(field) || data[field] == null) {
          logger.w('Missing required field: $field');
          return false;
        }
      }

      // Validate URLs
      final urlFields = ['entryUrl', 'termsUrl', 'imageUrl'];
      for (final field in urlFields) {
        if (data.containsKey(field) && data[field] != null) {
          if (!isValidUrl(data[field].toString())) {
            logger.w('Invalid URL in field: $field');
            return false;
          }
        }
      }

      // Validate text fields for suspicious content
      final textFields = ['title', 'description', 'sponsor'];
      for (final field in textFields) {
        if (data.containsKey(field) && data[field] != null) {
          final sanitized = sanitizeInput(data[field].toString());
          if (sanitized != data[field].toString()) {
            logger.w('Suspicious content detected in field: $field');
            return false;
          }
        }
      }

      // Validate prize value
      if (data.containsKey('value')) {
        final value = data['value'].toString();
        if (!_isValidPrizeValue(value)) {
          logger.w('Invalid prize value: $value');
          return false;
        }
      }

      return true;
    } catch (e) {
      logger.e('Error validating contest data', error: e);
      return false;
    }
  }

  /// Validates prize value format and range
  static bool _isValidPrizeValue(String value) {
    if (value.isEmpty) return false;

    // Remove common currency symbols and whitespace
    final cleanValue = value.replaceAll(RegExp(r'[\$£€¥,\s]'), '');

    // Check if it's a valid number
    final number = double.tryParse(cleanValue);
    if (number == null) return false;

    // Reasonable range for prize values ($0 - $10M)
    return number >= 0 && number <= 10000000;
  }

  /// Validates API response data structure
  static bool validateApiResponse(Map<String, dynamic> response) {
    try {
      // Check for common attack patterns in API responses
      final jsonString = jsonEncode(response);

      final suspiciousPatterns = [
        '<script.*?>.*?</script>',
        'javascript:',
        'data:text/html',
        r'eval\(',
        r'document\.cookie',
        r'window\.location',
      ];

      for (final pattern in suspiciousPatterns) {
        if (RegExp(pattern, caseSensitive: false).hasMatch(jsonString)) {
          logger.w('Suspicious pattern detected in API response: $pattern');
          return false;
        }
      }

      return true;
    } catch (e) {
      logger.e('Error validating API response', error: e);
      return false;
    }
  }

  /// Encrypts data using a simple XOR cipher (for demonstration)
  /// Note: In production, use proper encryption libraries
  static String encryptData(String data, String key) {
    if (data.isEmpty || key.isEmpty) return data;

    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final encrypted = <int>[];

    for (var i = 0; i < dataBytes.length; i++) {
      encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64.encode(encrypted);
  }

  /// Decrypts data using XOR cipher
  static String decryptData(String encryptedData, String key) {
    if (encryptedData.isEmpty || key.isEmpty) return encryptedData;

    try {
      final keyBytes = utf8.encode(key);
      final encrypted = base64.decode(encryptedData);
      final decrypted = <int>[];

      for (var i = 0; i < encrypted.length; i++) {
        decrypted.add(encrypted[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decrypted);
    } catch (e) {
      logger.e('Failed to decrypt data', error: e);
      return '';
    }
  }

  /// Validates user session token
  static bool validateSessionToken(String token) {
    if (token.isEmpty) return false;

    // Check token format (base64 with minimum length)
    if (token.length < 16) return false;

    try {
      base64.decode(token);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Rate limiting check (simple in-memory implementation)
  static final Map<String, List<DateTime>> _rateLimitMap = {};

  static bool checkRateLimit(
    String identifier, {
    int maxRequests = 10,
    Duration window = const Duration(minutes: 1),
  }) {
    final now = DateTime.now();
    final windowStart = now.subtract(window);

    // Clean old entries
    _rateLimitMap[identifier]
        ?.removeWhere((timestamp) => timestamp.isBefore(windowStart));

    // Initialize if not exists
    _rateLimitMap[identifier] ??= [];

    // Check if within limit
    if (_rateLimitMap[identifier]!.length >= maxRequests) {
      logger.w('Rate limit exceeded for: $identifier');
      return false;
    }

    // Add current request
    _rateLimitMap[identifier]!.add(now);
    return true;
  }

  /// Sanitizes a string by removing/escaping dangerous content and HTML encoding
  static String sanitizeString(String input) {
    if (input.isEmpty) return input;

    // Remove script and iframe tags entirely
    var sanitized = input.replaceAll(
        RegExp(r'<script[^>]*>.*?</script>',
            caseSensitive: false, dotAll: true),
        '');
    sanitized = sanitized.replaceAll(
        RegExp(r'<iframe[^>]*>.*?</iframe>',
            caseSensitive: false, dotAll: true),
        '');

    // Remove javascript protocol
    sanitized =
        sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');

    // Remove event handlers
    sanitized =
        sanitized.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');

    // HTML encode special characters
    sanitized = sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .replaceAll('/', '&#x2F;');

    // Truncate if too long
    if (sanitized.length > 5000) {
      sanitized = sanitized.substring(0, 5000);
    }

    return sanitized;
  }

  /// Generalizes location by keeping only the first two components
  static String generalizeLocation(String location) {
    if (location.isEmpty) return 'Unknown Location';

    final parts = location.split(',').map((part) => part.trim()).toList();

    if (parts.length >= 2) {
      return '${parts[0]}, ${parts[1]}';
    } else if (parts.length == 1) {
      return parts[0];
    }

    return 'Unknown Location';
  }

  /// Checks if a string is safe based on security criteria
  static bool isSafeString(String input) {
    if (input.isEmpty) return false;
    if (input.length > 255) return false;

    // Check for dangerous patterns
    final dangerousPatterns = [
      r'<script[^>]*>',
      r'javascript:',
      r'<iframe[^>]*>',
      r'on\w+\s*=',
      r'[<>"\u0027]',
    ];

    for (final pattern in dangerousPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(input)) {
        return false;
      }
    }

    return true;
  }

  /// Validates file size against security limits
  static bool isValidFileSize(int sizeInBytes) {
    if (sizeInBytes <= 0) return false;

    // 5MB limit
    const maxSize = 5 * 1024 * 1024;
    return sizeInBytes <= maxSize;
  }

  /// Validates file extension against allowed extensions
  static bool isValidFileExtension(
      String filename, List<String> allowedExtensions) {
    if (filename.isEmpty) return false;

    final extension = filename.toLowerCase().split('.').last;
    final normalizedExtensions = allowedExtensions
        .map((ext) => ext.toLowerCase().replaceAll('.', ''))
        .toList();

    return normalizedExtensions.contains(extension);
  }

  /// Detects SQL injection patterns in input
  static bool containsSqlInjectionPattern(String input) {
    final sqlPatterns = [
      r"'\s*OR\s+1\s*=\s*1",
      r"'\s*OR\s+",
      r'UNION\s+SELECT',
      r'DROP\s+TABLE',
      r"'\s*--",
      r';.*--',
      r'INSERT\s+INTO',
      r'DELETE\s+FROM',
      r'UPDATE\s+.*SET',
    ];

    for (final pattern in sqlPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(input)) {
        return true;
      }
    }

    return false;
  }

  /// Redacts sensitive information from text
  static String redactSensitiveInfo(String text) {
    var redacted = text;

    // Redact email addresses
    redacted = redacted.replaceAll(
        RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
        '[EMAIL_REDACTED]');

    // Redact phone numbers (various formats)
    redacted = redacted.replaceAll(
        RegExp(r'\b\d{3}-\d{3}-\d{4}\b'), '[PHONE_REDACTED]');
    redacted = redacted.replaceAll(
        RegExp(r'\b\(\d{3}\)\s*\d{3}-\d{4}\b'), '[PHONE_REDACTED]');

    // Redact credit card numbers
    redacted = redacted.replaceAll(
        RegExp(r'\b\d{4}\s*\d{4}\s*\d{4}\s*\d{4}\b'), '[CC_REDACTED]');

    // Redact SSN
    redacted =
        redacted.replaceAll(RegExp(r'\b\d{3}-\d{2}-\d{4}\b'), '[SSN_REDACTED]');

    return redacted;
  }

  /// Validates password strength and returns detailed results
  static Map<String, dynamic> validatePasswordStrength(String password) {
    final errors = <String>[];
    var strength = 0;

    // Check length
    if (password.length < 8) {
      errors.add('Password must be at least 8 characters long');
    } else {
      strength += 20;
    }

    // Check for uppercase
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('Password must contain at least one uppercase letter');
    } else {
      strength += 20;
    }

    // Check for lowercase
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add('Password must contain at least one lowercase letter');
    } else {
      strength += 20;
    }

    // Check for numbers
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      errors.add('Password must contain at least one number');
    } else {
      strength += 20;
    }

    // Check for special characters
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      errors.add('Password must contain at least one special character');
    } else {
      strength += 20;
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'strength': strength,
    };
  }

  /// Strips HTML tags from text
  static String stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Sanitizes filename by removing dangerous characters
  static String sanitizeFilename(String filename) {
    if (filename.isEmpty) return 'unnamed';

    // Replace dangerous characters with underscores
    var sanitized = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    // Replace spaces with underscores
    sanitized = sanitized.replaceAll(' ', '_');

    // Remove any remaining dangerous patterns
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '_');

    return sanitized.isEmpty ? 'unnamed' : sanitized;
  }

  /// Recursively sanitizes data structures (maps and lists)
  static dynamic sanitizeData(dynamic data, {int depth = 0}) {
    const maxDepth = 10;

    if (depth > maxDepth) {
      return 'Maximum recursion depth exceeded';
    }

    if (data is String) {
      return sanitizeString(data);
    } else if (data is Map<String, dynamic>) {
      final sanitized = <String, dynamic>{};
      for (final entry in data.entries) {
        if (entry.key == 'location') {
          sanitized[entry.key] = generalizeLocation(entry.value.toString());
        } else {
          sanitized[entry.key] = sanitizeData(entry.value, depth: depth + 1);
        }
      }
      return sanitized;
    } else if (data is List) {
      return data.map((item) => sanitizeData(item, depth: depth + 1)).toList();
    }

    return data;
  }
}
