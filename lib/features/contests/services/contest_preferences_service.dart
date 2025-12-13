import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/contest.dart';
import '../../../core/services/user_preferences_service.dart';

class ContestPreferencesService with ChangeNotifier {
  ContestPreferencesService(this._prefs, this._userPreferencesService) {
    _loadPreferences();
  }
  static const String _savedForLaterKey = 'saved_for_later_contests';
  static const String _hiddenContestsKey = 'hidden_contests';
  final SharedPreferences _prefs;
  final UserPreferencesService _userPreferencesService;

  Set<String> _savedForLaterIds = {};
  Set<String> _hiddenIds = {};

  Future<void> _loadPreferences() async {
    final savedForLaterList = _prefs.getStringList(_savedForLaterKey);
    if (savedForLaterList != null) {
      _savedForLaterIds = savedForLaterList.toSet();
    }

    final hiddenList = _prefs.getStringList(_hiddenContestsKey);
    if (hiddenList != null) {
      _hiddenIds = hiddenList.toSet();
    }

    notifyListeners();
  }

  bool isSavedForLater(String contestId) =>
      _savedForLaterIds.contains(contestId);

  bool isHidden(String contestId) => _hiddenIds.contains(contestId);

  Set<String> getSavedForLaterIds() => _savedForLaterIds;

  Set<String> getHiddenIds() => _hiddenIds;

  Future<void> saveForLater(String contestId) async {
    if (_savedForLaterIds.add(contestId)) {
      await _prefs.setStringList(_savedForLaterKey, _savedForLaterIds.toList());
      notifyListeners();
    }
  }

  Future<void> removeFromSavedForLater(String contestId) async {
    if (_savedForLaterIds.remove(contestId)) {
      await _prefs.setStringList(_savedForLaterKey, _savedForLaterIds.toList());
      notifyListeners();
    }
  }

  Future<void> toggleSavedForLater(String contestId) async {
    if (isSavedForLater(contestId)) {
      await removeFromSavedForLater(contestId);
    } else {
      await saveForLater(contestId);
    }
  }

  Future<void> hideContest(Contest contest) async {
    if (_hiddenIds.add(contest.id)) {
      await _prefs.setStringList(_hiddenContestsKey, _hiddenIds.toList());
      await _userPreferencesService.trackNegativeInteraction(
          category: contest.category, sponsor: contest.sponsor,);
      notifyListeners();
    }
  }

  Future<void> unhideContest(String contestId) async {
    if (_hiddenIds.remove(contestId)) {
      await _prefs.setStringList(_hiddenContestsKey, _hiddenIds.toList());
      notifyListeners();
    }
  }

  Future<void> toggleHidden(String contestId) async {
    if (isHidden(contestId)) {
      await unhideContest(contestId);
    } else {
      // Just add to hidden list - hideContest requires Contest object
      if (_hiddenIds.add(contestId)) {
        await _prefs.setStringList(_hiddenContestsKey, _hiddenIds.toList());
        notifyListeners();
      }
    }
  }

  Future<void> clearAllHidden() async {
    _hiddenIds.clear();
    await _prefs.setStringList(_hiddenContestsKey, []);
    notifyListeners();
  }
}
