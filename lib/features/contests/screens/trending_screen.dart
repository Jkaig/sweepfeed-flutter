import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_helper.dart';
import '../providers/contest_providers.dart';
import '../widgets/contest_feed_skeleton.dart';
import '../widgets/unified_contest_card.dart';

class TrendingScreen extends ConsumerWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Assuming we have a provider for trending contests, or we filter the main feed
    // For now, reusing the main feed provider but we might want a specific 'trending' sort
    final contestFeedState = ref.watch(contestFeedProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Trending Contests'),
        leading: const BackButton(color: AppColors.textWhite),
      ),
      body: CustomScrollView(
        slivers: [
          if (contestFeedState.isLoading && contestFeedState.contests.isEmpty)
             const SliverPadding(
               padding: EdgeInsets.all(16),
               sliver: ContestFeedSkeleton(),
             )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getHorizontalPadding(context),
                vertical: 16,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final contest = contestFeedState.contests[index];
                    return UnifiedContestCard(style: CardStyle.detailed, contest: contest);
                  },
                  childCount: contestFeedState.contests.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

