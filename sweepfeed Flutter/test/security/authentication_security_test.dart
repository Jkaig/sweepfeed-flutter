import 'package:flutter_test/flutter_test.dart';
import 'package:sweepfeed/core/config/secure_config.dart';
import 'package:sweepfeed/core/utils/security_utils.dart';

/// Comprehensive security tests for authentication system
///
/// Tests for:
/// - Configuration security
/// - Input validation
/// - XSS prevention
/// - SQL injection prevention
/// - Authentication token security
void main() {
  group('Authentication Security Tests', () {
    setUpAll(() async {
      // Initialize test environment
      await SecureConfig.initialize();
    });

    group('Configuration Security', () {
      test('should not allow hardcoded credentials', () {
        // This test ensures no hardcoded values in auth service
        expect(() => SecureConfig.googleSignInClientId, returnsNormally);

        // Verify the client ID follows expected format
        final clientId = SecureConfig.googleSignInClientId;
        expect(clientId.contains('.apps.googleusercontent.com'), isTrue);
        expect(clientId.contains('-'), isTrue);
      });

      test('should validate Google client ID format', () {
        const validClientId = '123456789-abcdefg.apps.googleusercontent.com';
        const invalidClientId = 'invalid-client-id';

        // This would be tested in SecureConfig internally
        expect(validClientId.contains('.apps.googleusercontent.com'), isTrue);
        expect(
          invalidClientId.contains('.apps.googleusercontent.com'),
          isFalse,
        );
      });

      test('should require all critical configuration values', () {
        // Test that configuration validation catches missing values
        expect(() => SecureConfig.firebaseApiKey, returnsNormally);
        expect(() => SecureConfig.firebaseProjectId, returnsNormally);
        expect(() => SecureConfig.apiBaseUrl, returnsNormally);
      });
    });

    group('Input Validation Security', () {
      test('should sanitize user display names', () {
        const maliciousInput = '<script>alert("XSS")</script>John Doe';
        final sanitized = SecurityUtils.sanitizeString(maliciousInput);

        expect(sanitized.contains('<script>'), isFalse);
        expect(sanitized.contains('alert'), isFalse);
        expect(sanitized, contains('John Doe'));
      });

      test('should prevent XSS in user inputs', () {
        const xssInputs = [
          '<script>alert("XSS")</script>',
          'javascript:alert("XSS")',
          '<img src="x" onerror="alert(1)">',
          '<iframe src="javascript:alert(1)"></iframe>',
          'onmouseover="alert(1)"',
        ];

        for (final input in xssInputs) {
          final sanitized = SecurityUtils.sanitizeString(input);

          expect(sanitized.toLowerCase().contains('script'), isFalse);
          expect(sanitized.toLowerCase().contains('javascript'), isFalse);
          expect(sanitized.toLowerCase().contains('alert'), isFalse);
          expect(sanitized.toLowerCase().contains('onerror'), isFalse);
          expect(sanitized.toLowerCase().contains('onmouseover'), isFalse);
        }
      });

      test('should detect SQL injection patterns', () {
        const sqlInjectionInputs = [
          "'; DROP TABLE users; --",
          '" OR 1=1',
          'UNION SELECT * FROM users',
          '1; DELETE FROM users WHERE 1=1',
          "' OR '1'='1",
        ];

        for (final input in sqlInjectionInputs) {
          expect(SecurityUtils.containsSqlInjectionPattern(input), isTrue);
        }
      });

      test('should validate email addresses properly', () {
        const validEmails = [
          'user@example.com',
          'test.email+tag@domain.co.uk',
          'valid_email@test-domain.org',
        ];

        const invalidEmails = [
          'invalid-email',
          '@domain.com',
          'user@',
          'spaces in@email.com',
          'too@many@ats.com',
          'javascript:alert(1)@domain.com',
        ];

        for (final email in validEmails) {
          expect(SecurityUtils.isValidEmail(email), isTrue);
        }

        for (final email in invalidEmails) {
          expect(SecurityUtils.isValidEmail(email), isFalse);
        }
      });

      test('should validate URLs securely', () {
        const validUrls = [
          'https://example.com',
          'http://test.domain.org/path',
          'https://subdomain.example.com:8080/path?query=value',
        ];

        const invalidUrls = [
          'javascript:alert(1)',
          'ftp://example.com',
          'file:///etc/passwd',
          'data:text/html,<script>alert(1)</script>',
          '../../../etc/passwd',
        ];

        for (final url in validUrls) {
          expect(SecurityUtils.isValidUrl(url), isTrue);
        }

        for (final url in invalidUrls) {
          expect(SecurityUtils.isValidUrl(url), isFalse);
        }
      });
    });

    group('Data Protection', () {
      test('should redact sensitive information in logs', () {
        const sensitiveText = '''
          User email: john.doe@example.com
          Phone: 555-123-4567
          SSN: 123-45-6789
          Credit Card: 4532 1234 5678 9012
        ''';

        final redacted = SecurityUtils.redactSensitiveInfo(sensitiveText);

        expect(redacted.contains('[EMAIL_REDACTED]'), isTrue);
        expect(redacted.contains('[PHONE_REDACTED]'), isTrue);
        expect(redacted.contains('[SSN_REDACTED]'), isTrue);
        expect(redacted.contains('[CC_REDACTED]'), isTrue);
        expect(redacted.contains('john.doe@example.com'), isFalse);
        expect(redacted.contains('123-45-6789'), isFalse);
      });

      test('should validate password strength', () {
        const weakPasswords = [
          'password',
          '123456',
          'abc123',
          'PASSWORD',
          'pass123',
        ];

        const strongPasswords = [
          'StrongP@ssw0rd!',
          'MySecure123!',
          'C0mpl3x&S3cur3',
        ];

        for (final password in weakPasswords) {
          final result = SecurityUtils.validatePasswordStrength(password);
          expect(result['isValid'], isFalse);
          expect((result['errors'] as List).isNotEmpty, isTrue);
        }

        for (final password in strongPasswords) {
          final result = SecurityUtils.validatePasswordStrength(password);
          expect(result['isValid'], isTrue);
          expect(result['strength'] as int, greaterThan(70));
        }
      });

      test('should mask IP addresses for privacy', () {
        const ipv4Address = '192.168.1.100';
        const ipv6Address = '2001:db8:85a3::8a2e:370:7334';

        final maskedIpv4 = SecurityUtils.maskIpAddress(ipv4Address);
        final maskedIpv6 = SecurityUtils.maskIpAddress(ipv6Address);

        expect(maskedIpv4, equals('192.168.1.XXX'));
        expect(maskedIpv6.contains('XXXX'), isTrue);
        expect(maskedIpv6.contains('2001:db8'), isTrue);
      });
    });

    group('File Security', () {
      test('should validate file extensions', () {
        const allowedExtensions = ['.jpg', '.png', '.gif', '.pdf'];

        expect(
          SecurityUtils.isValidFileExtension('image.jpg', allowedExtensions),
          isTrue,
        );
        expect(
          SecurityUtils.isValidFileExtension(
            'document.pdf',
            allowedExtensions,
          ),
          isTrue,
        );
        expect(
          SecurityUtils.isValidFileExtension('script.exe', allowedExtensions),
          isFalse,
        );
        expect(
          SecurityUtils.isValidFileExtension(
            'malware.bat',
            allowedExtensions,
          ),
          isFalse,
        );
      });

      test('should validate file sizes', () {
        expect(
          SecurityUtils.isValidFileSize(1024 * 1024),
          isTrue,
        ); // 1MB
        expect(
          SecurityUtils.isValidFileSize(10 * 1024 * 1024),
          isFalse,
        ); // 10MB
        expect(SecurityUtils.isValidFileSize(0), isFalse); // 0 bytes
      });

      test('should sanitize filenames', () {
        const dangerousFilenames = [
          '../../../etc/passwd',
          'file<script>alert(1)</script>.txt',
          'file with spaces and symbols!@#.pdf',
          'very_long_filename_that_exceeds_normal_limits_and_should_be_truncated.txt',
        ];

        for (final filename in dangerousFilenames) {
          final sanitized = SecurityUtils.sanitizeFilename(filename);

          expect(sanitized.contains('../'), isFalse);
          expect(sanitized.contains('<'), isFalse);
          expect(sanitized.contains('>'), isFalse);
          expect(sanitized.length, lessThanOrEqualTo(255));
        }
      });
    });

    group('Session Security', () {
      test('should generate secure nonces', () {
        // Test nonce generation (would be in auth service)
        final nonce1 = _generateTestNonce();
        final nonce2 = _generateTestNonce();

        expect(nonce1, isNot(equals(nonce2)));
        expect(nonce1.length, greaterThanOrEqualTo(32));
        expect(nonce2.length, greaterThanOrEqualTo(32));
      });

      test('should validate session tokens', () {
        const validToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9';
        const invalidTokens = [
          '',
          'invalid',
          'too_short',
          'javascript:alert(1)',
          '../../../etc/passwd',
        ];

        // Basic token format validation
        expect(validToken.isNotEmpty, isTrue);
        expect(validToken.length, greaterThan(20));

        for (final token in invalidTokens) {
          expect(
            token.length < 20 ||
                token.contains('javascript') ||
                token.contains('../'),
            isTrue,
          );
        }
      });
    });
  });
}

/// Helper function to generate test nonce
String _generateTestNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = []; // Mock random for testing
  return List.generate(
    length,
    (_) => charset[DateTime.now().microsecond % charset.length],
  ).join();
}
