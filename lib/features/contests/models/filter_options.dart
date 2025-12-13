import 'advanced_filter_model.dart';

/// Sort options for contests
enum SortOption {
  endingSoon,
  newest,
  prizeValueHighToLow,
  prizeValueLowToHigh,
  trending,
}

extension SortOptionExtension on SortOption {
  String get label {
    switch (this) {
      case SortOption.endingSoon:
        return 'Ending Soon';
      case SortOption.newest:
        return 'Newest';
      case SortOption.prizeValueHighToLow:
        return 'Prize Value: High to Low';
      case SortOption.prizeValueLowToHigh:
        return 'Prize Value: Low to High';
      case SortOption.trending:
        return 'Trending';
    }
  }
}



/// Filter options for contest queries
class FilterOptions {
  const FilterOptions({
    this.sortOption = SortOption.newest,
    this.minPrizeValue = 0.0,
    this.maxPrizeValue = double.infinity,
    this.entryMethods = const <String>{},
    this.platforms = const <String>{},
    this.selectedCategories = const <String>{},
    this.selectedPrizeTypes = const <PrizeType>[],
    this.selectedBrands = const <String>{},
    this.requiresPurchase,
    this.showEnteredContests = true,
  });

  final SortOption sortOption;
  final double minPrizeValue;
  final double maxPrizeValue;
  final Set<String> entryMethods;
  final Set<String> platforms;
  final Set<String> selectedCategories;
  final List<PrizeType> selectedPrizeTypes;
  final Set<String> selectedBrands;
  final bool? requiresPurchase;
  final bool showEnteredContests;

  FilterOptions copyWith({
    SortOption? sortOption,
    double? minPrizeValue,
    double? maxPrizeValue,
    Set<String>? entryMethods,
    Set<String>? platforms,
    Set<String>? selectedCategories,
    List<PrizeType>? selectedPrizeTypes,
    Set<String>? selectedBrands,
    bool? requiresPurchase,
    bool? showEnteredContests,
  }) =>
      FilterOptions(
        sortOption: sortOption ?? this.sortOption,
        minPrizeValue: minPrizeValue ?? this.minPrizeValue,
        maxPrizeValue: maxPrizeValue ?? this.maxPrizeValue,
        entryMethods: entryMethods ?? this.entryMethods,
        platforms: platforms ?? this.platforms,
        selectedCategories: selectedCategories ?? this.selectedCategories,
        selectedPrizeTypes: selectedPrizeTypes ?? this.selectedPrizeTypes,
        selectedBrands: selectedBrands ?? this.selectedBrands,
        requiresPurchase: requiresPurchase ?? this.requiresPurchase,
        showEnteredContests: showEnteredContests ?? this.showEnteredContests,
      );
}
