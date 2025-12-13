import 'package:flutter_test/flutter_test.dart';
import 'package:sweepfeed/core/security/security_utils.dart';

void main() {
  group('SecurityUtils - Input Sanitization', () {
    test('sanitizes script tags', () {
      expect(
        SecurityUtils.sanitizeInput('<script>alert("XSS")</script>'),
        '&lt;script&gt;alert(&#34;XSS&#34;)&lt;/script&gt;',
      );
      expect(
        SecurityUtils.sanitizeInput('Hello<script>evil</script>World'),
        'Hello&lt;script&gt;evil&lt;/script&gt;World',
      );
    });

    test('sanitizes javascript protocol', () {
      expect(
        SecurityUtils.sanitizeInput('javascript:alert("XSS")'),
        'js:alert(&#34;XSS&#34;)',
      );
      expect(SecurityUtils.sanitizeInput('JAVASCRIPT:void(0)'), 'js:void(0)');
    });

    test('sanitizes iframe tags', () {
      expect(
        SecurityUtils.sanitizeInput('<iframe src="evil.com"></iframe>'),
        '&lt;iframe src=&#34;evil.com&#34;&gt;&lt;/iframe&gt;',
      );
    });

    test('sanitizes SQL injection characters', () {
      expect(
        SecurityUtils.sanitizeInput("'; DROP TABLE users; --"),
        '&#39;&#59; DROP TABLE users&#59; &#45;&#45;',
      );
      expect(SecurityUtils.sanitizeInput('"OR 1=1'), '&#34;OR 1=1');
    });

    test('truncates long input', () {
      final longInput = 'a' * 1500;
      final sanitized = SecurityUtils.sanitizeInput(longInput);
      expect(sanitized.length, 1000);
    });

    test('handles empty input', () {
      expect(SecurityUtils.sanitizeInput(''), '');
      expect(SecurityUtils.sanitizeInput('   '), '');
    });
  });

  group('SecurityUtils - URL Validation', () {
    test('validates safe URLs', () {
      expect(SecurityUtils.isValidUrl('https://example.com'), isTrue);
      expect(SecurityUtils.isValidUrl('http://example.com'), isTrue);
      expect(
        SecurityUtils.isValidUrl('https://sub.example.com/path?query=1'),
        isTrue,
      );
    });

    test('rejects unsafe URLs', () {
      expect(SecurityUtils.isValidUrl(''), isFalse);
      expect(SecurityUtils.isValidUrl('javascript:alert(1)'), isFalse);
      expect(SecurityUtils.isValidUrl('ftp://example.com'), isFalse);
      expect(SecurityUtils.isValidUrl('data:text/html,<script>'), isFalse);
      expect(SecurityUtils.isValidUrl('file:///etc/passwd'), isFalse);
    });

    test('blocks localhost and private IPs', () {
      expect(SecurityUtils.isValidUrl('http://localhost:8080'), isFalse);
      expect(SecurityUtils.isValidUrl('https://127.0.0.1'), isFalse);
      expect(SecurityUtils.isValidUrl('http://192.168.1.1'), isFalse);
      expect(SecurityUtils.isValidUrl('https://10.0.0.1'), isFalse);
    });

    test('blocks suspicious domains', () {
      expect(SecurityUtils.isValidUrl('https://malicious.tk'), isFalse);
      expect(SecurityUtils.isValidUrl('http://bit.ly/abc123'), isFalse);
      expect(SecurityUtils.isValidUrl('https://tinyurl.com/test'), isFalse);
    });
  });

  group('SecurityUtils - Email Validation', () {
    test('validates correct email formats', () {
      expect(SecurityUtils.isValidEmail('user@example.com'), isTrue);
      expect(SecurityUtils.isValidEmail('test.user@example.co.uk'), isTrue);
      expect(SecurityUtils.isValidEmail('user+tag@example.com'), isTrue);
    });

    test('rejects invalid email formats', () {
      expect(SecurityUtils.isValidEmail(''), isFalse);
      expect(SecurityUtils.isValidEmail('notanemail'), isFalse);
      expect(SecurityUtils.isValidEmail('@example.com'), isFalse);
      expect(SecurityUtils.isValidEmail('user@'), isFalse);
      expect(SecurityUtils.isValidEmail('user@.com'), isFalse);
    });

    test('blocks suspicious email patterns', () {
      expect(SecurityUtils.isValidEmail('user+script@example.com'), isFalse);
      expect(SecurityUtils.isValidEmail('user<script>@example.com'), isFalse);
      expect(SecurityUtils.isValidEmail('user@example.com/../'), isFalse);
      expect(SecurityUtils.isValidEmail('javascript:@example.com'), isFalse);
    });
  });

  group('SecurityUtils - Token Generation', () {
    test('generates tokens of correct length', () {
      final token16 = SecurityUtils.generateSecureToken(16);
      final token32 = SecurityUtils.generateSecureToken();
      final token64 = SecurityUtils.generateSecureToken(64);

      expect(token16.length, 16);
      expect(token32.length, 32);
      expect(token64.length, 64);
    });

    test('generates unique tokens', () {
      final token1 = SecurityUtils.generateSecureToken();
      final token2 = SecurityUtils.generateSecureToken();

      expect(token1, isNot(equals(token2)));
      expect(token1.length, 32); // Default length
    });
  });

  group('SecurityUtils - Hash Functions', () {
    test('hashes strings consistently', () {
      const input = 'test string';
      final hash1 = SecurityUtils.hashString(input);
      final hash2 = SecurityUtils.hashString(input);

      expect(hash1, equals(hash2));
      expect(hash1.length, 64); // SHA-256 produces 64-character hex string
    });

    test('produces different hashes for different inputs', () {
      final hash1 = SecurityUtils.hashString('input1');
      final hash2 = SecurityUtils.hashString('input2');

      expect(hash1, isNot(equals(hash2)));
    });

    test('uses salt correctly', () {
      const input = 'test';
      final hashNoSalt = SecurityUtils.hashString(input);
      final hashWithSalt = SecurityUtils.hashString(input, 'salt123');

      expect(hashNoSalt, isNot(equals(hashWithSalt)));
    });
  });

  group('SecurityUtils - Contest Data Validation', () {
    test('validates correct contest data', () {
      final validData = {
        'title': 'Valid Contest',
        'sponsor': 'Valid Sponsor',
        'value': '\$1000',
        'entryUrl': 'https://example.com/enter',
        'termsUrl': 'https://example.com/terms',
        'description': 'A valid contest description',
      };

      expect(SecurityUtils.validateContestData(validData), isTrue);
    });

    test('rejects missing required fields', () {
      final invalidData = {
        'title': 'Contest',
        // Missing sponsor, value, entryUrl, termsUrl
      };

      expect(SecurityUtils.validateContestData(invalidData), isFalse);
    });

    test('rejects invalid URLs in contest data', () {
      final invalidData = {
        'title': 'Contest',
        'sponsor': 'Sponsor',
        'value': '\$1000',
        'entryUrl': 'javascript:alert(1)',
        'termsUrl': 'https://example.com/terms',
      };

      expect(SecurityUtils.validateContestData(invalidData), isFalse);
    });

    test('rejects suspicious content in text fields', () {
      final invalidData = {
        'title': '<script>alert(1)</script>Contest',
        'sponsor': 'Sponsor',
        'value': '\$1000',
        'entryUrl': 'https://example.com/enter',
        'termsUrl': 'https://example.com/terms',
      };

      expect(SecurityUtils.validateContestData(invalidData), isFalse);
    });

    test('validates prize values', () {
      final validPrizes = ['\$1000', '£500', '€750', '¥10000', '5000'];
      for (final prize in validPrizes) {
        final data = {
          'title': 'Contest',
          'sponsor': 'Sponsor',
          'value': prize,
          'entryUrl': 'https://example.com/enter',
          'termsUrl': 'https://example.com/terms',
        };
        expect(
          SecurityUtils.validateContestData(data),
          isTrue,
          reason: 'Prize: $prize',
        );
      }
    });

    test('rejects invalid prize values', () {
      final invalidPrizes = ['invalid', '\$-100', '\$99999999999', ''];
      for (final prize in invalidPrizes) {
        final data = {
          'title': 'Contest',
          'sponsor': 'Sponsor',
          'value': prize,
          'entryUrl': 'https://example.com/enter',
          'termsUrl': 'https://example.com/terms',
        };
        expect(
          SecurityUtils.validateContestData(data),
          isFalse,
          reason: 'Prize: $prize',
        );
      }
    });
  });

  group('SecurityUtils - API Response Validation', () {
    test('validates clean API responses', () {
      final cleanResponse = {
        'data': [
          {'title': 'Contest 1', 'value': '1000'},
          {'title': 'Contest 2', 'value': '2000'},
        ],
        'status': 'success',
      };

      expect(SecurityUtils.validateApiResponse(cleanResponse), isTrue);
    });

    test('detects malicious script content', () {
      final maliciousResponse = {
        'data': '<script>alert("XSS")</script>',
        'status': 'success',
      };

      expect(SecurityUtils.validateApiResponse(maliciousResponse), isFalse);
    });

    test('detects javascript protocol', () {
      final maliciousResponse = {
        'redirect': 'javascript:alert(1)',
        'status': 'success',
      };

      expect(SecurityUtils.validateApiResponse(maliciousResponse), isFalse);
    });
  });

  group('SecurityUtils - Encryption/Decryption', () {
    test('encrypts and decrypts data correctly', () {
      const originalData = 'sensitive information';
      const key = 'encryption-key';

      final encrypted = SecurityUtils.encryptData(originalData, key);
      final decrypted = SecurityUtils.decryptData(encrypted, key);

      expect(decrypted, equals(originalData));
      expect(encrypted, isNot(equals(originalData)));
    });

    test('handles empty data', () {
      const key = 'key';

      expect(SecurityUtils.encryptData('', key), '');
      expect(SecurityUtils.decryptData('', key), '');
    });

    test('handles empty key', () {
      const data = 'data';

      expect(SecurityUtils.encryptData(data, ''), data);
      expect(SecurityUtils.decryptData(data, ''), data);
    });
  });

  group('SecurityUtils - Session Token Validation', () {
    test('validates correct session tokens', () {
      final token = SecurityUtils.generateSecureToken();
      expect(SecurityUtils.validateSessionToken(token), isTrue);
    });

    test('rejects invalid session tokens', () {
      expect(SecurityUtils.validateSessionToken(''), isFalse);
      expect(SecurityUtils.validateSessionToken('short'), isFalse);
      expect(SecurityUtils.validateSessionToken('invalid-base64!@#'), isFalse);
    });
  });

  group('SecurityUtils - Rate Limiting', () {
    test('allows requests within limit', () {
      const identifier = 'test-user-1';

      for (var i = 0; i < 5; i++) {
        expect(
          SecurityUtils.checkRateLimit(identifier),
          isTrue,
          reason: 'Request $i should be allowed',
        );
      }
    });

    test('blocks requests over limit', () {
      const identifier = 'test-user-2';

      // Fill up the limit
      for (var i = 0; i < 3; i++) {
        SecurityUtils.checkRateLimit(identifier, maxRequests: 3);
      }

      // Next request should be blocked
      expect(
        SecurityUtils.checkRateLimit(identifier, maxRequests: 3),
        isFalse,
      );
    });

    test('handles different identifiers separately', () {
      const identifier1 = 'user-1';
      const identifier2 = 'user-2';

      // Fill limit for user-1
      for (var i = 0; i < 3; i++) {
        SecurityUtils.checkRateLimit(identifier1, maxRequests: 3);
      }

      // user-2 should still be allowed
      expect(
        SecurityUtils.checkRateLimit(identifier2, maxRequests: 3),
        isTrue,
      );
    });
  });
}
