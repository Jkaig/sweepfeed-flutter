import 'package:flutter/material.dart';

class WinnerClass {
  const WinnerClass({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.abilities,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.stats,
    required this.bonusFeatures,
  });
  final String id;
  final String name;
  final String title;
  final String description;
  final List<String> abilities;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final Map<String, int> stats;
  final List<String> bonusFeatures;
}
