import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

class UserPreferencesService {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keySelectedCategories = 'selected_categories';
  static const String _keyMinPrizeValue = 'min_prize_value';
  static const String _keyMaxPrizeValue = 'max_prize_value';
  static const String _keyLocationFilter = 'location_filter';
  static const String _keyAgeFilter = 'age_filter';
  static const String _keySortPreference = 'sort_preference';
  static const String _keyAutoEnterEnabled = 'auto_enter_enabled';
  static const String _keyDailyNotificationTime = 'daily_notification_time';
  static const String _keyLanguage = 'language';
  static const String _keyOnboardingCompleted = 'onboarding_completed';

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      logger.d('UserPreferencesService initialized');
    } catch (e) {
      logger.e('Failed to initialize UserPreferencesService', error: e);
    }
  }

  Future<void> setThemeMode(String mode) async {
    try {
      await _prefs?.setString(_keyThemeMode, mode);
      logger.d('Theme mode set to: $mode');
    } catch (e) {
      logger.e('Failed to set theme mode', error: e);
    }
  }

  String getThemeMode() => _prefs?.getString(_keyThemeMode) ?? 'system';

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      await _prefs?.setBool(_keyNotificationsEnabled, enabled);
      logger.d('Notifications enabled: $enabled');
    } catch (e) {
      logger.e('Failed to set notifications enabled', error: e);
    }
  }

  bool getNotificationsEnabled() =>
      _prefs?.getBool(_keyNotificationsEnabled) ?? true;

  Future<void> setSelectedCategories(List<String> categories) async {
    try {
      await _prefs?.setStringList(_keySelectedCategories, categories);
      logger.d('Selected categories: $categories');
    } catch (e) {
      logger.e('Failed to set selected categories', error: e);
    }
  }

  List<String> getSelectedCategories() =>
      _prefs?.getStringList(_keySelectedCategories) ?? [];

  Future<void> setMinPrizeValue(int value) async {
    try {
      await _prefs?.setInt(_keyMinPrizeValue, value);
      logger.d('Min prize value: $value');
    } catch (e) {
      logger.e('Failed to set min prize value', error: e);
    }
  }

  int getMinPrizeValue() => _prefs?.getInt(_keyMinPrizeValue) ?? 0;

  Future<void> setMaxPrizeValue(int value) async {
    try {
      await _prefs?.setInt(_keyMaxPrizeValue, value);
      logger.d('Max prize value: $value');
    } catch (e) {
      logger.e('Failed to set max prize value', error: e);
    }
  }

  int getMaxPrizeValue() => _prefs?.getInt(_keyMaxPrizeValue) ?? 1000000;

  Future<void> setLocationFilter(String location) async {
    try {
      await _prefs?.setString(_keyLocationFilter, location);
      logger.d('Location filter: $location');
    } catch (e) {
      logger.e('Failed to set location filter', error: e);
    }
  }

  String getLocationFilter() => _prefs?.getString(_keyLocationFilter) ?? '';

  Future<void> setAgeFilter(int age) async {
    try {
      await _prefs?.setInt(_keyAgeFilter, age);
      logger.d('Age filter: $age');
    } catch (e) {
      logger.e('Failed to set age filter', error: e);
    }
  }

  int getAgeFilter() => _prefs?.getInt(_keyAgeFilter) ?? 18;

  Future<void> setSortPreference(String sortBy) async {
    try {
      await _prefs?.setString(_keySortPreference, sortBy);
      logger.d('Sort preference: $sortBy');
    } catch (e) {
      logger.e('Failed to set sort preference', error: e);
    }
  }

  String getSortPreference() =>
      _prefs?.getString(_keySortPreference) ?? 'end_date';

  Future<void> setAutoEnterEnabled(bool enabled) async {
    try {
      await _prefs?.setBool(_keyAutoEnterEnabled, enabled);
      logger.d('Auto-enter enabled: $enabled');
    } catch (e) {
      logger.e('Failed to set auto-enter enabled', error: e);
    }
  }

  bool getAutoEnterEnabled() => _prefs?.getBool(_keyAutoEnterEnabled) ?? false;

  Future<void> setDailyNotificationTime(int hour) async {
    try {
      await _prefs?.setInt(_keyDailyNotificationTime, hour);
      logger.d('Daily notification time: $hour:00');
    } catch (e) {
      logger.e('Failed to set daily notification time', error: e);
    }
  }

  int getDailyNotificationTime() =>
      _prefs?.getInt(_keyDailyNotificationTime) ?? 9;

  Future<void> setLanguage(String languageCode) async {
    try {
      await _prefs?.setString(_keyLanguage, languageCode);
      logger.d('Language: $languageCode');
    } catch (e) {
      logger.e('Failed to set language', error: e);
    }
  }

  String getLanguage() => _prefs?.getString(_keyLanguage) ?? 'en';

  Future<void> setOnboardingCompleted(bool completed) async {
    try {
      await _prefs?.setBool(_keyOnboardingCompleted, completed);
      logger.d('Onboarding completed: $completed');
    } catch (e) {
      logger.e('Failed to set onboarding completed', error: e);
    }
  }

  bool getOnboardingCompleted() =>
      _prefs?.getBool(_keyOnboardingCompleted) ?? false;

  Future<void> clearAllPreferences() async {
    try {
      await _prefs?.clear();
      logger.d('All preferences cleared');
    } catch (e) {
      logger.e('Failed to clear preferences', error: e);
    }
  }

  Map<String, dynamic> getAllPreferences() => {
        'theme_mode': getThemeMode(),
        'notifications_enabled': getNotificationsEnabled(),
        'selected_categories': getSelectedCategories(),
        'min_prize_value': getMinPrizeValue(),
        'max_prize_value': getMaxPrizeValue(),
        'location_filter': getLocationFilter(),
        'age_filter': getAgeFilter(),
        'sort_preference': getSortPreference(),
        'auto_enter_enabled': getAutoEnterEnabled(),
        'daily_notification_time': getDailyNotificationTime(),
        'language': getLanguage(),
        'onboarding_completed': getOnboardingCompleted(),
      };
}

final userPreferencesService = UserPreferencesService();
