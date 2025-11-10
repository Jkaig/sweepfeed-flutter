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

  group('SecurityUtils - Location Generalization', () {
    test('generalizes location with multiple components', () {
      expect(
        SecurityUtils.generalizeLocation('New York, NY, 10001'),
        'New York, NY',
      );
      expect(
        SecurityUtils.generalizeLocation('Los Angeles, CA, USA'),
        'Los Angeles, CA',
      );
      expect(
        SecurityUtils.generalizeLocation('London, England, UK'),
        'London, England',
      );
    });

    test('handles locations with two components', () {
      expect(SecurityUtils.generalizeLocation('New York, NY'), 'New York, NY');
      expect(SecurityUtils.generalizeLocation('London, UK'), 'London, UK');
    });

    test('handles single component locations', () {
      expect(SecurityUtils.generalizeLocation('USA'), 'USA');
      expect(SecurityUtils.generalizeLocation('London'), 'London');
    });

    test('handles empty or invalid locations', () {
      expect(SecurityUtils.generalizeLocation(''), 'Unknown Location');
    });
  });

  group('SecurityUtils - String Sanitization', () {
    test('removes script tags', () {
      expect(
        SecurityUtils.sanitizeString('<script>alert("XSS")</script>'),
        '',
      );
      expect(
        SecurityUtils.sanitizeString('Hello<script>alert("XSS")</script>World'),
        'HelloWorld',
      );
    });

    test('removes iframe tags', () {
      expect(
        SecurityUtils.sanitizeString('<iframe src="malicious.com"></iframe>'),
        '',
      );
    });

    test('removes javascript protocol', () {
      expect(
        SecurityUtils.sanitizeString('javascript:alert("XSS")'),
        'alert(&quot;XSS&quot;)',
      );
    });

    test('removes event handlers', () {
      expect(
        SecurityUtils.sanitizeString('<img src="x" onerror="alert(1)">'),
        '&lt;img src=&quot;x&quot; &quot;alert(1)&quot;&gt;',
      );
    });

    test('HTML-encodes special characters', () {
      expect(
        SecurityUtils.sanitizeString('<div>Test</div>'),
        '&lt;div&gt;Test&lt;&#x2F;div&gt;',
      );
      expect(SecurityUtils.sanitizeString('"quoted"'), '&quot;quoted&quot;');
      expect(SecurityUtils.sanitizeString("'quoted'"), '&#39;quoted&#39;');
      expect(SecurityUtils.sanitizeString('a & b'), 'a &amp; b');
    });

    test('truncates long strings', () {
      final longString = 'a' * 6000;
      final sanitized = SecurityUtils.sanitizeString(longString);
      expect(sanitized.length, 5000);
    });

    test('handles empty strings', () {
      expect(SecurityUtils.sanitizeString(''), '');
    });

    test('removes multiple XSS vectors', () {
      const malicious =
          '<script>alert(1)</script><iframe src="x"></iframe>javascript:void(0)';
      final sanitized = SecurityUtils.sanitizeString(malicious);
      expect(sanitized.contains('script'), false);
      expect(sanitized.contains('iframe'), false);
      expect(sanitized.contains('javascript'), false);
    });
  });

  group('SecurityUtils - Data Sanitization', () {
    test('sanitizes nested maps', () {
      final data = {
        'name': '<script>alert(1)</script>John',
        'profile': {
          'bio': '<iframe>test</iframe>',
          'location': 'New York, NY, 10001',
        },
      };

      final sanitized = SecurityUtils.sanitizeData(data);
      expect(sanitized['name'], 'John');
      expect((sanitized['profile'] as Map)['bio'], '');
    });

    test('sanitizes lists', () {
      final data = {
        'tags': ['<script>tag1</script>', 'tag2', '<iframe>tag3</iframe>'],
      };

      final sanitized = SecurityUtils.sanitizeData(data);
      final tags = sanitized['tags'] as List;
      expect(tags[0], '');
      expect(tags[1], 'tag2');
      expect(tags[2], '');
    });

    test('handles recursion depth limit', () {
      var deepNest = <String, dynamic>{'value': 'test'};
      for (var i = 0; i < 15; i++) {
        deepNest = {'nested': deepNest};
      }

      final sanitized = SecurityUtils.sanitizeData(deepNest);
      expect(sanitized.toString().contains('Maximum recursion'), true);
    });
  });

  group('SecurityUtils - Validation', () {
    test('validates email addresses', () {
      expect(SecurityUtils.isValidEmail('user@example.com'), true);
      expect(SecurityUtils.isValidEmail('test.user@example.co.uk'), true);
      expect(SecurityUtils.isValidEmail('user+tag@example.com'), true);

      expect(SecurityUtils.isValidEmail(''), false);
      expect(SecurityUtils.isValidEmail('notanemail'), false);
      expect(SecurityUtils.isValidEmail('@example.com'), false);
      expect(SecurityUtils.isValidEmail('user@'), false);
      expect(SecurityUtils.isValidEmail('user@.com'), false);
    });

    test('validates URLs', () {
      expect(SecurityUtils.isValidUrl('https://example.com'), true);
      expect(SecurityUtils.isValidUrl('http://example.com'), true);
      expect(
        SecurityUtils.isValidUrl('https://example.com/path?query=1'),
        true,
      );

      expect(SecurityUtils.isValidUrl(''), false);
      expect(SecurityUtils.isValidUrl('notaurl'), false);
      expect(SecurityUtils.isValidUrl('ftp://example.com'), false);
      expect(SecurityUtils.isValidUrl('javascript:alert(1)'), false);
    });

    test('validates safe strings', () {
      expect(SecurityUtils.isSafeString('username123'), true);
      expect(SecurityUtils.isSafeString('user.name'), true);
      expect(SecurityUtils.isSafeString('user-name'), true);
      expect(SecurityUtils.isSafeString('user_name'), true);
      expect(SecurityUtils.isSafeString('user@example.com'), true);

      expect(SecurityUtils.isSafeString(''), false);
      expect(SecurityUtils.isSafeString('user<script>'), false);
      expect(SecurityUtils.isSafeString('user"name'), false);
      expect(SecurityUtils.isSafeString('a' * 300), false);
    });

    test('validates file sizes', () {
      expect(SecurityUtils.isValidFileSize(1024), true);
      expect(SecurityUtils.isValidFileSize(5 * 1024 * 1024), true);
      expect(SecurityUtils.isValidFileSize(6 * 1024 * 1024), false);
      expect(SecurityUtils.isValidFileSize(0), false);
      expect(SecurityUtils.isValidFileSize(-1), false);
    });

    test('validates file extensions', () {
      expect(
        SecurityUtils.isValidFileExtension('photo.jpg', ['.jpg', '.png']),
        true,
      );
      expect(
        SecurityUtils.isValidFileExtension('photo.PNG', ['.jpg', '.png']),
        true,
      );
      expect(
        SecurityUtils.isValidFileExtension('document.pdf', ['.pdf', '.doc']),
        true,
      );

      expect(
        SecurityUtils.isValidFileExtension('script.exe', ['.jpg', '.png']),
        false,
      );
      expect(SecurityUtils.isValidFileExtension('', ['.jpg']), false);
    });
  });

  group('SecurityUtils - SQL Injection Detection', () {
    test('detects SQL injection patterns', () {
      expect(SecurityUtils.containsSqlInjectionPattern("' OR 1=1--"), true);
      expect(
        SecurityUtils.containsSqlInjectionPattern(
          'UNION SELECT * FROM users',
        ),
        true,
      );
      expect(
        SecurityUtils.containsSqlInjectionPattern('DROP TABLE users'),
        true,
      );
      expect(SecurityUtils.containsSqlInjectionPattern("admin'--"), true);

      expect(
        SecurityUtils.containsSqlInjectionPattern('normal user input'),
        false,
      );
      expect(
        SecurityUtils.containsSqlInjectionPattern('user@example.com'),
        false,
      );
    });
  });

  group('SecurityUtils - Sensitive Info Redaction', () {
    test('redacts email addresses', () {
      const text = 'Contact me at user@example.com';
      expect(
        SecurityUtils.redactSensitiveInfo(text),
        'Contact me at [EMAIL_REDACTED]',
      );
    });

    test('redacts phone numbers', () {
      const text = 'Call me at 555-123-4567';
      expect(
        SecurityUtils.redactSensitiveInfo(text),
        'Call me at [PHONE_REDACTED]',
      );
    });

    test('redacts credit card numbers', () {
      const text = 'Card: 1234 5678 9012 3456';
      expect(SecurityUtils.redactSensitiveInfo(text), 'Card: [CC_REDACTED]');
    });

    test('redacts SSN', () {
      const text = 'SSN: 123-45-6789';
      expect(SecurityUtils.redactSensitiveInfo(text), 'SSN: [SSN_REDACTED]');
    });
  });

  group('SecurityUtils - Password Validation', () {
    test('validates strong passwords', () {
      final result = SecurityUtils.validatePasswordStrength('StrongP@ss123');
      expect(result['isValid'], true);
      expect(result['errors'], isEmpty);
      expect(result['strength'], greaterThan(70));
    });

    test('detects weak passwords', () {
      final result = SecurityUtils.validatePasswordStrength('weak');
      expect(result['isValid'], false);
      expect(result['errors'], isNotEmpty);
    });

    test('checks password criteria', () {
      var result = SecurityUtils.validatePasswordStrength('short');
      expect(result['errors'], contains(contains('8 characters')));

      result = SecurityUtils.validatePasswordStrength('nouppercase123!');
      expect(result['errors'], contains(contains('uppercase')));

      result = SecurityUtils.validatePasswordStrength('NOLOWERCASE123!');
      expect(result['errors'], contains(contains('lowercase')));

      result = SecurityUtils.validatePasswordStrength('NoNumbers!');
      expect(result['errors'], contains(contains('number')));

      result = SecurityUtils.validatePasswordStrength('NoSpecialChar123');
      expect(result['errors'], contains(contains('special character')));
    });
  });

  group('SecurityUtils - Utility Functions', () {
    test('strips HTML tags', () {
      expect(SecurityUtils.stripHtmlTags('<p>Hello</p>'), 'Hello');
      expect(
        SecurityUtils.stripHtmlTags('<div><span>Test</span></div>'),
        'Test',
      );
      expect(SecurityUtils.stripHtmlTags('No tags here'), 'No tags here');
    });

    test('sanitizes filenames', () {
      expect(
        SecurityUtils.sanitizeFilename('normal_file.txt'),
        'normal_file.txt',
      );
      expect(
        SecurityUtils.sanitizeFilename('file with spaces.txt'),
        'file_with_spaces.txt',
      );
      expect(
        SecurityUtils.sanitizeFilename('file<script>.txt'),
        'file_script_.txt',
      );
      expect(SecurityUtils.sanitizeFilename(''), 'unnamed');
    });
  });
}
