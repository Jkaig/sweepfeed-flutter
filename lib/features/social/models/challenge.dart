enum ChallengeStatus {
  pending,
  accepted,
  declined,
  completed,
}

class Challenge {
  Challenge({
    required this.id,
    required this.challengerId,
    required this.challengedId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String challengerId;
  final String challengedId;
  final ChallengeStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
}
