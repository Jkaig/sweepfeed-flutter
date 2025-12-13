import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/contest.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/streak_service.dart';
import '../services/checklist_service.dart';

class ChecklistState {
  ChecklistState({
    this.contests = const [],
    this.completionStatus = const {},
    this.hiddenItems = const {},
    this.isLoading = true,
  });
  final List<Contest> contests;
  final Map<String, bool> completionStatus;
  final Set<String> hiddenItems;
  final bool isLoading;

  ChecklistState copyWith({
    List<Contest>? contests,
    Map<String, bool>? completionStatus,
    Set<String>? hiddenItems,
    bool? isLoading,
  }) =>
      ChecklistState(
        contests: contests ?? this.contests,
        completionStatus: completionStatus ?? this.completionStatus,
        hiddenItems: hiddenItems ?? this.hiddenItems,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ChecklistNotifier extends StateNotifier<ChecklistState> {
  ChecklistNotifier(this._ref) : super(ChecklistState()) {
    _loadChecklistData();
  }
  final Ref _ref;
  final ChecklistService _checklistService = ChecklistService();
  late final StreakService _streakService = StreakService(
    _ref.read(dustBunniesServiceProvider),
  );

  Future<void> _loadChecklistData() async {
    final userId = _ref.read(firebaseServiceProvider).currentUser?.uid;
    if (userId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final contests = await _ref
          .read(contestServiceProvider)
          .getDailyChecklistContests()
          .first;
      final completionStatus =
          await _checklistService.getCompletionStatus(userId, DateTime.now());
      final hiddenItems =
          await _checklistService.getHiddenItems(userId, DateTime.now());

      state = state.copyWith(
        contests: contests,
        completionStatus: completionStatus,
        hiddenItems: hiddenItems,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggleComplete(String contestId) async {
    final userId = _ref.read(firebaseServiceProvider).currentUser?.uid;
    if (userId == null) return;

    final currentStatus = state.completionStatus[contestId] ?? false;
    final newStatus = !currentStatus;

    final newCompletionStatus = Map<String, bool>.from(state.completionStatus);
    newCompletionStatus[contestId] = newStatus;
    state = state.copyWith(completionStatus: newCompletionStatus);

    await _checklistService.updateCompletionStatus(
      userId,
      contestId,
      newStatus,
      DateTime.now(),
    );

    if (newStatus) {
      // Award DustBunnies for completing a checklist item
      await _ref.read(dustBunniesServiceProvider).awardDustBunnies(
        userId: userId,
        action: 'complete_checklist',
      );
      
      await _streakService.checkIn(userId);
    }
  }

  Future<void> hideItem(String contestId) async {
    final userId = _ref.read(firebaseServiceProvider).currentUser?.uid;
    if (userId == null) return;

    final newHiddenItems = Set<String>.from(state.hiddenItems)..add(contestId);
    state = state.copyWith(hiddenItems: newHiddenItems);

    await _checklistService.hideItem(userId, contestId, DateTime.now());
  }
}

final checklistProvider =
    StateNotifierProvider<ChecklistNotifier, ChecklistState>(
        ChecklistNotifier.new,);
