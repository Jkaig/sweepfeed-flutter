import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/dust_bunnies_service.dart' show LeaderboardEntry;
import '../../../core/providers/providers.dart';
import '../../../core/widgets/loading_indicator.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: leaderboardAsync.when(
        data: (leaderboard) {
          if (leaderboard.isEmpty) {
            return const Center(
              child: Text('The leaderboard is empty.'),
            );
          }
          return ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              return ListTile(
                leading: Text(
                  '#${entry.rank}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                title: Text(entry.displayName),
                subtitle: Text('Level ${entry.level}'),
                trailing: Text(
                  '${entry.totalDB} DB',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(
          child: Text('Error loading leaderboard'),
        ),
      ),
    );
  }
}

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final dustBunniesService = ref.watch(dustBunniesServiceProvider);
  return dustBunniesService.getLeaderboard();
});