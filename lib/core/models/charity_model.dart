import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a charity organization.
class Charity {
  /// Creates a new [Charity] instance.
  const Charity({
    required this.id,
    required this.name,
    required this.description,
    required this.emblemUrl,
  });

  factory Charity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Charity(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      emblemUrl: data['emblemUrl'] ?? '',
    );
  }

  /// The unique identifier of the charity.
  final String id;
  /// The name of the charity.
  final String name;
  /// A brief description of the charity.
  final String description;
  /// URL to the charity's logo/emblem
  final String emblemUrl;
}
