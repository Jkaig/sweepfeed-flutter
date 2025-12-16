import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/providers/providers.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/glassmorphic_container.dart';
import 'unified_contest_card.dart';

class PopularContestsList extends ConsumerWidget {
  const PopularContestsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularContests = ref.watch(popularContestsProvider);

    return popularContests.when(
      data: (contests) {
        if (contests.isEmpty) {
          return SizedBox(
            height: 200,
            child: GlassmorphicContainer(
              borderRadius: 16.0,
              blur: 10,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.5),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              child: const EmptyStateWidget(
                icon: Icons.trending_up,
                title: 'No Popular Contests Yet',
                message: 'Check back soon for trending contests!',
                useDustBunny: true,
                dustBunnyImage: 'assets/images/dustbunnies/dustbunny_icon.png',
              ),
            ),
          );
        }

        return SizedBox(
          height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: contests.length,
            itemBuilder: (context, index) {
              final contest = contests[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16 : 0,
                  right: 16,
                ),
                child: UnifiedContestCard(style: CardStyle.trending, contest: contest),
                            );
                          },
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
