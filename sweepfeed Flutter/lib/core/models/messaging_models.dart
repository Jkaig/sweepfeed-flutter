import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  Chat({
    required this.id,
    required this.userIds,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });
  final String id;
  final List<String> userIds;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;
}

class Message {
  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });
  final String id;
  final String senderId;
  final String text;
  final Timestamp timestamp;
}
