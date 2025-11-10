import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/widgets/loading_indicator.dart';

class Filter {
  Filter({required this.id, required this.name, this.sortBy});

  factory Filter.fromString(String filterName) => Filter(
        id: filterName.toLowerCase().replaceAll(' ', '_'),
        name: filterName,
        sortBy: 'Default',
      );
  final String id;
  final String name;
  final String? sortBy;
}

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
              // TODO: Navigate to a "create/edit filter" screen
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
          final filterObjects = filters.map(Filter.fromString).toList();
          return ListView.builder(
            itemCount: filterObjects.length,
            itemBuilder: (context, index) {
              final filter = filterObjects[index];
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
                        // TODO: Navigate to a "create/edit filter" screen with this filter's data
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
