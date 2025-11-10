import 'dart:convert';
import 'package:flutter/material.dart';

import '../utils/logger.dart';

class AppSettings {
  // Appearance Settings
  final double fontSize;
  final bool compactMode;
  final bool reducedAnimations;
  final bool highContrast;
  final String accentColor;

  // Main Settings
  final bool personalizedFeedFirst;
  final bool autoPlayVideos;
  final bool hapticFeedback;
  final String defaultView;

  const AppSettings({
    // Appearance defaults
    this.fontSize = 16.0,
    this.compactMode = false,
    this.reducedAnimations = false,
    this.highContrast = false,
    this.accentColor = 'cyan',

    // Main settings defaults
    this.personalizedFeedFirst = false,
    this.autoPlayVideos = true,
    this.hapticFeedback = true,
    this.defaultView = 'Grid',
  });

  // Copy with method for immutable updates
  AppSettings copyWith({
    double? fontSize,
    bool? compactMode,
    bool? reducedAnimations,
    bool? highContrast,
    String? accentColor,
    bool? personalizedFeedFirst,
    bool? autoPlayVideos,
    bool? hapticFeedback,
    String? defaultView,
  }) {
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      compactMode: compactMode ?? this.compactMode,
      reducedAnimations: reducedAnimations ?? this.reducedAnimations,
      highContrast: highContrast ?? this.highContrast,
      accentColor: accentColor ?? this.accentColor,
      personalizedFeedFirst:
          personalizedFeedFirst ?? this.personalizedFeedFirst,
      autoPlayVideos: autoPlayVideos ?? this.autoPlayVideos,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      defaultView: defaultView ?? this.defaultView,
    );
  }

  // Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'compactMode': compactMode,
        'reducedAnimations': reducedAnimations,
        'highContrast': highContrast,
        'accentColor': accentColor,
        'personalizedFeedFirst': personalizedFeedFirst,
        'autoPlayVideos': autoPlayVideos,
        'hapticFeedback': hapticFeedback,
        'defaultView': defaultView,
      };

  // Create from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
        compactMode: json['compactMode'] as bool? ?? false,
        reducedAnimations: json['reducedAnimations'] as bool? ?? false,
        highContrast: json['highContrast'] as bool? ?? false,
        accentColor: json['accentColor'] as String? ?? 'cyan',
        personalizedFeedFirst: json['personalizedFeedFirst'] as bool? ?? false,
        autoPlayVideos: json['autoPlayVideos'] as bool? ?? true,
        hapticFeedback: json['hapticFeedback'] as bool? ?? true,
        defaultView: json['defaultView'] as String? ?? 'Grid',
      );

  // Convert to JSON string for SharedPreferences
  String toJsonString() => jsonEncode(toJson());

  // Create from JSON string
  factory AppSettings.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return AppSettings.fromJson(json);
    } catch (e) {
      logger.e('Error parsing settings JSON', error: e);
      return const AppSettings(); // Return default settings on error
    }
  }

  // Get accent color as Flutter Color
  Color get accentColorValue {
    switch (accentColor) {
      case 'cyan':
        return const Color(0xFF64FFDA);
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      default:
        return const Color(0xFF64FFDA); // Default to cyan
    }
  }

  // Get font size scale factor
  double get fontSizeScale => fontSize / 16.0; // Base font size is 16

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppSettings &&
        other.fontSize == fontSize &&
        other.compactMode == compactMode &&
        other.reducedAnimations == reducedAnimations &&
        other.highContrast == highContrast &&
        other.accentColor == accentColor &&
        other.personalizedFeedFirst == personalizedFeedFirst &&
        other.autoPlayVideos == autoPlayVideos &&
        other.hapticFeedback == hapticFeedback &&
        other.defaultView == defaultView;
  }

  @override
  int get hashCode => Object.hash(
        fontSize,
        compactMode,
        reducedAnimations,
        highContrast,
        accentColor,
        personalizedFeedFirst,
        autoPlayVideos,
        hapticFeedback,
        defaultView,
      );

  @override
  String toString() => 'AppSettings(fontSize: $fontSize, compactMode: $compactMode, '
      'reducedAnimations: $reducedAnimations, highContrast: $highContrast, '
      'accentColor: $accentColor, personalizedFeedFirst: $personalizedFeedFirst, '
      'autoPlayVideos: $autoPlayVideos, hapticFeedback: $hapticFeedback, '
      'defaultView: $defaultView)';
}
