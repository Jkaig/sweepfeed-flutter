import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweepfeed/core/models/filter_set_model.dart';

import '../../../core/providers/providers.dart';
import '../../../core/widgets/loading_indicator.dart';
import 'create_edit_filter_screen.dart';

class FilterManagementScreen extends ConsumerWidget {
  const FilterManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedFilters = ref.watch(savedFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Filters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add New Filter',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateEditFilterScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: savedFilters.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (filters) {
          if (filters.isEmpty) {
            return const Center(
              child: Text('You have no saved filters.'),
            );
          }
          return ListView.builder(
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filter = filters[index];
              return ListTile(
                title: Text(filter.name),
                subtitle: Text('Sort by: ${filter.sortBy ?? 'Default'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CreateEditFilterScreen(filter: filter),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                      onPressed: () {
                        final userId =
                            ref.read(firebaseAuthProvider).currentUser?.uid;
                        if (userId != null) {
                          ref
                              .read(profileServiceProvider)
                              .deleteFilterSet(userId, filter.id);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
