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
    this.isVetted = false,
    this.schedule,
    this.sponsorLogoUrl,
    this.administrator,
    this.brand,
    this.entryRequirements,
    this.winnerCount,
    this.eligibilityAge,
    this.eligibilityLocation,
    this.prizeValueUsd,
    this.prizeCount,
    this.prizeTier,
    this.prizeRetailer,
    this.taxesAnd1099,
    this.entryMethods,
    this.entryUrls,
    this.amoeDetails,
    this.entryDeadline,
    this.drawDate,
    this.drawingDates,
    this.winnerAnnouncementDate,
    this.notificationMethodDeadline,
    this.eligibilityRequirements,
    this.excludedRegions,
    this.excludedStates,
    this.excludedCountries,
    this.requiresPurchase,
    this.legalDisclaimer,
    this.aggregatorSource,
    this.dataSource,
    this.isValid,
    this.trendingScore,
    this.status = ContestStatus.active,
    this.isDailyEntry,
    this.description,
    this.updatedAt,
    this.coSponsors,
    this.sponsorContactEmail,
    this.sponsorSocialMedia,
    this.totalArv,
    this.prizeImages,
    this.prizeCategory,
    this.prizeBrand,
    this.startDatetimeTz,
    this.endDatetimeTz,
    this.rulesText,
    this.rulesTextChecksum,
    this.rulesSourceMime,
    this.aggregatorEntryUrl,
    this.aggregatorDetailUrl,
  });

  factory Contest.fromMap(Map<String, dynamic> json, [String? providedId]) =>
      Contest.fromJson(json, providedId);

  /// Create Contest from Firestore document snapshot
  factory Contest.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Contest document ${doc.id} has null data');
    }
    return Contest.fromJson(data, doc.id);
  }

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
      isVetted: json['isVetted'] as bool? ?? false,
      isDailyEntry: json['isDailyEntry'] as bool?,
      description: json['description'] as String?,
      schedule: json['schedule'] as Map<String, dynamic>?,
      sponsorLogoUrl: json['sponsorLogoUrl'] as String?,
      administrator: json['administrator'] as String?,
      brand: json['brand'] as String?,
      entryRequirements: json['entryRequirements'] as String?,
      winnerCount: json['winnerCount'] as String?,
      eligibilityAge: json['eligibilityAge'] as String?,
      eligibilityLocation: json['eligibilityLocation'] as String?,
      prizeValueUsd: (json['prizeValueUsd'] as num?)?.toDouble(),
      prizeCount: json['prizeCount'] as String?,
      prizeTier: json['prizeTier'] as String?,
      prizeRetailer: json['prizeRetailer'] as String?,
      taxesAnd1099: json['taxesAnd1099'] as String?,
      entryMethods: List<String>.from((json['entryMethods'] as List<dynamic>?) ?? const []),
      entryUrls: List<String>.from((json['entryUrls'] as List<dynamic>?) ?? const []),
      amoeDetails: json['amoeDetails'] as String?,
      entryDeadline: DateTime.tryParse((json['entryDeadline'] as String?) ?? ''),
      drawDate: DateTime.tryParse((json['drawDate'] as String?) ?? ''),
      drawingDates: (json['drawingDates'] as List<dynamic>?)
          ?.map((e) => DateTime.tryParse(e as String ?? '')!)
          .whereType<DateTime>()
          .toList(),
      winnerAnnouncementDate: DateTime.tryParse((json['winnerAnnouncementDate'] as String?) ?? ''),
      notificationMethodDeadline: json['notificationMethodDeadline'] as String?,
      eligibilityRequirements: json['eligibilityRequirements'] as String?,
      excludedRegions: List<String>.from((json['excludedRegions'] as List<dynamic>?) ?? const []),
      excludedStates: List<String>.from((json['excludedStates'] as List<dynamic>?) ?? const []),
      excludedCountries: List<String>.from((json['excludedCountries'] as List<dynamic>?) ?? const []),
      requiresPurchase: json['requiresPurchase'] as bool?,
      legalDisclaimer: json['legalDisclaimer'] as String?,
      aggregatorSource: json['aggregatorSource'] as String?,
      dataSource: json['dataSource'] as String?,
      isValid: json['isValid'] as bool?,
      trendingScore: (json['trendingScore'] as num?)?.toDouble(),
      status: ContestStatus.fromString(json['status'] as String?),
      updatedAt: _parseDateNullable(json['updated_at'] ?? json['updatedAt']),
      coSponsors: List<String>.from((json['coSponsors'] as List<dynamic>?) ?? const []),
      sponsorContactEmail: json['sponsorContactEmail'] as String?,
      sponsorSocialMedia: json['sponsorSocialMedia'] != null
          ? Map<String, String>.from(json['sponsorSocialMedia'] as Map)
          : null,
      totalArv: json['totalArv'] as String?,
      prizeImages: List<String>.from((json['prizeImages'] as List<dynamic>?) ?? const []),
      prizeCategory: json['prizeCategory'] as String?,
      prizeBrand: json['prizeBrand'] as String?,
      startDatetimeTz: json['startDatetimeTz'] as String?,
      endDatetimeTz: json['endDatetimeTz'] as String?,
      rulesText: json['rulesText'] as String?,
      rulesTextChecksum: json['rulesTextChecksum'] as String?,
      rulesSourceMime: json['rulesSourceMime'] as String?,
      aggregatorEntryUrl: json['aggregatorEntryUrl'] as String?,
      aggregatorDetailUrl: json['aggregatorDetailUrl'] as String?,
    );
  }

  final String id;
  final String title;
  final String sponsor;
  final String category;
  final List<String> categories;
  final String prize;
  final String frequency;
  final DateTime endDate;
  final String entryUrl;
  final String imageUrl;
  final String eligibility;
  final String source;
  final List<String> badges;
  final DateTime createdAt;
  final String prizeValue;
  final String? sponsorWebsite;
  final Map<String, String>? prizeDetails;
  final double? value;
  final DateTime? startDate;
  final DateTime? postedDate;
  final String? rulesUrl;
  final DateTime? retrievedAt;
  final bool isPremium;
  final String? platform;
  final String? entryMethod;
  final bool isHot;
  final int? entryCount;
  final int entryLimit;
  final int likes;
  final int clicks;
  final int saves;
  final bool isVip;
  final bool isVetted;
  final Map<String, dynamic>? schedule;
  final String? sponsorLogoUrl;
  final String? administrator;
  final String? brand;
  final String? entryRequirements;
  final String? winnerCount;
  final String? eligibilityAge;
  final String? eligibilityLocation;
  final double? prizeValueUsd;
  final String? prizeCount;
  final String? prizeTier;
  final String? prizeRetailer;
  final String? taxesAnd1099;
  final List<String>? entryMethods;
  final List<String>? entryUrls;
  final String? amoeDetails;
  final DateTime? entryDeadline;
  final DateTime? drawDate;
  final List<DateTime>? drawingDates;
  final DateTime? winnerAnnouncementDate;
  final String? notificationMethodDeadline;
  final String? eligibilityRequirements;
  final List<String>? excludedRegions;
  final List<String>? excludedStates;
  final List<String>? excludedCountries;
  final bool? requiresPurchase;
  final String? legalDisclaimer;
  final String? aggregatorSource;
  final String? dataSource;
  final bool? isValid;
  final double? trendingScore;
  final ContestStatus status;
  final bool? isDailyEntry;
  final String? description;
  final DateTime? updatedAt;
  final List<String>? coSponsors;
  final String? sponsorContactEmail;
  final Map<String, String>? sponsorSocialMedia;
  final String? totalArv;
  final List<String>? prizeImages;
  final String? prizeCategory;
  final String? prizeBrand;
  final String? startDatetimeTz;
  final String? endDatetimeTz;
  final String? rulesText;
  final String? rulesTextChecksum;
  final String? rulesSourceMime;
  final String? aggregatorEntryUrl;
  final String? aggregatorDetailUrl;

  Map<String, dynamic> toMap() => {
      'id': id,
      'title': title,
      'sponsor': sponsor,
      'sponsorWebsite': sponsorWebsite,
      'category': category,
      'categories': categories,
      'prize': prize,
      'prizeDetails': prizeDetails,
      'value': value,
      'frequency': frequency,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'postedDate': postedDate?.toIso8601String(),
      'entryUrl': entryUrl,
      'rulesUrl': rulesUrl,
      'imageUrl': imageUrl,
      'eligibility': eligibility,
      'retrievedAt': retrievedAt?.toIso8601String(),
      'source': source,
      'badges': badges,
      'isPremium': isPremium,
      'platform': platform,
      'createdAt': createdAt.toIso8601String(),
      'entryMethod': entryMethod,
      'isHot': isHot,
      'entryCount': entryCount,
      'prizeValue': prizeValue,
      'entryLimit': entryLimit,
      'likes': likes,
      'clicks': clicks,
      'saves': saves,
      'isVip': isVip,
      'isVetted': isVetted,
      'schedule': schedule,
      'sponsorLogoUrl': sponsorLogoUrl,
      'administrator': administrator,
      'brand': brand,
      'entryRequirements': entryRequirements,
      'winnerCount': winnerCount,
      'eligibilityAge': eligibilityAge,
      'eligibilityLocation': eligibilityLocation,
      'prizeValueUsd': prizeValueUsd,
      'prizeCount': prizeCount,
      'prizeTier': prizeTier,
      'prizeRetailer': prizeRetailer,
      'taxesAnd1099': taxesAnd1099,
      'entryMethods': entryMethods,
      'entryUrls': entryUrls,
      'amoeDetails': amoeDetails,
      'entryDeadline': entryDeadline?.toIso8601String(),
      'drawDate': drawDate?.toIso8601String(),
      'drawingDates': drawingDates?.map((e) => e.toIso8601String()).toList(),
      'winnerAnnouncementDate': winnerAnnouncementDate?.toIso8601String(),
      'notificationMethodDeadline': notificationMethodDeadline,
      'eligibilityRequirements': eligibilityRequirements,
      'excludedRegions': excludedRegions,
      'excludedStates': excludedStates,
      'excludedCountries': excludedCountries,
      'requiresPurchase': requiresPurchase,
      'legalDisclaimer': legalDisclaimer,
      'aggregatorSource': aggregatorSource,
      'dataSource': dataSource,
      'isValid': isValid,
      'trendingScore': trendingScore,
      'isDailyEntry': isDailyEntry,
      'description': description,
      'status': status.value,
      'updatedAt': updatedAt?.toIso8601String(),
      'coSponsors': coSponsors,
      'sponsorContactEmail': sponsorContactEmail,
      'sponsorSocialMedia': sponsorSocialMedia,
      'totalArv': totalArv,
      'prizeImages': prizeImages,
      'prizeCategory': prizeCategory,
      'prizeBrand': prizeBrand,
      'startDatetimeTz': startDatetimeTz,
      'endDatetimeTz': endDatetimeTz,
      'rulesText': rulesText,
      'rulesTextChecksum': rulesTextChecksum,
      'rulesSourceMime': rulesSourceMime,
      'aggregatorEntryUrl': aggregatorEntryUrl,
      'aggregatorDetailUrl': aggregatorDetailUrl,
    };

  Map<String, dynamic> toFirestore() => toMap();

  Map<String, dynamic> toJson() => toMap();

  Contest copyWith({
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
    String? sponsorWebsite,
    Map<String, String>? prizeDetails,
    double? value,
    DateTime? startDate,
    DateTime? postedDate,
    String? rulesUrl,
    DateTime? retrievedAt,
    bool? isPremium,
    String? platform,
    String? entryMethod,
    bool? isHot,
    int? entryCount,
    int? entryLimit,
    int? likes,
    int? clicks,
    int? saves,
    bool? isVip,
    bool? isVetted,
    Map<String, dynamic>? schedule,
    String? sponsorLogoUrl,
    String? administrator,
    String? brand,
    String? entryRequirements,
    String? winnerCount,
    String? eligibilityAge,
    String? eligibilityLocation,
    double? prizeValueUsd,
    String? prizeCount,
    String? prizeTier,
    String? prizeRetailer,
    String? taxesAnd1099,
    List<String>? entryMethods,
    List<String>? entryUrls,
    String? amoeDetails,
    DateTime? entryDeadline,
    DateTime? drawDate,
    List<DateTime>? drawingDates,
    DateTime? winnerAnnouncementDate,
    String? notificationMethodDeadline,
    String? eligibilityRequirements,
    List<String>? excludedRegions,
    List<String>? excludedStates,
    List<String>? excludedCountries,
    bool? requiresPurchase,
    String? legalDisclaimer,
    String? aggregatorSource,
    String? dataSource,
    bool? isValid,
    double? trendingScore,
    bool? isDailyEntry,
    String? description,
    ContestStatus? status,
    DateTime? updatedAt,
    List<String>? coSponsors,
    String? sponsorContactEmail,
    Map<String, String>? sponsorSocialMedia,
    String? totalArv,
    List<String>? prizeImages,
    String? prizeCategory,
    String? prizeBrand,
    String? startDatetimeTz,
    String? endDatetimeTz,
    String? rulesText,
    String? rulesTextChecksum,
    String? rulesSourceMime,
    String? aggregatorEntryUrl,
    String? aggregatorDetailUrl,
  }) => Contest(
      id: id ?? this.id,
      title: title ?? this.title,
      sponsor: sponsor ?? this.sponsor,
      category: category ?? this.category,
      categories: categories ?? this.categories,
      prize: prize ?? this.prize,
      frequency: frequency ?? this.frequency,
      endDate: endDate ?? this.endDate,
      entryUrl: entryUrl ?? this.entryUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      eligibility: eligibility ?? this.eligibility,
      source: source ?? this.source,
      badges: badges ?? this.badges,
      createdAt: createdAt ?? this.createdAt,
      prizeValue: prizeValue ?? this.prizeValue,
      sponsorWebsite: sponsorWebsite ?? this.sponsorWebsite,
      prizeDetails: prizeDetails ?? this.prizeDetails,
      value: value ?? this.value,
      startDate: startDate ?? this.startDate,
      postedDate: postedDate ?? this.postedDate,
      rulesUrl: rulesUrl ?? this.rulesUrl,
      retrievedAt: retrievedAt ?? this.retrievedAt,
      isPremium: isPremium ?? this.isPremium,
      platform: platform ?? this.platform,
      entryMethod: entryMethod ?? this.entryMethod,
      isHot: isHot ?? this.isHot,
      entryCount: entryCount ?? this.entryCount,
      entryLimit: entryLimit ?? this.entryLimit,
      likes: likes ?? this.likes,
      clicks: clicks ?? this.clicks,
      saves: saves ?? this.saves,
      isVip: isVip ?? this.isVip,
      isVetted: isVetted ?? this.isVetted,
      schedule: schedule ?? this.schedule,
      sponsorLogoUrl: sponsorLogoUrl ?? this.sponsorLogoUrl,
      administrator: administrator ?? this.administrator,
      brand: brand ?? this.brand,
      entryRequirements: entryRequirements ?? this.entryRequirements,
      winnerCount: winnerCount ?? this.winnerCount,
      eligibilityAge: eligibilityAge ?? this.eligibilityAge,
      eligibilityLocation: eligibilityLocation ?? this.eligibilityLocation,
      prizeValueUsd: prizeValueUsd ?? this.prizeValueUsd,
      prizeCount: prizeCount ?? this.prizeCount,
      prizeTier: prizeTier ?? this.prizeTier,
      prizeRetailer: prizeRetailer ?? this.prizeRetailer,
      taxesAnd1099: taxesAnd1099 ?? this.taxesAnd1099,
      entryMethods: entryMethods ?? this.entryMethods,
      entryUrls: entryUrls ?? this.entryUrls,
      amoeDetails: amoeDetails ?? this.amoeDetails,
      entryDeadline: entryDeadline ?? this.entryDeadline,
      drawDate: drawDate ?? this.drawDate,
      drawingDates: drawingDates ?? this.drawingDates,
      winnerAnnouncementDate: winnerAnnouncementDate ?? this.winnerAnnouncementDate,
      notificationMethodDeadline: notificationMethodDeadline ?? this.notificationMethodDeadline,
      eligibilityRequirements: eligibilityRequirements ?? this.eligibilityRequirements,
      excludedRegions: excludedRegions ?? this.excludedRegions,
      excludedStates: excludedStates ?? this.excludedStates,
      excludedCountries: excludedCountries ?? this.excludedCountries,
      requiresPurchase: requiresPurchase ?? this.requiresPurchase,
      legalDisclaimer: legalDisclaimer ?? this.legalDisclaimer,
      aggregatorSource: aggregatorSource ?? this.aggregatorSource,
      dataSource: dataSource ?? this.dataSource,
      isValid: isValid ?? this.isValid,
      trendingScore: trendingScore ?? this.trendingScore,
      isDailyEntry: isDailyEntry ?? this.isDailyEntry,
      description: description ?? this.description,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      coSponsors: coSponsors ?? this.coSponsors,
      sponsorContactEmail: sponsorContactEmail ?? this.sponsorContactEmail,
      sponsorSocialMedia: sponsorSocialMedia ?? this.sponsorSocialMedia,
      totalArv: totalArv ?? this.totalArv,
      prizeImages: prizeImages ?? this.prizeImages,
      prizeCategory: prizeCategory ?? this.prizeCategory,
      prizeBrand: prizeBrand ?? this.prizeBrand,
      startDatetimeTz: startDatetimeTz ?? this.startDatetimeTz,
      endDatetimeTz: endDatetimeTz ?? this.endDatetimeTz,
      rulesText: rulesText ?? this.rulesText,
      rulesTextChecksum: rulesTextChecksum ?? this.rulesTextChecksum,
      rulesSourceMime: rulesSourceMime ?? this.rulesSourceMime,
      aggregatorEntryUrl: aggregatorEntryUrl ?? this.aggregatorEntryUrl,
      aggregatorDetailUrl: aggregatorDetailUrl ?? this.aggregatorDetailUrl,
    );

  // Helper method to parse dates safely
  static DateTime _parseDate(date) {
    if (date == null) return DateTime.now();
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    if (date is int) {
      return DateTime.fromMillisecondsSinceEpoch(date);
    }
    return DateTime.now();
  }

  static DateTime? _parseDateNullable(date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is String) {
      final parsed = DateTime.tryParse(date);
      return parsed;
    }
    if (date is int) {
      return DateTime.fromMillisecondsSinceEpoch(date);
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
    if (value != null) return value;
    if (prizeValueUsd != null) return prizeValueUsd;
    if (prizeValue.isNotEmpty) {
      final match = RegExp(r'[\d,]+(?:\.\d+)?').firstMatch(prizeValue);
      if (match != null) {
        final cleanValue = match.group(0)!.replaceAll(',', '');
        return double.tryParse(cleanValue);
      }
    }
    return null;
  }

  /// Computed: Minimum age requirement
  int? get minAge {
    if (eligibilityAge == null || eligibilityAge!.isEmpty) return null;
    final match = RegExp(r'\d+').firstMatch(eligibilityAge!);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  /// Computed: Formatted prize string for display
  String get prizeFormatted {
    // If prizeValue is available and non-empty, use it
    if (prizeValue.isNotEmpty) {
      return prizeValue;
    }
    // If value is available, format it as currency
    if (value != null) {
      return '\$${value!.toStringAsFixed(0)}';
    }
    // If prizeValueUsd is available, format it
    if (prizeValueUsd != null) {
      return '\$${prizeValueUsd!.toStringAsFixed(0)}';
    }
    // Fallback to prize field
    return prize.isNotEmpty ? prize : 'Prize Available';
  }

  @override
  String toString() =>
      'Contest($title by $sponsor - \$${value ?? prizeValue} ends ${endDate.toIso8601String()})';
}
