import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/providers.dart';

const _hiddenContestsKey = 'hiddenContests';

class HiddenContestsNotifier extends StateNotifier<List<String>> {
  HiddenContestsNotifier(this._sharedPreferences)
      : super(_sharedPreferences?.getStringList(_hiddenContestsKey) ?? []);

  final SharedPreferences? _sharedPreferences;

  Future<void> hideContest(String contestId) async {
    if (!state.contains(contestId)) {
      state = [...state, contestId];
      await _sharedPreferences?.setStringList(_hiddenContestsKey, state);
    }
  }

  Future<void> unhideContest(String contestId) async {
    if (state.contains(contestId)) {
      state = state.where((id) => id != contestId).toList();
      await _sharedPreferences?.setStringList(_hiddenContestsKey, state);
    }
  }
}

final hiddenContestsProvider =
    StateNotifierProvider<HiddenContestsNotifier, List<String>>((ref) {
  final sharedPreferencesAsync = ref.watch(sharedPreferencesProvider);
  return sharedPreferencesAsync.when(
    data: HiddenContestsNotifier.new,
    loading: () => HiddenContestsNotifier(null),
    error: (error, stack) => HiddenContestsNotifier(null),
  );
});
