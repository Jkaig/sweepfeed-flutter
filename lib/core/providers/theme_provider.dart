import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Key for storing theme preference
const String _themePreferenceKey = 'app_theme_mode';

/// Notifier for managing and persisting the app's theme mode using ChangeNotifier.
class ThemeProvider extends ChangeNotifier {
  // Default theme

  ThemeProvider(this._prefs) {
    _loadThemeMode();
  }
  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void _loadThemeMode() {
    final themeIndex = _prefs.getInt(_themePreferenceKey);
    if (themeIndex != null &&
        themeIndex >= 0 &&
        themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    } else {
      _themeMode = ThemeMode
          .system; // Default to system theme if nothing is stored or invalid
    }
    // No need to call notifyListeners() here as this is typically called during construction
    // and the initial value is used when the provider is first read.
    // If this were an async load after construction, then notifyListeners() would be needed.
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      try {
        await _prefs.setInt(_themePreferenceKey, mode.index);
      } catch (e) {
        // Handle potential errors during save, e.g., log them
      }
      notifyListeners(); // Notify listeners about the change
    }
  }
}
