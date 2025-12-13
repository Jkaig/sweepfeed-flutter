import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/contest.dart';
import '../../../core/providers/providers.dart'; // Add this import
import '../services/contest_service.dart';

/// Provider for live search on home screen
final homeSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for filtered search results on home screen
final homeSearchResultsProvider = FutureProvider<List<Contest>>((ref) async {
  final query = ref.watch(homeSearchQueryProvider);
  final contestService = ref.watch(contestServiceProvider);

  if (query.isEmpty || query.length < 2) {
    return [];
  }

  return contestService.searchContests(query, limit: 20);
});
