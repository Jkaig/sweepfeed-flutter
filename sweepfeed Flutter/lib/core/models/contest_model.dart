import 'package:cloud_firestore/cloud_firestore.dart';

class Contest {
  Contest({
    required this.id,
    required this.title,
    required this.sponsor,
    required this.category,
    required this.categories,
    required this.prize,
    required this.frequency,
    required this.endDate,
    required this.entryUrl,
    required this.imageUrl,
    required this.eligibility,
    required this.source,
    required this.badges,
    required this.createdAt,
    required this.prizeValue,
    this.sponsorWebsite,
    this.prizeDetails,
    this.value,
    this.startDate,
    this.postedDate,
    this.rulesUrl,
    this.retrievedAt,
    this.isPremium = false,
    this.platform,
    this.entryMethod,
    this.isHot = false,
    this.entryCount,
    this.entryLimit = 1,
    this.likes = 0,
    this.clicks = 0,
    this.saves = 0,
    this.isVip = false,
    this.schedule,
    this.sponsorLogoUrl,
  });

  factory Contest.fromMap(Map<String, dynamic> json, [String? providedId]) =>
      Contest.fromJson(json, providedId);

  factory Contest.fromJson(Map<String, dynamic> json, [String? providedId]) {
    // Resolve id from provided argument or embedded json
    final resolvedId = providedId ?? (json['id'] as String? ?? '');

    // Resolve sponsor and sponsorWebsite from multiple possible shapes
    var resolvedSponsor = '';
    String? resolvedSponsorWebsite;
    final dynamic sourceField = json['source'];
    if (json['sponsor'] is String) {
      resolvedSponsor = json['sponsor'] as String;
    } else if (json['sponsor_name'] is String) {
      resolvedSponsor = json['sponsor_name'] as String;
    } else if (sourceField is Map) {
      resolvedSponsor = (sourceField['sponsor_name'] as String?) ??
          (sourceField['name'] as String?) ??
          '';
      resolvedSponsorWebsite = sourceField['sponsor_website'] as String?;
    }

    final isPremium = json['isPremium'] as bool? ?? false;

    return Contest(
      id: resolvedId,
      title: (json['title'] as String?) ?? '',
      sponsor: resolvedSponsor,
      sponsorWebsite:
          resolvedSponsorWebsite ?? (json['sponsorWebsite'] as String?),
      category: (json['category'] as String?) ?? '',
      categories:
          List<String>.from((json['categories'] as List<dynamic>?) ?? const []),
      prize: (json['prize'] as String?) ?? '',
      prizeDetails: json['prizeDetails'] != null
          ? Map<String, String>.from(json['prizeDetails'] as Map)
          : null,
      value: (json['value'] as num?)?.toDouble(),
      frequency: (json['frequency'] as String?) ?? '',
      startDate: DateTime.tryParse((json['startDate'] as String?) ?? ''),
      endDate: _parseDate(json['endDate']),
      postedDate: DateTime.tryParse((json['postedDate'] as String?) ?? ''),
      entryUrl: (json['entryUrl'] as String?) ?? '',
      rulesUrl: json['rulesUrl'] as String?,
      imageUrl: (json['imageUrl'] as String?) ?? '',
      eligibility: (json['eligibility'] as String?) ?? '',
      retrievedAt: DateTime.tryParse((json['retrievedAt'] as String?) ?? ''),
      source: sourceField is Map
          ? ((sourceField['name'] as String?) ?? '')
          : ((json['source'] as String?) ?? ''),
      badges: List<String>.from((json['badges'] as List<dynamic>?) ?? const []),
      isPremium: isPremium,
      platform: json['platform'] as String?,
      createdAt: _parseDate(json['createdAt']),
      entryMethod: json['entryMethod'] as String?,
      isHot: (json['isHot'] as bool?) ?? false,
      entryCount: json['entryCount'] as int?,
      prizeValue: (json['prizeValue'] as String?) ?? '',
      entryLimit: json['entryLimit'] as int? ?? 1,
      likes: json['likes'] as int? ?? 0,
      clicks: json['clicks'] as int? ?? 0,
      saves: json['saves'] as int? ?? 0,
      isVip: json['isVip'] as bool? ?? false,
      schedule: json['schedule'] as String?,
      sponsorLogoUrl: json['sponsorLogoUrl'] as String?,
    );
  }

  factory Contest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Contest(
      id: doc.id,
      title: data['title'] ?? '',
      sponsor: data['sponsor'] ?? '',
      sponsorWebsite: data['sponsorWebsite'] as String?,
      category: data['category'] ?? '',
      categories:
          List<String>.from((data['categories'] as List<dynamic>?) ?? const []),
      prize: data['prize'] ?? '',
      prizeDetails: data['prizeDetails'] != null
          ? Map<String, String>.from(data['prizeDetails'] as Map)
          : null,
      value: (data['value'] as num?)?.toDouble(),
      frequency: data['frequency'] ?? '',
      startDate: DateTime.tryParse((data['startDate'] as String?) ?? ''),
      endDate: _parseDate(data['endDate']),
      postedDate: DateTime.tryParse((data['postedDate'] as String?) ?? ''),
      entryUrl: data['entryUrl'] ?? '',
      rulesUrl: data['rulesUrl'] as String?,
      imageUrl: data['imageUrl'] ?? '',
      eligibility: data['eligibility'] ?? '',
      retrievedAt: DateTime.tryParse((data['retrievedAt'] as String?) ?? ''),
      source: data['source'] as String? ?? '',
      badges: List<String>.from((data['badges'] as List<dynamic>?) ?? const []),
      isPremium: data['isPremium'] as bool? ?? false,
      platform: data['platform'] as String?,
      createdAt: _parseDate(data['createdAt']),
      entryMethod: data['entryMethod'] as String?,
      isHot: (data['isHot'] as bool?) ?? false,
      entryCount: data['entryCount'] as int?,
      prizeValue: data['prizeValue'] ?? '',
      entryLimit: data['entryLimit'] ?? 1,
      likes: data['likes'] ?? 0,
      clicks: data['clicks'] ?? 0,
      saves: data['saves'] ?? 0,
      isVip: data['isVip'] ?? false,
      schedule: data['schedule'] as String?,
      sponsorLogoUrl: data['sponsorLogoUrl'] as String?,
    );
  }
  // Merged fields from both models
  final String id;
  final String title;
  final String sponsor;
  final String? sponsorWebsite;
  final String category;
  final List<String> categories;
  final String prize;
  final Map<String, String>? prizeDetails;
  final double? value;
  final String frequency;
  final DateTime? startDate;
  final DateTime endDate;
  final DateTime? postedDate;
  final String entryUrl;
  final String? rulesUrl;
  final String imageUrl;
  final String eligibility;
  final DateTime? retrievedAt;
  final String source; // Changed from Map to String to match new JSON
  final List<String> badges;
  final bool isPremium;
  final String? platform;
  final DateTime createdAt;
  final String? entryMethod;
  final bool isHot;
  final int? entryCount;
  final String prizeValue;
  final int entryLimit;
  final int likes;
  final int clicks;
  final int saves;
  final bool isVip;
  final String? schedule;
  final String? sponsorLogoUrl;

  static DateTime _parseDate(date) {
    if (date is Timestamp) {
      return date.toDate();
    }
    if (date is String) {
      return DateTime.tryParse(date) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String get prizeFormatted => '\$${value?.toStringAsFixed(2) ?? prize}';
  String get entryFrequency => frequency;

  int get daysLeft {
    final difference = endDate.difference(DateTime.now());
    return difference.inDays > 0 ? difference.inDays : 0;
  }

  Contest copyWith({
    String? id,
    String? title,
    String? sponsor,
    String? sponsorWebsite,
    String? category,
    List<String>? categories,
    String? prize,
    Map<String, String>? prizeDetails,
    double? value,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? postedDate,
    String? entryUrl,
    String? rulesUrl,
    String? imageUrl,
    String? eligibility,
    DateTime? retrievedAt,
    String? source,
    List<String>? badges,
    bool? isPremium,
    String? platform,
    DateTime? createdAt,
    String? entryMethod,
    bool? isHot,
    int? entryCount,
    String? prizeValue,
    int? entryLimit,
    int? likes,
    int? clicks,
    int? saves,
    bool? isVip,
    String? schedule,
    String? sponsorLogoUrl,
  }) =>
      Contest(
        id: id ?? this.id,
        title: title ?? this.title,
        sponsor: sponsor ?? this.sponsor,
        sponsorWebsite: sponsorWebsite ?? this.sponsorWebsite,
        category: category ?? this.category,
        categories: categories ?? this.categories,
        prize: prize ?? this.prize,
        prizeDetails: prizeDetails ?? this.prizeDetails,
        value: value ?? this.value,
        frequency: frequency ?? this.frequency,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        postedDate: postedDate ?? this.postedDate,
        entryUrl: entryUrl ?? this.entryUrl,
        rulesUrl: rulesUrl ?? this.rulesUrl,
        imageUrl: imageUrl ?? this.imageUrl,
        eligibility: eligibility ?? this.eligibility,
        retrievedAt: retrievedAt ?? this.retrievedAt,
        source: source ?? this.source,
        badges: badges ?? this.badges,
        isPremium: isPremium ?? this.isPremium,
        platform: platform ?? this.platform,
        createdAt: createdAt ?? this.createdAt,
        entryMethod: entryMethod ?? this.entryMethod,
        isHot: isHot ?? this.isHot,
        entryCount: entryCount ?? this.entryCount,
        prizeValue: prizeValue ?? this.prizeValue,
        entryLimit: entryLimit ?? this.entryLimit,
        likes: likes ?? this.likes,
        clicks: clicks ?? this.clicks,
        saves: saves ?? this.saves,
        isVip: isVip ?? this.isVip,
        schedule: schedule ?? this.schedule,
        sponsorLogoUrl: sponsorLogoUrl ?? this.sponsorLogoUrl,
      );
}
