import 'dart:convert';
import 'package:flutter/services.dart';

class ContestDataService {
  factory ContestDataService() => _instance;
  ContestDataService._internal();
  static final ContestDataService _instance = ContestDataService._internal();

  List<Map<String, dynamic>> _contests = [];
  bool _isLoaded = false;

  Future<void> loadContests() async {
    if (_isLoaded) return;

    try {
      // Load the Flutter-optimized contest data
      final jsonString =
          await rootBundle.loadString('assets/FLUTTER_SWEEPFEED_DATA.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      _contests = List<Map<String, dynamic>>.from(jsonData['contests'] ?? []);
      _isLoaded = true;
    } catch (e) {
      // Fallback to empty list if loading fails
      _contests = [];
    }
  }

  List<Map<String, dynamic>> get allContests => _contests;

  List<Map<String, dynamic>> getFeaturedContests() =>
      _contests.where((c) => c['featured'] == true).toList();

  List<Map<String, dynamic>> getTrendingContests() =>
      _contests.where((c) => c['trending'] == true).toList();

  List<Map<String, dynamic>> getNewContests() =>
      _contests.where((c) => c['new'] == true).toList();

  List<Map<String, dynamic>> getContestsByCategory(String category) {
    if (category == 'all') return _contests;
    return _contests.where((c) => c['category'] == category).toList();
  }

  List<Map<String, dynamic>> getEndingSoonContests() =>
      _contests.where((c) => c['daysLeft'] <= 7).toList()
        ..sort((a, b) => a['daysLeft'].compareTo(b['daysLeft']));

  List<Map<String, dynamic>> getHighValueContests() =>
      _contests.where((c) => c['value'] >= 1000).toList()
        ..sort((a, b) => b['value'].compareTo(a['value']));

  List<Map<String, dynamic>> searchContests(String query) {
    final searchTerm = query.toLowerCase();
    return _contests.where((contest) {
      final searchText = contest['searchText'] ?? '';
      final title = contest['title'] ?? '';
      final sponsor = contest['sponsor'] ?? '';

      return searchText.contains(searchTerm) ||
          title.toLowerCase().contains(searchTerm) ||
          sponsor.toLowerCase().contains(searchTerm);
    }).toList();
  }
}
