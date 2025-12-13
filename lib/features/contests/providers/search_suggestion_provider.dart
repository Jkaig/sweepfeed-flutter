import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'contest_providers.dart';

final searchSuggestionProvider =
    FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.isEmpty) {
    return [];
  }

  final contestFeedState = ref.watch(contestFeedProvider);
  final contests = contestFeedState.contests;
  final lowerCaseQuery = query.toLowerCase();

  final suggestions = contests
      .where((contest) =>
          contest.title.toLowerCase().contains(lowerCaseQuery) ||
          contest.sponsor.toLowerCase().contains(lowerCaseQuery))
      .map((contest) => contest.title)
      .toSet()
      .toList();

  return suggestions.take(5).toList();
});
