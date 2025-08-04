import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String sweepstakeId;
  final String text;
  final Timestamp timestamp; // Changed to Timestamp to align with Firestore
  final String? parentCommentId;
  final String? userName; // New field for user's display name

  Comment({
    required this.id,
    required this.userId,
    required this.sweepstakeId,
    required this.text,
    required this.timestamp,
    this.parentCommentId,
    this.userName, // Added to constructor
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id, // Use document ID as the comment ID
      userId: data['userId'] as String? ?? '',
      sweepstakeId: data['sweepstakeId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      // Ensure timestamp is handled correctly, defaulting if null.
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      parentCommentId: data['parentCommentId'] as String?,
      userName: data['userName'] as String?, // Fetch userName
    );
  }

  // Optional: Method to convert Comment instance to JSON for posting
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'sweepstakeId': sweepstakeId,
      'text': text,
      'timestamp': timestamp, // Store as Timestamp
      'parentCommentId': parentCommentId,
      'userName': userName, // Include userName
    };
  }
}