import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/contest.dart';

class SavedContestsService extends ChangeNotifier {
  SavedContestsService(this._prefs) {
    _loadSavedContests();
  }
  static const String _savedContestsKey = 'saved_contests';
  final SharedPreferences _prefs;
  final List<Contest> _savedContests = [];

  List<Contest> get savedContests => List.unmodifiable(_savedContests);

  bool isSaved(String contestId) =>
      _savedContests.any((contest) => contest.id == contestId);

  Future<void> saveContest(Contest contest) async {
    if (!isSaved(contest.id)) {
      _savedContests.add(contest);
      await _saveContests();
      notifyListeners();
    }
  }

  Future<void> unsaveContest(String contestId) async {
    _savedContests.removeWhere((contest) => contest.id == contestId);
    await _saveContests();
    notifyListeners();
  }

  Future<void> _loadSavedContests() async {
    final savedContestsJson = _prefs.getStringList(_savedContestsKey);
    if (savedContestsJson != null) {
      _savedContests.clear();
      for (final contestJson in savedContestsJson) {
        _savedContests.add(Contest.fromJson(json.decode(contestJson)));
      }
      notifyListeners();
    }
  }

  Future<void> _saveContests() async {
    final savedContestsJson =
        _savedContests.map((contest) => json.encode(contest.toJson())).toList();
    await _prefs.setStringList(_savedContestsKey, savedContestsJson);
  }
}