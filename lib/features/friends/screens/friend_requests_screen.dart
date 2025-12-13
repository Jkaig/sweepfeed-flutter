import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../profile/widgets/profile_picture_avatar.dart';
import '../../social/screens/contacts_screen.dart';
import '../../social/screens/friends_screen.dart';

final friendRequestsProvider = StreamProvider<QuerySnapshot>(
    (ref) => ref.watch(friendServiceProvider).getFriendRequests(),);

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(friendRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        backgroundColor: AppColors.primaryMedium,
      ),
      backgroundColor: AppColors.primaryDark,
      body: requestsAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Could not load requests: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people_outline,
                        size: 60,
                        color: AppColors.brandCyan,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Pending Requests',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Connect with friends to share wins,\ncompete on leaderboards, and celebrate together!',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const FriendsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.explore),
                      label: const Text('Discover Friends'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandCyan,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ContactsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Invite Friends'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandCyan,
                        side: const BorderSide(
                          color: AppColors.brandCyan,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
              final request = snapshot.docs[index];
              final fromUserId = request.id;

              return _FriendRequestTile(fromUserId: fromUserId);
            },
          );
        },
      ),
    );
  }
}

class _FriendRequestTile extends ConsumerWidget {
  const _FriendRequestTile({required this.fromUserId});
  final String fromUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileFamilyProvider(fromUserId));

    return userProfileAsync.when(
      loading: () => const ListTile(title: LoadingIndicator(size: 20)),
      error: (err, stack) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return ListTile(
          leading: ProfilePictureAvatar(user: user, radius: 24),
          title: Text(
            user.name ?? 'A user',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 28,
                ),
                onPressed: () async {
                  final result = await ref
                      .read(friendServiceProvider)
                      .acceptFriendRequest(fromUserId);

                  if (result == 'success' && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Accepted friend request from ${user.name ?? "user"}!',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.successGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                onPressed: () {
                  ref
                      .read(friendServiceProvider)
                      .declineFriendRequest(fromUserId);
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textLight),
                onSelected: (value) async {
                  if (value == 'block') {
                    final confirmed = await _showBlockConfirmDialog(
                      context,
                      user.name ?? 'this user',
                    );
                    if (confirmed == true) {
                      final result = await ref
                          .read(friendServiceProvider)
                          .blockUser(fromUserId);
                      if (result == 'success' && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.block,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text('Blocked ${user.name ?? "user"}'),
                              ],
                            ),
                            backgroundColor: AppColors.errorRed,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  } else if (value == 'report') {
                    _showReportDialog(
                      context,
                      ref,
                      fromUserId,
                      user.name ?? 'user',
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block, color: AppColors.errorRed, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Block User',
                          style: TextStyle(color: AppColors.textWhite),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag,
                          color: AppColors.warningOrange,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Report',
                          style: TextStyle(color: AppColors.textWhite),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<bool?> _showBlockConfirmDialog(BuildContext context, String userName) =>
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.block, color: AppColors.errorRed, size: 28),
            SizedBox(width: 12),
            Text('Block User?', style: TextStyle(color: AppColors.textWhite)),
          ],
        ),
        content: Text(
          "Are you sure you want to block $userName? They won't be able to send you friend requests or see your activity.",
          style: const TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );

void _showReportDialog(
  BuildContext context,
  WidgetRef ref,
  String userId,
  String userName,
) {
  var selectedReason = 'spam';
  final detailsController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.flag, color: AppColors.warningOrange, size: 28),
            SizedBox(width: 12),
            Text('Report User', style: TextStyle(color: AppColors.textWhite)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why are you reporting $userName?',
              style: const TextStyle(color: AppColors.textLight, fontSize: 16),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedReason,
              dropdownColor: AppColors.primaryDark,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppColors.primaryLight,
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'spam',
                  child: Text('Spam / Unwanted Requests'),
                ),
                DropdownMenuItem(
                  value: 'harassment',
                  child: Text('Harassment'),
                ),
                DropdownMenuItem(
                  value: 'inappropriate',
                  child: Text('Inappropriate Content'),
                ),
                DropdownMenuItem(value: 'fake', child: Text('Fake Account')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => selectedReason = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: detailsController,
              style: const TextStyle(color: AppColors.textWhite),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Additional details (optional)',
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.primaryLight,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              detailsController.dispose();
              Navigator.pop(context);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await ref.read(friendServiceProvider).reportUser(
                    userId: userId,
                    reason: selectedReason,
                    additionalDetails: detailsController.text.isEmpty
                        ? null
                        : detailsController.text,
                  );

              detailsController.dispose();
              Navigator.pop(context);

              if (result == 'success' && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Report submitted. Thank you for helping keep SweepFeed safe.',
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.successGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningOrange,
              foregroundColor: AppColors.primaryDark,
            ),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    ),
  );
}
