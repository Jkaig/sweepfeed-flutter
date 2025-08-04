import 'package:flutter/material.dart'; // For IconData
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sweepfeed_app/features/auth/services/auth_service.dart'; // To call awardBadge

// --- Badge Definition ---
class Badge {
  final String id;
  final String name;
  final String description;
  final IconData icon; // Using IconData for placeholder icons

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

// --- Badge Definitions ---
// It's good practice to define badge IDs as constants as well.
class BadgeIds {
  static const String welcomeAboard = 'welcome_aboard';
  static const String entryEnthusiast = 'entry_enthusiast';
  static const String referralRockstar = 'referral_rockstar';
  static const String sharpshooter = 'sharpshooter';
  // Add more badge IDs here if needed, e.g., dailyDedication
}

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Assuming AuthService is a singleton or provided via DI.
  // For simplicity, creating an instance here, but DI is preferred in larger apps.
  final AuthService _authService = AuthService(); 

  // List of all available badges in the app
  static final List<Badge> allBadges = [
    const Badge(
      id: BadgeIds.welcomeAboard,
      name: 'Welcome Aboard!',
      description: 'Awarded for successfully creating your SweepFeed account.',
      icon: Icons.sailing_outlined,
    ),
    const Badge(
      id: BadgeIds.entryEnthusiast,
      name: 'Entry Enthusiast',
      description: 'Awarded for entering 10 contests.',
      icon: Icons.star_outline,
    ),
    const Badge(
      id: BadgeIds.referralRockstar,
      name: 'Referral Rockstar',
      description: 'Awarded for successfully referring 5 friends.',
      icon: Icons.people_alt_outlined,
    ),
    const Badge(
      id: BadgeIds.sharpshooter,
      name: 'Sharpshooter',
      description: 'Awarded for completely filling out your user profile.',
      icon: Icons.person_pin_circle_outlined,
    ),
    // Example for a daily check-in badge (if feature existed)
    // const Badge(
    //   id: 'daily_dedication',
    //   name: 'Daily Dedication',
    //   description: 'Awarded for 7 consecutive daily check-ins.',
    //   icon: Icons.calendar_today_outlined,
    // ),
  ];

  // Helper to get badge metadata by ID
  static Badge? getBadgeById(String badgeId) {
    try {
      return allBadges.firstWhere((badge) => badge.id == badgeId);
    } catch (e) {
      return null; // Badge ID not found
    }
  }

  Future<DocumentSnapshot?> _getUserDocument(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc : null;
    } catch (e) {
      print("Error fetching user document for gamification: $e");
      return null;
    }
  }

  Future<List<String>> _getCollectedBadges(String userId) async {
    final userDoc = await _getUserDocument(userId);
    if (userDoc != null && userDoc.data() != null) {
      final data = userDoc.data() as Map<String, dynamic>;
      // Path to badges: gamification -> badges -> collected
      final gamificationData = data['gamification'] as Map<String, dynamic>?;
      final badgesData = gamificationData?['badges'] as Map<String, dynamic>?;
      final collected = badgesData?['collected'] as List<dynamic>?;
      return collected?.map((item) => item.toString()).toList() ?? [];
    }
    return [];
  }

  Future<void> _checkAndAward(String userId, String badgeId, bool criteriaMet) async {
    if (!criteriaMet) return;

    final collectedBadges = await _getCollectedBadges(userId);
    if (!collectedBadges.contains(badgeId)) {
      // User hasn't collected this badge yet, award it.
      // AuthService.awardBadge also handles adding points.
      await _authService.awardBadge(badgeId); 
      print("Awarded badge: $badgeId to user: $userId");
      // Optionally, show an in-app notification here.
    }
  }

  // --- Specific Badge Checking Methods ---

  Future<void> checkAndAwardWelcomeAboard(String userId) async {
    // This badge is typically awarded right after account creation.
    // The criteria is simply that the user exists.
    await _checkAndAward(userId, BadgeIds.welcomeAboard, true);
  }

  Future<void> checkAndAwardEntryEnthusiast(String userId) async {
    final userDoc = await _getUserDocument(userId);
    if (userDoc == null) return;
    final data = userDoc.data() as Map<String, dynamic>;
    final totalEntries = data['stats']?['totalEntries'] as int? ?? 0;
    await _checkAndAward(userId, BadgeIds.entryEnthusiast, totalEntries >= 10);
  }
  
  Future<void> checkAndAwardReferralRockstar(String userId) async {
    // This check should ideally be triggered when a referral is confirmed and count is updated.
    final userDoc = await _getUserDocument(userId);
    if (userDoc == null) return;
    final data = userDoc.data() as Map<String, dynamic>;
    final referralCount = data['referralCount'] as int? ?? 0; // Assuming 'referralCount' is at the root
    await _checkAndAward(userId, BadgeIds.referralRockstar, referralCount >= 5);
  }

  Future<void> checkAndAwardSharpshooter(String userId) async {
    // This requires fetching the user's profile data to check for completeness.
    // The definition of "complete" needs to be established.
    // Let's assume it means having a bio, location, and at least one interest.
    // This would use the 'userProfiles' collection, not the 'users' collection directly for these fields.
    
    // For 'userProfiles' data:
    final userProfileDoc = await _firestore.collection('userProfiles').doc(userId).get();
    bool isProfileComplete = false;
    if (userProfileDoc.exists) {
        final profileData = userProfileDoc.data() as Map<String, dynamic>;
        final bio = profileData['bio'] as String?;
        final location = profileData['location'] as String?;
        final interests = profileData['interests'] as List<dynamic>?;

        isProfileComplete = (bio != null && bio.isNotEmpty) &&
                            (location != null && location.isNotEmpty) &&
                            (interests != null && interests.isNotEmpty);
    }
    
    // Now, check and award the badge based on this completeness.
    // The badge itself is stored in the 'users' collection under 'gamification.badges.collected'.
    await _checkAndAward(userId, BadgeIds.sharpshooter, isProfileComplete);
  }

  // Example for Daily Dedication (if such a feature existed)
  // Future<void> checkAndAwardDailyDedication(String userId, int consecutiveCheckIns) async {
  //   await _checkAndAward(userId, 'daily_dedication', consecutiveCheckIns >= 7);
  // }
}
