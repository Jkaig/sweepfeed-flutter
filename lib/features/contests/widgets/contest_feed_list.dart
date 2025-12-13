import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../providers/contest_feed_provider.dart';
import 'contest_feed_skeleton.dart';
import 'unified_contest_card.dart';

class ContestFeedList extends ConsumerWidget {
  const ContestFeedList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestsAsync = ref.watch(contestFeedProvider);
    final isTablet = ResponsiveHelper.isTablet(context);
    final columns = ResponsiveHelper.getGridColumns(context);

    return contestsAsync.when(
      data: (contests) {
        if (contests.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.celebration,
            title: 'No Contests Available',
            message: 'New contests are added daily.\nCheck back soon!',
          );
        }

        // Use grid layout on tablets/desktop, list on phones
        if (isTablet && columns > 1) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, // Adjust based on card design
            ),
            padding: EdgeInsets.all(
              ResponsiveHelper.getHorizontalPadding(context),
            ),
            itemCount: contests.length,
            itemBuilder: (context, index) {
              final contest = contests[index];
              return UnifiedContestCard(style: CardStyle.detailed, contest: contest);
            },
          );
        }

        // List layout for phones
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.getHorizontalPadding(context),
          ),
          itemCount: contests.length,
          cacheExtent: 500, // Optimize scrolling performance
          itemBuilder: (context, index) {
            final contest = contests[index];
            return Padding(
              key: ValueKey('contest_${contest.id}'),
              padding: const EdgeInsets.only(bottom: 16),
              child: UnifiedContestCard(style: CardStyle.detailed, contest: contest),
            );
          },
        );
      },
      loading: () {
        if (isTablet && columns > 1) {
          return ContestGridSkeleton(
            crossAxisCount: columns,
          );
        }
        return const ContestFeedSkeleton();
      },
      error: (error, stack) => EmptyStateWidget(
        icon: Icons.wifi_off,
        title: 'Connection Error',
        message:
            'Could not load contests.\nPlease check your internet connection.',
        actionText: 'Retry',
        onAction: () => ref.refresh(contestFeedProvider),
      ),
    );
  }
}
