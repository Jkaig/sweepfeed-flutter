import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../challenges/models/daily_challenge_model.dart';
import '../../challenges/services/daily_challenge_service.dart';
import '../../../core/utils/logger.dart';

class SavedSweepstakesService with ChangeNotifier {
  SavedSweepstakesService(this._prefs) {
    _loadSavedIds();
  }
  static const String _prefsKey = 'saved_sweepstakes';
  final SharedPreferences _prefs;
  final DailyChallengeService _challengeService = DailyChallengeService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Keep a local cache for faster access
  Set<String> _savedIds = {};

  Future<void> _loadSavedIds() async {
    final savedList = _prefs.getStringList(_prefsKey);
    if (savedList != null) {
      _savedIds = savedList.toSet();
    }
    notifyListeners();
  }

  Set<String> getSavedIds() => _savedIds;

  bool isSaved(String contestId) => _savedIds.contains(contestId);

  Future<void> saveSweepstake(String contestId) async {
    if (_savedIds.add(contestId)) {
      await _persistSavedIds();
      notifyListeners();

      // Update daily challenge progress for saving contest
      await _updateSaveChallengeProgress();
    }
  }

  Future<void> unsaveSweepstake(String contestId) async {
    if (_savedIds.remove(contestId)) {
      await _persistSavedIds();
      notifyListeners();
    }
  }

  Future<String> toggleSaved(String contestId) async {
    if (isSaved(contestId)) {
      await unsaveSweepstake(contestId);
      return 'removed';
    } else {
      await saveSweepstake(contestId);
      return 'saved';
    }
  }

  Future<void> _persistSavedIds() async {
    await _prefs.setStringList(_prefsKey, _savedIds.toList());
  }

  /// Update daily challenge progress for saving contests
  Future<void> _updateSaveChallengeProgress() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _challengeService.updateChallengeProgress(
          userId: user.uid,
          actionType: ChallengeType.saveContest,
        );
        logger.i('Updated daily challenge progress for contest save');
      }
    } catch (e) {
      logger.e('Failed to update daily challenge progress for save', error: e);
    }
  }
}
