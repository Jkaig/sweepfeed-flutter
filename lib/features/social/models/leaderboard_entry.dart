import 'package:flutter/foundation.dart';

/// Represents a single entry in a leaderboard
@immutable
class LeaderboardEntry {
  // Bronze, Silver, Gold brackets

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.rank,
    required this.score,
    required this.badge,
    required this.level,
    required this.userLevel,
  });

  /// Create from Firestore document
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String,
        avatarUrl: json['avatarUrl'] as String? ?? '',
        rank: json['rank'] as int,
        score: json['score'] as int,
        badge: json['badge'] as String? ?? '',
        level: json['level'] as int,
        userLevel: json['userLevel'] as String? ?? 'Bronze',
      );
  final String userId;
  final String displayName;
  final String avatarUrl;
  final int rank;
  final int score;
  final String badge;
  final int level;
  final String userLevel;

  /// Convert to Firestore document
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'rank': rank,
        'score': score,
        'badge': badge,
        'level': level,
        'userLevel': userLevel,
      };

  /// Create a copy with updated values
  LeaderboardEntry copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    int? rank,
    int? score,
    String? badge,
    int? level,
    String? userLevel,
  }) =>
      LeaderboardEntry(
        userId: userId ?? this.userId,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        rank: rank ?? this.rank,
        score: score ?? this.score,
        badge: badge ?? this.badge,
        level: level ?? this.level,
        userLevel: userLevel ?? this.userLevel,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntry &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          rank == other.rank &&
          score == other.score;

  @override
  int get hashCode => userId.hashCode ^ rank.hashCode ^ score.hashCode;

  @override
  String toString() =>
      'LeaderboardEntry(userId: $userId, displayName: $displayName, rank: $rank, score: $score, level: $level)';
}

/// Represents different types of leaderboards
enum LeaderboardType {
  daily('Daily', 'Top performers today'),
  weekly('Weekly', 'Top performers this week'),
  allTime('All-Time', 'Hall of Fame'),
  friends('Friends', 'Compete with friends');

  const LeaderboardType(this.displayName, this.description);

  final String displayName;
  final String description;
}

/// User level brackets for fair competition
enum UserLevelBracket {
  bronze('Bronze', 1, 10, 0xFF8B4513), // Bronze color
  silver('Silver', 11, 25, 0xFFC0C0C0), // Silver color
  gold('Gold', 26, 50, 0xFFFFD700), // Gold color
  platinum('Platinum', 51, 100, 0xFFE5E4E2), // Platinum color
  diamond('Diamond', 101, 999, 0xFF00E5FF); // Cyan color to match theme

  const UserLevelBracket(this.name, this.minLevel, this.maxLevel, this.color);

  final String name;
  final int minLevel;
  final int maxLevel;
  final int color;

  /// Get user bracket based on level
  static UserLevelBracket getBracket(int level) {
    if (level >= diamond.minLevel) return diamond;
    if (level >= platinum.minLevel) return platinum;
    if (level >= gold.minLevel) return gold;
    if (level >= silver.minLevel) return silver;
    return bronze;
  }
}

/// Represents leaderboard metadata
@immutable
class LeaderboardMetadata {
  const LeaderboardMetadata({
    required this.type,
    required this.lastUpdated,
    required this.totalEntries,
    required this.bracket,
  });

  factory LeaderboardMetadata.fromJson(Map<String, dynamic> json) =>
      LeaderboardMetadata(
        type: LeaderboardType.values.firstWhere(
          (type) => type.name == json['type'],
          orElse: () => LeaderboardType.daily,
        ),
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
        totalEntries: json['totalEntries'] as int,
        bracket: UserLevelBracket.values.firstWhere(
          (bracket) => bracket.name == json['bracket'],
          orElse: () => UserLevelBracket.bronze,
        ),
      );
  final LeaderboardType type;
  final DateTime lastUpdated;
  final int totalEntries;
  final UserLevelBracket bracket;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'lastUpdated': lastUpdated.toIso8601String(),
        'totalEntries': totalEntries,
        'bracket': bracket.name,
      };
}
