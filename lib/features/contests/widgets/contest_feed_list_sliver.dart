import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../subscription/models/subscription_tiers.dart';

import '../providers/contest_feed_provider.dart';
import 'contest_feed_skeleton.dart';
import 'entry_limit_reached_card.dart';
import 'feed_upgrade_card.dart';
import 'unified_contest_card.dart';

/// Sliver version of ContestFeedList for use in CustomScrollView
class ContestFeedListSliver extends ConsumerWidget {
  const ContestFeedListSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestsAsync = ref.watch(contestFeedProvider);
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final tierService = ref.watch(tierManagementServiceProvider);
    
    // Get view limit logic
    final currentTier = subscriptionService.currentTier;
    final viewLimit = currentTier.dailyContestViewLimit;
    final entryLimit = currentTier.dailyEntryLimit;
    
    // Check if entry limit is reached (for free users)
    final isEntryLimitReached = entryLimit != null && 
        tierService.todayEntriesCount >= entryLimit;
    
    final isTablet = ResponsiveHelper.isTablet(context);
    final columns = ResponsiveHelper.getGridColumns(context);
    final horizontalPadding = ResponsiveHelper.getHorizontalPadding(context);

    return contestsAsync.when(
      data: (contests) {
        if (contests.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: EmptyStateWidget(
                icon: Icons.celebration,
                title: 'No Contests Found',
                message: 'Try adjusting your filters or check back later!',
                useDustBunny: true,
                dustBunnyImage: 'assets/images/dustbunnies/dustbunny_sad.png',
              ),
            ),
          );
        }

        // Calculate display limits
        final rawCount = contests.length;
        final isLimited = viewLimit != null && rawCount >= viewLimit;
        final displayCount = isLimited ? viewLimit : rawCount;
        
        // Add entry limit card if reached (show after first few contests so they can see what's popular)
        final showEntryLimitCard = isEntryLimitReached && currentTier == SubscriptionTier.free;
        final entryLimitCardIndex = showEntryLimitCard ? 3 : -1; // Show after 3 contests
        final totalItemCount = isLimited 
            ? displayCount + 1 + (showEntryLimitCard ? 1 : 0)
            : rawCount + (showEntryLimitCard ? 1 : 0);
        
        // Helper to get actual contest index accounting for entry limit card
        int getContestIndex(int displayIndex) {
          if (!showEntryLimitCard) return displayIndex;
          if (displayIndex < entryLimitCardIndex) return displayIndex;
          if (displayIndex == entryLimitCardIndex) return -1; // Entry limit card position
          return displayIndex - 1; // Adjust for entry limit card
        }

        // Grid Layout (Tablet/Desktop)
        if (isTablet && columns > 1) {
          return SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Show Entry Limit Card at specific index
                  if (showEntryLimitCard && index == entryLimitCardIndex) {
                    return EntryLimitReachedCard(
                      onUpgradePressed: () {
                        Navigator.pushNamed(context, '/subscription');
                      },
                    );
                  }
                  
                  // Get actual contest index
                  final contestIndex = getContestIndex(index);
                  
                  // Show Upgrade Card as the last item if limited
                  if (isLimited && contestIndex == displayCount) {
                    return FeedUpgradeCard(
                      onUpgradePressed: () {
                        Navigator.pushNamed(context, '/subscription');
                      },
                    );
                  }
                  
                  // Skip if invalid index
                  if (contestIndex < 0 || contestIndex >= contests.length) {
                    return const SizedBox.shrink();
                  }
                  
                  final contest = contests[contestIndex];
                  return UnifiedContestCard(style: CardStyle.detailed,
                    key: ValueKey('contest_${contest.id}'),
                    contest: contest,
                  );
                },
                childCount: totalItemCount,
              ),
            ),
          );
        }

        // List Layout (Mobile)
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Show Entry Limit Card at specific index
                if (showEntryLimitCard && index == entryLimitCardIndex) {
                  return EntryLimitReachedCard(
                    onUpgradePressed: () {
                      Navigator.pushNamed(context, '/subscription');
                    },
                  );
                }
                
                // Get actual contest index
                final contestIndex = getContestIndex(index);
                
                // Show Upgrade Card as the last item if limited
                if (isLimited && contestIndex == displayCount) {
                  return FeedUpgradeCard(
                    onUpgradePressed: () {
                      Navigator.pushNamed(context, '/subscription');
                    },
                  );
                }
                
                // Skip if invalid index
                if (contestIndex < 0 || contestIndex >= contests.length) {
                  return const SizedBox.shrink();
                }

                final contest = contests[contestIndex];
                return Padding(
                  key: ValueKey('contest_${contest.id}'),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: UnifiedContestCard(style: CardStyle.detailed,contest: contest),
                );
              },
              childCount: totalItemCount,
            ),
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: isTablet && columns > 1
              ? const ContestGridSkeleton()
              : const ContestFeedSkeleton(itemCount: 3),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: EmptyStateWidget(
            icon: Icons.wifi_off,
            title: 'Connection Error',
            message: 'Could not load contests.',
            actionText: 'Retry',
            onAction: () => ref.refresh(contestFeedProvider),
          ),
        ),
      ),
    );
  }
}
