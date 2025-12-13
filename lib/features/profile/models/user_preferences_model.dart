class TrackedInterest {
  TrackedInterest({required this.lastUpdated, this.score = 0.0});

  factory TrackedInterest.fromMap(Map<String, dynamic> map) => TrackedInterest(
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: (map['lastUpdated'] as int?) ?? 0,
    );

  final double score;
  final int lastUpdated; // Using epoch milliseconds for easier backend processing

  Map<String, dynamic> toMap() => {
      'score': score,
      'lastUpdated': lastUpdated,
    };
}

class UserPreferences {
  UserPreferences({
    this.explicitInterests = const {},
    this.implicitCategoryInterests = const {},
    this.implicitSponsorInterests = const {},
    this.dislikedCategories = const {},
    this.dislikedSponsors = const {},
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) => UserPreferences(
      explicitInterests: Set<String>.from(map['explicitInterests'] ?? []),
      implicitCategoryInterests:
          (map['implicitCategoryInterests'] as Map<String, dynamic>?)?.map(
                (key, value) =>
                    MapEntry(key, TrackedInterest.fromMap(value)),
              ) ??
              {},
      implicitSponsorInterests:
          (map['implicitSponsorInterests'] as Map<String, dynamic>?)?.map(
                (key, value) =>
                    MapEntry(key, TrackedInterest.fromMap(value)),
              ) ??
              {},
      dislikedCategories: Set<String>.from(map['dislikedCategories'] ?? []),
      dislikedSponsors: Set<String>.from(map['dislikedSponsors'] ?? []),
    );

  final Set<String> explicitInterests;
  final Map<String, TrackedInterest> implicitCategoryInterests;
  final Map<String, TrackedInterest> implicitSponsorInterests;
  final Set<String> dislikedCategories;
  final Set<String> dislikedSponsors;

  Map<String, dynamic> toMap() => {
      'explicitInterests': explicitInterests.toList(),
      'implicitCategoryInterests': implicitCategoryInterests
          .map((key, value) => MapEntry(key, value.toMap())),
      'implicitSponsorInterests': implicitSponsorInterests
          .map((key, value) => MapEntry(key, value.toMap())),
      'dislikedCategories': dislikedCategories.toList(),
      'dislikedSponsors': dislikedSponsors.toList(),
    };
}
