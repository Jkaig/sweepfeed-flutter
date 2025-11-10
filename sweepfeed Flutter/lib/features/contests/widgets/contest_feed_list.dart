import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../providers/contest_feed_provider.dart';
import 'contest_card.dart';

class ContestFeedList extends ConsumerWidget {
  const ContestFeedList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestsAsync = ref.watch(contestFeedProvider);

    return contestsAsync.when(
      data: (contests) {
        if (contests.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.celebration,
            title: 'No Sweepstakes Available',
            message: 'New contests are added daily.\nCheck back soon!',
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contests.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ContestCard(contest: contests[index]),
          ),
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => EmptyStateWidget(
        icon: Icons.wifi_off,
        title: 'Connection Error',
        message:
            'Could not load sweepstakes.\nPlease check your internet connection.',
        actionText: 'Retry',
        onAction: () => ref.refresh(contestFeedProvider),
      ),
    );
  }
}
