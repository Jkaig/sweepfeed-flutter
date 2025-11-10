import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage contest expiration and history
class ContestExpirationService {
  factory ContestExpirationService() => _instance;
  ContestExpirationService._internal();
  static final ContestExpirationService _instance =
      ContestExpirationService._internal();

  List<Map<String, dynamic>> _activeContests = [];
  final List<Map<String, dynamic>> _expiredContests = [];
  List<Map<String, dynamic>> _contestHistory = [];

  Timer? _expirationTimer;
  bool _isLoaded = false;

  /// Load contests from the massive dataset (1000+ contests)
  Future<void> loadMassiveContests() async {
    if (_isLoaded) return;

    try {
      // Try to load the quality contest file first
      String jsonString;
      try {
        jsonString =
            await rootBundle.loadString('assets/FINAL_QUALITY_CONTESTS.json');
      } catch (e) {
        try {
          // Fallback to massive dataset
          jsonString = await rootBundle
              .loadString('assets/MASSIVE_ACTIVE_CONTESTS.json');
        } catch (e2) {
          // Final fallback
          jsonString =
              await rootBundle.loadString('assets/FLUTTER_SWEEPFEED_DATA.json');
        }
      }

      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> contests = jsonData['contests'] ?? [];

      // Process each contest
      for (final contest in contests) {
        final processed = await _processContest(contest);
        if (processed['isActive']) {
          _activeContests.add(processed);
        } else {
          _expiredContests.add(processed);
        }
      }

      _isLoaded = true;

      // Load history from local storage
      await _loadHistory();

      // Start expiration monitoring
      _startExpirationMonitoring();
    } catch (e) {
      // print('Error loading contest data: $e');
    }
  }

  /// Process a contest and check if it's expired
  Future<Map<String, dynamic>> _processContest(
    Map<String, dynamic> contest,
  ) async {
    final now = DateTime.now();

    // Parse end date
    DateTime? endDate;
    if (contest['end_date_iso'] != null) {
      try {
        endDate = DateTime.parse(contest['end_date_iso']);
      } catch (e) {
        // Try other formats
      }
    }

    // If no valid date, try to parse from string
    if (endDate == null && contest['end_date'] != null) {
      endDate = _parseEndDate(contest['end_date']);
    }

    // If still no date, assume 30 days from now
    endDate ??= now.add(const Duration(days: 30));

    // Calculate days left
    final daysLeft = endDate.difference(now).inDays;

    // Update contest data
    contest['endDateTime'] = endDate.toIso8601String();
    contest['daysLeft'] = daysLeft > 0 ? daysLeft : 0;
    contest['isActive'] = daysLeft > 0;
    contest['isExpired'] = daysLeft <= 0;

    // Add status indicators
    if (daysLeft <= 0) {
      contest['status'] = 'expired';
      contest['statusColor'] = 0xFFE53935; // Red
    } else if (daysLeft <= 3) {
      contest['status'] = 'ending_very_soon';
      contest['statusColor'] = 0xFFFF6F00; // Deep Orange
    } else if (daysLeft <= 7) {
      contest['status'] = 'ending_soon';
      contest['statusColor'] = 0xFFFFA726; // Orange
    } else if (daysLeft <= 14) {
      contest['status'] = 'limited_time';
      contest['statusColor'] = 0xFFFFEB3B; // Yellow
    } else {
      contest['status'] = 'active';
      contest['statusColor'] = 0xFF4CAF50; // Green
    }

    // Add urgency message
    if (daysLeft <= 0) {
      contest['urgencyMessage'] = 'EXPIRED';
    } else if (daysLeft == 1) {
      contest['urgencyMessage'] = 'LAST DAY!';
    } else if (daysLeft <= 3) {
      contest['urgencyMessage'] = 'ENDING VERY SOON!';
    } else if (daysLeft <= 7) {
      contest['urgencyMessage'] = 'Ending in $daysLeft days';
    } else {
      contest['urgencyMessage'] = '';
    }

    return contest;
  }

  /// Parse various date formats
  DateTime? _parseEndDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    // Try common formats
    final formats = [
      RegExp(r'(\w+)\s+(\d{1,2}),?\s+(\d{4})'), // Month DD, YYYY
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{2,4})'), // MM/DD/YYYY
      RegExp(r'(\d{4})-(\d{2})-(\d{2})'), // YYYY-MM-DD
    ];

    // Month names to numbers
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

    // Try month name format
    if (formats[0].hasMatch(dateStr)) {
      final match = formats[0].firstMatch(dateStr);
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
    if (formats[1].hasMatch(dateStr)) {
      final match = formats[1].firstMatch(dateStr);
      if (match != null) {
        final month = int.tryParse(match.group(1) ?? '');
        final day = int.tryParse(match.group(2) ?? '');
        var year = int.tryParse(match.group(3) ?? '');

        if (month != null && day != null && year != null) {
          // Handle 2-digit years
          if (year < 100) {
            year += 2000;
          }
          return DateTime(year, month, day);
        }
      }
    }

    // Try ISO format
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Start monitoring for expired contests
  void _startExpirationMonitoring() {
    // Check every hour for expired contests
    _expirationTimer?.cancel();
    _expirationTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkForExpiredContests();
    });

    // Also check immediately
    _checkForExpiredContests();
  }

  /// Check and move expired contests
  Future<void> _checkForExpiredContests() async {
    final now = DateTime.now();
    final stillActive = <Map<String, dynamic>>[];
    final newlyExpired = <Map<String, dynamic>>[];

    for (final contest in _activeContests) {
      final endDateStr = contest['endDateTime'];
      if (endDateStr != null) {
        try {
          final endDate = DateTime.parse(endDateStr);
          if (endDate.isBefore(now)) {
            // Contest has expired
            contest['isActive'] = false;
            contest['isExpired'] = true;
            contest['status'] = 'expired';
            contest['expiredAt'] = now.toIso8601String();
            newlyExpired.add(contest);

            // Add to history
            _addToHistory(contest);
          } else {
            // Update days left
            contest['daysLeft'] = endDate.difference(now).inDays;
            stillActive.add(contest);
          }
        } catch (e) {
          stillActive.add(contest);
        }
      } else {
        stillActive.add(contest);
      }
    }

    // Update lists
    _activeContests = stillActive;
    _expiredContests.addAll(newlyExpired);

    if (newlyExpired.isNotEmpty) {
      // print('Moved ${newlyExpired.length} expired contests to history');
      await _saveHistory();
    }
  }

  /// Add contest to history
  void _addToHistory(Map<String, dynamic> contest) {
    final historyEntry = Map<String, dynamic>.from(contest);
    historyEntry['movedToHistoryAt'] = DateTime.now().toIso8601String();
    _contestHistory.add(historyEntry);
  }

  /// Load history from local storage
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('contest_history');
      if (historyJson != null) {
        final List<dynamic> history = json.decode(historyJson);
        _contestHistory = history.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // print('Error loading history: $e');
    }
  }

  /// Save history to local storage
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(_contestHistory);
      await prefs.setString('contest_history', historyJson);
    } catch (e) {
      // print('Error saving history: $e');
    }
  }

  /// Get active contests (not expired)
  List<Map<String, dynamic>> get activeContests => _activeContests;

  /// Get expired contests (for history view)
  List<Map<String, dynamic>> get expiredContests => _expiredContests;

  /// Get full history
  List<Map<String, dynamic>> get contestHistory => _contestHistory;

  /// Get contests ending soon (within 7 days)
  List<Map<String, dynamic>> getEndingSoon() => _activeContests.where((c) {
        final daysLeft = c['daysLeft'] ?? 30;
        return daysLeft <= 7 && daysLeft > 0;
      }).toList()
        ..sort((a, b) => a['daysLeft'].compareTo(b['daysLeft']));

  /// Get contests by urgency level
  List<Map<String, dynamic>> getByUrgency(String urgency) {
    switch (urgency) {
      case 'ending_very_soon':
        return _activeContests
            .where((c) => c['daysLeft'] <= 3 && c['daysLeft'] > 0)
            .toList();
      case 'ending_soon':
        return _activeContests
            .where((c) => c['daysLeft'] <= 7 && c['daysLeft'] > 3)
            .toList();
      case 'limited_time':
        return _activeContests
            .where((c) => c['daysLeft'] <= 14 && c['daysLeft'] > 7)
            .toList();
      default:
        return _activeContests;
    }
  }

  /// Search contests (active only by default)
  List<Map<String, dynamic>> searchContests(
    String query, {
    bool includeExpired = false,
  }) {
    final searchTerm = query.toLowerCase();
    final searchPool = includeExpired
        ? [..._activeContests, ..._expiredContests]
        : _activeContests;

    return searchPool.where((contest) {
      final title = (contest['title'] ?? '').toString().toLowerCase();
      final prize = (contest['prize'] ?? '').toString().toLowerCase();
      final sponsor = (contest['sponsor'] ?? '').toString().toLowerCase();

      return title.contains(searchTerm) ||
          prize.contains(searchTerm) ||
          sponsor.contains(searchTerm);
    }).toList();
  }

  /// Get statistics
  Map<String, int> getStatistics() => {
        'total': _activeContests.length + _expiredContests.length,
        'active': _activeContests.length,
        'expired': _expiredContests.length,
        'ending_very_soon': getByUrgency('ending_very_soon').length,
        'ending_soon': getByUrgency('ending_soon').length,
        'history': _contestHistory.length,
      };

  /// Clean up
  void dispose() {
    _expirationTimer?.cancel();
  }
}
