import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../cache/contest_cache_service.dart';
import '../../models/contest.dart';
import '../../utils/logger.dart';
import 'contest_repository.dart';

class CachedContestRepository {
  CachedContestRepository({
    ContestRepository? repository,
    ContestCacheService? cacheService,
  })  : _repository = repository ?? ContestRepository(),
        _cacheService = cacheService ?? contestCacheService;
  final ContestRepository _repository;
  final ContestCacheService _cacheService;

  Future<void> initialize() async {
    await _cacheService.initialize();
  }

  Future<List<Contest>> getActiveContests({
    String? category,
    String? sortBy,
    bool ascending = true,
    int limit = 50,
    DocumentSnapshot? startAfter,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        'active_${category ?? "all"}_${sortBy ?? "default"}_$limit';

    if (!forceRefresh) {
      final cached = await _cacheService.getCachedContests(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        logger.d('Returning ${cached.length} cached active contests');
        _refreshCacheInBackground(cacheKey, category, sortBy, ascending, limit);
        return cached;
      }
    }

    final contests = await _repository.getActiveContests(
      category: category,
      sortBy: sortBy,
      ascending: ascending,
      limit: limit,
      startAfter: startAfter,
    );

    if (contests.isNotEmpty) {
      await _cacheService.cacheContests(cacheKey, contests);
    }

    return contests;
  }

  Future<List<Contest>> getHighValueContests({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'high_value';

    if (!forceRefresh) {
      final cached = await _cacheService.getCachedContests(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        logger.d('Returning ${cached.length} cached high value contests');
        _refreshHighValueCacheInBackground(limit);
        return cached;
      }
    }

    final contests = await _repository.getHighValueContests(limit: limit);

    if (contests.isNotEmpty) {
      await _cacheService.cacheContests(cacheKey, contests);
    }

    return contests;
  }

  Future<List<Contest>> getEndingSoonContests({
    int limit = 10,
    int maxDaysRemaining = 7,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'ending_soon_$maxDaysRemaining';

    if (!forceRefresh) {
      final cached = await _cacheService.getCachedContests(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        logger.d('Returning ${cached.length} cached ending soon contests');
        _refreshEndingSoonCacheInBackground(limit, maxDaysRemaining);
        return cached;
      }
    }

    final contests = await _repository.getEndingSoonContests(
      limit: limit,
      maxDaysRemaining: maxDaysRemaining,
    );

    if (contests.isNotEmpty) {
      await _cacheService.cacheContests(cacheKey, contests);
    }

    return contests;
  }

  Future<Contest?> getContestById(
    String id, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'contest_$id';

    if (!forceRefresh) {
      final cached = await _cacheService.getCachedContests(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        logger.d('Returning cached contest $id');
        return cached.first;
      }
    }

    final contest = await _repository.getContestById(id);

    if (contest != null) {
      await _cacheService.cacheContests(cacheKey, [contest]);
    }

    return contest;
  }

  Future<List<String>> getAvailableCategories({
    bool forceRefresh = false,
  }) async =>
      _repository.getAvailableCategories();

  Future<int> getActiveContestCount({bool forceRefresh = false}) async =>
      _repository.getActiveContestCount();

  Stream<List<Contest>> getActiveContestsStream({
    String? category,
    String? sortBy,
    bool ascending = true,
    int limit = 50,
  }) =>
      _repository.getActiveContestsStream(
        category: category,
        sortBy: sortBy,
        ascending: ascending,
        limit: limit,
      );

  Future<void> invalidateCache(String key) async {
    await _cacheService.invalidateCache(key);
  }

  Future<void> invalidateAllCache() async {
    await _cacheService.clearAllCache();
  }

  void _refreshCacheInBackground(
    String cacheKey,
    String? category,
    String? sortBy,
    bool ascending,
    int limit,
  ) {
    Future.microtask(() async {
      try {
        final contests = await _repository.getActiveContests(
          category: category,
          sortBy: sortBy,
          ascending: ascending,
          limit: limit,
        );
        if (contests.isNotEmpty) {
          await _cacheService.cacheContests(cacheKey, contests);
          logger.d('Background refresh completed for $cacheKey');
        }
      } on FirebaseException catch (e) {
        logger.w('Firebase error in background cache refresh for $cacheKey: ${e.code}', error: e);
      } on Exception catch (e) {
        logger.w('Background cache refresh failed for $cacheKey', error: e);
      }
    });
  }

  void _refreshHighValueCacheInBackground(int limit) {
    Future.microtask(() async {
      try {
        final contests = await _repository.getHighValueContests(limit: limit);
        if (contests.isNotEmpty) {
          await _cacheService.cacheContests('high_value', contests);
          logger.d('Background refresh completed for high_value');
        }
      } on FirebaseException catch (e) {
        logger.w('Firebase error in background high value cache refresh: ${e.code}', error: e);
      } on Exception catch (e) {
        logger.w('Background cache refresh failed for high_value', error: e);
      }
    });
  }

  void _refreshEndingSoonCacheInBackground(
    int limit,
    int maxDaysRemaining,
  ) {
    Future.microtask(() async {
      try {
        final contests = await _repository.getEndingSoonContests(
          limit: limit,
          maxDaysRemaining: maxDaysRemaining,
        );
        if (contests.isNotEmpty) {
          await _cacheService.cacheContests(
            'ending_soon_$maxDaysRemaining',
            contests,
          );
          logger.d('Background refresh completed for ending_soon');
        }
      } on FirebaseException catch (e) {
        logger.w('Firebase error in background ending soon cache refresh: ${e.code}', error: e);
      } on Exception catch (e) {
        logger.w('Background cache refresh failed for ending_soon', error: e);
      }
    });
  }
}
