import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a category for contests.
class Category {
  Category({
    required this.id,
    required this.name,
    required this.emoji,
    this.popularity = 0,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '❓',
      popularity: data['popularity'] as int? ?? 0,
    );
  }
  final String id;
  final String name;
  final String emoji;
  final int popularity;
}
