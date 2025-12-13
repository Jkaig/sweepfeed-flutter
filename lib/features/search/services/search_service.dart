import 'package:flutter/foundation.dart';
import '../../../core/models/contest.dart';

class SearchService extends ChangeNotifier {
  List<Contest> _allContest = [];
  List<Contest> _filteredContest = [];
  String _currentSearchQuery = '';
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedEntryMethods = {};

  List<Contest> get allContest => _allContest;
  List<Contest> get filteredContest => _filteredContest;
  String get currentSearchQuery => _currentSearchQuery;
  Set<String> get selectedCategories => _selectedCategories;
  Set<String> get selectedEntryMethods => _selectedEntryMethods;

  void updateContest(List<Contest> contests) {
    _allContest = contests;
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
    _filteredContest = _allContest.where((contests) {
      // Apply text search
      if (_currentSearchQuery.isNotEmpty) {
        final matchesTitle =
            contests.title.toLowerCase().contains(_currentSearchQuery);
        final matchesSponsor =
            contests.sponsor.toLowerCase().contains(_currentSearchQuery);
        if (!matchesTitle && !matchesSponsor) return false;
      }

      // Apply category filters
      if (_selectedCategories.isNotEmpty) {
        var hasMatchingCategory = false;
        for (final category in contests.categories) {
          if (_selectedCategories.contains(category)) {
            hasMatchingCategory = true;
            break;
          }
        }
        if (!hasMatchingCategory) return false;
      }

      // Apply entry method filters - use frequency instead
      if (_selectedEntryMethods.isNotEmpty) {
        final entryFrequency = contests.frequency;
        if (!_selectedEntryMethods.contains(entryFrequency)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by end date (closest first)
    _filteredContest.sort((a, b) => a.endDate.compareTo(b.endDate));
  }
}
