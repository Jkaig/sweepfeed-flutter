
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageLimitsService with ChangeNotifier {
  static final UsageLimitsService _instance = UsageLimitsService._internal();
  factory UsageLimitsService() => _instance;
  UsageLimitsService._internal();

  // Configuration values
  static const int _maxFreeTierViewsPerDay = 15;
  static const int _maxFreeTierSavedItems = 5;
  static const int _maxFreeTierDailyEntries = 3;

  // SharedPreferences keys
  static const String _viewsCountKey = 'free_tier_views_count';
  static const String _viewsCountDateKey = 'free_tier_views_count_date';
  static const String _savedItemsCountKey = 'free_tier_saved_items_count';

  // Current usage counts
  int _viewsCount = 0;
  DateTime? _viewsCountDate;
  int _savedItemsCount = 0;

  // Getters
  int get viewsCount => _viewsCount;
  int get savedItemsCount => _savedItemsCount;
  int get viewsRemaining => _maxFreeTierViewsPerDay - _viewsCount;
  int get savedItemsRemaining => _maxFreeTierSavedItems - _savedItemsCount;

  bool get hasReachedViewLimit => _viewsCount >= _maxFreeTierViewsPerDay;
  bool get hasReachedSavedItemsLimit =>
      _savedItemsCount >= _maxFreeTierSavedItems;

  int get maxFreeTierViewsPerDay => _maxFreeTierViewsPerDay;
  int get maxFreeTierSavedItems => _maxFreeTierSavedItems;
  int get maxFreeTierDailyEntries => _maxFreeTierDailyEntries;

  // Initialize with stored values
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load views count, but reset if it's from a different day
    _viewsCount = prefs.getInt(_viewsCountKey) ?? 0;
    final viewsCountDateStr = prefs.getString(_viewsCountDateKey);

    if (viewsCountDateStr != null) {
      _viewsCountDate = DateTime.parse(viewsCountDateStr);

      // Check if views count is from today
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final viewsCountDay = DateTime(
          _viewsCountDate!.year, _viewsCountDate!.month, _viewsCountDate!.day);

      if (viewsCountDay.isBefore(today)) {
        // Reset views count for a new day
        _viewsCount = 0;
        _viewsCountDate = now;
        await _saveViewsCount();
      }
    } else {
      _viewsCountDate = DateTime.now();
      await _saveViewsCount();
    }

    // Load saved items count
    _savedItemsCount = prefs.getInt(_savedItemsCountKey) ?? 0;

    notifyListeners();
  }

  // Increment views count
  Future<bool> incrementViewsCount() async {
    if (_viewsCount >= _maxFreeTierViewsPerDay) {
      return false; // Already reached limit
    }

    _viewsCount++;
    await _saveViewsCount();
    notifyListeners();
    return true;
  }

  // Increment saved items count
  Future<bool> incrementSavedItemsCount() async {
    if (_savedItemsCount >= _maxFreeTierSavedItems) {
      return false; // Already reached limit
    }

    _savedItemsCount++;
    await _saveSavedItemsCount();
    notifyListeners();
    return true;
  }

  // Decrement saved items count
  Future<void> decrementSavedItemsCount() async {
    if (_savedItemsCount > 0) {
      _savedItemsCount--;
      await _saveSavedItemsCount();
      notifyListeners();
    }
  }

  // Reset counts (e.g., when user subscribes)
  Future<void> resetLimits() async {
    _viewsCount = 0;
    _savedItemsCount = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_viewsCountKey, 0);
    await prefs.setInt(_savedItemsCountKey, 0);

    notifyListeners();
  }

  // Save views count to SharedPreferences
  Future<void> _saveViewsCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_viewsCountKey, _viewsCount);

    if (_viewsCountDate != null) {
      await prefs.setString(
          _viewsCountDateKey, _viewsCountDate!.toIso8601String());
    }
  }

  // Save saved items count to SharedPreferences
  Future<void> _saveSavedItemsCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_savedItemsCountKey, _savedItemsCount);
  }
}
