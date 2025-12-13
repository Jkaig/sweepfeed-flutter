import 'package:flutter_test/flutter_test.dart';
import 'package:sweepfeed/core/models/contest.dart';

/// Helper function to create a valid test Contest with all required fields
Contest createTestContest({
  String? id,
  String? title,
  String? sponsor,
  String? category,
  List<String>? categories,
  String? prize,
  String? frequency,
  DateTime? endDate,
  String? entryUrl,
  String? imageUrl,
  String? eligibility,
  String? source,
  List<String>? badges,
  DateTime? createdAt,
  String? prizeValue,
  double? value,
  DateTime? startDate,
  ContestStatus? status,
}) => Contest(
    id: id ?? 'test-id',
    title: title ?? 'Test Contest',
    sponsor: sponsor ?? 'Test Sponsor',
    category: category ?? 'Cash',
    categories: categories ?? ['Cash'],
    prize: prize ?? '1000 USD',
    frequency: frequency ?? 'One-time',
    endDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
    entryUrl: entryUrl ?? 'https://example.com/enter',
    imageUrl: imageUrl ?? 'https://example.com/image.png',
    eligibility: eligibility ?? 'US residents 18+',
    source: source ?? 'Test Source',
    badges: badges ?? [],
    createdAt: createdAt ?? DateTime.now(),
    prizeValue: prizeValue ?? '\$1,000',
    value: value,
    startDate: startDate,
    status: status ?? ContestStatus.active,
  );

void main() {
  group('Contest Model Tests', () {
    test('fromMap creates valid Contest with all fields', () {
      final data = {
        'id': 'test123',
        'sponsor': 'Test Sponsor',
        'title': 'Win \$10,000 Cash Prize',
        'prize': '10000 USD Cash',
        'value': 10000,
        'startDate': DateTime.now().toIso8601String(),
        'endDate':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'entryMethods': ['Online Form', 'Email'],
        'entryUrl': 'https://example.com/enter',
        'eligibilityAge': '18+',
        'eligibilityLocation': 'US',
        'category': 'Cash',
        'categories': ['Cash', 'Prizes'],
        'frequency': 'One-time',
        'sponsorWebsite': 'https://example.com',
        'sponsorLogoUrl': 'https://example.com/logo.png',
        'imageUrl': 'https://example.com/prize.png',
        'rulesUrl': 'https://example.com/terms',
        'entryRequirements': 'Must be 18 or older',
        'winnerCount': '1',
        'status': 'active',
        'badges': ['Hot', 'Featured'],
        'createdAt': DateTime.now().toIso8601String(),
        'eligibility': 'US residents 18+',
        'prizeValue': '\$10,000',
        'source': 'Test Source',
      };

      final contest = Contest.fromMap(data);

      expect(contest.id, 'test123');
      expect(contest.sponsor, 'Test Sponsor');
      expect(contest.title, 'Win \$10,000 Cash Prize');
      expect(contest.prize, '10000 USD Cash');
      expect(contest.value, 10000.0);
      expect(contest.entryMethods, ['Online Form', 'Email']);
      expect(contest.status, ContestStatus.active);
    });

    test('fromMap handles missing/null fields with fallbacks', () {
      final data = <String, dynamic>{
        'title': 'Minimal Contest',
      };

      final contest = Contest.fromMap(data);

      expect(contest.sponsor, '');
      expect(contest.title, 'Minimal Contest');
      expect(contest.prize, '');
      expect(contest.value, isNull);
      expect(contest.entryMethods, isEmpty);
      expect(contest.eligibilityAge, isNull);
      expect(contest.eligibilityLocation, isNull);
      expect(contest.category, '');
    });

    test('toFirestore creates correct map structure', () {
      final contest = createTestContest(
        sponsor: 'Test Sponsor',
        title: 'Test Contest',
        prize: 'Cash Prize',
        value: 1000.0,
        startDate: DateTime(2025),
        endDate: DateTime(2025, 2),
        category: 'Cash',
        frequency: 'One-time',
      );

      final map = contest.toFirestore();

      expect(map['sponsor'], 'Test Sponsor');
      expect(map['title'], 'Test Contest');
      expect(map['prize'], 'Cash Prize');
      expect(map['status'], 'active');
      expect(map['value'], 1000.0);
    });

    test('isActive returns true for active future contests', () {
      final contest = createTestContest(
        endDate: DateTime.now().add(const Duration(days: 10)),
        status: ContestStatus.active,
      );

      expect(contest.isActive, true);
    });

    test('isActive returns false for expired contests', () {
      final contest = createTestContest(
        endDate: DateTime.now().subtract(const Duration(days: 10)),
        status: ContestStatus.active,
      );

      expect(contest.isActive, false);
    });

    test('daysRemaining calculates correctly', () {
      final contest = createTestContest(
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      expect(contest.daysRemaining, greaterThanOrEqualTo(6));
      expect(contest.daysRemaining, lessThanOrEqualTo(7));
    });

    test('daysRemaining never returns negative value', () {
      final contest = createTestContest(
        endDate: DateTime.now().subtract(const Duration(days: 10)),
      );

      expect(contest.daysRemaining, 0);
    });

    test('prizeValueAmount parses correctly', () {
      final contest = createTestContest(
        prizeValue: '\$10,000 USD',
      );

      expect(contest.prizeValueAmount, 10000.0);
    });

    test('minAge parses correctly', () {
      final contest = Contest(
        id: 'test-age',
        sponsor: 'Test',
        title: 'Test',
        prize: 'Prize',
        value: 100.0,
        endDate: DateTime.now().add(const Duration(days: 10)),
        entryUrl: 'https://example.com',
        eligibilityAge: '21+',
        category: 'General',
        categories: [],
        frequency: 'One-time',
        imageUrl: 'https://example.com/image.png',
        eligibility: 'US residents',
        source: 'Test',
        badges: [],
        createdAt: DateTime.now(),
        prizeValue: '\$100',
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
