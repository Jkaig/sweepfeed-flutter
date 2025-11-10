import 'package:flutter_test/flutter_test.dart';
import 'package:sweepfeed/core/models/contest.dart';

void main() {
  group('Contest Model Tests', () {
    test('fromMap creates valid Contest with all fields', () {
      final data = {
        'id': 'test123',
        'sponsor': 'Test Sponsor',
        'title': 'Win \$10,000 Cash Prize',
        'prize': '10000 USD Cash',
        'prize_details': 'Cash will be transferred via PayPal',
        'value': '10000',
        'start_date': DateTime.now().millisecondsSinceEpoch,
        'end_date':
            DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch,
        'entry_methods': ['Online Form', 'Email'],
        'entry_url': 'https://example.com/enter',
        'eligibility_age': '18+',
        'eligibility_location': 'US',
        'category': 'Cash',
        'frequency': 'One-time',
        'sponsor_website': 'https://example.com',
        'sponsor_logo': 'https://example.com/logo.png',
        'prize_image': 'https://example.com/prize.png',
        'terms_url': 'https://example.com/terms',
        'entry_requirements': 'Must be 18 or older',
        'winner_count': '1',
        'status': 'active',
      };

      final contest = Contest.fromMap(data);

      expect(contest.id, 'test123');
      expect(contest.sponsor, 'Test Sponsor');
      expect(contest.title, 'Win \$10,000 Cash Prize');
      expect(contest.prize, '10000 USD Cash');
      expect(contest.value, '10000');
      expect(contest.entryMethods, ['Online Form', 'Email']);
      expect(contest.status, ContestStatus.active);
    });

    test('fromMap handles missing/null fields with fallbacks', () {
      final data = <String, dynamic>{
        'title': 'Minimal Contest',
      };

      final contest = Contest.fromMap(data);

      expect(contest.sponsor, 'Unknown Sponsor');
      expect(contest.title, 'Minimal Contest');
      expect(contest.prize, 'Prize TBA');
      expect(contest.value, '0');
      expect(contest.entryMethods, isEmpty);
      expect(contest.eligibilityAge, '18+');
      expect(contest.eligibilityLocation, 'US');
      expect(contest.category, 'General');
    });

    test('toFirestore creates correct map structure', () {
      final contest = Contest(
        sponsor: 'Test Sponsor',
        title: 'Test Contest',
        prize: 'Cash Prize',
        prizeDetails: 'Details here',
        value: '1000',
        startDate: DateTime(2025),
        endDate: DateTime(2025, 2),
        entryMethods: ['Online'],
        entryUrl: 'https://example.com',
        eligibilityAge: '18+',
        eligibilityLocation: 'US',
        category: 'Cash',
        frequency: 'One-time',
        sponsorWebsite: 'https://sponsor.com',
        sponsorLogo: '',
        prizeImage: '',
        termsUrl: '',
        entryRequirements: '',
        winnerCount: '1',
      );

      final map = contest.toFirestore();

      expect(map['sponsor'], 'Test Sponsor');
      expect(map['title'], 'Test Contest');
      expect(map['prize'], 'Cash Prize');
      expect(map['status'], 'active');
      expect(map['entry_methods'], ['Online']);
    });

    test('isActive returns true for active future contests', () {
      final contest = Contest(
        sponsor: 'Test',
        title: 'Test',
        prize: 'Prize',
        prizeDetails: '',
        value: '100',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 10)),
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

      expect(contest.isActive, true);
    });

    test('isActive returns false for expired contests', () {
      final contest = Contest(
        sponsor: 'Test',
        title: 'Test',
        prize: 'Prize',
        prizeDetails: '',
        value: '100',
        startDate: DateTime.now().subtract(const Duration(days: 20)),
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

      expect(contest.isActive, false);
    });

    test('daysRemaining calculates correctly', () {
      final contest = Contest(
        sponsor: 'Test',
        title: 'Test',
        prize: 'Prize',
        prizeDetails: '',
        value: '100',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
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

      expect(contest.daysRemaining, greaterThanOrEqualTo(6));
      expect(contest.daysRemaining, lessThanOrEqualTo(7));
    });

    test('daysRemaining never returns negative value', () {
      final contest = Contest(
        sponsor: 'Test',
        title: 'Test',
        prize: 'Prize',
        prizeDetails: '',
        value: '100',
        startDate: DateTime.now().subtract(const Duration(days: 20)),
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

      expect(contest.daysRemaining, 0);
    });

    test('prizeValueAmount parses correctly', () {
      final contest = Contest(
        sponsor: 'Test',
        title: 'Test',
        prize: 'Prize',
        prizeDetails: '',
        value: '\$10,000 USD',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 10)),
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

      expect(contest.prizeValueAmount, 10000.0);
    });

    test('minAge parses correctly', () {
      final contest = Contest(
        sponsor: 'Test',
        title: 'Test',
        prize: 'Prize',
        prizeDetails: '',
        value: '100',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 10)),
        entryMethods: [],
        entryUrl: '',
        eligibilityAge: '21+',
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

      expect(contest.minAge, 21);
    });

    test('ContestStatus.fromString parses correctly', () {
      expect(ContestStatus.fromString('active'), ContestStatus.active);
      expect(ContestStatus.fromString('expired'), ContestStatus.expired);
      expect(ContestStatus.fromString('pending'), ContestStatus.pending);
      expect(ContestStatus.fromString(''), ContestStatus.active);
      expect(ContestStatus.fromString(null), ContestStatus.active);
      expect(ContestStatus.fromString('invalid'), ContestStatus.active);
    });

    test('ContestStatus.value returns correct string', () {
      expect(ContestStatus.active.value, 'active');
      expect(ContestStatus.expired.value, 'expired');
      expect(ContestStatus.pending.value, 'pending');
    });
  });
}
