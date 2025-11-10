import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../messaging/screens/chat_screen.dart';
import '../../profile/widgets/profile_picture_avatar.dart';

final friendsProvider = StreamProvider<QuerySnapshot>(
    (ref) => ref.watch(friendServiceProvider).getFriends());

class FriendsListScreen extends ConsumerWidget {
  const FriendsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: AppColors.primaryMedium,
      ),
      backgroundColor: AppColors.primaryDark,
      body: friendsAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Could not load friends: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 80,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Friends Yet',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Start connecting with friends to see their favorite contests and compete on the leaderboard!',
                      style:
                          TextStyle(color: AppColors.textLight, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // User can navigate to leaderboard from main menu
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Find Friends'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: snapshot.docs.length,
            itemBuilder: (context, index) {
              final friendId = snapshot.docs[index].id;
              return _FriendTile(friendId: friendId);
            },
          );
        },
      ),
    );
  }
}

class _FriendTile extends ConsumerWidget {
  const _FriendTile({required this.friendId});
  final String friendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileFamilyProvider(friendId));

    return userProfileAsync.when(
      loading: () => const ListTile(title: LoadingIndicator(size: 20)),
      error: (err, stack) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return ListTile(
          leading: ProfilePictureAvatar(user: user, radius: 24),
          title: Text(
            user.name ?? 'Friend',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: ElevatedButton(
            child: const Text('Message'),
            onPressed: () async {
              final chatId = await ref
                  .read(messagingServiceProvider)
                  .getOrCreateChat(friendId);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      ChatScreen(chatId: chatId, otherUser: user),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
