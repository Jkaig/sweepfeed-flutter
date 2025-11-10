import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/cached_contest_repository.dart';
import '../models/contest.dart';
import 'contest_providers.dart';

final cachedContestRepositoryProvider =
    Provider<CachedContestRepository>((ref) {
  final repository = CachedContestRepository();
  repository.initialize();
  return repository;
});

final cachedActiveContestsProvider =
    FutureProvider.family<List<Contest>, ContestQueryParams>(
  (ref, params) async {
    final repository = ref.watch(cachedContestRepositoryProvider);
    return repository.getActiveContests(
      category: params.category,
      sortBy: params.sortBy,
      ascending: params.ascending,
      limit: params.limit,
    );
  },
);

final cachedHighValueContestsProvider =
    FutureProvider.family<List<Contest>, int>(
  (ref, limit) async {
    final repository = ref.watch(cachedContestRepositoryProvider);
    return repository.getHighValueContests(limit: limit);
  },
);

final cachedEndingSoonContestsProvider =
    FutureProvider.family<List<Contest>, EndingSoonParams>(
  (ref, params) async {
    final repository = ref.watch(cachedContestRepositoryProvider);
    return repository.getEndingSoonContests(
      limit: params.limit,
      maxDaysRemaining: params.maxDaysRemaining,
    );
  },
);

final cachedContestByIdProvider = FutureProvider.family<Contest?, String>(
  (ref, id) async {
    final repository = ref.watch(cachedContestRepositoryProvider);
    return repository.getContestById(id);
  },
);
