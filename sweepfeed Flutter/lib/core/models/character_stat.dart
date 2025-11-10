import 'package:flutter/material.dart';

class CharacterStat {
  const CharacterStat({
    required this.name,
    required this.description,
    required this.icon,
    required this.value,
    required this.color,
    this.maxValue = 100,
  });
  final String name;
  final String description;
  final IconData icon;
  final int value;
  final int maxValue;
  final Color color;
}
