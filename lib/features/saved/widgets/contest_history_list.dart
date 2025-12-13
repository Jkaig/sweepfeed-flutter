import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/skeleton_loader.dart';

class ContestHistoryList extends ConsumerStatefulWidget {
  const ContestHistoryList({super.key});

  @override
  _ContestHistoryListState createState() => _ContestHistoryListState();
}

class _ContestHistoryListState extends ConsumerState<ContestHistoryList> {
  Future<List<Map<String, dynamic>>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  void _loadHistory() {
    final userId = ref.read(firebaseServiceProvider).currentUser?.uid;
    if (userId != null) {
      final profileService = ref.read(profileServiceProvider);
      if (mounted) {
        setState(() {
          _historyFuture =
              profileService.getUserEntriesWithContestDetails(userId);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _historyFuture = Future.value([]);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const ListItemSkeleton(),
            );
          }
          if (snapshot.hasError) {
            return EmptyStateWidget(
              icon: Icons.error_outline,
              title: 'Error Loading History',
              message: 'Could not load your contest history.\nPlease try again.',
              actionText: 'Retry',
              onAction: () {
                setState(_loadHistory);
              },
            );
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history,
              title: 'No Entry History',
              message: "You haven't entered any contests yet.\nStart entering to see your history here!",
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_loadHistory);
              await _historyFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                final entryDate = entry['entryDate'] as DateTime;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: AppColors.primaryMedium,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      entry['contestName'] ?? 'No Title',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textWhite,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Entered on: ${DateFormat.yMMMd().format(entryDate)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    trailing: Text(
                      entry['prize'] ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.brandCyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
}
