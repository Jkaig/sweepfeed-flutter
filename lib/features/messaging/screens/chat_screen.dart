import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';

final messagesProvider = StreamProvider.family<QuerySnapshot, String>(
    (ref, chatId) => ref.watch(messagingServiceProvider).getMessages(chatId),);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.chatId, required this.otherUser, super.key});
  final String chatId;
  final UserProfile otherUser;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUser.name ?? 'Chat'),
        backgroundColor: AppColors.primaryMedium,
      ),
      backgroundColor: AppColors.primaryDark,
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: LoadingIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              data: (snapshot) => ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(8),
                itemCount: snapshot.docs.length,
                itemBuilder: (context, index) {
                  final message = snapshot.docs[index];
                  final isMe = message['senderId'] == currentUserId;
                  return _buildMessageBubble(message, isMe);
                },
              ),
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(QueryDocumentSnapshot message, bool isMe) =>
      Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: isMe ? AppColors.accent : AppColors.primaryMedium,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message['text'],
            style:
                TextStyle(color: isMe ? AppColors.primaryDark : Colors.white),
          ),
        ),
      );

  Widget _buildMessageComposer() => Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.primaryMedium,
          border: Border(top: BorderSide(color: AppColors.primaryLight)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: const TextStyle(color: AppColors.textLight),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.primaryDark,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.accent),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      );

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (userId == null) return;

    final referralLink =
        await ref.read(referralServiceProvider).generateReferralLink(userId);
    final messageWithReferral = '$text\n\nMy referral link: $referralLink';

    await ref
        .read(messagingServiceProvider)
        .sendMessage(widget.chatId, messageWithReferral);

    _messageController.clear();
  }
}
