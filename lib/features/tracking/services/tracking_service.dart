import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/contest.dart';

class TrackingService extends ChangeNotifier {
  TrackingService(this._prefs) {
    _loadTrackedEntries();
  }
  static const String _entriesKey = 'tracked_entries';
  final SharedPreferences _prefs;
  final Map<String, DateTime> _trackedEntries = {};

  Map<String, DateTime> get trackedEntries => Map.unmodifiable(_trackedEntries);

  bool isTracked(String contestsId) =>
      _trackedEntries.containsKey(contestsId);

  Future<void> trackEntry(Contest contest) async {
    _trackedEntries[contest.id] = DateTime.now();
    await _saveTrackedEntries();
    notifyListeners();
  }

  Future<void> untrackEntry(String contestsId) async {
    _trackedEntries.remove(contestsId);
    await _saveTrackedEntries();
    notifyListeners();
  }

  Future<void> _loadTrackedEntries() async {
    final entriesJson = _prefs.getString(_entriesKey);
    if (entriesJson != null) {
      final Map<String, dynamic> entries = json.decode(entriesJson);
      _trackedEntries.clear();
      entries.forEach((key, value) {
        _trackedEntries[key] = DateTime.parse(value);
      });
      notifyListeners();
    }
  }

  Future<void> _saveTrackedEntries() async {
    final entriesJson = json.encode(
      _trackedEntries
          .map((key, value) => MapEntry(key, value.toIso8601String())),
    );
    await _prefs.setString(_entriesKey, entriesJson);
  }

  List<Contest> filterTrackedSweepstakes(List<Contest> contests) =>
      contests.where((s) => isTracked(s.id)).toList();

  List<Contest> getDailyEntries(List<Contest> contests) =>
      contests.where((s) {
        if (s.isDailyEntry != true || !isTracked(s.id)) return false;
        final lastEntry = _trackedEntries[s.id]!;
        return DateTime.now().difference(lastEntry).inHours >= 24;
      }).toList();

  List<Contest> getEndingSoon(List<Contest> contests) {
    final now = DateTime.now();
    return contests.where((s) {
      if (!isTracked(s.id)) return false;
      final timeLeft = s.endDate.difference(now);
      return timeLeft.inHours <= 48 && timeLeft.inHours > 0;
    }).toList();
  }
}
