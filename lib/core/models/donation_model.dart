/// Represents a donation made by a user to a charity.
class Donation {
  /// Creates a new [Donation] instance.
  Donation({
    required this.id,
    required this.userId,
    required this.charityId,
    required this.amount,
    required this.timestamp,
  });

  /// The unique identifier of the donation.
  final String id;
  /// The ID of the user who made the donation.
  final String userId;
  /// The ID of the charity that received the donation.
  final String charityId;
  /// The amount of the donation.
  final double amount;
  /// The date and time the donation was made.
  final DateTime timestamp;
}
