import 'package:cloud_firestore/cloud_firestore.dart';

class UserActivity {
  const UserActivity({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata = const {},
  });

  factory UserActivity.fromMap(Map<String, dynamic> map) => UserActivity(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        type: map['type'] ?? '',
        description: map['description'] ?? '',
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      );
  final String id;
  final String userId;
  final String type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type,
        'description': description,
        'timestamp': Timestamp.fromDate(timestamp),
        'metadata': metadata,
      };
}
