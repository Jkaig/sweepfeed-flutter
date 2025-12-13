import 'package:flutter/material.dart';

class Badge {
  // Using IconData for placeholder icons

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
  final String id;
  final String name;
  final String description;
  final IconData icon;
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
