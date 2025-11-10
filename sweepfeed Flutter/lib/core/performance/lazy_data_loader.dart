import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/contest.dart';
import '../utils/logger.dart';

/// A performance-optimized lazy data loader that supports pagination,
/// caching, and background prefetching
class LazyDataLoader<T> {
  LazyDataLoader({
    required Future<List<T>> Function(int page, int pageSize) fetchData,
    int pageSize = 20,
    int maxCacheSize = 100,
    Duration cacheExpiry = const Duration(minutes: 5),
  })  : _fetchData = fetchData,
        _pageSize = pageSize,
        _maxCacheSize = maxCacheSize,
        _cacheExpiry = cacheExpiry;
  final Future<List<T>> Function(int page, int pageSize) _fetchData;
  final int _pageSize;
  final int _maxCacheSize;
  final Duration _cacheExpiry;

  final Map<int, List<T>> _cache = {};
  final Map<int, DateTime> _cacheTimestamps = {};
  final Set<int> _loadingPages = {};
  final Queue<int> _accessOrder = Queue<int>();

  /// Loads a specific page of data with lazy loading and caching
  Future<List<T>> loadPage(int page) async {
    // Check if page is already being loaded
    if (_loadingPages.contains(page)) {
      // Wait for ongoing load to complete
      while (_loadingPages.contains(page)) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    // Check cache first
    if (_cache.containsKey(page) && !_isCacheExpired(page)) {
      _updateAccessOrder(page);
      return _cache[page]!;
    }

    // Start loading
    _loadingPages.add(page);

    try {
      final data = await _fetchData(page, _pageSize);

      // Store in cache
      _cache[page] = data;
      _cacheTimestamps[page] = DateTime.now();
      _updateAccessOrder(page);

      // Clean up cache if needed
      _cleanupCache();

      // Prefetch next page in background
      _prefetchNextPage(page);

      logger.d('Loaded page $page with ${data.length} items');
      return data;
    } catch (e) {
      logger.e('Failed to load page $page', error: e);
      rethrow;
    } finally {
      _loadingPages.remove(page);
    }
  }

  /// Loads multiple pages efficiently
  Future<List<T>> loadPages(List<int> pages) async {
    final results = <T>[];

    // Load pages in parallel where possible
    final futures = pages.map(loadPage);
    final pageResults = await Future.wait(futures);

    for (final pageData in pageResults) {
      results.addAll(pageData);
    }

    return results;
  }

  /// Preloads the next page in background for better UX
  void _prefetchNextPage(int currentPage) {
    final nextPage = currentPage + 1;

    if (!_cache.containsKey(nextPage) && !_loadingPages.contains(nextPage)) {
      // Prefetch in background without blocking
      Future.microtask(() async {
        try {
          await loadPage(nextPage);
        } catch (e) {
          logger.d('Background prefetch failed for page $nextPage', error: e);
        }
      });
    }
  }

  /// Checks if cached data is expired
  bool _isCacheExpired(int page) {
    final timestamp = _cacheTimestamps[page];
    if (timestamp == null) return true;

    return DateTime.now().difference(timestamp) > _cacheExpiry;
  }

  /// Updates the access order for LRU cache management
  void _updateAccessOrder(int page) {
    _accessOrder.remove(page);
    _accessOrder.addLast(page);
  }

  /// Cleans up old cache entries based on LRU policy
  void _cleanupCache() {
    while (_cache.length > _maxCacheSize && _accessOrder.isNotEmpty) {
      final oldestPage = _accessOrder.removeFirst();
      _cache.remove(oldestPage);
      _cacheTimestamps.remove(oldestPage);
      logger.d('Removed page $oldestPage from cache');
    }
  }

  /// Clears all cached data
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    _accessOrder.clear();
    logger.d('Cache cleared');
  }

  /// Gets current cache statistics
  Map<String, dynamic> getCacheStats() => {
        'cachedPages': _cache.length,
        'loadingPages': _loadingPages.length,
        'maxCacheSize': _maxCacheSize,
        'cacheHitRatio':
            _accessOrder.isNotEmpty ? _cache.length / _accessOrder.length : 0.0,
      };
}

/// Memoization utility for expensive computations
class Memoizer<K, V> {
  Memoizer({
    Duration expiry = const Duration(minutes: 5),
    int maxSize = 1000,
  })  : _expiry = expiry,
        _maxSize = maxSize;
  final Map<K, V> _cache = {};
  final Map<K, DateTime> _timestamps = {};
  final Duration _expiry;
  final int _maxSize;

  /// Gets or computes a value with memoization
  V memoize(K key, V Function() computation) {
    // Check if we have a valid cached value
    if (_cache.containsKey(key) && !_isExpired(key)) {
      return _cache[key]!;
    }

    // Compute new value
    final value = computation();

    // Store in cache
    _cache[key] = value;
    _timestamps[key] = DateTime.now();

    // Clean up if cache is too large
    _cleanup();

    return value;
  }

  /// Checks if a cached value is expired
  bool _isExpired(K key) {
    final timestamp = _timestamps[key];
    if (timestamp == null) return true;

    return DateTime.now().difference(timestamp) > _expiry;
  }

  /// Cleans up expired entries
  void _cleanup() {
    final now = DateTime.now();
    final expiredKeys = <K>[];

    for (final entry in _timestamps.entries) {
      if (now.difference(entry.value) > _expiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
      _timestamps.remove(key);
    }

    // If still too large, remove oldest entries
    while (_cache.length > _maxSize) {
      K? oldestKey;
      DateTime? oldestTime;

      for (final entry in _timestamps.entries) {
        if (oldestTime == null || entry.value.isBefore(oldestTime)) {
          oldestTime = entry.value;
          oldestKey = entry.key;
        }
      }

      if (oldestKey != null) {
        _cache.remove(oldestKey);
        _timestamps.remove(oldestKey);
      } else {
        break;
      }
    }
  }

  /// Clears all cached values
  void clear() {
    _cache.clear();
    _timestamps.clear();
  }

  /// Gets cache statistics
  Map<String, dynamic> getStats() => {
        'cacheSize': _cache.length,
        'maxSize': _maxSize,
        'expiredEntries': _timestamps.values
            .where(
              (timestamp) => DateTime.now().difference(timestamp) > _expiry,
            )
            .length,
      };
}

/// Performance-optimized contest loader
class ContestLazyLoader extends LazyDataLoader<Contest> {
  ContestLazyLoader({
    required Future<List<Contest>> Function(int page, int pageSize)
        fetchContests,
  }) : super(
          fetchData: fetchContests,
          pageSize: 20,
          maxCacheSize: 50,
          cacheExpiry: const Duration(minutes: 10),
        );
}

/// Widget rebuild optimization utilities
class WidgetOptimizer {
  static final Memoizer<String, Widget> _widgetMemoizer = Memoizer(
    expiry: const Duration(minutes: 1),
    maxSize: 500,
  );

  /// Memoizes widget building to prevent unnecessary rebuilds
  static Widget memoizeWidget(String key, Widget Function() builder) =>
      _widgetMemoizer.memoize(key, builder);

  /// Creates a stable key for widget memoization
  static String createWidgetKey(String widgetType, Map<String, dynamic> props) {
    final propsString =
        props.entries.map((e) => '${e.key}:${e.value}').join(',');
    return '$widgetType($propsString)';
  }
}

/// Performance monitoring for lazy loading
class PerformanceMonitor {
  static final Map<String, List<Duration>> _operationTimes = {};
  static final Map<String, int> _operationCounts = {};

  /// Times an operation and stores performance data
  static Future<T> timeOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();

      _recordOperation(operationName, stopwatch.elapsed);

      return result;
    } catch (e) {
      stopwatch.stop();
      _recordOperation('${operationName}_error', stopwatch.elapsed);
      rethrow;
    }
  }

  /// Records operation timing
  static void _recordOperation(String operationName, Duration duration) {
    _operationTimes.putIfAbsent(operationName, () => []);
    _operationCounts.putIfAbsent(operationName, () => 0);

    _operationTimes[operationName]!.add(duration);
    _operationCounts[operationName] = _operationCounts[operationName]! + 1;

    // Keep only last 100 measurements
    if (_operationTimes[operationName]!.length > 100) {
      _operationTimes[operationName]!.removeAt(0);
    }

    // Log slow operations
    if (duration.inMilliseconds > 1000) {
      logger.w(
        'Slow operation detected: $operationName took ${duration.inMilliseconds}ms',
      );
    }
  }

  /// Gets performance statistics
  static Map<String, dynamic> getStats() {
    final stats = <String, dynamic>{};

    for (final operationName in _operationTimes.keys) {
      final times = _operationTimes[operationName]!;
      final count = _operationCounts[operationName]!;

      if (times.isNotEmpty) {
        final avgMs =
            times.map((d) => d.inMilliseconds).reduce((a, b) => a + b) /
                times.length;
        final maxMs =
            times.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
        final minMs =
            times.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);

        stats[operationName] = {
          'count': count,
          'avgMs': avgMs.round(),
          'maxMs': maxMs,
          'minMs': minMs,
        };
      }
    }

    return stats;
  }

  /// Clears all performance data
  static void clear() {
    _operationTimes.clear();
    _operationCounts.clear();
  }
}
