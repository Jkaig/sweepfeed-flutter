import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a reward that a user can earn.
class Reward {
  /// Creates a new [Reward] instance.
  const Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
  });

  factory Reward.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Reward(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      points: data['points'] ?? 0,
    );
  }

  /// The unique identifier of the reward.
  final String id;
  /// The name of the reward.
  final String name;
  /// A brief description of the reward.
  final String description;
  /// The number of points required to unlock the reward.
  final int points;
}
