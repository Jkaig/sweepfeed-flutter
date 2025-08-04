import 'package:shared_preferences/shared_preferences.dart';


class SavedSweepstakesService {  
  static const String _prefsKey = 'saved_sweepstakes';
  final SharedPreferences _prefs;

  // Keep a local cache for faster access
  Set<String> _savedIds = {};

  SavedSweepstakesService(this._prefs) {
    _loadSavedIds();
  }

  Future<void> _loadSavedIds() async {
    final savedList = _prefs.getStringList(_prefsKey);
    if (savedList != null) {
      _savedIds = savedList.toSet();
    }
  }

  Set<String> getSavedIds() {
    return _savedIds;
  }

  bool isSaved(String contestId) {
    return _savedIds.contains(contestId);
  }

  Future<void> saveSweepstake(String contestId) async {
    if (_savedIds.add(contestId)) {
      await _persistSavedIds();
    }
  }

  Future<void> unsaveSweepstake(String contestId) async {
    if (_savedIds.remove(contestId)) {
      await _persistSavedIds();
    }
  }

  Future<void> toggleSaved(String contestId) async {
    if (isSaved(contestId)) {
      await unsaveSweepstake(contestId);
    } else {
      await saveSweepstake(contestId);
    }
  }

  Future<void> _persistSavedIds() async {
    await _prefs.setStringList(_prefsKey, _savedIds.toList());
  }
}
