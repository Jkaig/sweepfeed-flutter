import 'package:flutter/material.dart';

/// Demographics for targeting onboarding experience
enum UserDemographic {
  /// 18-25: Digital natives, TikTok generation, instant gratification
  genZ,

  /// 26-41: Tech-savvy, value authenticity, side hustles
  millennials,

  /// 42-57: Practical, skeptical, value security
  genX,

  /// 58+: Need clarity, trust indicators, simple navigation
  boomers,

  /// Looking for life-changing wins, free entertainment
  lowIncome,

  /// Luxury prizes, exclusive experiences, time-saving
  highIncome,

  /// Flexible timing, family prizes, community
  stayAtHomeParents,

  /// Textbooks, tech, small frequent wins
  students,

  /// Travel, leisure, easy to understand
  retirees,

  /// Achievement systems, competitive elements
  gamingEnthusiasts,
}

/// User personality types for branching onboarding
enum PersonalityType {
  /// Loves big risks, huge prizes, adrenaline rush
  thrill_seeker,

  /// Calculated, wants good odds, researches everything
  strategic_player,

  /// Loves community features, sharing wins, referrals
  social_butterfly,

  /// Just wants easy wins, minimal effort
  casual_browser,

  /// Only interested in high-value, exclusive prizes
  luxury_hunter,

  /// Loves deals, discounts, everyday practical prizes
  bargain_hunter,
}

/// Prize preferences with psychological targeting
enum PrizeCategory {
  /// Cash prizes
  cash,

  /// Gift cards
  giftCards,

  /// Electronics prizes
  electronics,

  /// Luxury car prizes
  luxuryCars,

  /// Travel prizes
  travel,

  /// Gaming prizes
  gaming,

  /// Fashion prizes
  fashion,

  /// Home prizes
  home,

  /// Food prizes
  food,

  /// Experience prizes
  experiences,

  /// Crypto prizes
  crypto,

  /// Education prizes
  education,
}

/// Risk tolerance levels
enum RiskTolerance {
  /// Wants sure wins, low odds don't matter
  conservative,

  /// Balanced approach
  moderate,

  /// Go big or go home mentality
  aggressive,
}

/// Time availability patterns
enum TimeAvailability {
  /// Phone always in hand
  always_available,

  /// Early bird catches the worm
  morning_person,

  /// Night owl
  evening_warrior,

  /// Busy professional
  weekend_only,

  /// Random free moments
  sporadic,
}

/// Social preference types
enum SocialPreference {
  /// Prefers individual experience
  solo_player,

  /// Loves group activities and sharing
  community_focused,

  /// Wants leaderboards and competitions
  competitive,

  /// Enjoys referring friends and helping others
  helper,
}

/// Onboarding step data model
class OnboardingStep {
  /// Creates an onboarding step.
  const OnboardingStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.animationDuration = const Duration(milliseconds: 600),
    this.targetDemographics = const [],
    this.customData = const {},
    this.isRequired = true,
    this.pointsReward = 100,
  });

  /// Unique identifier for the step.
  final String id;

  /// Title of the step.
  final String title;

  /// Subtitle of the step.
  final String subtitle;

  /// Detailed description of the step.
  final String description;

  /// Icon to display for the step.
  final IconData icon;

  /// Accent color for the step's UI.
  final Color accentColor;

  /// Duration for animations related to the step.
  final Duration animationDuration;

  /// List of user demographics this step is targeted towards.
  final List<UserDemographic> targetDemographics;

  /// Any custom data associated with the step.
  final Map<String, dynamic> customData;

  /// Indicates if the step is required for onboarding completion.
  final bool isRequired;

  /// Points awarded for completing the step.
  final int pointsReward;
}

/// User onboarding profile
class OnboardingProfile {
  /// Creates an onboarding profile for a user.
  const OnboardingProfile({
    required this.userId,
    required this.createdAt,
    required this.lastUpdated,
    this.primaryDemographic,
    this.secondaryDemographics = const [],
    this.personalityType,
    this.preferredPrizes = const [],
    this.riskTolerance = RiskTolerance.moderate,
    this.timeAvailability = TimeAvailability.sporadic,
    this.socialPreference = SocialPreference.solo_player,
    this.totalPoints = 0,
    this.completedSteps = const [],
    this.unlockedAchievements = const [],
    this.customAttributes = const {},
  });

  /// Creates an [OnboardingProfile] from a JSON map.
  factory OnboardingProfile.fromJson(Map<String, dynamic> json) =>
      OnboardingProfile(
        userId: json['userId'] ?? '',
        primaryDemographic: json['primaryDemographic'] != null
            ? UserDemographic.values.firstWhere(
                (d) => d.name == json['primaryDemographic'],
                orElse: () => UserDemographic.millennials,
              )
            : null,
        secondaryDemographics: (json['secondaryDemographics'] as List<dynamic>?)
                ?.map(
                  (d) => UserDemographic.values.firstWhere(
                    (demo) => demo.name == d,
                    orElse: () => UserDemographic.millennials,
                  ),
                )
                .toList() ??
            [],
        personalityType: json['personalityType'] != null
            ? PersonalityType.values.firstWhere(
                (p) => p.name == json['personalityType'],
                orElse: () => PersonalityType.casual_browser,
              )
            : null,
        preferredPrizes: (json['preferredPrizes'] as List<dynamic>?)
                ?.map(
                  (p) => PrizeCategory.values.firstWhere(
                    (prize) => prize.name == p,
                    orElse: () => PrizeCategory.cash,
                  ),
                )
                .toList() ??
            [],
        riskTolerance: RiskTolerance.values.firstWhere(
          (r) => r.name == json['riskTolerance'],
          orElse: () => RiskTolerance.moderate,
        ),
        timeAvailability: TimeAvailability.values.firstWhere(
          (t) => t.name == json['timeAvailability'],
          orElse: () => TimeAvailability.sporadic,
        ),
        socialPreference: SocialPreference.values.firstWhere(
          (s) => s.name == json['socialPreference'],
          orElse: () => SocialPreference.solo_player,
        ),
        totalPoints: json['totalPoints'] ?? 0,
        completedSteps: List<String>.from(json['completedSteps'] ?? []),
        unlockedAchievements:
            List<String>.from(json['unlockedAchievements'] ?? []),
        createdAt: DateTime.parse(
            json['createdAt'] ?? DateTime.now().toIso8601String()),
        lastUpdated: DateTime.parse(
          json['lastUpdated'] ?? DateTime.now().toIso8601String(),
        ),
        customAttributes:
            Map<String, dynamic>.from(json['customAttributes'] ?? {}),
      );

  /// Unique identifier for the user.
  final String userId;

  /// User's primary demographic.
  final UserDemographic? primaryDemographic;

  /// List of user's secondary demographics.
  final List<UserDemographic> secondaryDemographics;

  /// User's personality type.
  final PersonalityType? personalityType;

  /// List of user's preferred prize categories.
  final List<PrizeCategory> preferredPrizes;

  /// User's risk tolerance level.
  final RiskTolerance riskTolerance;

  /// User's time availability pattern.
  final TimeAvailability timeAvailability;

  /// User's social preference.
  final SocialPreference socialPreference;

  /// Total points earned by the user.
  final int totalPoints;

  /// List of IDs of completed onboarding steps.
  final List<String> completedSteps;

  /// List of IDs of unlocked achievements.
  final List<String> unlockedAchievements;

  /// Timestamp of profile creation.
  final DateTime createdAt;

  /// Timestamp of last profile update.
  final DateTime lastUpdated;

  /// Any custom attributes associated with the user's profile.
  final Map<String, dynamic> customAttributes;

  /// Creates a copy of this [OnboardingProfile] with the given fields replaced with the new values.
  OnboardingProfile copyWith({
    String? userId,
    UserDemographic? primaryDemographic,
    List<UserDemographic>? secondaryDemographics,
    PersonalityType? personalityType,
    List<PrizeCategory>? preferredPrizes,
    RiskTolerance? riskTolerance,
    TimeAvailability? timeAvailability,
    SocialPreference? socialPreference,
    int? totalPoints,
    List<String>? completedSteps,
    List<String>? unlockedAchievements,
    DateTime? createdAt,
    DateTime? lastUpdated,
    Map<String, dynamic>? customAttributes,
  }) =>
      OnboardingProfile(
        userId: userId ?? this.userId,
        primaryDemographic: primaryDemographic ?? this.primaryDemographic,
        secondaryDemographics:
            secondaryDemographics ?? this.secondaryDemographics,
        personalityType: personalityType ?? this.personalityType,
        preferredPrizes: preferredPrizes ?? this.preferredPrizes,
        riskTolerance: riskTolerance ?? this.riskTolerance,
        timeAvailability: timeAvailability ?? this.timeAvailability,
        socialPreference: socialPreference ?? this.socialPreference,
        totalPoints: totalPoints ?? this.totalPoints,
        completedSteps: completedSteps ?? this.completedSteps,
        unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
        createdAt: createdAt ?? this.createdAt,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        customAttributes: customAttributes ?? this.customAttributes,
      );

  /// Converts this [OnboardingProfile] to a JSON map.
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'primaryDemographic': primaryDemographic?.name,
        'secondaryDemographics':
            secondaryDemographics.map((d) => d.name).toList(),
        'personalityType': personalityType?.name,
        'preferredPrizes': preferredPrizes.map((p) => p.name).toList(),
        'riskTolerance': riskTolerance.name,
        'timeAvailability': timeAvailability.name,
        'socialPreference': socialPreference.name,
        'totalPoints': totalPoints,
        'completedSteps': completedSteps,
        'unlockedAchievements': unlockedAchievements,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
        'customAttributes': customAttributes,
      };
}

/// Achievement data model
class OnboardingAchievement {
  /// Creates an achievement.
  const OnboardingAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.pointsReward = 100,
    this.requirements = const [],
    this.isSecret = false,
    this.imageUrl,
  });

  /// Unique identifier for the achievement.
  final String id;

  /// Title of the achievement.
  final String title;

  /// Description of the achievement.
  final String description;

  /// Icon to display for the achievement.
  final IconData icon;

  /// Color associated with the achievement.
  final Color color;

  /// Points awarded for unlocking the achievement.
  final int pointsReward;

  /// List of step IDs required to unlock the achievement.
  final List<String> requirements;

  /// Indicates if the achievement is a secret.
  final bool isSecret;

  /// URL of an image to display for the achievement.
  final String? imageUrl;
}

/// Social proof data for building trust
class SocialProofData {
  /// Creates a social proof data object.
  const SocialProofData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.avatarUrl,
    this.location,
    this.data = const {},
  });

  /// Type of social proof ('winner', 'testimonial', 'stat')
  final String type; // 'winner', 'testimonial', 'stat'

  /// Title of the social proof
  final String title;

  /// Subtitle of the social proof
  final String subtitle;

  /// URL of an avatar to display.
  final String? avatarUrl;

  /// Location associated with the social proof.
  final String? location;

  /// Timestamp of the social proof event.
  final DateTime timestamp;

  /// Any custom data associated with the social proof.
  final Map<String, dynamic> data;
}

/// Trust indicator for security
class TrustIndicator {
  /// Creates a trust indicator.
  const TrustIndicator({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.certificationUrl,
    this.isVerified = true,
  });

  /// Unique identifier for the trust indicator.
  final String id;

  /// Title of the trust indicator.
  final String title;

  /// Description of the trust indicator.
  final String description;

  /// Icon to display for the trust indicator.
  final IconData icon;

  /// Color associated with the trust indicator.
  final Color color;

  /// URL of a certification associated with the indicator.
  final String? certificationUrl;

  /// Indicates if the trust indicator is verified.
  final bool isVerified;
}

/// Extension methods for demographic targeting
extension UserDemographicExtensions on UserDemographic {
  /// Get preferred animation speed based on demographic
  Duration get preferredAnimationSpeed {
    switch (this) {
      case UserDemographic.genZ:
        return const Duration(milliseconds: 200); // Fast, snappy
      case UserDemographic.millennials:
        return const Duration(milliseconds: 400); // Smooth, polished
      case UserDemographic.genX:
        return const Duration(milliseconds: 600); // Steady, reliable
      case UserDemographic.boomers:
        return const Duration(milliseconds: 800); // Slower, clearer
      case UserDemographic.gamingEnthusiasts:
        return const Duration(milliseconds: 150); // Ultra-fast
      default:
        return const Duration(milliseconds: 400); // Default
    }
  }

  /// Get preferred color scheme based on demographic
  List<Color> get preferredColors {
    switch (this) {
      case UserDemographic.genZ:
        return [Colors.purple, Colors.pink, Colors.cyan];
      case UserDemographic.millennials:
        return [Colors.orange, Colors.deepOrange, Colors.amber];
      case UserDemographic.genX:
        return [Colors.blue, Colors.indigo, Colors.blueGrey];
      case UserDemographic.boomers:
        return [Colors.green, Colors.teal, Colors.lightGreen];
      case UserDemographic.gamingEnthusiasts:
        return [Colors.red, Colors.cyan, Colors.purple];
      case UserDemographic.highIncome:
        return [Colors.amber, Colors.black, Colors.white];
      default:
        return [Colors.cyan, Colors.blue, Colors.purple];
    }
  }

  /// Get motivational messages targeted to demographic
  List<String> get motivationalMessages {
    switch (this) {
      case UserDemographic.genZ:
        return [
          'About to change your whole vibe ✨',
          'Your main character moment starts now',
          'Time to level up your life',
          'No cap, this is going to be epic',
        ];
      case UserDemographic.millennials:
        return [
          'Finally, a side hustle that actually works',
          'Your financial freedom journey starts here',
          'Time to make your money work for you',
          'Building generational wealth, one win at a time',
        ];
      case UserDemographic.genX:
        return [
          'Smart financial decisions start here',
          "Secure your family's future",
          'Proven strategies for real results',
          'Trustworthy opportunities for stable growth',
        ];
      case UserDemographic.boomers:
        return [
          'Enjoy the retirement you deserve',
          'Simple, secure, and rewarding',
          'Your golden years just got brighter',
          'Safe and trusted by thousands',
        ];
      default:
        return [
          'Your winning streak starts now',
          'Ready to change your life?',
          'Unlock your potential today',
          'Success is just a click away',
        ];
    }
  }
}
