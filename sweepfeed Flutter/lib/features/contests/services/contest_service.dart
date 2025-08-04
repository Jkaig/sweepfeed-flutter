import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/models/contest_model.dart';

class ContestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService firebaseService;
  ContestService(this.firebaseService);
  static const String _contestCacheKey = 'contest_cache';

  Future<void> _saveContestsToCache(List<Contest> contests) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> jsonList =
          contests.map((c) => json.encode(c.toJson())).toList();
      await prefs.setStringList(_contestCacheKey, jsonList);
      print('Saved ${contests.length} contests to cache.');
    } catch (e) {
      print("Error saving contests to cache: $e");
    }
  }

  Future<List<Contest>> _loadContestsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? jsonList = prefs.getStringList(_contestCacheKey);
      if (jsonList != null) {
        List<Contest> contests = jsonList.map((jsonString) {
          Map<String, dynamic> map = json.decode(jsonString);
          return Contest.fromJson(map);
        }).toList();
        print('Loaded ${contests.length} contests from cache.');
        return contests;
      }
    } catch (e) {
      print("Error loading contests from cache: $e");
    }
    return [];
  }

  Stream<List<Contest>> getContests(
      {Map<String, dynamic>? filters, int limit = 20}) async* {
    final userId = firebaseService.currentUser?.uid;
    if (userId != null) {
      yield* _getContestsForUser(userId: userId, filters: filters, limit: limit);
    } else {
      yield* _getAllContests(filters: filters, limit: limit);
    }
  }
  Stream<List<Contest>> _getAllContests({
    Map<String, dynamic>? filters,
    int limit = 20,
  }) async* {
    // Attempt to load from cache only if no filters are applied.
    // If filters are present, we need to fetch fresh data.
    if (filters == null || filters.isEmpty) {
      final cachedContests = await _loadContestsFromCache();
      if (cachedContests.isNotEmpty) {
        print("Emitting cached contests...");
        yield cachedContests;
        // Optionally, you might still want to fetch fresh data in the background
        // For now, we return cached data and stop if no filters.
        // return; 
      }
    }

    Query query = _firestore.collection('contests');

    if (filters != null) {
      if (filters['categories'] != null && filters['categories'].isNotEmpty) {
        query =
            query.where('categories', arrayContainsAny: filters['categories']);
      }
      if (filters['entryMethods'] != null &&
          filters['entryMethods'].isNotEmpty) {
        query = query.where('entryMethod', whereIn: filters['entryMethods']);
      }
      if (filters['platforms'] != null && filters['platforms'].isNotEmpty) { // New
        query = query.where('platform', whereIn: filters['platforms']);
      }
      if (filters['entryFrequencies'] != null && filters['entryFrequencies'].isNotEmpty) { // New
        query = query.where('entryFrequency', whereIn: filters['entryFrequencies']);
      }
      if (filters['active'] == true) {
        query = query.where('endDate',
            isGreaterThan: Timestamp.fromDate(DateTime.now()));
      } else if (filters['endingSoon'] == true) {
        final now = DateTime.now();
        final soonDate = now.add(const Duration(days: 3));
        query = query
            .where('endDate', isGreaterThan: Timestamp.fromDate(now))
            .where('endDate',
                isLessThanOrEqualTo: Timestamp.fromDate(soonDate));
      }
      if (filters['newContestDuration'] != null) { // New
        final now = DateTime.now();
        DateTime cutoffDate;
        if (filters['newContestDuration'] == '24h') {
          cutoffDate = now.subtract(const Duration(hours: 24));
        } else if (filters['newContestDuration'] == '48h') {
          cutoffDate = now.subtract(const Duration(hours: 48));
        } else {
          cutoffDate = now; // Should not happen with current UI
        }
        // Assuming 'createdAt' is a Timestamp field in Firestore
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate));
      }
      if (filters['minPrize'] != null) {
        query = query.where('prizeValue',
            isGreaterThanOrEqualTo: filters['minPrize']);
      }
      if (filters['maxPrize'] != null) {
        query =
            query.where('prizeValue', isLessThanOrEqualTo: filters['maxPrize']);
      }
    }

    // It's important to have a default sort order, especially if not all queries define one.
    // However, Firestore requires the first orderBy field to match any inequality filter field.
    // If 'createdAt' or 'endDate' is used in an inequality, it should be the first orderBy.
    // This logic might need adjustment based on which filters are active.
    // For simplicity, if 'newContestDuration' is active, we sort by 'createdAt'.
    // Otherwise, by 'endDate'. This is a common use case.
    if (filters != null && filters['newContestDuration'] != null) {
        query = query.orderBy('createdAt', descending: true).limit(limit);
    } else {
        query = query.orderBy('endDate').limit(limit);
    }

    await for (var snapshot in query.snapshots()) {
      List<Contest> freshContests = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Contest.fromJson(data);
      }).toList();

      print(
          "Emitting fresh contests from Firestore (${freshContests.length})...");
      yield freshContests;

      if (filters == null || filters.isEmpty) {
        await _saveContestsToCache(freshContests);
      }
    }
  }

  Stream<List<Contest>> _getContestsForUser(
      {required String userId,
      Map<String, dynamic>? filters,
      int limit = 20}) async* {
    // Reference to the original stream from Firebase
    Stream<QuerySnapshot<Map<String, dynamic>>> sweepstakesStream =
        firebaseService.getSweepstakesForUser(userId: userId, limit: limit).asStream();

    await for (var snapshot in sweepstakesStream) {
      List<Contest> contests = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Contest.fromJson(data);
      }).toList();

      // Apply client-side filtering if filters are provided
      if (filters != null && filters.isNotEmpty) {
        contests = contests.where((contest) {
          bool passes = true;
          if (filters['categories'] != null &&
              filters['categories'].isNotEmpty) {
            passes = passes &&
                (contest.categories?.any(
                        (category) => filters['categories'].contains(category)) ??
                    false);
          }
          if (filters['entryMethods'] != null &&
              filters['entryMethods'].isNotEmpty) {
            passes = passes &&
                (filters['entryMethods'].contains(contest.entryMethod));
          }
          if (filters['platforms'] != null && filters['platforms'].isNotEmpty) {
            passes = passes && (filters['platforms'].contains(contest.platform));
          }
          if (filters['entryFrequencies'] != null &&
              filters['entryFrequencies'].isNotEmpty) {
            passes = passes &&
                (filters['entryFrequencies'].contains(contest.entryFrequency));
          }
          if (filters['endingSoon'] == true) {
            final now = DateTime.now();
            final soonDate = now.add(const Duration(days: 3));
            passes = passes &&
                (contest.endDate.isAfter(now) &&
                    contest.endDate.isBefore(soonDate));
          }
          if (filters['newContestDuration'] != null) {
            final now = DateTime.now();
            DateTime cutoffDate;
            if (filters['newContestDuration'] == '24h') {
              cutoffDate = now.subtract(const Duration(hours: 24));
            } else if (filters['newContestDuration'] == '48h') {
              cutoffDate = now.subtract(const Duration(hours: 48));
            } else {
              cutoffDate = now; // Should not happen
            }
            passes = passes && (contest.createdAt.isAfter(cutoffDate));
          }
          if (filters['minPrize'] != null) {
            passes = passes && (contest.prizeValue >= filters['minPrize']);
          }
          if (filters['maxPrize'] != null) {
            passes = passes && (contest.prizeValue <= filters['maxPrize']);
          }
          return passes;
        }).toList();
      }

      print(
          "Emitting contests for user (filtered: ${filters != null && filters.isNotEmpty}, count: ${contests.length})...");
      yield contests;

      // Cache only if no filters are applied to avoid caching filtered results incorrectly
      if (filters == null || filters.isEmpty) {
        await _saveContestsToCache(contests);
      }
    }
  }

  Future<Contest?> getContestById(String contestId) async {
    try {
      final doc = await _firestore.collection('contests').doc(contestId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Contest.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching contest: $e');
      return null;
    }
  }

  Future<List<Contest>> getPremiumContests() async {
    try {
      final snapshot =
          await _firestore.collection('contests').where('isPremium', isEqualTo: true).get();
      return snapshot.docs.map((doc) => Contest.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching premium contests: $e');
      return [];
    }
  }

  Future<List<Contest>> fetchContestsByIds(List<String> contestIds) async {
    if (contestIds.isEmpty) {
      return [];
    }

    try {
      final List<Contest> contests = [];
      for (var i = 0; i < contestIds.length; i += 10) {
        final sublist = contestIds.sublist(
            i, i + 10 > contestIds.length ? contestIds.length : i + 10);

        final snapshot = await _firestore
            .collection('contests')
            .where(FieldPath.documentId, whereIn: sublist)
            .get();

        contests.addAll(snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Contest.fromJson(data);
        }).toList());
      }

      return contests;
    } catch (e) {
      print('Error fetching contests by IDs: $e');
      return [];
    }
  }

  Stream<List<Contest>> getFeaturedContests({int limit = 5}) {
    return _firestore
        .collection('contests')
        .where('featured', isEqualTo: true)
        .where('endDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('endDate')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Contest.fromJson(data);
      }).toList();
    });
  }

  Stream<List<Contest>> getSavedContests(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('savedContests')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Contest> contests = [];
      for (var doc in snapshot.docs) {
        final contestId = doc.id;
        final contest = await getContestById(contestId);
        if (contest != null) {
          contests.add(contest);
        }
      }
      return contests;
    });
  }

  Stream<List<Contest>> getDailyChecklistContests({int limit = 5}) {
    // Example: Fetch contests ending soon, not entered by user, etc.
    // For now, just get generic contests for simplicity, prioritizing those ending soon.
    // This query might need adjustments based on your data model and desired checklist logic.
    // Consider adding filters like 'not entered by user' if that data is available.
    return _firestore
        .collection('contests') 
        .where('endDate', isGreaterThan: Timestamp.now()) // Only active contests
        .orderBy('endDate', descending: false) 
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // Assuming Contest.fromFirestore correctly maps the document
            // If doc.data() doesn't include 'id', it should be added like in other methods:
            // final data = doc.data() as Map<String, dynamic>;
            // data['id'] = doc.id;
            // return Contest.fromJson(data);
            return Contest.fromFirestore(doc); // If fromFirestore handles id from doc.id
          }).toList();
        });
  }

  // Save a contest for a user
  Future<void> saveContest(String userId, String contestId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('savedContests')
        .doc(contestId)
        .set({
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove a saved contest
  Future<void> unsaveContest(String userId, String contestId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('savedContests')
        .doc(contestId)
        .delete();
  }

  // Mark a contest as entered by the user
  Future<void> markAsEntered(String userId, String contestId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('enteredContests')
        .doc(contestId)
        .set({
      'enteredAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Search Logic ---
  Future<List<Contest>> searchContests(String query) async {
    if (query.isEmpty || query.length < 3) {
      return [];
    }

    // Prepare query for prefix matching (case-insensitive requires backend/search service)
    // Firestore queries are case-sensitive by default.
    // We search based on the provided query casing.
    String endQuery = query.substring(0, query.length - 1) +
        String.fromCharCode(query.codeUnitAt(query.length - 1) + 1);

    try {
      print('Searching Firestore for title >= "$query" and < "$endQuery"');
      // Query Firestore - Requires index on 'title' (ascending) and 'endDate' (ascending)
      final snapshot = await _firestore
          .collection('contests')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: endQuery)
          .orderBy('title') // Order by title first for the range query
          .orderBy(
              'endDate') // Then potentially by endDate (might require composite index)
          .limit(20) // Limit search results
          .get();

      print(
          'Firestore search found ${snapshot.docs.length} potential matches.');

      List<Contest> results = snapshot.docs.map((doc) {
        final data = doc.data(); // No need to cast with helper
        data['id'] = doc.id;
        return Contest.fromJson(data);
      }).toList();

      // Optional: If Firestore search isn't powerful enough (e.g., need case-insensitive),
      // you might still fetch a broader range and filter client-side,
      // but that defeats the purpose of server-side search.

      return results;
    } catch (e) {
      print('Error searching contests in Firestore: $e');
      // Handle potential index-missing errors - prompt user/log details
      if (e.toString().contains('requires an index')) {
        print(
            'Firestore Index Required: Please create a composite index on the contests collection including \'title\' (ascending) and \'endDate\' (ascending).');
      }
      return [];
    }
  }

  // Mock user entry statistics for UI development
  Future<Map<String, dynamic>> getUserEntryStats() async {
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock stats
    return {
      'totalEntered': 24,
      'dailyStreak': 5,
      'lastEntryDate': DateTime.now().subtract(const Duration(hours: 6)),
      'totalWon': 0,
      'enteredToday': 3,
      'dailyGoal': 5,
    };
  }

  // Record user entry in Firestore
  Future<void> enterSweepstakes(String sweepstakesId) async {
    if (_auth.currentUser == null) {
      throw Exception('User not logged in');
    }

    final userId = _auth.currentUser!.uid;
    final now = DateTime.now();

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('entries')
        .doc(sweepstakesId)
        .set({
      'enteredAt': now,
      'sweepstakesId': sweepstakesId,
    });

    // Also add to user's entry history
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('entryHistory')
        .add({
      'enteredAt': now,
      'sweepstakesId': sweepstakesId,
    });

    // Increment entry count in user profile
    await _firestore.collection('users').doc(userId).update({
      'totalEntries': FieldValue.increment(1),
      'lastEntryDate': now,
    });
  }

  Future<void> submitContestForReview(Map<String, dynamic> contestData, String userId) async {
    try {
      final submissionData = {
        ...contestData,
        'submittedBy': userId,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, approved, rejected
      };
      // Ensure all required fields for a base contest are present, even if null,
      // if your Contest.fromFirestore factory expects them.
      submissionData.putIfAbsent('badges', () => []);
      submissionData.putIfAbsent('isPremium', () => false);
      // createdAt might be set here or by admin on approval. If set here, ensure it's a Timestamp.
      submissionData.putIfAbsent('createdAt', () => FieldValue.serverTimestamp()); 
      // 'imageUrl' might be null initially, to be added by admin.
      // 'source' is already part of contestData from the form.
      // 'frequency', 'eligibility', 'platform', 'entryMethod', 'prizeValue', 'isHot' are also part of contestData (some with defaults).


      await _firestore.collection('pendingContests').add(submissionData);
      debugPrint('Contest submitted for review: ${submissionData['title']}');
    } catch (e) {
      debugPrint('Error submitting contest for review: $e');
      rethrow;
    }
  }
}
