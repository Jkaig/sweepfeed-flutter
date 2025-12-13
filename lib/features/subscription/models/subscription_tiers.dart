import 'package:flutter/material.dart';

/// Enum representing the different subscription tiers available in the app
enum SubscriptionTier {
  /// Free tier - basic functionality only
  free,

  /// Basic subscription tier - limited premium features
  basic,

  /// Premium subscription tier - full access to all features
  premium,
}

/// Extension to provide additional functionality for SubscriptionTier
extension SubscriptionTierExtension on SubscriptionTier {
  /// Returns the identifier for the subscription tier
  String get id {
    switch (this) {
      case SubscriptionTier.free:
        return 'free';
      case SubscriptionTier.basic:
        return 'basic';
      case SubscriptionTier.premium:
        return 'premium';
    }
  }

  /// Returns the display name for the subscription tier
  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.basic:
        return 'Basic';
      case SubscriptionTier.premium:
        return 'Premium';
    }
  }

  /// Returns the description for the subscription tier
  String get description {
    switch (this) {
      case SubscriptionTier.free:
        return 'Basic features with limited access';
      case SubscriptionTier.basic:
        return 'Enhanced features and priority access';
      case SubscriptionTier.premium:
        return 'Full access to all premium features';
    }
  }

  /// Returns the color for the subscription tier
  Color get color {
    switch (this) {
      case SubscriptionTier.free:
        return const Color(0xFF6B7280);
      case SubscriptionTier.basic:
        return const Color(0xFF00E5FF);
      case SubscriptionTier.premium:
        return const Color(0xFFFF9800);
    }
  }

  /// Returns the monthly price for the subscription tier
  double get price {
    switch (this) {
      case SubscriptionTier.free:
        return 0.0;
      case SubscriptionTier.basic:
        return 3.99;
      case SubscriptionTier.premium:
        return 6.99;
    }
  }

  /// Returns the annual price for the subscription tier
  double get annualPrice {
    switch (this) {
      case SubscriptionTier.free:
        return 0.0;
      case SubscriptionTier.basic:
        return 39.99;
      case SubscriptionTier.premium:
        return 69.99;
    }
  }

  /// Returns the features list for the subscription tier
  List<FeatureItem> get features {
    switch (this) {
      case SubscriptionTier.free:
        return [
          const FeatureItem(
            title: 'Browse up to 15 sweepstakes daily',
            included: true,
          ),
          const FeatureItem(
            title: 'Save up to 5 sweepstakes',
            included: true,
          ),
          const FeatureItem(
            title: 'Basic sweepstakes filtering',
            included: true,
          ),
          const FeatureItem(
            title: 'Ad-free experience',
            included: false,
          ),
          const FeatureItem(
            title: 'Advanced filters & sorting',
            included: false,
          ),
          const FeatureItem(
            title: 'Access to high-value sweepstakes',
            included: false,
          ),
          const FeatureItem(
            title: 'Early notification for new sweepstakes',
            included: false,
          ),
          const FeatureItem(
            title: 'Premium-only sweepstakes',
            included: false,
          ),
          const FeatureItem(
            title: 'Dedicated email inbox (@sweepfeed.com)',
            included: false,
          ),
        ];
      case SubscriptionTier.basic:
        return [
          const FeatureItem(
            title: 'Browse up to 100 sweepstakes daily',
            included: true,
          ),
          const FeatureItem(
            title: 'Save up to 50 sweepstakes',
            included: true,
          ),
          const FeatureItem(
            title: 'Ad-free experience',
            included: true,
          ),
          const FeatureItem(
            title: 'Basic sweepstakes filtering',
            included: true,
          ),
          const FeatureItem(
            title: 'Advanced filters & sorting',
            included: true,
          ),
          const FeatureItem(
            title: 'Access to high-value sweepstakes',
            included: true,
          ),
          const FeatureItem(
            title: 'Early notification for new sweepstakes',
            included: false,
          ),
          const FeatureItem(
            title: 'Premium-only sweepstakes',
            included: false,
          ),
          const FeatureItem(
            title: 'Dedicated email inbox (@sweepfeed.com)',
            included: false,
          ),
        ];
      case SubscriptionTier.premium:
        return [
          const FeatureItem(
            title: 'Unlimited sweepstakes browsing',
            included: true,
          ),
          const FeatureItem(
            title: 'Unlimited saved sweepstakes',
            included: true,
          ),
          const FeatureItem(
            title: 'Ad-free experience',
            included: true,
          ),
          const FeatureItem(
            title: 'Basic sweepstakes filtering',
            included: true,
          ),
          const FeatureItem(
            title: 'Advanced filters & sorting',
            included: true,
          ),
          const FeatureItem(
            title: 'Access to high-value sweepstakes',
            included: true,
          ),
          const FeatureItem(
            title: 'Early notification for new sweepstakes',
            included: true,
          ),
          const FeatureItem(
            title: 'Premium-only sweepstakes',
            included: true,
          ),
          const FeatureItem(
            title: 'Dedicated email inbox (@sweepfeed.com)',
            included: true,
          ),
        ];
    }
  }

  /// Returns true if this tier includes premium features
  bool get isPremium => this == SubscriptionTier.basic || this == SubscriptionTier.premium;

  /// Returns true if this is the highest tier
  bool get isTopTier => this == SubscriptionTier.premium;

  /// Returns the daily contest view limit (feed limit)
  int? get dailyContestViewLimit {
    switch (this) {
      case SubscriptionTier.free:
        return 10;
      case SubscriptionTier.basic:
      case SubscriptionTier.premium:
        return null; // unlimited
    }
  }

  /// Returns the daily entry limit for this tier
  int? get dailyEntryLimit {
    switch (this) {
      case SubscriptionTier.free:
        return 10;
      case SubscriptionTier.basic:
      case SubscriptionTier.premium:
        return null; // unlimited
    }
  }

  /// Returns the maximum saved contests for this tier
  int? get maxSavedContests {
    switch (this) {
      case SubscriptionTier.free:
        return 5;
      case SubscriptionTier.basic:
        return 50;
      case SubscriptionTier.premium:
        return null; // unlimited
    }
  }

  /// Returns the daily notification limit for this tier
  int? get dailyNotificationLimit {
    switch (this) {
      case SubscriptionTier.free:
        return 3;
      case SubscriptionTier.basic:
        return 15;
      case SubscriptionTier.premium:
        return null; // unlimited
    }
  }

  /// Returns the SweepCoins earning multiplier for this tier
  double get sweepCoinsMultiplier {
    switch (this) {
      case SubscriptionTier.free:
        return 1.0;
      case SubscriptionTier.basic:
        return 2.0;
      case SubscriptionTier.premium:
        return 3.0;
    }
  }

  /// Returns the entry history retention days for this tier
  int? get entryHistoryDays {
    switch (this) {
      case SubscriptionTier.free:
        return 30;
      case SubscriptionTier.basic:
        return 90;
      case SubscriptionTier.premium:
        return null; // unlimited
    }
  }

  /// Returns the maximum filter presets for this tier
  int get maxFilterPresets {
    switch (this) {
      case SubscriptionTier.free:
        return 3;
      case SubscriptionTier.basic:
        return 10;
      case SubscriptionTier.premium:
        return 50;
    }
  }

  /// Returns whether this tier has ad-free experience
  bool get isAdFree => this == SubscriptionTier.basic || this == SubscriptionTier.premium;

  /// Returns whether this tier has leaderboard access
  bool get hasLeaderboardAccess => this == SubscriptionTier.basic || this == SubscriptionTier.premium;

  /// Returns whether this tier has social challenges access
  bool get hasSocialChallengesAccess => this == SubscriptionTier.basic || this == SubscriptionTier.premium;

  /// Returns whether this tier has auto-entry scheduling
  bool get hasAutoEntryScheduling => this == SubscriptionTier.premium;

  /// Returns whether this tier has exclusive partner contests
  bool get hasExclusivePartnerSweepstakes => this == SubscriptionTier.premium;

  /// Returns whether this tier has analytics features
  bool get hasAnalytics => this == SubscriptionTier.premium;

  /// Returns whether this tier has priority customer support
  bool get hasPrioritySupport => this == SubscriptionTier.premium;

  /// Returns whether this tier has email inbox access
  bool get hasEmailInbox => this == SubscriptionTier.premium;

  /// Returns the marketing tagline for this tier
  String get tagline {
    switch (this) {
      case SubscriptionTier.free:
        return 'Endless Sweeps, Effortless Entry';
      case SubscriptionTier.basic:
        return 'Supercharge Your Sweepstaking';
      case SubscriptionTier.premium:
        return 'Dominate the Sweepstakes Game';
    }
  }

  /// Returns upgrade triggers for this tier
  List<String> get upgradeTrigggers {
    switch (this) {
      case SubscriptionTier.free:
        return [
          'Reached daily view limit',
          'Daily entry limit hit',
          'Need more saved contests',
          'Ad fatigue',
          'Want leaderboard access',
        ];
      case SubscriptionTier.basic:
        return [
          'Need more organization',
          'Want exclusive contests',
          'Advanced analytics interest',
          'Auto-entry scheduling desire',
        ];
      case SubscriptionTier.premium:
        return []; // No upgrade triggers for top tier
    }
  }

  /// Returns retention mechanisms for this tier
  List<String> get retentionMechanisms {
    switch (this) {
      case SubscriptionTier.free:
        return [
          'Streaks',
          'Points',
          'Basic gamification',
          'Contest discovery',
        ];
      case SubscriptionTier.basic:
        return [
          'Leaderboards',
          'Social features',
          'Ad-free experience',
          'Advanced filtering',
          'SweepCoins multiplier',
        ];
      case SubscriptionTier.premium:
        return [
          'Exclusivity',
          'Automation',
          'Analytics',
          'VIP status',
          'Priority support',
          'Win optimization',
        ];
    }
  }
}

/// Represents a feature item for display in subscription tiers
class FeatureItem {
  const FeatureItem({
    required this.title,
    required this.included,
    this.details,
  });
  final String title;
  final bool included;
  final String? details;
}
