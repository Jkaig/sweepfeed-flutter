import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/filter_options.dart';

/// Provider that calculates the number of active filters
final activeFilterCountProvider = Provider<int>((ref) {
  final filterOptions = ref.watch(filterOptionsProvider);
  var count = 0;

  // Count non-default sort option (newest is default)
  if (filterOptions.sortOption != SortOption.newest) count++;

  // Count min prize value filter
  if (filterOptions.minPrizeValue > 0) count++;

  // Count max prize value filter
  if (filterOptions.maxPrizeValue < double.infinity) count++;

  // Count selected entry methods
  count += filterOptions.entryMethods.length;

  // Count selected platforms
  count += filterOptions.platforms.length;

  // Count purchase requirement filter
  if (filterOptions.requiresPurchase != null) count++;

  // Count show entered contests toggle (if false, it's a filter)
  if (!filterOptions.showEnteredContests) count++;

  return count;
});

class FilterOptionsNotifier extends StateNotifier<FilterOptions> {
  FilterOptionsNotifier() : super(const FilterOptions());

  void setSortOption(SortOption sortOption) {
    state = state.copyWith(sortOption: sortOption);
  }

  void setPrizeValueRange(double? min, double? max) {
    state = state.copyWith(minPrizeValue: min, maxPrizeValue: max);
  }

  void toggleEntryMethod(String method) {
    final newMethods = Set<String>.from(state.entryMethods);
    if (newMethods.contains(method)) {
      newMethods.remove(method);
    } else {
      newMethods.add(method);
    }
    state = state.copyWith(entryMethods: newMethods);
  }

  void togglePlatform(String platform) {
    final newPlatforms = Set<String>.from(state.platforms);
    if (newPlatforms.contains(platform)) {
      newPlatforms.remove(platform);
    } else {
      newPlatforms.add(platform);
    }
    state = state.copyWith(platforms: newPlatforms);
  }

  void setPurchaseRequirement(bool? required) {
    state = state.copyWith(requiresPurchase: required);
  }

  void setShowEnteredContests(bool show) {
    state = state.copyWith(showEnteredContests: show);
  }

  void clearFilters() {
    state = const FilterOptions();
  }
}

final filterOptionsProvider =
    StateNotifierProvider<FilterOptionsNotifier, FilterOptions>(
  (ref) => FilterOptionsNotifier(),
);
