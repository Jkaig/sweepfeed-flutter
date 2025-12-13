import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/block_service.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: blockedUsersAsync.when(
        data: (blockedUsers) {
          if (blockedUsers.isEmpty) {
            return const Center(
              child: Text("You don't have any blocked users."),
            );
          }
          return ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return ListTile(
                title: Text(user),
                trailing: ElevatedButton(
                  onPressed: () {
                    ref.read(blockServiceProvider).unblockUser(user);
                    ref.refresh(blockedUsersProvider);
                  },
                  child: const Text('Unblock'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(
          child: Text('Error loading blocked users'),
        ),
      ),
    );
  }
}

final blockedUsersProvider = FutureProvider<List<String>>((ref) async {
  final blockService = ref.watch(blockServiceProvider);
  return blockService.getBlockedUsers();
});
