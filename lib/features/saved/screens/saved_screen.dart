import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../contests/widgets/unified_contest_card.dart';
import '../services/saved_contests_service.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedContestsService = ref.watch(savedContestsServiceProvider);
    final savedContests = savedContestsService.savedContests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Contests'),
      ),
      body: savedContests.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: AppColors.primaryMedium,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No saved contests',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the bookmark icon to save a contest for later.',
                    style: TextStyle(color: AppColors.primaryMedium),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedContests.length,
              itemBuilder: (context, index) {
                final contest = savedContests[index];
                return UnifiedContestCard(
                  contest: contest,
                  style: CardStyle.detailed,
                  onSave: () {
                    savedContestsService.unsaveContest(contest.id);
                  },
                  isSaved: true,
                );
              },
            ),
    );
  }
}