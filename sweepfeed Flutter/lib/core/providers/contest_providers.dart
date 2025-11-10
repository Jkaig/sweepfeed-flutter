import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/contest_repository.dart';
import '../models/contest.dart';
import '../utils/logger.dart';

final contestRepositoryProvider =
    Provider<ContestRepository>((ref) => ContestRepository());

final activeContestsStreamProvider =
    StreamProvider.family<List<Contest>, ContestQueryParams>((ref, params) {
  final repository = ref.watch(contestRepositoryProvider);
  return repository.getActiveContestsStream(
    category: params.category,
    sortBy: params.sortBy,
    ascending: params.ascending,
    limit: params.limit,
  );
});

final activeContestsFutureProvider =
    FutureProvider.family<List<Contest>, ContestQueryParams>(
        (ref, params) async {
  final repository = ref.watch(contestRepositoryProvider);
  try {
    return await repository.getActiveContests(
      category: params.category,
      sortBy: params.sortBy,
      ascending: params.ascending,
      limit: params.limit,
    );
  } catch (e, stackTrace) {
    logger.e(
      'Error in activeContestsFutureProvider',
      error: e,
      stackTrace: stackTrace,
    );
    // Retry once after a short delay
    await Future.delayed(const Duration(seconds: 2));
    try {
      return await repository.getActiveContests(
        category: params.category,
        sortBy: params.sortBy,
        ascending: params.ascending,
        limit: params.limit,
      );
    } catch (retryError) {
      logger.e(
        'Retry failed in activeContestsFutureProvider',
        error: retryError,
      );
      rethrow;
    }
  }
});

final highValueContestsProvider =
    FutureProvider.family<List<Contest>, int>((ref, limit) async {
  final repository = ref.watch(contestRepositoryProvider);
  try {
    return await repository.getHighValueContests(limit: limit);
  } catch (e, stackTrace) {
    logger.e(
      'Error in highValueContestsProvider',
      error: e,
      stackTrace: stackTrace,
    );
    // Retry once after a short delay
    await Future.delayed(const Duration(seconds: 2));
    try {
      return await repository.getHighValueContests(limit: limit);
    } catch (retryError) {
      logger.e('Retry failed in highValueContestsProvider', error: retryError);
      rethrow;
    }
  }
});

final endingSoonContestsProvider =
    FutureProvider.family<List<Contest>, EndingSoonParams>((ref, params) async {
  final repository = ref.watch(contestRepositoryProvider);
  try {
    return await repository.getEndingSoonContests(
      limit: params.limit,
      maxDaysRemaining: params.maxDaysRemaining,
    );
  } catch (e, stackTrace) {
    logger.e(
      'Error in endingSoonContestsProvider',
      error: e,
      stackTrace: stackTrace,
    );
    // Retry once after a short delay
    await Future.delayed(const Duration(seconds: 2));
    try {
      return await repository.getEndingSoonContests(
        limit: params.limit,
        maxDaysRemaining: params.maxDaysRemaining,
      );
    } catch (retryError) {
      logger.e('Retry failed in endingSoonContestsProvider', error: retryError);
      rethrow;
    }
  }
});

final contestByIdProvider =
    FutureProvider.family<Contest?, String>((ref, id) async {
  final repository = ref.watch(contestRepositoryProvider);
  try {
    return await repository.getContestById(id);
  } catch (e, stackTrace) {
    logger.e(
      'Error in contestByIdProvider for id: $id',
      error: e,
      stackTrace: stackTrace,
    );
    // For individual contest fetching, retry with exponential backoff
    await Future.delayed(const Duration(seconds: 1));
    try {
      return await repository.getContestById(id);
    } catch (retryError) {
      logger.e(
        'Retry failed in contestByIdProvider for id: $id',
        error: retryError,
      );
      return null; // Return null instead of throwing for individual contests
    }
  }
});

final availableCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(contestRepositoryProvider);
  try {
    return await repository.getAvailableCategories();
  } catch (e, stackTrace) {
    logger.e(
      'Error in availableCategoriesProvider',
      error: e,
      stackTrace: stackTrace,
    );
    // For categories, provide fallback list if fetch fails
    logger.i('Returning fallback categories due to fetch error');
    return ['General', 'Gaming', 'Technology', 'Fashion', 'Travel', 'Food'];
  }
});

final activeContestCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(contestRepositoryProvider);
  try {
    return await repository.getActiveContestCount();
  } catch (e, stackTrace) {
    logger.e(
      'Error in activeContestCountProvider',
      error: e,
      stackTrace: stackTrace,
    );
    // Return 0 as fallback for count
    return 0;
  }
});

class ContestQueryParams {
  const ContestQueryParams({
    this.category,
    this.sortBy,
    this.ascending = true,
    this.limit = 50,
  });

  final String? category;
  final String? sortBy;
  final bool ascending;
  final int limit;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ContestQueryParams &&
        other.category == category &&
        other.sortBy == sortBy &&
        other.ascending == ascending &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(category, sortBy, ascending, limit);

  ContestQueryParams copyWith({
    String? category,
    String? sortBy,
    bool? ascending,
    int? limit,
  }) =>
      ContestQueryParams(
        category: category ?? this.category,
        sortBy: sortBy ?? this.sortBy,
        ascending: ascending ?? this.ascending,
        limit: limit ?? this.limit,
      );
}

class EndingSoonParams {
  const EndingSoonParams({
    this.limit = 10,
    this.maxDaysRemaining = 7,
  });

  final int limit;
  final int maxDaysRemaining;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EndingSoonParams &&
        other.limit == limit &&
        other.maxDaysRemaining == maxDaysRemaining;
  }

  @override
  int get hashCode => Object.hash(limit, maxDaysRemaining);
}
