import 'package:flutter_test/flutter_test.dart';
import 'package:sweepfeed/core/models/contest.dart';
import 'package:sweepfeed/core/validation/contest_validator.dart';

void main() {
  group('ContestValidator Tests', () {
    test('valid contest passes validation', () {
      final contest = Contest(
        sponsor: 'Test Sponsor',
        title: 'Win \$10,000 Cash Prize',
        prize: '10000 USD Cash',
        prizeDetails: 'Cash will be transferred via PayPal',
        value: '10000',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        entryMethods: ['Online Form', 'Email'],
        entryUrl: 'https://example.com/enter',
        eligibilityAge: '18+',
        eligibilityLocation: 'US',
        category: 'Cash',
        frequency: 'One-time',
        sponsorWebsite: 'https://example.com',
        sponsorLogo: 'https://example.com/logo.png',
        prizeImage: 'https://example.com/prize.png',
        termsUrl: 'https://example.com/terms',
        entryRequirements: 'Must be 18 or older',
        winnerCount: '1',
      );

      final result = ContestValidator.validate(contest);

      expect(result.isValid, true);
      expect(result.errors, isEmpty);
    });

    test('empty title fails validation', () {
      final contest = Contest(
        sponsor: 'Test Sponsor',
        title: '',
        prize: '10000 USD',
        prizeDetails: 'Details',
        value: '10000',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        entryMethods: ['Online'],
        entryUrl: 'https://example.com',
        eligibilityAge: '18+',
        eligibilityLocation: 'US',
        category: 'Cash',
        frequency: 'One-time',
        sponsorWebsite: 'https://example.com',
        sponsorLogo: '',
        prizeImage: '',
        termsUrl: 'https://example.com/terms',
        entryRequirements: '',
        winnerCount: '1',
      );

      final result = ContestValidator.validate(contest);

      expect(result.isValid, false);
      expect(result.errors, contains('Title cannot be empty'));
    });

    test('end date before start date fails validation', () {
      final contest = Contest(
        sponsor: 'Test Sponsor',
        title: 'Test Contest',
        prize: '1000 USD',
        prizeDetails: 'Details',
        value: '1000',
        startDate: DateTime.now(),
        endDate: DateTime.now().subtract(const Duration(days: 10)),
        entryMethods: ['Online'],
        entryUrl: 'https://example.com',
        eligibilityAge: '18+',
        eligibilityLocation: 'US',
        category: 'Cash',
        frequency: 'One-time',
        sponsorWebsite: 'https://example.com',
        sponsorLogo: '',
        prizeImage: '',
        termsUrl: 'https://example.com/terms',
        entryRequirements: '',
        winnerCount: '1',
      );

      final result = ContestValidator.validate(contest);

      expect(result.isValid, false);
      expect(result.errors, contains('End date cannot be before start date'));
    });

    test('missing entry URL fails validation', () {
      final contest = Contest(
        sponsor: 'Test Sponsor',
        title: 'Test Contest',
        prize: '1000 USD',
        prizeDetails: 'Details',
        value: '1000',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        entryMethods: ['Online'],
        entryUrl: '',
        eligibilityAge: '18+',
        eligibilityLocation: 'US',
        category: 'Cash',
        frequency: 'One-time',
        sponsorWebsite: 'https://example.com',
        sponsorLogo: '',
        prizeImage: '',
        termsUrl: '',
        entryRequirements: '',
        winnerCount: '1',
      );

      final result = ContestValidator.validate(contest);

      expect(result.isValid, false);
      expect(result.errors, contains('Entry URL is required'));
    });

    test('invalid URL format fails validation', () {
      final contest = Contest(
        sponsor: 'Test Sponsor',
        title: 'Test Contest',
        prize: '1000 USD',
        prizeDetails: 'Details',
        value: '1000',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        entryMethods: ['Online'],
        entryUrl: 'not-a-valid-url',
        eligibilityAge: '18+',
        eligibilityLocation: 'US',
        category: 'Cash',
        frequency: 'One-time',
        sponsorWebsite: 'https://example.com',
        sponsorLogo: '',
        prizeImage: '',
        termsUrl: 'also-invalid',
        entryRequirements: '',
        winnerCount: '1',
      );

      final result = ContestValidator.validate(contest);

      expect(result.isValid, false);
      expect(result.errors, isNotEmpty);
    });

    test('negative prize value fails validation', () {
      final contest = Contest(
        sponsor: 'Test Sponsor',
        title: 'Test Contest',
        prize: 'Cash',
        prizeDetails: 'Details',
        value: '-1000',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        entryMethods: ['Online'],
        entryUrl: 'https://example.com',
        eligibilityAge: '18+',
        eligibilityLocation: 'US',
        category: 'Cash',
        frequency: 'One-time',
        sponsorWebsite: 'https://example.com',
        sponsorLogo: '',
        prizeImage: '',
        termsUrl: 'https://example.com/terms',
        entryRequirements: '',
        winnerCount: '1',
      );

      final result = ContestValidator.validate(contest);

      expect(result.isValid, false);
      expect(result.errors, contains('Prize value cannot be negative'));
    });

    test('short title generates warning', () {
      final contest = Contest(
        sponsor: 'Test Sponsor',
        title: 'Win',
        prize: '1000 USD',
        prizeDetails: 'Details',
        value: '1000',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        entryMethods: ['Online'],
        entryUrl: 'https://example.com',
        eligibilityAge: '18+',
        eligibilityLocation: 'US',
        category: 'Cash',
        frequency: 'One-time',
        sponsorWebsite: 'https://example.com',
        sponsorLogo: '',
        prizeImage: '',
        termsUrl: 'https://example.com/terms',
        entryRequirements: '',
        winnerCount: '1',
      );

      final result = ContestValidator.validate(contest);

      expect(result.isValid, true);
      expect(result.warnings, isNotEmpty);
    });

    test('filterValidContests removes invalid contests', () {
      final validContest = Contest(
        sponsor: 'Test Sponsor',
        title: 'Valid Contest',
        prize: '1000 USD',
        prizeDetails: 'Details',
        value: '1000',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        entryMethods: ['Online'],
        entryUrl: 'https://example.com',
        eligibilityAge: '18+',
        eligibilityLocation: 'US',
        category: 'Cash',
        frequency: 'One-time',
        sponsorWebsite: 'https://example.com',
        sponsorLogo: '',
        prizeImage: '',
        termsUrl: 'https://example.com/terms',
        entryRequirements: '',
        winnerCount: '1',
      );

      final invalidContest = Contest(
        sponsor: 'Test Sponsor',
        title: '',
        prize: 'Prize',
        prizeDetails: '',
        value: '100',
        startDate: DateTime.now(),
        endDate: DateTime.now().subtract(const Duration(days: 10)),
        entryMethods: [],
        entryUrl: '',
        eligibilityAge: '18+',
        eligibilityLocation: 'US',
        category: 'General',
        frequency: 'One-time',
        sponsorWebsite: '',
        sponsorLogo: '',
        prizeImage: '',
        termsUrl: '',
        entryRequirements: '',
        winnerCount: '1',
      );

      final contests = [validContest, invalidContest];
      final filtered = ContestValidator.filterValidContests(contests);

      expect(filtered.length, 1);
      expect(filtered.first.title, 'Valid Contest');
    });
  });
}
