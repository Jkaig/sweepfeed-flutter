import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Represents a challenge definition stored in Firestore
@immutable
class ChallengeDefinition {
  const ChallengeDefinition({
    required this.id,
    required this.type,
    required this.target,
    required this.reward,
    required this.difficulty,
    required this.description,
    required this.title,
    required this.iconCodePoint,
    this.isActive = true,
  });

  final String id;
  final String type;
  final int target;
  final int reward;
  final String difficulty;
  final String description;
  final String title;
  final int iconCodePoint;
  final bool isActive;

  /// Create from Firestore document
  factory ChallengeDefinition.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return ChallengeDefinition(
      id: snapshot.id,
      type: data['type'] as String,
      target: data['target'] as int,
      reward: data['reward'] as int,
      difficulty: data['difficulty'] as String,
      description: data['description'] as String,
      title: data['title'] as String,
      iconCodePoint: data['iconCodePoint'] as int,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'target': target,
      'reward': reward,
      'difficulty': difficulty,
      'description': description,
      'title': title,
      'iconCodePoint': iconCodePoint,
      'isActive': isActive,
    };
  }

  @override
  String toString() =>
      'ChallengeDefinition(id: $id, type: $type, target: $target, reward: $reward)';
}

/// Represents a user's assigned challenge with progress
@immutable
class UserChallenge {
  const UserChallenge({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.progress,
    required this.completed,
    required this.assignedAt,
    this.completedAt,
    this.claimedAt,
  });

  final String id;
  final String challengeId;
  final String userId;
  final int progress;
  final bool completed;
  final DateTime assignedAt;
  final DateTime? completedAt;
  final DateTime? claimedAt;

  /// Check if reward has been claimed
  bool get isClaimed => claimedAt != null;

  /// Create from Firestore document
  factory UserChallenge.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;
    return UserChallenge(
      id: snapshot.id,
      challengeId: data['challenge_id'] as String,
      userId: data['user_id'] as String,
      progress: data['progress'] as int,
      completed: data['completed'] as bool,
      assignedAt: (data['assigned_at'] as Timestamp).toDate(),
      completedAt: data['completed_at'] != null
          ? (data['completed_at'] as Timestamp).toDate()
          : null,
      claimedAt: data['claimed_at'] != null
          ? (data['claimed_at'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'challenge_id': challengeId,
      'user_id': userId,
      'progress': progress,
      'completed': completed,
      'assigned_at': Timestamp.fromDate(assignedAt),
      'completed_at':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'claimed_at': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
    };
  }

  /// Copy with updated values
  UserChallenge copyWith({
    String? id,
    String? challengeId,
    String? userId,
    int? progress,
    bool? completed,
    DateTime? assignedAt,
    DateTime? completedAt,
    DateTime? claimedAt,
  }) {
    return UserChallenge(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      userId: userId ?? this.userId,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
      assignedAt: assignedAt ?? this.assignedAt,
      completedAt: completedAt ?? this.completedAt,
      claimedAt: claimedAt ?? this.claimedAt,
    );
  }

  @override
  String toString() =>
      'UserChallenge(id: $id, challengeId: $challengeId, progress: $progress/$completed, completed: $completed)';
}

/// Combined model for UI display
@immutable
class DailyChallengeDisplay {
  const DailyChallengeDisplay({
    required this.definition,
    required this.userChallenge,
  });

  final ChallengeDefinition definition;
  final UserChallenge userChallenge;

  /// Progress percentage (0.0 to 1.0)
  double get progressPercentage =>
      definition.target > 0 ? userChallenge.progress / definition.target : 0.0;

  /// Progress text for UI (e.g., "2/5")
  String get progressText => '${userChallenge.progress}/${definition.target}';

  /// Check if challenge is complete (progress >= target)
  bool get isComplete => userChallenge.progress >= definition.target;

  /// Check if can be claimed (complete but not claimed)
  bool get canClaim => isComplete && !userChallenge.isClaimed;

  @override
  String toString() =>
      'DailyChallengeDisplay(${definition.title}: ${progressText}, complete: $isComplete)';
}

/// Challenge types enum for type safety
enum ChallengeType {
  enterContest('enter_contest'),
  saveContest('save_contest'),
  shareContest('share_contest'),
  watchAd('watch_ad'),
  completeProfile('complete_profile'),
  dailyLogin('daily_login');

  const ChallengeType(this.value);
  final String value;

  static ChallengeType fromString(String value) {
    return ChallengeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ChallengeType.enterContest,
    );
  }
}

/// Challenge difficulty levels
enum ChallengeDifficulty {
  easy('easy'),
  medium('medium'),
  hard('hard');

  const ChallengeDifficulty(this.value);
  final String value;

  static ChallengeDifficulty fromString(String value) {
    return ChallengeDifficulty.values.firstWhere(
      (difficulty) => difficulty.value == value,
      orElse: () => ChallengeDifficulty.easy,
    );
  }
}

/// Result of challenge action (completion, claiming, etc.)
@immutable
class ChallengeActionResult {
  const ChallengeActionResult({
    required this.success,
    required this.challengeId,
    this.pointsAwarded = 0,
    this.newProgress = 0,
    this.completed = false,
    this.message,
    this.error,
  });

  final bool success;
  final String challengeId;
  final int pointsAwarded;
  final int newProgress;
  final bool completed;
  final String? message;
  final String? error;

  @override
  String toString() =>
      'ChallengeActionResult(success: $success, challengeId: $challengeId, points: $pointsAwarded)';
}
