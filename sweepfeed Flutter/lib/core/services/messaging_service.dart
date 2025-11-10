import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/messaging_models.dart';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // Get or create a chat between the current user and another user
  Future<String> getOrCreateChat(String otherUserId) async {
    if (_currentUserId == null) throw Exception('User not logged in');

    final userIds = [_currentUserId, otherUserId]..sort();
    final chatId = userIds.join('_');

    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        'userIds': userIds,
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  // Send a message
  Future<void> sendMessage(String chatId, String text) async {
    if (_currentUserId == null || text.trim().isEmpty) return;

    final messageRef =
        _firestore.collection('chats').doc(chatId).collection('messages').doc();
    final chatRef = _firestore.collection('chats').doc(chatId);

    final message = Message(
      id: messageRef.id,
      senderId: _currentUserId!,
      text: text,
      timestamp: Timestamp.now(),
    );

    // Use a batch write for atomicity
    final batch = _firestore.batch();
    batch.set(messageRef, {
      'senderId': message.senderId,
      'text': message.text,
      'timestamp': message.timestamp,
    });
    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageTimestamp': message.timestamp,
    });

    await batch.commit();
  }

  // Get a stream of messages for a chat
  Stream<QuerySnapshot> getMessages(String chatId) => _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots();

  // Get a stream of the user's chats
  Stream<QuerySnapshot> getChats() {
    if (_currentUserId == null) return const Stream.empty();
    return _firestore
        .collection('chats')
        .where('userIds', arrayContains: _currentUserId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }
}
