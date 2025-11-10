import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/contest.dart';
import '../utils/logger.dart';

class ContestCacheService {
  static const String _boxName = 'contests_cache';
  static const String _metadataBoxName = 'cache_metadata';
  static const Duration _cacheExpiry = Duration(hours: 6);

  Box<Map>? _contestBox;
  Box<Map>? _metadataBox;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      _contestBox = await Hive.openBox<Map>(_boxName);
      _metadataBox = await Hive.openBox<Map>(_metadataBoxName);

      _isInitialized = true;
      logger.d('ContestCacheService initialized successfully');
    } on HiveError catch (e) {
      logger.e('Hive error during initialization: ${e.message}', error: e);
      _isInitialized = false;
    } on FileSystemException catch (e) {
      logger.e('File system error during cache initialization', error: e);
      _isInitialized = false;
    } on Exception catch (e) {
      logger.e('Unexpected error during ContestCacheService initialization',
          error: e);
      _isInitialized = false;
    }
  }

  Future<void> cacheContests(
    String key,
    List<Contest> contests,
  ) async {
    if (!_isInitialized) {
      logger.w('Cache not initialized, skipping cacheContests');
      return;
    }

    try {
      final contestsData = contests.map((c) => c.toFirestore()).toList();

      await _contestBox?.put(key, {
        'data': contestsData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      await _metadataBox?.put(key, {
        'count': contests.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      logger.d('Cached ${contests.length} contests with key: $key');
    } on HiveError catch (e) {
      logger.e('Hive error caching contests for key: $key - ${e.message}',
          error: e);
    } on FileSystemException catch (e) {
      logger.e('File system error caching contests for key: $key', error: e);
    } on Exception catch (e) {
      logger.e('Unexpected error caching contests for key: $key', error: e);
    }
  }

  Future<List<Contest>?> getCachedContests(String key) async {
    if (!_isInitialized) {
      logger.w('Cache not initialized, returning null');
      return null;
    }

    try {
      final cached = _contestBox?.get(key);
      if (cached == null) {
        logger.d('No cached data found for key: $key');
        return null;
      }

      final timestamp = cached['timestamp'] as int?;
      if (timestamp == null) {
        logger.w('Invalid cache timestamp for key: $key');
        await _contestBox?.delete(key);
        return null;
      }

      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _cacheExpiry.inMilliseconds) {
        logger.d('Cache expired for key: $key');
        await _contestBox?.delete(key);
        await _metadataBox?.delete(key);
        return null;
      }

      final contestsData = cached['data'] as List?;
      if (contestsData == null) {
        logger.w('Invalid cache data for key: $key');
        return null;
      }

      final contests = <Contest>[];
      for (final data in contestsData) {
        try {
          final contestMap = Map<String, dynamic>.from(data as Map);
          contests.add(Contest.fromMap(contestMap));
        } on FormatException catch (e) {
          logger.w('Failed to parse cached contest data format', error: e);
        } on TypeError catch (e) {
          logger.w('Failed to parse cached contest type error', error: e);
        } on Exception catch (e) {
          logger.w('Failed to parse cached contest', error: e);
        }
      }

      logger.d('Retrieved ${contests.length} cached contests for key: $key');
      return contests;
    } on Exception catch (e) {
      logger.e('Error retrieving cached contests for key: $key', error: e);
      return null;
    }
  }

  Future<void> invalidateCache(String key) async {
    if (!_isInitialized) return;

    try {
      await _contestBox?.delete(key);
      await _metadataBox?.delete(key);
      logger.d('Invalidated cache for key: $key');
    } on Exception catch (e) {
      logger.e('Error invalidating cache for key: $key', error: e);
    }
  }

  Future<void> clearAllCache() async {
    if (!_isInitialized) return;

    try {
      await _contestBox?.clear();
      await _metadataBox?.clear();
      logger.d('Cleared all cache');
    } on Exception catch (e) {
      logger.e('Error clearing all cache', error: e);
    }
  }

  Future<Map<String, dynamic>> getCacheMetadata(String key) async {
    if (!_isInitialized) return {};

    try {
      final metadata = _metadataBox?.get(key);
      if (metadata == null) return {};

      return Map<String, dynamic>.from(metadata);
    } on Exception catch (e) {
      logger.e('Error getting cache metadata for key: $key', error: e);
      return {};
    }
  }

  Future<bool> isCacheValid(String key) async {
    if (!_isInitialized) return false;

    try {
      final cached = _contestBox?.get(key);
      if (cached == null) return false;

      final timestamp = cached['timestamp'] as int?;
      if (timestamp == null) return false;

      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      return cacheAge <= _cacheExpiry.inMilliseconds;
    } on Exception catch (e) {
      logger.e('Error checking cache validity for key: $key', error: e);
      return false;
    }
  }

  Future<void> dispose() async {
    try {
      await _contestBox?.close();
      await _metadataBox?.close();
      _isInitialized = false;
      logger.d('ContestCacheService disposed');
    } on Exception catch (e) {
      logger.e('Error disposing ContestCacheService', error: e);
    }
  }
}

final contestCacheService = ContestCacheService();
