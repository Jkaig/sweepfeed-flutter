import 'package:flutter/foundation.dart';

/// Comprehensive user profile for social features
@immutable
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.avatarUrl,
    required this.level,
    required this.dustBunnies,
    required this.totalContestsEntered,
    required this.challengesCompleted,
    required this.totalPrizesWon,
    required this.sweepCoins,
    required this.currentStreak,
    required this.longestStreak,
    required this.badges,
    required this.joinedDate,
    required this.lastActiveDate,
    required this.isOnline,
    required this.bio,
    required this.stats,
    required this.friends,
    required this.following,
    required this.followers,
  });

  /// Create from Firestore document
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String,
        avatarUrl: json['avatarUrl'] as String? ?? '',
        level: json['level'] as int? ?? 1,
        dustBunnies: json['dustBunnies'] as int? ??
            json['sweepPoints'] as int? ??
            json['xp'] as int? ??
            0,
        totalContestsEntered: json['totalContestsEntered'] as int? ?? 0,
        challengesCompleted: json['challengesCompleted'] as int? ?? 0,
        totalPrizesWon: json['totalPrizesWon'] as int? ?? 0,
        sweepCoins: json['sweepCoins'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        badges: List<String>.from(json['badges'] as List? ?? []),
        joinedDate: DateTime.parse(json['joinedDate'] as String),
        lastActiveDate: DateTime.parse(json['lastActiveDate'] as String),
        isOnline: json['isOnline'] as bool? ?? false,
        bio: json['bio'] as String? ?? '',
        stats: Map<String, dynamic>.from(json['stats'] as Map? ?? {}),
        friends: List<String>.from(json['friends'] as List? ?? []),
        following: List<String>.from(json['following'] as List? ?? []),
        followers: List<String>.from(json['followers'] as List? ?? []),
      );
  final String uid;
  final String displayName;
  final String avatarUrl;
  final int level;
  final int dustBunnies;

  @Deprecated('Use dustBunnies instead. SweepPoints is now DustBunnies (DB).')
  int get sweepPoints => dustBunnies;

  @Deprecated('Use dustBunnies instead. XP is now DustBunnies (DB).')
  int get xp => dustBunnies;
  final int totalContestsEntered;
  final int challengesCompleted;
  final int totalPrizesWon;
  final int sweepCoins;
  final int currentStreak;
  final int longestStreak;
  final List<String> badges;
  final DateTime joinedDate;
  final DateTime lastActiveDate;
  final bool isOnline;
  final String bio;
  final Map<String, dynamic> stats;
  final List<String> friends;
  final List<String> following;
  final List<String> followers;

  /// Convert to Firestore document
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'level': level,
        'dustBunnies': dustBunnies,
        'sweepPoints': dustBunnies, // Backward compatibility
        'totalContestsEntered': totalContestsEntered,
        'challengesCompleted': challengesCompleted,
        'totalPrizesWon': totalPrizesWon,
        'sweepCoins': sweepCoins,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'badges': badges,
        'joinedDate': joinedDate.toIso8601String(),
        'lastActiveDate': lastActiveDate.toIso8601String(),
        'isOnline': isOnline,
        'bio': bio,
        'stats': stats,
        'friends': friends,
        'following': following,
        'followers': followers,
      };

  /// Create a copy with updated values
  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? avatarUrl,
    int? level,
    int? dustBunnies,
    int? totalContestsEntered,
    int? challengesCompleted,
    int? totalPrizesWon,
    int? sweepCoins,
    int? currentStreak,
    int? longestStreak,
    List<String>? badges,
    DateTime? joinedDate,
    DateTime? lastActiveDate,
    bool? isOnline,
    String? bio,
    Map<String, dynamic>? stats,
    List<String>? friends,
    List<String>? following,
    List<String>? followers,
  }) =>
      UserProfile(
        uid: uid ?? this.uid,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        level: level ?? this.level,
        dustBunnies: dustBunnies ?? this.dustBunnies,
        totalContestsEntered: totalContestsEntered ?? this.totalContestsEntered,
        challengesCompleted: challengesCompleted ?? this.challengesCompleted,
        totalPrizesWon: totalPrizesWon ?? this.totalPrizesWon,
        sweepCoins: sweepCoins ?? this.sweepCoins,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        badges: badges ?? this.badges,
        joinedDate: joinedDate ?? this.joinedDate,
        lastActiveDate: lastActiveDate ?? this.lastActiveDate,
        isOnline: isOnline ?? this.isOnline,
        bio: bio ?? this.bio,
        stats: stats ?? this.stats,
        friends: friends ?? this.friends,
        following: following ?? this.following,
        followers: followers ?? this.followers,
      );

  /// Calculate DustBunnies needed for next level
  int get dbToNextLevel {
    final currentLevelDB = _calculateDBForLevel(level);
    final nextLevelDB = _calculateDBForLevel(level + 1);
    return nextLevelDB - dustBunnies;
  }

  @Deprecated('Use dbToNextLevel instead. SweepPoints is now DustBunnies (DB).')
  int get spToNextLevel => dbToNextLevel;

  @Deprecated('Use dbToNextLevel instead. XP is now DustBunnies (DB).')
  int get xpToNextLevel => dbToNextLevel;

  /// Calculate progress percentage to next level
  double get progressToNextLevel {
    final currentLevelDB = _calculateDBForLevel(level);
    final nextLevelDB = _calculateDBForLevel(level + 1);
    final currentProgress = dustBunnies - currentLevelDB;
    final levelRange = nextLevelDB - currentLevelDB;

    if (levelRange <= 0) return 1.0;
    return (currentProgress / levelRange).clamp(0.0, 1.0);
  }

  /// Get user's bracket based on level
  String get userBracket {
    if (level >= 101) return 'Diamond';
    if (level >= 51) return 'Platinum';
    if (level >= 26) return 'Gold';
    if (level >= 11) return 'Silver';
    return 'Bronze';
  }

  /// Get total friends count
  int get totalFriends => friends.length;

  /// Get total following count
  int get totalFollowing => following.length;

  /// Get total followers count
  int get totalFollowers => followers.length;

  /// Check if user has specific badge
  bool hasBadge(String badgeId) => badges.contains(badgeId);

  /// Get days since joined
  int get daysSinceJoined => DateTime.now().difference(joinedDate).inDays;

  /// Helper method to calculate DustBunnies required for a specific level
  static int _calculateDBForLevel(int level) {
    // Progressive DB requirements: Level 1 = 0, Level 2 = 100, Level 3 = 250, etc.
    if (level <= 1) return 0;
    return ((level - 1) * 100) + ((level - 1) * (level - 2) * 25);
  }

  /// @deprecated Use _calculateDBForLevel instead. SweepPoints is now DustBunnies (DB).
  @Deprecated(
      'Use _calculateDBForLevel instead. SweepPoints is now DustBunnies (DB).')
  static int _calculateSPForLevel(int level) => _calculateDBForLevel(level);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() =>
      'UserProfile(uid: $uid, displayName: $displayName, level: $level, dustBunnies: $dustBunnies)';
}

/// Friend request model
@immutable
class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    required this.fromUserAvatar,
    required this.createdAt,
    required this.status,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
        id: json['id'] as String,
        fromUserId: json['fromUserId'] as String,
        toUserId: json['toUserId'] as String,
        fromUserName: json['fromUserName'] as String,
        fromUserAvatar: json['fromUserAvatar'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: FriendRequestStatus.values.firstWhere(
          (status) => status.name == json['status'],
          orElse: () => FriendRequestStatus.pending,
        ),
      );
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUserName;
  final String fromUserAvatar;
  final DateTime createdAt;
  final FriendRequestStatus status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromUserName': fromUserName,
        'fromUserAvatar': fromUserAvatar,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
      };
}

/// Status of friend requests
enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
  cancelled,
}

/// User activity for activity feed
@immutable
class UserActivity {
  const UserActivity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.type,
    required this.description,
    required this.data,
    required this.createdAt,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) => UserActivity(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        userAvatar: json['userAvatar'] as String? ?? '',
        type: ActivityType.values.firstWhere(
          (type) => type.name == json['type'],
          orElse: () => ActivityType.other,
        ),
        description: json['description'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final ActivityType type;
  final String description;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'type': type.name,
        'description': description,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Types of user activities
enum ActivityType {
  levelUp,
  badgeEarned,
  contestWon,
  challengeCompleted,
  friendAdded,
  streakMilestone,
  other,
}
