import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// Data loading service that uses isolates to prevent UI blocking
class IsolateDataLoader {
  factory IsolateDataLoader() => _instance;
  IsolateDataLoader._internal();
  static final IsolateDataLoader _instance = IsolateDataLoader._internal();

  // Cache for loaded data
  List<Map<String, dynamic>> _cachedContests = [];
  List<Map<String, dynamic>> _cachedActiveContests = [];
  List<Map<String, dynamic>> _cachedExpiredContests = [];

  bool _isLoading = false;
  bool _isLoaded = false;
  final Completer<void> _loadCompleter = Completer<void>();

  /// Get loaded data status
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  Future<void> get loadComplete => _loadCompleter.future;

  /// Get cached data
  List<Map<String, dynamic>> get cachedContests =>
      List.unmodifiable(_cachedContests);
  List<Map<String, dynamic>> get cachedActiveContests =>
      List.unmodifiable(_cachedActiveContests);
  List<Map<String, dynamic>> get cachedExpiredContests =>
      List.unmodifiable(_cachedExpiredContests);

  /// Load contest data using isolates for heavy processing
  Future<void> loadContestDataAsync() async {
    if (_isLoaded || _isLoading) {
      return _loadCompleter.future;
    }

    _isLoading = true;
    logger.d('Starting isolate-based contest data loading...');

    try {
      // Step 1: Load raw JSON data (must be on main isolate)
      final rawData = await _loadRawContestData();

      // Step 2: Process data in compute isolate for heavy operations
      final processedData =
          await compute(_processContestDataInIsolate, rawData);

      // Step 3: Cache processed data
      _cacheProcessedData(processedData);

      _isLoaded = true;
      _loadCompleter.complete();
      logger.d('Contest data loading completed successfully');
    } catch (e) {
      logger.e('Contest data loading failed: $e');
      _loadCompleter.completeError(e);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Load raw contest data from assets
  Future<Map<String, dynamic>> _loadRawContestData() async {
    try {
      // Try to load from different sources in order of preference
      String? jsonString;

      try {
        jsonString =
            await rootBundle.loadString('assets/FINAL_QUALITY_CONTESTS.json');
        logger.d('Loaded FINAL_QUALITY_CONTESTS.json');
      } catch (e) {
        try {
          jsonString = await rootBundle
              .loadString('assets/MASSIVE_ACTIVE_CONTESTS.json');
          logger.d('Loaded MASSIVE_ACTIVE_CONTESTS.json');
        } catch (e2) {
          try {
            jsonString =
                await rootBundle.loadString('assets/FLUTTER_SWEEPFEED_DATA.json');
            logger.d('Loaded FLUTTER_SWEEPFEED_DATA.json');
          } catch (e3) {
            // All files missing - return empty data gracefully
            logger.w('No contest data files found, returning empty data');
            return {
              'jsonData': '{"contests": []}',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            };
          }
        }
      }

      return {
        'jsonData': jsonString ?? '{"contests": []}',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      logger.e('Failed to load contest data files: $e');
      // Return empty data instead of crashing
      return {
        'jsonData': '{"contests": []}',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Process contest data in isolate (static function for compute)
  static Map<String, dynamic> _processContestDataInIsolate(
    Map<String, dynamic> rawData,
  ) {
    try {
      final jsonString = rawData['jsonData'] as String;
      final timestamp = rawData['timestamp'] as int;

      // Parse JSON in isolate
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> contests = jsonData['contests'] ?? [];

      final processedContests = <Map<String, dynamic>>[];
      final activeContests = <Map<String, dynamic>>[];
      final expiredContests = <Map<String, dynamic>>[];

      final now = DateTime.now();

      // Process each contest
      for (final contest in contests) {
        try {
          final processed = _processIndividualContest(contest, now);
          processedContests.add(processed);

          // Sort into active/expired
          if (processed['isActive'] == true) {
            activeContests.add(processed);
          } else {
            expiredContests.add(processed);
          }
        } catch (e) {
          // Skip invalid contests but don't crash
          continue;
        }
      }

      return {
        'allContests': processedContests,
        'activeContests': activeContests,
        'expiredContests': expiredContests,
        'processedAt': now.toIso8601String(),
        'totalCount': processedContests.length,
        'activeCount': activeContests.length,
        'expiredCount': expiredContests.length,
      };
    } catch (e) {
      throw Exception('Contest data processing failed: $e');
    }
  }

  /// Process individual contest data
  static Map<String, dynamic> _processIndividualContest(
    contest,
    DateTime now,
  ) {
    final contestMap = Map<String, dynamic>.from(contest);

    // Parse end date
    DateTime? endDate;
    if (contestMap['end_date_iso'] != null) {
      try {
        endDate = DateTime.parse(contestMap['end_date_iso']);
      } catch (e) {
        // Try other date formats
      }
    }

    // Fallback date parsing
    if (endDate == null && contestMap['end_date'] != null) {
      endDate = _parseEndDate(contestMap['end_date'].toString());
    }

    // Default to 30 days if no valid date
    endDate ??= now.add(const Duration(days: 30));

    // Calculate status
    final daysLeft = endDate.difference(now).inDays;

    // Update contest data
    contestMap['endDateTime'] = endDate.toIso8601String();
    contestMap['daysLeft'] = daysLeft > 0 ? daysLeft : 0;
    contestMap['isActive'] = daysLeft > 0;
    contestMap['isExpired'] = daysLeft <= 0;

    // Add status and urgency info
    if (daysLeft <= 0) {
      contestMap['status'] = 'expired';
      contestMap['statusColor'] = 0xFFE53935;
      contestMap['urgencyMessage'] = 'EXPIRED';
    } else if (daysLeft <= 3) {
      contestMap['status'] = 'ending_very_soon';
      contestMap['statusColor'] = 0xFFFF6F00;
      contestMap['urgencyMessage'] =
          daysLeft == 1 ? 'LAST DAY!' : 'ENDING VERY SOON!';
    } else if (daysLeft <= 7) {
      contestMap['status'] = 'ending_soon';
      contestMap['statusColor'] = 0xFFFFA726;
      contestMap['urgencyMessage'] = 'Ending in $daysLeft days';
    } else if (daysLeft <= 14) {
      contestMap['status'] = 'limited_time';
      contestMap['statusColor'] = 0xFFFFEB3B;
      contestMap['urgencyMessage'] = '';
    } else {
      contestMap['status'] = 'active';
      contestMap['statusColor'] = 0xFF4CAF50;
      contestMap['urgencyMessage'] = '';
    }

    // Add search text for better performance
    final searchText = [
      contestMap['title'] ?? '',
      contestMap['sponsor'] ?? '',
      contestMap['prize'] ?? '',
      contestMap['category'] ?? '',
    ].join(' ').toLowerCase();

    contestMap['searchText'] = searchText;

    return contestMap;
  }

  /// Parse various date formats
  static DateTime? _parseEndDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    // Try ISO format first
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      // Continue to other formats
    }

    // Try common formats
    final monthRegex = RegExp(r'(\w+)\s+(\d{1,2}),?\s+(\d{4})');
    final slashRegex = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{2,4})');

    // Month names
    final months = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    // Try month format
    if (monthRegex.hasMatch(dateStr)) {
      final match = monthRegex.firstMatch(dateStr);
      if (match != null) {
        final monthName = match.group(1)?.toLowerCase();
        final day = int.tryParse(match.group(2) ?? '');
        final year = int.tryParse(match.group(3) ?? '');

        if (monthName != null && day != null && year != null) {
          final month = months[monthName];
          if (month != null) {
            return DateTime(year, month, day);
          }
        }
      }
    }

    // Try MM/DD/YYYY format
    if (slashRegex.hasMatch(dateStr)) {
      final match = slashRegex.firstMatch(dateStr);
      if (match != null) {
        final month = int.tryParse(match.group(1) ?? '');
        final day = int.tryParse(match.group(2) ?? '');
        var year = int.tryParse(match.group(3) ?? '');

        if (month != null && day != null && year != null) {
          if (year < 100) year += 2000;
          return DateTime(year, month, day);
        }
      }
    }

    return null;
  }

  /// Cache processed data
  void _cacheProcessedData(Map<String, dynamic> processedData) {
    _cachedContests =
        List<Map<String, dynamic>>.from(processedData['allContests'] ?? []);
    _cachedActiveContests =
        List<Map<String, dynamic>>.from(processedData['activeContests'] ?? []);
    _cachedExpiredContests =
        List<Map<String, dynamic>>.from(processedData['expiredContests'] ?? []);

    logger.d('Cached ${_cachedContests.length} total contests '
        '(${_cachedActiveContests.length} active, ${_cachedExpiredContests.length} expired)');
  }

  /// Get contests by category (fast lookup from cache)
  List<Map<String, dynamic>> getContestsByCategory(String category) {
    if (category == 'all') return _cachedActiveContests;
    return _cachedActiveContests
        .where((c) => c['category'] == category)
        .toList();
  }

  /// Get contests ending soon
  List<Map<String, dynamic>> getEndingSoon() => _cachedActiveContests
      .where((c) => (c['daysLeft'] as int? ?? 30) <= 7)
      .toList()
    ..sort((a, b) => (a['daysLeft'] as int).compareTo(b['daysLeft'] as int));

  /// Search contests (fast text search)
  List<Map<String, dynamic>> searchContests(String query) {
    if (query.isEmpty) return _cachedActiveContests;

    final searchTerm = query.toLowerCase();
    return _cachedActiveContests
        .where(
          (contest) =>
              (contest['searchText'] as String? ?? '').contains(searchTerm),
        )
        .toList();
  }

  /// Get featured contests
  List<Map<String, dynamic>> getFeaturedContests() =>
      _cachedActiveContests.where((c) => c['featured'] == true).toList();

  /// Get trending contests
  List<Map<String, dynamic>> getTrendingContests() =>
      _cachedActiveContests.where((c) => c['trending'] == true).toList();

  /// Clear cache
  void clearCache() {
    _cachedContests.clear();
    _cachedActiveContests.clear();
    _cachedExpiredContests.clear();
    _isLoaded = false;
  }

  /// Get loading statistics
  Map<String, dynamic> getStatistics() => {
        'isLoaded': _isLoaded,
        'isLoading': _isLoading,
        'totalContests': _cachedContests.length,
        'activeContests': _cachedActiveContests.length,
        'expiredContests': _cachedExpiredContests.length,
        'endingSoon': getEndingSoon().length,
      };
}
