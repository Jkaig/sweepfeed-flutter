import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/contest.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../core/widgets/confetti_overlay.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../checklist/providers/checklist_provider.dart';
import '../screens/contest_detail_screen.dart';
import 'interactive_daily_checklist_item.dart';

/// A widget that displays the user's daily checklist of contests.
class DailyChecklist extends ConsumerWidget {
  /// Creates a [DailyChecklist].
  const DailyChecklist({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistState = ref.watch(checklistProvider);

    if (checklistState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: LoadingIndicator(),
        ),
      );
    }

    final visibleItems = checklistState.contests
        .where((c) => !checklistState.hiddenItems.contains(c.id))
        .toList();

    if (visibleItems.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.check_circle_outline,
        title: 'All Caught Up!',
        message:
            'No checklist items for today.\nComplete daily tasks to earn bonus entries.',
        useDustBunny: true,
        dustBunnyImage: 'assets/images/dustbunnies/dustbunny_happy.png',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: visibleItems.length,
      itemBuilder: (context, index) {
        final contest = visibleItems[index];
        return Consumer(
          builder: (context, ref, child) {
            final isCompleted = ref.watch(
              checklistProvider.select(
                (state) => state.completionStatus[contest.id] ?? false,
              ),
            );
            return InteractiveDailyChecklistItem(
              contest: contest,
              isCompleted: isCompleted,
                onToggleComplete: (contestId) {
                  if (!isCompleted) {
                    ref.read(confettiProvider).play(); // Trigger confetti on completion
                  }
                  ref.read(checklistProvider.notifier).toggleComplete(contestId);
                },
              onHide: (contestId) =>
                  ref.read(checklistProvider.notifier).hideItem(contestId),
              onViewDetails: (selectedContest) {
                final contest = selectedContest as Contest?;
                if (contest != null) {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    PageTransitions.sharedAxisTransition(
                      page: ContestDetailScreen(contestId: contest.id),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
