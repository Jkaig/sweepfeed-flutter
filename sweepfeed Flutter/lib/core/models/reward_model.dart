/// Represents a reward that can be unlocked by a user.
class Reward {
  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsRequired,
    required this.imageUrl,
  });
  final String id;
  final String name;
  final String description;
  final int pointsRequired;
  final String imageUrl;
}
