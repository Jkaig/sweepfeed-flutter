import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../subscription/models/subscription_tiers.dart';

import '../providers/optimized_contest_feed_provider.dart';
import 'contest_feed_skeleton.dart';
import 'entry_limit_reached_card.dart';
import 'feed_upgrade_card.dart';
import 'unified_contest_card.dart';

/// Optimized sliver feed with infinite scroll pagination
/// Handles hundreds of thousands of contests efficiently
class OptimizedContestFeedListSliver extends ConsumerStatefulWidget {
  const OptimizedContestFeedListSliver({super.key});

  @override
  ConsumerState<OptimizedContestFeedListSliver> createState() =>
      _OptimizedContestFeedListSliverState();
}

class _OptimizedContestFeedListSliverState
    extends ConsumerState<OptimizedContestFeedListSliver> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when user scrolls near bottom (80% of scroll extent)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    final feedState = ref.read(optimizedContestFeedProvider);
    if (!feedState.hasMore || feedState.isLoading) return;

    setState(() => _isLoadingMore = true);
    await ref.read(optimizedContestFeedProvider.notifier).fetchNextPage();
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(optimizedContestFeedProvider);
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final tierService = ref.watch(tierManagementServiceProvider);

    // Get view limit logic
    final currentTier = subscriptionService.currentTier;
    final viewLimit = currentTier.dailyContestViewLimit;
    final entryLimit = currentTier.dailyEntryLimit;

    // Check if entry limit is reached (for free users)
    final isEntryLimitReached =
        entryLimit != null && tierService.todayEntriesCount >= entryLimit;

    final isTablet = ResponsiveHelper.isTablet(context);
    final columns = ResponsiveHelper.getGridColumns(context);
    final horizontalPadding = ResponsiveHelper.getHorizontalPadding(context);

    // Show error state
    if (feedState.error != null && feedState.contests.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: EmptyStateWidget(
            icon: Icons.wifi_off,
            title: 'Connection Error',
            message: feedState.error!,
            actionText: 'Retry',
            onAction: () {
              ref.read(optimizedContestFeedProvider.notifier).refresh();
            },
          ),
        ),
      );
    }

    // Show loading state (initial load)
    if (feedState.isLoading && feedState.contests.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: isTablet && columns > 1
              ? const ContestGridSkeleton()
              : const ContestFeedSkeleton(itemCount: 3),
        ),
      );
    }

    // Show empty state
    if (feedState.contests.isEmpty && !feedState.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: EmptyStateWidget(
            icon: Icons.celebration,
            title: 'No Contests Found',
            message: 'Try adjusting your filters or check back later!',
          ),
        ),
      );
    }

    // Calculate display limits
    final rawCount = feedState.contests.length;
    final isLimited = viewLimit != null && rawCount >= viewLimit;
    final displayCount = isLimited ? viewLimit : rawCount;

    // Add entry limit card if reached
    final showEntryLimitCard =
        isEntryLimitReached && currentTier == SubscriptionTier.free;
    final entryLimitCardIndex = showEntryLimitCard ? 3 : -1;
    final totalItemCount = isLimited
        ? displayCount + 1 + (showEntryLimitCard ? 1 : 0) + (feedState.hasMore ? 1 : 0)
        : rawCount + (showEntryLimitCard ? 1 : 0) + (feedState.hasMore ? 1 : 0);

    // Helper to get actual contest index
    int getContestIndex(int displayIndex) {
      if (!showEntryLimitCard) return displayIndex;
      if (displayIndex < entryLimitCardIndex) return displayIndex;
      if (displayIndex == entryLimitCardIndex) return -1; // Entry limit card
      return displayIndex - 1;
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
              // Show Entry Limit Card
              if (showEntryLimitCard && index == entryLimitCardIndex) {
                return EntryLimitReachedCard(
                  onUpgradePressed: () {
                    Navigator.pushNamed(context, '/subscription');
                  },
                );
              }

              final contestIndex = getContestIndex(index);

              // Show Upgrade Card
              if (isLimited && contestIndex == displayCount) {
                return FeedUpgradeCard(
                  onUpgradePressed: () {
                    Navigator.pushNamed(context, '/subscription');
                  },
                );
              }

              // Show loading indicator at bottom
              if (index == totalItemCount - 1 && feedState.hasMore) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Skip if invalid index
              if (contestIndex < 0 || contestIndex >= feedState.contests.length) {
                return const SizedBox.shrink();
              }

              final contest = feedState.contests[contestIndex];
              return UnifiedContestCard(
                style: CardStyle.detailed,
                key: ValueKey('contest_${contest.id}_$contestIndex'),
                contest: contest,
              );
            },
            childCount: totalItemCount,
          ),
        ),
      );
    }

    // List Layout (Mobile) with infinite scroll
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Show Entry Limit Card
            if (showEntryLimitCard && index == entryLimitCardIndex) {
              return EntryLimitReachedCard(
                onUpgradePressed: () {
                  Navigator.pushNamed(context, '/subscription');
                },
              );
            }

            final contestIndex = getContestIndex(index);

            // Show Upgrade Card
            if (isLimited && contestIndex == displayCount) {
              return FeedUpgradeCard(
                onUpgradePressed: () {
                  Navigator.pushNamed(context, '/subscription');
                },
              );
            }

            // Show loading indicator at bottom
            if (index == totalItemCount - 1 && feedState.hasMore) {
              // Trigger load more
              WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Skip if invalid index
            if (contestIndex < 0 || contestIndex >= feedState.contests.length) {
              return const SizedBox.shrink();
            }

            final contest = feedState.contests[contestIndex];
            return Padding(
              key: ValueKey('contest_${contest.id}_$contestIndex'),
              padding: const EdgeInsets.only(bottom: 16),
              child: UnifiedContestCard(
                style: CardStyle.detailed,
                contest: contest,
              ),
            );
          },
          childCount: totalItemCount,
        ),
      ),
    );
  }
}
