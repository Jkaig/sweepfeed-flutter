import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  UserProfile({
    required this.id,
    required this.reference,
    this.name,
    this.email,
    this.profilePictureUrl,
    this.bio,
    this.location,
    this.interests = const [],
    this.favoriteBrands = const [],
    this.totalEntries = 0,
    this.activeEntries = 0,
    this.totalWins = 0,
    this.winRate = 0.0,
    this.points = 0,
    this.streak = 0,
    this.level = 1,
    this.rank = 'Bronze',
    this.experience = 0,
    this.claimedRewards = const [],
    this.premiumUntil,
    this.negativePreferences = const [],
    this.unlockedBadgeIds = const [],
    this.onboardingCompleted = false,
    this.selectedCharityIds = const [],
    this.sweepDust = 0,
    this.contestsEntered = 0,
    this.monthlyEntries = 0,
    this.wins = 0,
    this.likedContests = const [],
    this.savedContests = const [],
    this.tier = 'free',
    this.selectedCharityId,
    this.signInProvider,
    this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      name: data['name'] as String?,
      email: data['email'] as String?,
      profilePictureUrl: data['profilePictureUrl'] as String?,
      bio: data['bio'] as String?,
      location: data['location'] as String?,
      interests: (data['interests'] is List)
          ? List<String>.from(data['interests'])
          : [],
      favoriteBrands: (data['favoriteBrands'] is List)
          ? List<String>.from(data['favoriteBrands'])
          : [],
      totalEntries: (data['totalEntries'] as num?)?.toInt() ?? 0,
      activeEntries: (data['activeEntries'] as num?)?.toInt() ?? 0,
      totalWins: (data['totalWins'] as num?)?.toInt() ?? 0,
      winRate: (data['winRate'] as num?)?.toDouble() ?? 0.0,
      points: (data['points'] as num?)?.toInt() ?? 0,
      streak: (data['streak'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
      rank: data['rank'] as String? ?? 'Bronze',
      experience: (data['experience'] as num?)?.toInt() ?? 0,
      claimedRewards: (data['claimedRewards'] is List)
          ? List<String>.from(data['claimedRewards'])
          : [],
      premiumUntil: data['premiumUntil'] as Timestamp?,
      negativePreferences: (data['negativePreferences'] is List)
          ? List<String>.from(data['negativePreferences'])
          : [],
      unlockedBadgeIds: (data['unlockedBadgeIds'] is List)
          ? List<String>.from(data['unlockedBadgeIds'])
          : [],
      onboardingCompleted: data['onboardingCompleted'] ?? false,
      selectedCharityIds: (data['selectedCharityIds'] is List)
          ? List<String>.from(data['selectedCharityIds'])
          : [],
      sweepDust: data['sweepDust'] ?? 0,
      contestsEntered: data['contestsEntered'] ?? 0,
      monthlyEntries: data['monthlyEntries'] ?? 0,
      wins: data['wins'] ?? 0,
      likedContests: (data['likedContests'] is List)
          ? List<String>.from(data['likedContests'])
          : [],
      savedContests: (data['savedContests'] is List)
          ? List<String>.from(data['savedContests'])
          : [],
      reference: doc.reference,
      tier: data['tier'] ?? 'free',
      selectedCharityId: data['selectedCharityId'] as String?,
      signInProvider: data['signInProvider'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
  final String id;
  final String? name;
  final String? email;
  final String? profilePictureUrl;
  final String? bio;
  final String? location;
  final List<String> interests;
  final List<String> favoriteBrands;
  final int totalEntries;
  final int activeEntries;
  final int totalWins;
  final double winRate;
  final int points;
  final int streak;
  final int level;
  final String rank;
  String get rankTitle => rank;
  final int experience;
  final List<String> claimedRewards;
      final Timestamp? premiumUntil;  final List<String> negativePreferences;
  final List<String> unlockedBadgeIds;
  final bool onboardingCompleted;
  final List<String> selectedCharityIds;
  final int sweepDust;
  final int contestsEntered;
  final int monthlyEntries;
  final int wins;
  final List<String> likedContests;
  final List<String> savedContests;
  final DocumentReference reference;
  final String tier;
  final String? selectedCharityId;
  final String? signInProvider;
  final Timestamp? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'profilePictureUrl': profilePictureUrl,
        'bio': bio,
        'location': location,
        'interests': interests,
        'favoriteBrands': favoriteBrands,
        'totalEntries': totalEntries,
        'activeEntries': activeEntries,
        'totalWins': totalWins,
        'winRate': winRate,
        'points': points,
        'streak': streak,
        'level': level,
        'rank': rank,
        'experience': experience,
        'claimedRewards': claimedRewards,
        'premiumUntil': premiumUntil,
        'negativePreferences': negativePreferences,
        'unlockedBadgeIds': unlockedBadgeIds,
        'onboardingCompleted': onboardingCompleted,
        'selectedCharityIds': selectedCharityIds,
        'sweepDust': sweepDust,
        'contestsEntered': contestsEntered,
        'monthlyEntries': monthlyEntries,
        'wins': wins,
        'likedContests': likedContests,
        'savedContests': savedContests,
        'tier': tier,
        'selectedCharityId': selectedCharityId,
        'signInProvider': signInProvider,
        'createdAt': createdAt,
      };

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePictureUrl,
    String? bio,
    String? location,
    List<String>? interests,
    List<String>? favoriteBrands,
    int? totalEntries,
    int? activeEntries,
    int? totalWins,
    double? winRate,
    int? points,
    int? streak,
    int? level,
    String? rank,
    int? experience,
    List<String>? claimedRewards,
    Timestamp? premiumUntil,
    List<String>? negativePreferences,
    List<String>? unlockedBadgeIds,
    bool? onboardingCompleted,
    List<String>? selectedCharityIds,
    int? sweepDust,
    int? contestsEntered,
    int? monthlyEntries,
    int? wins,
    List<String>? likedContests,
    List<String>? savedContests,
    DocumentReference? reference,
    String? tier,
    String? selectedCharityId,
    String? signInProvider,
    Timestamp? createdAt,
  }) =>
      UserProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
        bio: bio ?? this.bio,
        location: location ?? this.location,
        interests: interests ?? this.interests,
        favoriteBrands: favoriteBrands ?? this.favoriteBrands,
        totalEntries: totalEntries ?? this.totalEntries,
        activeEntries: activeEntries ?? this.activeEntries,
        totalWins: totalWins ?? this.totalWins,
        winRate: winRate ?? this.winRate,
        points: points ?? this.points,
        streak: streak ?? this.streak,
        level: level ?? this.level,
        rank: rank ?? this.rank,
        experience: experience ?? this.experience,
        claimedRewards: claimedRewards ?? this.claimedRewards,
        premiumUntil: premiumUntil ?? this.premiumUntil,
        negativePreferences: negativePreferences ?? this.negativePreferences,
        unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        selectedCharityIds: selectedCharityIds ?? this.selectedCharityIds,
        sweepDust: sweepDust ?? this.sweepDust,
        contestsEntered: contestsEntered ?? this.contestsEntered,
        monthlyEntries: monthlyEntries ?? this.monthlyEntries,
        wins: wins ?? this.wins,
        likedContests: likedContests ?? this.likedContests,
        savedContests: savedContests ?? this.savedContests,
        reference: reference ?? this.reference,
        tier: tier ?? this.tier,
        selectedCharityId: selectedCharityId ?? this.selectedCharityId,
        signInProvider: signInProvider ?? this.signInProvider,
        createdAt: createdAt ?? this.createdAt,
      );
}
