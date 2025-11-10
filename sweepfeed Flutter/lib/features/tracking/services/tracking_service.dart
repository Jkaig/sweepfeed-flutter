import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/sweepstake.dart';

class TrackingService extends ChangeNotifier {
  TrackingService(this._prefs) {
    _loadTrackedEntries();
  }
  static const String _entriesKey = 'tracked_entries';
  final SharedPreferences _prefs;
  final Map<String, DateTime> _trackedEntries = {};

  Map<String, DateTime> get trackedEntries => Map.unmodifiable(_trackedEntries);

  bool isTracked(String sweepstakesId) =>
      _trackedEntries.containsKey(sweepstakesId);

  Future<void> trackEntry(Sweepstakes sweepstakes) async {
    _trackedEntries[sweepstakes.id] = DateTime.now();
    await _saveTrackedEntries();
    notifyListeners();
  }

  Future<void> untrackEntry(String sweepstakesId) async {
    _trackedEntries.remove(sweepstakesId);
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

  List<Sweepstakes> filterTrackedSweepstakes(List<Sweepstakes> sweepstakes) =>
      sweepstakes.where((s) => isTracked(s.id)).toList();

  List<Sweepstakes> getDailyEntries(List<Sweepstakes> sweepstakes) =>
      sweepstakes.where((s) {
        if (!s.isDailyEntry || !isTracked(s.id)) return false;
        final lastEntry = _trackedEntries[s.id]!;
        return DateTime.now().difference(lastEntry).inHours >= 24;
      }).toList();

  List<Sweepstakes> getEndingSoon(List<Sweepstakes> sweepstakes) {
    final now = DateTime.now();
    return sweepstakes.where((s) {
      if (!isTracked(s.id)) return false;
      final timeLeft = s.endDate!.difference(now);
      return timeLeft.inHours <= 48 && timeLeft.inHours > 0;
    }).toList();
  }
}
