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

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email) && email.length <= 320;
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
        RegExp('<script[^>]*>.*?</script>',
            caseSensitive: false, dotAll: true,),
        '',);
    sanitized = sanitized.replaceAll(
        RegExp('<iframe[^>]*>.*?</iframe>',
            caseSensitive: false, dotAll: true,),
        '',);

    // Remove javascript protocol
    sanitized =
        sanitized.replaceAll(RegExp('javascript:', caseSensitive: false), '');

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
  static bool isSafeString(String value, {int maxLength = 255}) {
    if (value.isEmpty || value.length > maxLength) {
      return false;
    }

    final safePattern = RegExp(r'^[a-zA-Z0-9\s\-_.@]+$');
    return safePattern.hasMatch(value);
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
      String filename, List<String> allowedExtensions,) {
    if (filename.isEmpty) return false;

    final extension = filename.toLowerCase().split('.').last;
    final normalizedExtensions = allowedExtensions
        .map((ext) => ext.toLowerCase().replaceAll('.', ''))
        .toList();

    return normalizedExtensions.contains(extension);
  }

  /// Detects SQL injection patterns in input
  static bool containsSqlInjectionPattern(String input) {
    if (input.isEmpty) return false;

    final sqlPatterns = [
      RegExp(
        r'(\s|^)(union|select|insert|update|delete|drop|create|alter|exec|execute)(\s|$)',
        caseSensitive: false,
      ),
      RegExp("[';]--"),
      RegExp(r'(--|#|/\*|\*/)', caseSensitive: false),
      RegExp(r'(\s|^)(and|or)(\s+)\d+\s*=\s*\d+', caseSensitive: false),
    ];

    return sqlPatterns.any((pattern) => pattern.hasMatch(input));
  }

  /// Redacts sensitive information from text
  static String redactSensitiveInfo(String text) {
    if (text.isEmpty) return text;

    var redacted = text;

    final emailPattern =
        RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    redacted = redacted.replaceAll(emailPattern, '[EMAIL_REDACTED]');

    final phonePattern = RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b');
    redacted = redacted.replaceAll(phonePattern, '[PHONE_REDACTED]');

    final ssnPattern = RegExp(r'\b\d{3}-\d{2}-\d{4}\b');
    redacted = redacted.replaceAll(ssnPattern, '[SSN_REDACTED]');

    final creditCardPattern =
        RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b');
    redacted = redacted.replaceAll(creditCardPattern, '[CC_REDACTED]');

    return redacted;
  }

  /// Validates password strength
  ///
  /// Returns a map with validation results:
  /// - isValid: true if all criteria are met
  /// - errors: list of validation failures
  static Map<String, dynamic> validatePasswordStrength(String password) {
    final errors = <String>[];

    if (password.length < 8) {
      errors.add('Password must be at least 8 characters long');
    }

    if (!RegExp('[A-Z]').hasMatch(password)) {
      errors.add('Password must contain at least one uppercase letter');
    }

    if (!RegExp('[a-z]').hasMatch(password)) {
      errors.add('Password must contain at least one lowercase letter');
    }

    if (!RegExp('[0-9]').hasMatch(password)) {
      errors.add('Password must contain at least one number');
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      errors.add('Password must contain at least one special character');
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'strength': _calculatePasswordStrength(password),
    };
  }

  /// Calculates password strength score (0-100)
  static int _calculatePasswordStrength(String password) {
    var score = 0;

    if (password.length >= 8) score += 20;
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;

    if (RegExp('[A-Z]').hasMatch(password)) score += 15;
    if (RegExp('[a-z]').hasMatch(password)) score += 15;
    if (RegExp('[0-9]').hasMatch(password)) score += 15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 15;

    return score.clamp(0, 100);
  }

  /// Strips HTML tags from text
  static String stripHtmlTags(String html) => html.replaceAll(RegExp('<[^>]*>'), '');

  /// Sanitizes filename by removing dangerous characters
  static String sanitizeFilename(String filename) {
    if (filename.isEmpty) return 'unnamed';

    return filename
        .replaceAll(RegExp(r'[^\w\s\-.]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp('_{2,}'), '_')
        .substring(0, filename.length > 255 ? 255 : filename.length);
  }

  /// Recursively sanitizes data structures (maps and lists)
  static dynamic sanitizeData(data, {int depth = 0}) {
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

  /// Masks an IP address for privacy protection
  ///
  /// Supports both IPv4 and IPv6 addresses:
  /// - IPv4: Masks the last octet (e.g., 192.168.1.100 -> 192.168.1.XXX)
  /// - IPv6: Masks the last 4 segments (e.g., 2001:db8::1 -> 2001:db8::XXXX)
  ///
  /// Returns a fully masked placeholder if the format is invalid.
  static String maskIpAddress(String ipAddress) {
    if (ipAddress.isEmpty) {
      return 'XXX.XXX.XXX.XXX';
    }

    if (ipAddress.contains(':')) {
      return _maskIpv6(ipAddress);
    } else {
      return _maskIpv4(ipAddress);
    }
  }

  /// Masks IPv4 addresses
  static String _maskIpv4(String ipAddress) {
    final parts = ipAddress.split('.');

    if (parts.length != 4) {
      return 'XXX.XXX.XXX.XXX';
    }

    for (final part in parts) {
      if (int.tryParse(part) == null) {
        return 'XXX.XXX.XXX.XXX';
      }
    }

    return '${parts[0]}.${parts[1]}.${parts[2]}.XXX';
  }

  /// Masks IPv6 addresses
  static String _maskIpv6(String ipAddress) {
    final parts = ipAddress.split(':');

    if (parts.length < 3) {
      return 'XXXX:XXXX:XXXX:XXXX';
    }

    final visibleSegments = parts.length <= 4 ? 2 : 4;
    final maskedParts = parts.take(visibleSegments).toList();
    maskedParts.add('XXXX');

    return maskedParts.join(':');
  }
}
