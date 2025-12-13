import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/contest.dart';
import '../../../core/models/recommendation_reason.dart';
import '../../../core/providers/providers.dart';
import '../models/filter_options.dart';
import '../services/contest_service.dart';
import 'filter_providers.dart';

final userPreferencesProvider = StreamProvider((ref) => ref.watch(userPreferencesServiceProvider).getPreferences());

class ContestFeedState {
  ContestFeedState({
    this.contests = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDocument,
  });

  final List<Contest> contests;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  ContestFeedState copyWith({
    List<Contest>? contests,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
  }) => ContestFeedState(
      contests: contests ?? this.contests,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
    );
}

class ContestFeedNotifier extends StateNotifier<ContestFeedState> {
  ContestFeedNotifier(this._contestService, this._filterOptions)
      : super(ContestFeedState()) {
    fetchNextPage();
  }

  final ContestService _contestService;
  final FilterOptions _filterOptions;
  static const int _pageSize = 20;

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    // This is a simplified way to get the last document.
    // In a real app, the service should return the DocumentSnapshot.
    final lastDocument = state.lastDocument;

    final newContests = await _contestService.getContestsPaginated(
      limit: _pageSize,
      startAfter: lastDocument,
      filterOptions: _filterOptions,
    );

    DocumentSnapshot? lastDoc;
    if (newContests.isNotEmpty) {
      final lastContestId = newContests.last.id;
      lastDoc = await FirebaseFirestore.instance
          .collection('contests')
          .doc(lastContestId)
          .get();
    }

    state = state.copyWith(
      contests: [...state.contests, ...newContests],
      isLoading: false,
      hasMore: newContests.length == _pageSize,
      lastDocument: lastDoc,
    );
  }

  Future<void> refresh() async {
    state = ContestFeedState();
    await fetchNextPage();
  }
}

final contestFeedProvider =
    StateNotifierProvider<ContestFeedNotifier, ContestFeedState>((ref) {
  final contestService = ref.watch(contestServiceProvider);
  final filterOptions = ref.watch(filterOptionsProvider);
  return ContestFeedNotifier(contestService, filterOptions);
});

final personalizedContestFeedProvider =
    FutureProvider<List<(Contest, RecommendationReason)>>((ref) async {
  final contestFeedState = ref.watch(contestFeedProvider);
  final personalizationEngine = ref.watch(personalizationEngineProvider);
  final userPreferences = ref.watch(userPreferencesProvider).asData?.value;

  if (userPreferences != null) {
    final rankedContests = personalizationEngine.rankContests(
      contests: contestFeedState.contests,
      preferences: userPreferences,
    );
    return rankedContests
        .map((e) => (e.$1.contest, e.$2))
        .toList();
  }

  // If preferences aren't loaded, return with a default reason
  return contestFeedState.contests
      .map((c) => (c, RecommendationReason(type: RecommendationType.popular)))
      .toList();
});
