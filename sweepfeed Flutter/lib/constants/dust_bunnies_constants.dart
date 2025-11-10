/// DustBunnies reward and gamification constants.
class DustBunniesConstants {
  /// Points awarded for entering a contest.
  static const int kContestEntryPoints = 25;

  /// Points awarded for daily login.
  static const int kDailyLoginPoints = 15;

  /// Points awarded for completing the user profile.
  static const int kProfileCompletePoints = 75;

  /// Points awarded for a successful referral.
  static const int kReferralSuccessPoints = 150;

  /// Points awarded for sharing a contest.
  static const int kShareContestPoints = 20;

  /// Points awarded for watching an ad.
  static const int kWatchAdPoints = 10;

  /// Points awarded for completing a checklist item.
  static const int kCompleteChecklistPoints = 30;

  /// Points awarded for winning a contest.
  static const int kWinContestPoints = 500;

  /// Points awarded as a streak bonus.
  static const int kStreakBonusPoints = 20;

  /// Points awarded for unlocking an achievement.
  static const int kAchievementUnlockPoints = 75;

  /// Points awarded for opening a mystery box.
  static const int kMysteryBoxOpenPoints = 35;

  /// Points awarded for posting a comment.
  static const int kCommentPostedPoints = 5;

  /// Points awarded for saving a contest.
  static const int kContestSavedPoints = 3;

  /// Points awarded for the first entry each day.
  static const int kFirstEntryDailyPoints = 50;

  /// The base value used in level calculation.
  static const double kLevelBase = 100.0;

  /// The exponent used in level calculation.
  static const double kLevelExponent = 1.5;

  /// The maximum level achievable.
  static const int kMaxLevel = 1000;

  /// The level considered a small milestone.
  static const int kSmallMilestoneLevel = 5;

  /// The level considered a medium milestone.
  static const int kMediumMilestoneLevel = 10;

  /// The level considered a quarter-century milestone.
  static const int kQuarterCenturyLevel = 25;

  /// The level considered a half-century milestone.
  static const int kHalfCenturyLevel = 50;

  /// The level considered a centurion milestone.
  static const int kCenturionLevel = 100;

  /// The default limit for leaderboard entries.
  static const int kDefaultLeaderboardLimit = 100;

  /// The number of top rankers to display.
  static const int kTopRankersDisplayCount = 10;

  /// The base reward for completing a daily challenge.
  static const int kDailyChallengeBaseReward = 50;

  /// The secondary reward for completing a daily challenge.
  static const int kDailyChallengeSecondaryReward = 20;

  /// The number of particles emitted during a level up animation.
  static const int kLevelUpParticleCount = 50;
}

/// Backward compatibility for SweepPoints constants
/// @deprecated Use DustBunniesConstants instead. SweepPoints is now DustBunnies (DB).
@Deprecated(
    'Use DustBunniesConstants instead. SweepPoints is now DustBunnies (DB).')
class SweepPointsConstants {
  // SweepPoints reward amounts
  static const int kContestEntryPoints =
      DustBunniesConstants.kContestEntryPoints;
  static const int kDailyLoginPoints = DustBunniesConstants.kDailyLoginPoints;
  static const int kProfileCompletePoints =
      DustBunniesConstants.kProfileCompletePoints;
  static const int kReferralSuccessPoints =
      DustBunniesConstants.kReferralSuccessPoints;
  static const int kShareContestPoints =
      DustBunniesConstants.kShareContestPoints;
  static const int kWatchAdPoints = DustBunniesConstants.kWatchAdPoints;
  static const int kCompleteChecklistPoints =
      DustBunniesConstants.kCompleteChecklistPoints;
  static const int kWinContestPoints = DustBunniesConstants.kWinContestPoints;
  static const int kStreakBonusPoints = DustBunniesConstants.kStreakBonusPoints;
  static const int kAchievementUnlockPoints =
      DustBunniesConstants.kAchievementUnlockPoints;
  static const int kMysteryBoxOpenPoints =
      DustBunniesConstants.kMysteryBoxOpenPoints;
  static const int kCommentPostedPoints =
      DustBunniesConstants.kCommentPostedPoints;
  static const int kContestSavedPoints =
      DustBunniesConstants.kContestSavedPoints;
  static const int kFirstEntryDailyPoints =
      DustBunniesConstants.kFirstEntryDailyPoints;

  // Level calculation constants
  static const double kLevelBase = DustBunniesConstants.kLevelBase;
  static const double kLevelExponent = DustBunniesConstants.kLevelExponent;
  static const int kMaxLevel = DustBunniesConstants.kMaxLevel;

  // Milestone reward levels
  static const int kSmallMilestoneLevel =
      DustBunniesConstants.kSmallMilestoneLevel;
  static const int kMediumMilestoneLevel =
      DustBunniesConstants.kMediumMilestoneLevel;
  static const int kQuarterCenturyLevel =
      DustBunniesConstants.kQuarterCenturyLevel;
  static const int kHalfCenturyLevel = DustBunniesConstants.kHalfCenturyLevel;
  static const int kCenturionLevel = DustBunniesConstants.kCenturionLevel;

  // Leaderboard settings
  static const int kDefaultLeaderboardLimit =
      DustBunniesConstants.kDefaultLeaderboardLimit;
  static const int kTopRankersDisplayCount =
      DustBunniesConstants.kTopRankersDisplayCount;

  // Daily challenge rewards
  static const int kDailyChallengeBaseReward =
      DustBunniesConstants.kDailyChallengeBaseReward;
  static const int kDailyChallengeSecondaryReward =
      DustBunniesConstants.kDailyChallengeSecondaryReward;

  // Particle animation settings
  static const int kLevelUpParticleCount =
      DustBunniesConstants.kLevelUpParticleCount;
}
