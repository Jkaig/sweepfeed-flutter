import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings_model.dart';
import '../utils/logger.dart';

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  static const String _settingsKey = 'app_settings';

  AppSettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        state = AppSettings.fromJsonString(settingsJson);
      }
    } catch (e) {
      logger.e('Error loading settings', error: e);
      // Keep default settings if loading fails
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, state.toJsonString());
    } catch (e) {
      logger.e('Error saving settings', error: e);
    }
  }

  // Font Size Methods
  Future<void> setFontSize(double fontSize) async {
    if (fontSize >= 12.0 && fontSize <= 24.0) {
      state = state.copyWith(fontSize: fontSize);
      await _saveSettings();
    }
  }

  // Compact Mode Methods
  Future<void> setCompactMode(bool enabled) async {
    state = state.copyWith(compactMode: enabled);
    await _saveSettings();
  }

  // Reduced Animations Methods
  Future<void> setReducedAnimations(bool enabled) async {
    state = state.copyWith(reducedAnimations: enabled);
    await _saveSettings();
  }

  // High Contrast Methods
  Future<void> setHighContrast(bool enabled) async {
    state = state.copyWith(highContrast: enabled);
    await _saveSettings();
  }

  // Accent Color Methods
  Future<void> setAccentColor(String color) async {
    const validColors = ['cyan', 'blue', 'green', 'purple', 'orange', 'pink'];
    if (validColors.contains(color)) {
      state = state.copyWith(accentColor: color);
      await _saveSettings();
    }
  }

  // Personalized Feed Methods
  Future<void> setPersonalizedFeedFirst(bool enabled) async {
    state = state.copyWith(personalizedFeedFirst: enabled);
    await _saveSettings();
  }

  // Auto Play Videos Methods
  Future<void> setAutoPlayVideos(bool enabled) async {
    state = state.copyWith(autoPlayVideos: enabled);
    await _saveSettings();
  }

  // Haptic Feedback Methods
  Future<void> setHapticFeedback(bool enabled) async {
    state = state.copyWith(hapticFeedback: enabled);
    await _saveSettings();
  }

  // Default View Methods
  Future<void> setDefaultView(String view) async {
    const validViews = ['Grid', 'List', 'Card'];
    if (validViews.contains(view)) {
      state = state.copyWith(defaultView: view);
      await _saveSettings();
    }
  }

  // Bulk update method for efficiency
  Future<void> updateSettings(AppSettings newSettings) async {
    state = newSettings;
    await _saveSettings();
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    state = const AppSettings();
    await _saveSettings();
  }

  // Getters for convenience
  double get fontSize => state.fontSize;
  bool get compactMode => state.compactMode;
  bool get reducedAnimations => state.reducedAnimations;
  bool get highContrast => state.highContrast;
  String get accentColor => state.accentColor;
  bool get personalizedFeedFirst => state.personalizedFeedFirst;
  bool get autoPlayVideos => state.autoPlayVideos;
  bool get hapticFeedback => state.hapticFeedback;
  String get defaultView => state.defaultView;

  // Get spacing based on compact mode
  double getSpacing([double defaultSpacing = 16.0]) {
    return compactMode ? defaultSpacing * 0.75 : defaultSpacing;
  }

  // Get padding based on compact mode
  double getPadding([double defaultPadding = 16.0]) {
    return compactMode ? defaultPadding * 0.75 : defaultPadding;
  }

  // Get animation duration based on reduced animations setting
  Duration getAnimationDuration(
      [Duration defaultDuration = const Duration(milliseconds: 300)]) {
    return reducedAnimations
        ? Duration(milliseconds: (defaultDuration.inMilliseconds * 0.5).round())
        : defaultDuration;
  }
}
