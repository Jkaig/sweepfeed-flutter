class AdvancedFilter {
  AdvancedFilter({
    this.selectedBrands = const [],
    this.selectedCategories = const [],
    this.prizeValueRange,
    this.selectedPrizeTypes = const [],
    this.searchQuery,
    this.savedFilterName,
  });

  factory AdvancedFilter.fromJson(Map<String, dynamic> json) => AdvancedFilter(
        selectedBrands: List<String>.from(json['selectedBrands'] ?? []),
        selectedCategories: List<String>.from(json['selectedCategories'] ?? []),
        prizeValueRange: json['prizeValueRange'] != null
            ? PrizeValueRange.fromJson(json['prizeValueRange'])
            : null,
        selectedPrizeTypes: (json['selectedPrizeTypes'] as List<dynamic>?)
                ?.map(
                  (e) => PrizeType.values.firstWhere((type) => type.name == e),
                )
                .toList() ??
            [],
        searchQuery: json['searchQuery'],
        savedFilterName: json['savedFilterName'],
      );
  final List<String> selectedBrands;
  final List<String> selectedCategories;
  final PrizeValueRange? prizeValueRange;
  final List<PrizeType> selectedPrizeTypes;
  final String? searchQuery;
  final String? savedFilterName;

  AdvancedFilter copyWith({
    List<String>? selectedBrands,
    List<String>? selectedCategories,
    PrizeValueRange? prizeValueRange,
    List<PrizeType>? selectedPrizeTypes,
    String? searchQuery,
    String? savedFilterName,
  }) =>
      AdvancedFilter(
        selectedBrands: selectedBrands ?? this.selectedBrands,
        selectedCategories: selectedCategories ?? this.selectedCategories,
        prizeValueRange: prizeValueRange ?? this.prizeValueRange,
        selectedPrizeTypes: selectedPrizeTypes ?? this.selectedPrizeTypes,
        searchQuery: searchQuery ?? this.searchQuery,
        savedFilterName: savedFilterName ?? this.savedFilterName,
      );

  bool get isEmpty =>
      selectedBrands.isEmpty &&
      selectedCategories.isEmpty &&
      prizeValueRange == null &&
      selectedPrizeTypes.isEmpty &&
      (searchQuery == null || searchQuery!.isEmpty);

  Map<String, dynamic> toJson() => {
        'selectedBrands': selectedBrands,
        'selectedCategories': selectedCategories,
        'prizeValueRange': prizeValueRange?.toJson(),
        'selectedPrizeTypes': selectedPrizeTypes.map((e) => e.name).toList(),
        'searchQuery': searchQuery,
        'savedFilterName': savedFilterName,
      };
}

class PrizeValueRange {
  PrizeValueRange({this.min, this.max});

  factory PrizeValueRange.fromJson(Map<String, dynamic> json) =>
      PrizeValueRange(
        min: json['min']?.toDouble(),
        max: json['max']?.toDouble(),
      );
  final double? min;
  final double? max;

  Map<String, dynamic> toJson() => {'min': min, 'max': max};

  String get label {
    if (min != null && max != null) {
      return '\$${min!.toInt()} - \$${max!.toInt()}';
    } else if (min != null) {
      return '\$${min!.toInt()}+';
    } else if (max != null) {
      return 'Up to \$${max!.toInt()}';
    }
    return 'Any Value';
  }
}

enum PrizeType {
  cash,
  electronics,
  travel,
  giftCard,
  vehicle,
  experience,
  merchandise,
  other,
}

extension PrizeTypeExtension on PrizeType {
  String get label {
    switch (this) {
      case PrizeType.cash:
        return 'Cash';
      case PrizeType.electronics:
        return 'Electronics';
      case PrizeType.travel:
        return 'Travel';
      case PrizeType.giftCard:
        return 'Gift Card';
      case PrizeType.vehicle:
        return 'Vehicle';
      case PrizeType.experience:
        return 'Experience';
      case PrizeType.merchandise:
        return 'Merchandise';
      case PrizeType.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case PrizeType.cash:
        return '💵';
      case PrizeType.electronics:
        return '📱';
      case PrizeType.travel:
        return '✈️';
      case PrizeType.giftCard:
        return '🎁';
      case PrizeType.vehicle:
        return '🚗';
      case PrizeType.experience:
        return '🎭';
      case PrizeType.merchandise:
        return '🛍️';
      case PrizeType.other:
        return '🎯';
    }
  }
}
