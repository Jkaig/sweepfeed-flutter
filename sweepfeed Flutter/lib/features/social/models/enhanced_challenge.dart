import 'package:flutter/foundation.dart';

/// Enhanced challenge model with more variety and engagement
@immutable
class EnhancedChallenge {
  // Extra challenge-specific data

  const EnhancedChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.type,
    required this.currentProgress,
    required this.maxProgress,
    required this.rewards,
    required this.createdAt,
    required this.expiresAt,
    required this.isCompleted,
    required this.isClaimed,
    required this.iconCode,
    required this.metadata,
  });

  /// Create from Firestore document
  factory EnhancedChallenge.fromJson(Map<String, dynamic> json) =>
      EnhancedChallenge(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: ChallengeCategory.values.firstWhere(
          (cat) => cat.name == json['category'],
          orElse: () => ChallengeCategory.general,
        ),
        difficulty: ChallengeDifficulty.values.firstWhere(
          (diff) => diff.name == json['difficulty'],
          orElse: () => ChallengeDifficulty.easy,
        ),
        type: ChallengeType.values.firstWhere(
          (type) => type.name == json['type'],
          orElse: () => ChallengeType.contest,
        ),
        currentProgress: json['currentProgress'] as int? ?? 0,
        maxProgress: json['maxProgress'] as int,
        rewards: (json['rewards'] as List?)
                ?.map((reward) => ChallengeReward.fromJson(reward))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        isCompleted: json['isCompleted'] as bool? ?? false,
        isClaimed: json['isClaimed'] as bool? ?? false,
        iconCode: json['iconCode'] as String? ?? '🎯',
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );
  final String id;
  final String title;
  final String description;
  final ChallengeCategory category;
  final ChallengeDifficulty difficulty;
  final ChallengeType type;
  final int currentProgress;
  final int maxProgress;
  final List<ChallengeReward> rewards;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isCompleted;
  final bool isClaimed;
  final String iconCode; // Emoji or icon identifier
  final Map<String, dynamic> metadata;

  /// Progress percentage (0.0 to 1.0)
  double get progressPercentage =>
      maxProgress > 0 ? (currentProgress / maxProgress).clamp(0.0, 1.0) : 0.0;

  /// Progress text (e.g., "2/3")
  String get progressText => '$currentProgress/$maxProgress';

  /// Check if challenge is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if challenge is available to claim
  bool get canClaim => isCompleted && !isClaimed && !isExpired;

  /// Time remaining as human-readable string
  String get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 'Expired';

    final difference = expiresAt.difference(now);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  /// Total DustBunnies reward
  int get totalDustBunniesReward => rewards
      .where((reward) => reward.type == RewardType.dustBunnies)
      .fold(0, (sum, reward) => sum + reward.amount);

  /// @deprecated Use totalDustBunniesReward instead. SweepPoints is now DustBunnies (DB).
  @Deprecated(
      'Use totalDustBunniesReward instead. SweepPoints is now DustBunnies (DB).')
  int get totalSweepPointsReward => totalDustBunniesReward;

  /// Total SweepCoins reward
  int get totalSweepCoinsReward => rewards
      .where((reward) => reward.type == RewardType.sweepCoins)
      .fold(0, (sum, reward) => sum + reward.amount);

  /// Convert to Firestore document
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'difficulty': difficulty.name,
        'type': type.name,
        'currentProgress': currentProgress,
        'maxProgress': maxProgress,
        'rewards': rewards.map((reward) => reward.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isCompleted': isCompleted,
        'isClaimed': isClaimed,
        'iconCode': iconCode,
        'metadata': metadata,
      };

  /// Create a copy with updated values
  EnhancedChallenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeCategory? category,
    ChallengeDifficulty? difficulty,
    ChallengeType? type,
    int? currentProgress,
    int? maxProgress,
    List<ChallengeReward>? rewards,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isCompleted,
    bool? isClaimed,
    String? iconCode,
    Map<String, dynamic>? metadata,
  }) =>
      EnhancedChallenge(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        difficulty: difficulty ?? this.difficulty,
        type: type ?? this.type,
        currentProgress: currentProgress ?? this.currentProgress,
        maxProgress: maxProgress ?? this.maxProgress,
        rewards: rewards ?? this.rewards,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        isCompleted: isCompleted ?? this.isCompleted,
        isClaimed: isClaimed ?? this.isClaimed,
        iconCode: iconCode ?? this.iconCode,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancedChallenge &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'EnhancedChallenge(id: $id, title: $title, progress: $currentProgress/$maxProgress)';
}

/// Challenge categories for better organization
enum ChallengeCategory {
  general('General', '🎯', 'Basic challenges for everyone'),
  contest('Contest', '🏆', 'Contest-related challenges'),
  social('Social', '👥', 'Share and connect with friends'),
  streak('Streak', '🔥', 'Daily activity and consistency'),
  exploration('Discovery', '🔍', 'Try new features and contests'),
  achievement('Achievement', '⭐', 'Milestone and accomplishment challenges'),
  special('Special', '✨', 'Limited-time special events');

  const ChallengeCategory(this.displayName, this.emoji, this.description);

  final String displayName;
  final String emoji;
  final String description;
}

/// Challenge difficulty levels
enum ChallengeDifficulty {
  easy('Easy', 1, 0xFF4CAF50), // Green
  medium('Medium', 2, 0xFFFF9800), // Orange
  hard('Hard', 3, 0xFFF44336), // Red
  expert('Expert', 4, 0xFF9C27B0), // Purple
  legendary('Legendary', 5, 0xFFFFD700); // Gold

  const ChallengeDifficulty(this.displayName, this.level, this.color);

  final String displayName;
  final int level;
  final int color;
}

/// Enhanced challenge types with more variety
enum ChallengeType {
  contest('Contest Entry', 'Enter specific types of contests'),
  share('Social Share', 'Share contests or wins with friends'),
  streak('Daily Streak', 'Maintain daily activity streaks'),
  weekly('Weekly Goal', 'Complete weekly objectives'),
  bonus('Bonus Challenge', 'Special limited-time challenges'),
  discovery('Discovery', 'Try new features or contest categories'),
  community('Community', 'Interact with other users'),
  achievement('Achievement', 'Reach specific milestones'),
  special('Special Event', 'Participate in special events');

  const ChallengeType(this.displayName, this.description);

  final String displayName;
  final String description;
}

/// Challenge rewards system
@immutable
class ChallengeReward {
  const ChallengeReward({
    required this.type,
    required this.amount,
    required this.displayName,
    required this.description,
    this.itemId,
  });

  factory ChallengeReward.fromJson(Map<String, dynamic> json) =>
      ChallengeReward(
        type: RewardType.values.firstWhere(
          (type) => type.name == json['type'],
          orElse: () => RewardType.dustBunnies,
        ),
        amount: json['amount'] as int,
        itemId: json['itemId'] as String?,
        displayName: json['displayName'] as String,
        description: json['description'] as String? ?? '',
      );
  final RewardType type;
  final int amount;
  final String? itemId; // For cosmetic items, badges, etc.
  final String displayName;
  final String description;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'amount': amount,
        'itemId': itemId,
        'displayName': displayName,
        'description': description,
      };
}

/// Types of rewards
enum RewardType {
  dustBunnies('DustBunnies', '⭐', 'DustBunnies for leveling up'),
  sweepCoins('SweepCoins', '🪙', 'In-app currency'),
  badge('Badge', '🏅', 'Achievement badge'),
  cosmetic('Cosmetic', '🎨', 'Avatar customization'),
  streak('Streak Bonus', '🔥', 'Streak multiplier'),
  special('Special Item', '✨', 'Unique reward');

  const RewardType(this.displayName, this.emoji, this.description);

  final String displayName;
  final String emoji;
  final String description;

  /// @deprecated Use dustBunnies instead. SweepPoints is now DustBunnies (DB).
  @Deprecated('Use dustBunnies instead. SweepPoints is now DustBunnies (DB).')
  static RewardType get sweepPoints => dustBunnies;
}

/// Challenge template for generating new challenges
@immutable
class ChallengeTemplate {
  const ChallengeTemplate({
    required this.id,
    required this.titleTemplate,
    required this.descriptionTemplate,
    required this.category,
    required this.difficulty,
    required this.type,
    required this.targetAmount,
    required this.duration,
    required this.baseRewards,
    required this.iconCode,
    required this.config,
  });
  final String id;
  final String titleTemplate;
  final String descriptionTemplate;
  final ChallengeCategory category;
  final ChallengeDifficulty difficulty;
  final ChallengeType type;
  final int targetAmount;
  final Duration duration;
  final List<ChallengeReward> baseRewards;
  final String iconCode;
  final Map<String, dynamic> config;

  /// Generate a new challenge from this template
  EnhancedChallenge generateChallenge() {
    final now = DateTime.now();

    return EnhancedChallenge(
      id: 'challenge_${DateTime.now().millisecondsSinceEpoch}_${type.name}',
      title: _processTemplate(titleTemplate),
      description: _processTemplate(descriptionTemplate),
      category: category,
      difficulty: difficulty,
      type: type,
      currentProgress: 0,
      maxProgress: targetAmount,
      rewards: baseRewards,
      createdAt: now,
      expiresAt: now.add(duration),
      isCompleted: false,
      isClaimed: false,
      iconCode: iconCode,
      metadata: Map<String, dynamic>.from(config),
    );
  }

  String _processTemplate(String template) {
    // Replace template variables with actual values
    return template
        .replaceAll('{amount}', targetAmount.toString())
        .replaceAll('{duration}', _formatDuration(duration))
        .replaceAll('{difficulty}', difficulty.displayName.toLowerCase());
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }
}
