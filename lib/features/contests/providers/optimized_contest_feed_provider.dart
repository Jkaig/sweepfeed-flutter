import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repositories/contest_repository.dart';
import '../../../core/models/contest.dart';
import '../../../core/providers/contest_providers.dart';
import '../../../core/providers/providers.dart';

import '../models/advanced_filter_model.dart';
import '../models/filter_options.dart';
import 'filter_providers.dart';

/// Optimized paginated contest feed provider
/// Handles hundreds of thousands of contests efficiently with server-side filtering
class OptimizedContestFeedState {
  OptimizedContestFeedState({
    this.contests = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDocument,
    this.error,
  });

  final List<Contest> contests;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final String? error;

  OptimizedContestFeedState copyWith({
    List<Contest>? contests,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    String? error,
    bool clearError = false,
  }) =>
      OptimizedContestFeedState(
        contests: contests ?? this.contests,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        lastDocument: lastDocument ?? this.lastDocument,
        error: clearError ? null : (error ?? this.error),
      );
}

class OptimizedContestFeedNotifier extends StateNotifier<OptimizedContestFeedState> {
  OptimizedContestFeedNotifier(
    this._repository,
    this._filterOptions,
    this._searchQuery,
    this._activeFilter,
  ) : super(OptimizedContestFeedState()) {
    _initialize();
  }

  final ContestRepository _repository;
  final FilterOptions _filterOptions;
  final String _searchQuery;
  final String _activeFilter;

  static const int _pageSize = 20; // Load 20 at a time for smooth scrolling
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;

  void _initialize() {
    // Start loading first page
    fetchNextPage();
  }

  /// Fetch next page of contests using repository
  Future<void> fetchNextPage() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Build filter options with active filter applied
      final filterOptions = _buildFilterOptions();

      // Use repository's paginated method
      final newContests = await _repository.getFilteredContests(
        filterOptions: filterOptions,
        limit: _pageSize,
        startAfter: _lastDocument,
      );

      if (newContests.isEmpty) {
        _hasMore = false;
        state = state.copyWith(
          isLoading: false,
          hasMore: false,
        );
        return;
      }

      // Apply client-side filtering for complex queries
      final filteredContests = newContests.where(_shouldIncludeContest).toList();

      // Update last document for pagination (use last contest's document)
      if (newContests.isNotEmpty) {
        final lastContest = newContests.last;
        final lastDoc = await FirebaseFirestore.instance
            .collection('contests')
            .doc(lastContest.id)
            .get();
        _lastDocument = lastDoc;
      }

      // Check if we have more results
      _hasMore = newContests.length == _pageSize;

      state = state.copyWith(
        contests: [...state.contests, ...filteredContests],
        isLoading: false,
        hasMore: _hasMore,
        lastDocument: _lastDocument,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load contests: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
    }
  }

  /// Build filter options from current state
  FilterOptions _buildFilterOptions() {
    // Convert active filter to sort option
    SortOption sortOption;
    switch (_activeFilter) {
      case 'endingSoon':
        sortOption = SortOption.endingSoon;
        break;
      case 'trending':
        sortOption = SortOption.trending;
        break;
      case 'highValue':
        sortOption = SortOption.prizeValueHighToLow;
        break;
      default:
        sortOption = SortOption.newest;
    }

    return FilterOptions(
      selectedCategories: _filterOptions.selectedCategories,
      minPrizeValue: _filterOptions.minPrizeValue,
      maxPrizeValue: _filterOptions.maxPrizeValue,
      entryMethods: _filterOptions.entryMethods,
      platforms: _filterOptions.platforms,
      selectedPrizeTypes: _filterOptions.selectedPrizeTypes,
      selectedBrands: _filterOptions.selectedBrands,
      sortOption: sortOption,
      requiresPurchase: _filterOptions.requiresPurchase,
    );
  }

  /// Client-side filtering for complex queries that can't be done server-side
  bool _shouldIncludeContest(Contest contest) {
    // Text search (if enabled, consider using Algolia for large datasets)
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      final matchesSearch = contest.title.toLowerCase().contains(searchLower) ||
          contest.sponsor.toLowerCase().contains(searchLower) ||
          contest.prize.toLowerCase().contains(searchLower) ||
          contest.category.toLowerCase().contains(searchLower);
      if (!matchesSearch) return false;
    }

    // Prize type filtering (complex matching - done client-side)
    if (_filterOptions.selectedPrizeTypes.isNotEmpty) {
      final prize = contest.prize.toLowerCase();
      final matchesPrizeType = _filterOptions.selectedPrizeTypes.any((type) {
        switch (type) {
          case PrizeType.cash:
            return prize.contains('cash') ||
                prize.contains('\$') ||
                prize.contains('money');
          case PrizeType.electronics:
            return prize.contains('phone') ||
                prize.contains('laptop') ||
                prize.contains('tablet') ||
                prize.contains('tv') ||
                prize.contains('electronics');
          case PrizeType.travel:
            return prize.contains('trip') ||
                prize.contains('travel') ||
                prize.contains('vacation') ||
                prize.contains('flight');
          case PrizeType.giftCard:
            return prize.contains('gift card') || prize.contains('giftcard');
          case PrizeType.vehicle:
            return prize.contains('car') ||
                prize.contains('vehicle') ||
                prize.contains('truck') ||
                prize.contains('suv');
          case PrizeType.experience:
            return prize.contains('experience') ||
                prize.contains('tickets') ||
                prize.contains('concert') ||
                prize.contains('event');
          case PrizeType.merchandise:
            return prize.contains('product') || prize.contains('merch');
          case PrizeType.other:
            return true;
        }
      });
      if (!matchesPrizeType) return false;
    }

    // Brand filtering
    if (_filterOptions.selectedBrands.isNotEmpty) {
      if (!_filterOptions.selectedBrands.contains(contest.sponsor)) {
        return false;
      }
    }

    // Entry frequency filtering
    if (_activeFilter == 'dailyEntry') {
      final frequency = contest.frequency.toLowerCase() ?? '';
      if (!frequency.contains('daily') && !frequency.contains('day')) {
        return false;
      }
    }

    if (_activeFilter == 'easyEntry') {
      final frequency = contest.frequency.toLowerCase() ?? '';
      if (frequency != 'one-time' &&
          frequency != 'once' &&
          frequency != 'single' &&
          !frequency.contains('one time') &&
          !frequency.contains('1 time') &&
          !frequency.contains('1x')) {
        return false;
      }
    }

    return true;
  }

  /// Refresh feed - reset and load first page
  Future<void> refresh() async {
    _lastDocument = null;
    _hasMore = true;
    state = OptimizedContestFeedState();
    await fetchNextPage();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for optimized contest feed with pagination
final optimizedContestFeedProvider =
    StateNotifierProvider<OptimizedContestFeedNotifier, OptimizedContestFeedState>(
  (ref) {
    final repository = ref.watch(contestRepositoryProvider);
    final filterOptions = ref.watch(filterOptionsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final activeFilter = ref.watch(activeContestFilterProvider);

    return OptimizedContestFeedNotifier(
      repository,
      filterOptions,
      searchQuery,
      activeFilter,
    );
  },
);

/// Cached categories provider - avoids repeated queries
final cachedCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(contestRepositoryProvider);
  return repository.getAvailableCategories();
});
