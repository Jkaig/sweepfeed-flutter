import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';

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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading contest history. Please try again.'),
            );
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return const Center(
              child: Text("You haven't entered any sweepstakes yet."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              final entryDate = entry['entryDate'] as DateTime;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(entry['contestName'] ?? 'No Title'),
                  subtitle: Text(
                      'Entered on: ${DateFormat.yMMMd().format(entryDate)}'),
                  trailing: Text(entry['prize'] ?? ''),
                ),
              );
            },
          );
        },
      );
}
