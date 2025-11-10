import 'package:cloud_firestore/cloud_firestore.dart';

/// Contest status enum for type safety
enum ContestStatus {
  active,
  expired,
  pending;

  /// Parse status from string with fallback to active
  static ContestStatus fromString(String? value) {
    if (value == null || value.isEmpty) return ContestStatus.active;

    switch (value.toLowerCase().trim()) {
      case 'active':
        return ContestStatus.active;
      case 'expired':
        return ContestStatus.expired;
      case 'pending':
        return ContestStatus.pending;
      default:
        return ContestStatus.active;
    }
  }

  /// Convert to string for Firestore storage
  String get value {
    switch (this) {
      case ContestStatus.active:
        return 'active';
      case ContestStatus.expired:
        return 'expired';
      case ContestStatus.pending:
        return 'pending';
    }
  }
}

/// Contest model - matches crawler 19-field output EXACTLY
class Contest {
  Contest({
    required this.sponsor,
    required this.title,
    required this.prize,
    required this.prizeDetails,
    required this.value,
    required this.startDate,
    required this.endDate,
    required this.entryMethods,
    required this.entryUrl,
    required this.eligibilityAge,
    required this.eligibilityLocation,
    required this.category,
    required this.frequency,
    required this.sponsorWebsite,
    required this.sponsorLogo,
    required this.prizeImage,
    required this.termsUrl,
    required this.entryRequirements,
    required this.winnerCount,
    this.id,
    this.status = ContestStatus.active,
    this.createdAt,
    this.updatedAt,
  });

  /// Create Contest from Firestore document
  factory Contest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    try {
      final data = snapshot.data();
      if (data == null) {
        throw FormatException('Contest document ${snapshot.id} has null data');
      }

      final entryMethodsRaw = data['entry_methods'];
      final entryMethods = entryMethodsRaw is List
          ? entryMethodsRaw.map((e) => e.toString()).toList()
          : <String>[];

      return Contest(
        id: snapshot.id,
        sponsor: _parseString(data['sponsor'], 'Unknown Sponsor'),
        title: _parseString(data['title'], 'Untitled Contest'),
        prize: _parseString(data['prize'], 'Prize TBA'),
        prizeDetails: _parseString(data['prize_details'], ''),
        value: _parseString(data['value'], '0'),
        startDate: _parseTimestamp(data['start_date']) ?? DateTime.now(),
        endDate: _parseTimestamp(data['end_date']) ??
            DateTime.now().add(const Duration(days: 30)),
        entryMethods: entryMethods,
        entryUrl: _parseString(data['entry_url'], ''),
        eligibilityAge: _parseString(data['eligibility_age'], '18+'),
        eligibilityLocation: _parseString(data['eligibility_location'], 'US'),
        category: _parseString(data['category'], 'General'),
        frequency: _parseString(data['frequency'], 'One-time'),
        sponsorWebsite: _parseString(data['sponsor_website'], ''),
        sponsorLogo: _parseString(data['sponsor_logo'], ''),
        prizeImage: _parseString(data['prize_image'], ''),
        termsUrl: _parseString(data['terms_url'], ''),
        entryRequirements: _parseString(data['entry_requirements'], ''),
        winnerCount: _parseString(data['winner_count'], '1'),
        status: ContestStatus.fromString(data['status'] as String?),
        createdAt: _parseTimestampNullable(data['created_at']),
        updatedAt: _parseTimestampNullable(data['updated_at']),
      );
    } catch (e) {
      throw FormatException('Failed to parse Contest from Firestore: $e');
    }
  }

  /// Create Contest from cached Map (for Hive cache)
  factory Contest.fromMap(Map<String, dynamic> data) {
    try {
      final entryMethodsRaw = data['entry_methods'];
      final entryMethods = entryMethodsRaw is List
          ? entryMethodsRaw.map((e) => e.toString()).toList()
          : <String>[];

      return Contest(
        id: data['id'] as String?,
        sponsor: _parseString(data['sponsor'], 'Unknown Sponsor'),
        title: _parseString(data['title'], 'Untitled Contest'),
        prize: _parseString(data['prize'], 'Prize TBA'),
        prizeDetails: _parseString(data['prize_details'], ''),
        value: _parseString(data['value'], '0'),
        startDate: _parseTimestamp(data['start_date']) ?? DateTime.now(),
        endDate: _parseTimestamp(data['end_date']) ??
            DateTime.now().add(const Duration(days: 30)),
        entryMethods: entryMethods,
        entryUrl: _parseString(data['entry_url'], ''),
        eligibilityAge: _parseString(data['eligibility_age'], '18+'),
        eligibilityLocation: _parseString(data['eligibility_location'], 'US'),
        category: _parseString(data['category'], 'General'),
        frequency: _parseString(data['frequency'], 'One-time'),
        sponsorWebsite: _parseString(data['sponsor_website'], ''),
        sponsorLogo: _parseString(data['sponsor_logo'], ''),
        prizeImage: _parseString(data['prize_image'], ''),
        termsUrl: _parseString(data['terms_url'], ''),
        entryRequirements: _parseString(data['entry_requirements'], ''),
        winnerCount: _parseString(data['winner_count'], '1'),
        status:
            ContestStatus.fromString(_parseString(data['status'], 'active')),
        createdAt: _parseTimestampNullable(data['created_at']),
        updatedAt: _parseTimestampNullable(data['updated_at']),
      );
    } catch (e) {
      throw FormatException('Failed to parse Contest from Map: $e');
    }
  }
  // Crawler fields (19 total)
  final String sponsor;
  final String title;
  final String prize;
  final String prizeDetails;
  final String value;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> entryMethods;
  final String entryUrl;
  final String eligibilityAge;
  final String eligibilityLocation;
  final String category;
  final String frequency;
  final String sponsorWebsite;
  final String sponsorLogo;
  final String prizeImage;
  final String termsUrl;
  final String entryRequirements;
  final String winnerCount;

  // App-specific fields
  final String? id; // Firestore document ID
  final ContestStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Safe string parsing with fallback
  static String _parseString(value, String fallback) {
    if (value == null) return fallback;
    if (value is String) return value.trim().isEmpty ? fallback : value.trim();
    return value.toString();
  }

  /// Convert Contest to Firestore map (for crawler to use)
  Map<String, dynamic> toFirestore() => {
        if (id != null) 'id': id,
        'sponsor': sponsor,
        'title': title,
        'prize': prize,
        'prize_details': prizeDetails,
        'value': value,
        'start_date': Timestamp.fromDate(startDate),
        'end_date': Timestamp.fromDate(endDate),
        'entry_methods': entryMethods,
        'entry_url': entryUrl,
        'eligibility_age': eligibilityAge,
        'eligibility_location': eligibilityLocation,
        'category': category,
        'frequency': frequency,
        'sponsor_website': sponsorWebsite,
        'sponsor_logo': sponsorLogo,
        'prize_image': prizeImage,
        'terms_url': termsUrl,
        'entry_requirements': entryRequirements,
        'winner_count': winnerCount,
        'status': status.value,
        'created_at': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

  /// Helper to parse Firestore Timestamp
  static DateTime? _parseTimestamp(value) {
    try {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String && value.isNotEmpty) return DateTime.parse(value);
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static DateTime? _parseTimestampNullable(value) {
    try {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String && value.isNotEmpty) return DateTime.parse(value);
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Computed: Is contest still active?
  bool get isActive =>
      endDate.isAfter(DateTime.now()) && status == ContestStatus.active;

  /// Computed: Days until contest ends (never negative)
  int get daysRemaining {
    final days = endDate.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  /// Computed: Prize value as number (parse from "1000 USD" format)
  double? get prizeValueAmount {
    final match = RegExp(r'[\d,]+(?:\.\d+)?').firstMatch(value);
    if (match != null) {
      final cleanValue = match.group(0)!.replaceAll(',', '');
      return double.tryParse(cleanValue);
    }
    return null;
  }

  /// Computed: Minimum age requirement
  int? get minAge {
    final match = RegExp(r'\d+').firstMatch(eligibilityAge);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  @override
  String toString() =>
      'Contest($title by $sponsor - \$$value ends ${endDate.toIso8601String()})';
}
