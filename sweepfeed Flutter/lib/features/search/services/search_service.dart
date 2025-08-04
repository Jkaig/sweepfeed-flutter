import 'package:flutter/foundation.dart';
import '../../contests/models/sweepstakes_model.dart';

class SearchService extends ChangeNotifier {
  List<Sweepstakes> _allSweepstakes = [];
  List<Sweepstakes> _filteredSweepstakes = [];
  String _currentSearchQuery = '';
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedEntryMethods = {};

  List<Sweepstakes> get allSweepstakes => _allSweepstakes;
  List<Sweepstakes> get filteredSweepstakes => _filteredSweepstakes;
  String get currentSearchQuery => _currentSearchQuery;
  Set<String> get selectedCategories => _selectedCategories;
  Set<String> get selectedEntryMethods => _selectedEntryMethods;

  void updateSweepstakes(List<Sweepstakes> sweepstakes) {
    _allSweepstakes = sweepstakes;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _currentSearchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void toggleCategory(String category) {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else {
      _selectedCategories.add(category);
    }
    _applyFilters();
    notifyListeners();
  }

  void toggleEntryMethod(String method) {
    if (_selectedEntryMethods.contains(method)) {
      _selectedEntryMethods.remove(method);
    } else {
      _selectedEntryMethods.add(method);
    }
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _currentSearchQuery = '';
    _selectedCategories.clear();
    _selectedEntryMethods.clear();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredSweepstakes = _allSweepstakes.where((sweepstakes) {
      // Apply text search
      if (_currentSearchQuery.isNotEmpty) {
        final matchesTitle =
            sweepstakes.title.toLowerCase().contains(_currentSearchQuery);
        final matchesSponsor =
            sweepstakes.sponsor.toLowerCase().contains(_currentSearchQuery);
        if (!matchesTitle && !matchesSponsor) return false;
      }

      // Apply category filters
      if (_selectedCategories.isNotEmpty) {
        bool hasMatchingCategory = false;
        for (final category in sweepstakes.categories) {
          if (_selectedCategories.contains(category)) {
            hasMatchingCategory = true;
            break;
          }
        }
        if (!hasMatchingCategory) return false;
      }

      // Apply entry method filters - use frequency instead
      if (_selectedEntryMethods.isNotEmpty) {
        final String entryFrequency = sweepstakes.frequencyText;
        if (!_selectedEntryMethods.contains(entryFrequency)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by end date (closest first)
    _filteredSweepstakes.sort((a, b) => a.endDate.compareTo(b.endDate));
  }
}
