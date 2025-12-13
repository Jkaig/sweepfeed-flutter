import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../ads/widgets/native_ad_card.dart';
import '../widgets/unified_contest_card.dart';

class LatestContestsScreen extends ConsumerWidget {
  const LatestContestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestContests = ref.watch(latestContestsProvider);

    return latestContests.when(
      data: (contests) => ListView.builder(
        itemCount:
            contests.length + (contests.length ~/ 5), // Add space for ads
        itemBuilder: (context, index) {
          if (index % 5 == 4) {
            return const NativeAdCard();
          }
          final contestIndex = index - (index ~/ 5);
          return UnifiedContestCard(style: CardStyle.detailed, contest: contests[contestIndex]);
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          const Center(child: Text('Could not load contests')),
    );
  }
}
