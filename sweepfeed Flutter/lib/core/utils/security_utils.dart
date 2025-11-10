/// Security utilities for data sanitization, IP masking, and input validation
///
/// This class provides centralized security functions to prevent XSS attacks,
/// protect user privacy, and ensure data integrity across the application.
class SecurityUtils {
  SecurityUtils._();

  static const int _maxStringLength = 5000;
  static const int _maxRecursionDepth = 10;

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

  /// Generalizes location data to protect user privacy
  ///
  /// Reduces location precision by keeping only the first two components
  /// (e.g., "New York, NY, 10001" -> "New York, NY")
  static String generalizeLocation(String location) {
    if (location.isEmpty) {
      return 'Unknown Location';
    }

    final locationParts = location.split(',').map((s) => s.trim()).toList();

    if (locationParts.length >= 2) {
      return '${locationParts[0]}, ${locationParts[1]}';
    }

    return locationParts.first;
  }

  /// Sanitizes a string to prevent XSS attacks
  ///
  /// Performs the following operations:
  /// 1. Truncates to maximum length
  /// 2. Removes dangerous script tags and iframes
  /// 3. Removes javascript: protocol handlers
  /// 4. Removes inline event handlers (onclick, onload, etc.)
  /// 5. HTML-encodes special characters
  static String sanitizeString(String value) {
    if (value.isEmpty) {
      return value;
    }

    var sanitized = value;

    if (sanitized.length > _maxStringLength) {
      sanitized = sanitized.substring(0, _maxStringLength);
    }

    sanitized = sanitized
        .replaceAll(
          RegExp(
            '<script[^>]*>.*?</script>',
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            '<iframe[^>]*>.*?</iframe>',
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            '<object[^>]*>.*?</object>',
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(RegExp('<embed[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp('javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '')
        .replaceAll(RegExp('<link[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp('<meta[^>]*>', caseSensitive: false), '');

    sanitized = _htmlEncode(sanitized);

    return sanitized;
  }

  /// HTML-encodes special characters to prevent XSS
  static String _htmlEncode(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;')
      .replaceAll('/', '&#x2F;');

  /// Sanitizes an entire data map recursively
  ///
  /// Applies string sanitization to all string values in the map,
  /// recursively processing nested maps and lists.
  ///
  /// Protects against stack overflow with a maximum recursion depth.
  static Map<String, dynamic> sanitizeData(
    Map<String, dynamic> data, {
    int depth = 0,
  }) {
    if (depth > _maxRecursionDepth) {
      return {'error': 'Maximum recursion depth exceeded'};
    }

    final sanitized = <String, dynamic>{};

    data.forEach((key, value) {
      final sanitizedKey = sanitizeString(key);

      if (value is String) {
        sanitized[sanitizedKey] = sanitizeString(value);
      } else if (value is Map) {
        sanitized[sanitizedKey] = sanitizeData(
          Map<String, dynamic>.from(value),
          depth: depth + 1,
        );
      } else if (value is List) {
        sanitized[sanitizedKey] = _sanitizeList(value, depth: depth + 1);
      } else {
        sanitized[sanitizedKey] = value;
      }
    });

    return sanitized;
  }

  /// Sanitizes a list recursively
  static List<dynamic> _sanitizeList(List<dynamic> list, {int depth = 0}) {
    if (depth > _maxRecursionDepth) {
      return ['Maximum recursion depth exceeded'];
    }

    return list.map((item) {
      if (item is String) {
        return sanitizeString(item);
      } else if (item is Map) {
        return sanitizeData(
          Map<String, dynamic>.from(item),
          depth: depth + 1,
        );
      } else if (item is List) {
        return _sanitizeList(item, depth: depth + 1);
      }
      return item;
    }).toList();
  }

  /// Validates an email address format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email) && email.length <= 320;
  }

  /// Validates a URL format and checks for allowed protocols
  static bool isValidUrl(
    String url, {
    List<String> allowedProtocols = const ['https', 'http'],
  }) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);

      if (!uri.hasScheme || !allowedProtocols.contains(uri.scheme)) {
        return false;
      }

      if (!uri.hasAuthority) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validates that a string contains only safe characters
  ///
  /// Useful for validating usernames, identifiers, etc.
  static bool isSafeString(String value, {int maxLength = 255}) {
    if (value.isEmpty || value.length > maxLength) {
      return false;
    }

    final safePattern = RegExp(r'^[a-zA-Z0-9\s\-_.@]+$');
    return safePattern.hasMatch(value);
  }

  /// Strips all HTML tags from a string
  static String stripHtmlTags(String html) {
    if (html.isEmpty) return html;

    return html.replaceAll(RegExp('<[^>]*>', dotAll: true), '');
  }

  /// Validates that a file size is within acceptable limits
  static bool isValidFileSize(int sizeInBytes, {int maxSizeInMB = 5}) {
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    return sizeInBytes > 0 && sizeInBytes <= maxSizeInBytes;
  }

  /// Validates a file extension against a whitelist
  static bool isValidFileExtension(
    String filename,
    List<String> allowedExtensions,
  ) {
    if (filename.isEmpty) return false;

    final extension = filename.toLowerCase().split('.').last;
    return allowedExtensions.contains('.$extension') ||
        allowedExtensions.contains(extension);
  }

  /// Generates a safe filename by removing dangerous characters
  static String sanitizeFilename(String filename) {
    if (filename.isEmpty) return 'unnamed';

    return filename
        .replaceAll(RegExp(r'[^\w\s\-.]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp('_{2,}'), '_')
        .substring(0, filename.length > 255 ? 255 : filename.length);
  }

  /// Checks if a string contains potential SQL injection patterns
  ///
  /// Note: This is a basic check and should not replace proper parameterized queries
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

  /// Redacts sensitive information from strings
  ///
  /// Useful for logging without exposing sensitive data
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
}
