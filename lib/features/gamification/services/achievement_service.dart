import 'package:flutter/material.dart' hide Badge;

import '../models/badge_model.dart';

class AchievementService {
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
  ];

  Future<List<Badge>> getAchievements() async {
    // For now, returning the static list.
    // Later, this can be extended to fetch from Firestore and check against user's unlocked achievements.
    return allBadges;
  }

  // Helper to get badge metadata by ID
  static Badge? getBadgeById(String badgeId) {
    try {
      return allBadges.firstWhere((badge) => badge.id == badgeId);
    } catch (e) {
      return null; // Badge ID not found
    }
  }
}
