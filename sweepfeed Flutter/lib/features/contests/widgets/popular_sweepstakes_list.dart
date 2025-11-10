import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/providers/providers.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'popular_sweepstake_card.dart';

class PopularSweepstakesList extends ConsumerStatefulWidget {
  const PopularSweepstakesList({super.key});

  @override
  ConsumerState<PopularSweepstakesList> createState() =>
      _PopularSweepstakesListState();
}

class _PopularSweepstakesListState
    extends ConsumerState<PopularSweepstakesList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final popularContests = ref.watch(popularContestsProvider);

    return popularContests.when(
      data: (contests) {
        if (contests.isEmpty) {
          return const SizedBox(
            height: 200,
            child: EmptyStateWidget(
              icon: Icons.trending_up,
              title: 'No Popular Contests Yet',
              message: 'Check back soon for trending sweepstakes!',
            ),
          );
        }

        return SizedBox(
          height: 200,
          child: AnimationLimiter(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: contests.length,
              itemBuilder: (context, index) =>
                  AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: AnimatedBuilder(
                          animation: _scrollController,
                          builder: (context, child) {
                            final cardPosition =
                                index * MediaQuery.of(context).size.width * 0.8;
                            final parallaxOffset =
                                (_scrollController.position.pixels -
                                        cardPosition) *
                                    0.1;
                            return PopularSweepstakeCard(
                              contest: contests[index],
                              parallaxOffset: parallaxOffset,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const _LoadingShimmer(),
      error: (error, stack) => SizedBox(
        height: 200,
        child: EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Oops!',
          message: 'Could not load popular contests.\nTap to try again.',
          actionText: 'Retry',
          onAction: () => ref.refresh(popularContestsProvider),
        ),
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 200,
        child: Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[700]!,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      );
}
