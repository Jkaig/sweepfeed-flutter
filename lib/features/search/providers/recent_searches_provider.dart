import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kRecentSearchesKey = 'recent_searches';
const _kMaxRecentSearches = 10;

/// Provider for managing recent search history
final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>(
  RecentSearchesNotifier.new,
);

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier(this._ref) : super([]) {
    _loadRecentSearches();
  }

  final Ref _ref;

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_kRecentSearchesKey) ?? [];
      state = searches;
    } catch (e) {
      state = [];
    }
  }

  Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || trimmed.length < 3) return;

    // Remove if already exists (will be re-added at top)
    final newSearches = state.where((s) => s != trimmed).toList();

    // Add to beginning
    newSearches.insert(0, trimmed);

    // Keep only max recent searches
    if (newSearches.length > _kMaxRecentSearches) {
      newSearches.removeRange(_kMaxRecentSearches, newSearches.length);
    }

    state = newSearches;
    await _saveSearches();
  }

  Future<void> removeSearch(String query) async {
    state = state.where((s) => s != query).toList();
    await _saveSearches();
  }

  Future<void> clearAll() async {
    state = [];
    await _saveSearches();
  }

  Future<void> _saveSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kRecentSearchesKey, state);
    } catch (e) {
      // Silently fail
    }
  }
}

/// Popular search suggestions (could be fetched from backend in future)
final popularSearchesProvider = Provider<List<String>>((ref) => [
      'Cash prizes',
      'Gift cards',
      'Electronics',
      'Travel',
      'Cars',
      'Amazon',
      'Nintendo',
      'iPhone',
    ],);
