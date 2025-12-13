import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/data/repositories/contest_repository.dart';
import '../../../core/models/contest.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/user_preferences_service.dart';
import '../../../core/utils/logger.dart';
import '../models/filter_options.dart';


/// A service class for managing contests, including fetching, saving, entering,
/// and submitting contests, as well as retrieving user entry statistics.
class ContestService {
  /// Constructs a [ContestService].
  ///
  /// Requires [firebaseService] for interacting with Firebase services and
  /// [contestRepository] for managing contest related data.
  ContestService(
    this.firebaseService,
    this.contestRepository,
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The Firebase service used for interacting with Firebase.
  final FirebaseService firebaseService;


  final ContestRepository contestRepository;

  /// Retrieves a stream of contests from Firestore, applying optional filters and limits.
  ///
  /// This method fetches contests from the 'contests' collection, allowing filtering
  /// based on categories, entry methods, platforms, entry frequencies, end date,
  /// active status, ending soon status, new contest duration, and prize value.
  /// It also supports ordering the results based on a specified field.
  ///
  /// @param filters A map of filters to apply to the query. Possible filter keys include:
  ///   - 'categories': A list of category strings to filter contests by.
  ///   - 'entryMethods': A list of entry method strings to filter contests by.
  ///   - 'platforms': A list of platform strings to filter contests by.
  ///   - 'entryFrequencies': A list of entry frequency strings to filter contests by.
  ///   - 'endDate_isGreaterThan': A DateTime to filter contests with end dates after this date.
  ///   - 'active': A boolean to filter for active contests (end date in the future).
  ///   - 'endingSoon': A boolean to filter for contests ending soon (within 3 days).
  ///   - 'newContestDuration': A string ('24h' or '48h') to filter for contests created within the specified duration.
  ///   - 'minPrize': A number to filter contests with prize values greater than or equal to this value.
  ///   - 'maxPrize': A number to filter contests with prize values less than or equal to this value.
  ///   - 'orderBy': A string representing the field to order the contests by.
  ///   - 'descending': A boolean indicating whether to order the contests in descending order (optional, defaults to false).
  /// @param limit The maximum number of contests to retrieve (defaults to 20).
  /// @returns A Stream of List<Contest> representing the contests that match the specified criteria.
  Stream<List<Contest>> getContests({
    Map<String, dynamic>? filters,
    int limit = 20,
  }) {
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
      if (filters['platforms'] != null && filters['platforms'].isNotEmpty) {
        // New
        query = query.where('platform', whereIn: filters['platforms']);
      }
      if (filters['entryFrequencies'] != null &&
          filters['entryFrequencies'].isNotEmpty) {
        // New
        query =
            query.where('entryFrequency', whereIn: filters['entryFrequencies']);
      }
      if (filters['endDate_isGreaterThan'] != null) {
        query = query.where(
          'endDate',
          isGreaterThan: Timestamp.fromDate(filters['endDate_isGreaterThan']),
        );
      }
      if (filters['active'] == true) {
        query = query.where(
          'endDate',
          isGreaterThan: Timestamp.fromDate(DateTime.now()),
        );
      } else if (filters['endingSoon'] == true) {
        final now = DateTime.now();
        final soonDate = now.add(const Duration(days: 3));
        query = query
            .where('endDate', isGreaterThan: Timestamp.fromDate(now))
            .where(
              'endDate',
              isLessThanOrEqualTo: Timestamp.fromDate(soonDate),
            );
      }
      if (filters['newContestDuration'] != null) {
        // New
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
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate),
        );
      }
      if (filters['minPrize'] != null) {
        query = query.where(
          'prizeValue',
          isGreaterThanOrEqualTo: filters['minPrize'],
        );
      }
      if (filters['maxPrize'] != null) {
        query =
            query.where('prizeValue', isLessThanOrEqualTo: filters['maxPrize']);
      }
    }

    if (filters != null && filters['orderBy'] != null) {
      query = query.orderBy(
        filters['orderBy'],
        descending: filters['descending'] ?? false,
      );
    } else {
      query = query.orderBy('endDate');
    }
    query = query.limit(limit);

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            return Contest.fromJson(data, doc.id);
          }).toList(),
        );
  }

  /// Retrieves a stream of saved contests for a given user.
  ///
  /// @param userId The ID of the user.
  /// @returns A stream of [Contest] objects that have been saved by the user.
  Stream<List<Contest>> getSavedContests(String userId) => _firestore
          .collection('users')
          .doc(userId)
          .collection('savedContests')
          .snapshots()
          .handleError((error) {
        logger.e('Error in getSavedContests stream', error: error);
        return <Contest>[];
      }).asyncMap((snapshot) async {
        final contests = <Contest>[];
        for (final doc in snapshot.docs) {
          try {
            final contestId = doc.id;
            final contest = await getContestById(contestId);
            if (contest != null) {
              contests.add(contest);
            }
          } catch (e) {
            logger.w('Error loading contest ${doc.id} in getSavedContests', error: e);
          }
        }
        return contests;
      });

  /// Retrieves a stream of contests to populate a daily checklist, limited by the specified number.
  ///
  /// Only active contests (where the end date is in the future) are included.
  ///
  /// @param limit The maximum number of contests to retrieve. Defaults to 5.
  /// @returns A stream of [Contest] objects that are currently active and ordered by their end date.
  Stream<List<Contest>> getDailyChecklistContests({int limit = 5}) => _firestore
      .collection('contests')
      .where(
        'endDate',
        isGreaterThan: Timestamp.now(),
      )
      .orderBy('endDate', descending: false)
      .limit(limit)
      .snapshots()
      .handleError((error) {
        logger.e('Error in getDailyChecklistContests stream', error: error);
        return <Contest>[];
      })
      .map(
        (snapshot) {
          final contests = <Contest>[];
          for (final doc in snapshot.docs) {
            try {
              contests.add(Contest.fromFirestore(doc));
            } catch (e) {
              logger.w('Error parsing contest ${doc.id} in getDailyChecklistContests', error: e);
            }
          }
          return contests;
        },
      );

  /// Retrieves a stream of the most popular contests, ordered by entry count.
  ///
  /// Only active contests (where the end date is in the future) are included.
  ///
  /// @param limit The maximum number of contests to retrieve. Defaults to 10.
  /// @returns A stream of [Contest] objects that are currently active and ordered by entry count.
  Stream<List<Contest>> getPopularContests({int limit = 10}) => _firestore
      .collection('contests')
      .where('endDate', isGreaterThan: Timestamp.now())
      .orderBy('trendingScore', descending: true)
      .limit(limit)
      .snapshots()
      .handleError((error) {
        logger.e('Error in getPopularContests stream', error: error);
        return <Contest>[];
      })
      .map(
        (snapshot) {
          final contests = <Contest>[];
          for (final doc in snapshot.docs) {
            try {
              contests.add(Contest.fromFirestore(doc));
            } catch (e) {
              logger.w('Error parsing contest ${doc.id} in getPopularContests', error: e);
            }
          }
          return contests;
        },
      );

  /// Retrieves a stream of contests that a user has entered.
  ///
  /// @param userId The ID of the user.
  /// @returns A stream of [Contest] objects that the user has entered.
  Stream<List<Contest>> getEnteredContests(String userId) =>
      firebaseService.getEnteredContests(userId).asyncMap((snapshot) async {
        final contests = <Contest>[];
        for (final doc in snapshot) {
          try {
            final contestId = doc.id;
            final contest = await getContestById(contestId);
            if (contest != null) {
              contests.add(contest);
            }
          } catch (e) {
            logger.w('Error loading contest ${doc.id} in getEnteredContests', error: e);
          }
        }
        return contests;
      });

  /// Saves a contest for a given user.
  ///
  /// This method stores the contest ID in the user's saved contests collection.
  ///
  /// @param userId The ID of the user.
  /// @param contestId The ID of the contest to save.
  /// @returns A [Future] that completes when the contest is saved.
  Future<void> saveContest(String userId, String contestId) => _firestore
          .collection('users')
          .doc(userId)
          .collection('savedContests')
          .doc(contestId)
          .set({
        'savedAt': FieldValue.serverTimestamp(),
      });

  /// Removes a saved contest for a given user.
  ///
  /// @param userId The ID of the user.
  /// @param contestId The ID of the contest to unsave.
  /// @returns A [Future] that completes when the contest is unsaved.
  Future<void> unsaveContest(String userId, String contestId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('savedContests')
      .doc(contestId)
      .delete();

  /// Marks a contest as entered by the user.
  ///
  /// This method stores the contest ID in the user's entered contests collection.
  ///
  /// @param userId The ID of the user.
  /// @param contestId The ID of the contest to mark as entered.
  /// @returns A [Future] that completes when the contest is marked as entered.
  Future<void> markAsEntered(String userId, String contestId) => _firestore
          .collection('users')
          .doc(userId)
          .collection('enteredContests')
          .doc(contestId)
          .set({
        'enteredAt': FieldValue.serverTimestamp(),
      });

  /// Retrieves mock user entry statistics for UI development.
  ///
  /// This method simulates a delay and returns mock data.
  ///
  /// @returns A [Future] that completes with a [Map] containing user entry statistics.
  Future<Map<String, dynamic>> getUserEntryStats() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return {
      'totalEntered': 24,
      'dailyStreak': 5,
      'lastEntryDate': DateTime.now().subtract(const Duration(hours: 6)),
      'totalWon': 0,
      'enteredToday': 3,
      'dailyGoal': 5,
    };
  }

  /// Records a user's entry into a sweepstakes.
  ///
  /// This method adds the entry to the user's entries and entry history collections,
  /// and increments the user's total entries count.
  ///
  /// @param contestId The ID of the contest entered.
  /// @returns A [Future] that completes when the entry is recorded.
  /// @throws Exception if the user is not logged in.
  Future<void> enterContest(String contestId) async {
    if (_auth.currentUser == null) {
      throw Exception('User not logged in');
    }

    final userId = _auth.currentUser!.uid;
    final now = DateTime.now();

    try {
      // Get contest details to track interest
      final contest = await getContestById(contestId);
      if (contest != null) {
        // Track interest for personalization
        final userPrefsService = UserPreferencesService();
        await userPrefsService.trackContestEntry(
          contestId,
          contest.category,
          contest.sponsor,
        );
      }

      // Use batch for atomic operations
      final batch = _firestore.batch();

      batch.set(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('entries')
            .doc(contestId),
        {
          'enteredAt': now,
          'contestId': contestId,
        },
      );

      batch.set(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('entryHistory')
            .doc(),
        {
          'enteredAt': now,
          'contestId': contestId,
        },
      );

      batch.update(
        _firestore.collection('users').doc(userId),
        {
          'totalEntries': FieldValue.increment(1),
          'lastEntryDate': now,
        },
      );

      await batch.commit().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              logger.w('enterSweepstakes batch commit timed out');
              throw TimeoutException('Entry operation timed out');
            },
          );
    } catch (e) {
      logger.e('Error entering sweepstakes: $contestId', error: e);
      rethrow;
    }
  }

  /// Retrieves a contest by its ID.
  ///
  /// @param contestId The ID of the contest to retrieve.
  /// @returns A [Future] that completes with the [Contest] object if found, otherwise null.
  Future<Contest?> getContestById(String contestId) async {
    try {
      final doc = await _firestore
          .collection('contests')
          .doc(contestId)
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              logger.w('getContestById query timed out for: $contestId');
              throw TimeoutException('Query timed out');
            },
          );
      if (doc.exists) {
        return Contest.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logger.e('Error getting contest by ID: $contestId', error: e);
      return null;
    }
  }

  /// Fetches a list of contests by their IDs.
  ///
  /// @param ids A list of contest IDs to retrieve.
  /// @returns A [Future] that completes with a list of [Contest] objects.
  Future<List<Contest>> fetchContestsByIds(List<String> ids) async {
    try {
      final contests = <Contest>[];
      for (final id in ids) {
        final contest = await getContestById(id);
        if (contest != null) {
          contests.add(contest);
        }
      }
      return contests;
    } catch (e) {
      logger.e('Error fetching contests by IDs', error: e);
      return [];
    }
  }

  /// Retrieves a list of premium contests.
  ///
  /// @param limit The maximum number of contests to retrieve. Defaults to 10.
  /// @returns A [Future] that completes with a list of [Contest] objects that are premium and currently active.
  Future<List<Contest>> getPremiumContests({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('contests')
          .where('isPremium', isEqualTo: true)
          .where('endDate', isGreaterThan: Timestamp.now())
          .limit(limit)
          .get()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              logger.w('getPremiumContests query timed out');
              throw TimeoutException('Query timed out');
            },
          );

      return snapshot.docs.map(Contest.fromFirestore).toList();
    } catch (e) {
      logger.e('Error getting premium contests', error: e);
      return [];
    }
  }

  /// Submits a contest for review.
  ///
  /// @param data The contest data to submit.
  /// @param userId The ID of the user submitting the contest.
  /// @returns A [Future] that completes when the contest is submitted.
  /// @throws Any exception that occurs during the submission process.
  Future<void> submitContestForReview(
    Map<String, dynamic> data,
    String userId,
  ) async {
    try {
      await _firestore.collection('contestSubmissions').add({
        ...data,
        'submittedBy': userId,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      logger.e('Error submitting contest for review', error: e);
      rethrow;
    }
  }

  /// Searches for contests based on a query string.
  ///
  /// Searches across multiple fields including title, sponsor, prize description,
  /// and categories for comprehensive results.
  ///
  /// @param query The search query string.
  /// @param limit The maximum number of results to return. Defaults to 20.
  /// @returns A [Future] that completes with a list of [Contest] objects matching the query.
  Future<List<Contest>> searchContests(String query, {int limit = 20}) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      // OPTIMIZED: Limit to reasonable number for text search
      // Note: For production with large datasets, consider Algolia/Elasticsearch
      final queryLower = query.toLowerCase();
      final snapshot = await _firestore
          .collection('contests')
          .where('status', isEqualTo: 'active')
          .where('endDate', isGreaterThan: Timestamp.now())
          .orderBy('endDate', descending: false) // Use indexed field
          .limit(50) // Reduced from 100 - fetch less, filter more efficiently
          .get()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              logger.w('Search contests query timed out');
              throw TimeoutException('Search query timed out');
            },
          );

      final results = snapshot.docs
          .map(Contest.fromFirestore)
          .where((contest) {
            // Search in title
            if (contest.title.toLowerCase().contains(queryLower)) return true;
            // Search in sponsor/company name
            if (contest.sponsor.toLowerCase().contains(queryLower)) return true;
            // Search in prize name
            if (contest.prize.toLowerCase().contains(queryLower)) return true;
            // Search in prize details if available (it's a Map<String, String>)
            if (contest.prizeDetails != null) {
              for (final value in contest.prizeDetails!.values) {
                if (value.toLowerCase().contains(queryLower)) return true;
              }
            }
            // Search in categories
            for (final category in contest.categories) {
              if (category.toLowerCase().contains(queryLower)) return true;
            }
            return false;
          })
          .take(limit)
          .toList();

      // Sort by relevance: exact title match first, then by end date
      results.sort((a, b) {
        final aExactTitle = a.title.toLowerCase() == queryLower;
        final bExactTitle = b.title.toLowerCase() == queryLower;
        if (aExactTitle && !bExactTitle) return -1;
        if (!aExactTitle && bExactTitle) return 1;

        final aTitleMatch = a.title.toLowerCase().contains(queryLower);
        final bTitleMatch = b.title.toLowerCase().contains(queryLower);
        if (aTitleMatch && !bTitleMatch) return -1;
        if (!aTitleMatch && bTitleMatch) return 1;

        return a.endDate.compareTo(b.endDate);
      });

      return results;
    } catch (e) {
      logger.e('Error searching contests', error: e);
      return [];
    }
  }

  Future<void> reportContest(String contestId, String reason) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      await _firestore.collection('contest_reports').add({
        'contestId': contestId,
        'reason': reason,
        'reportedBy': user.uid,
        'reportedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.e('Error reporting contest', error: e);
      rethrow;
    }
  }

  Future<List<Contest>> getContestsPaginated({
    required int limit,
    required FilterOptions filterOptions, DocumentSnapshot? startAfter,
  }) async => contestRepository.getFilteredContests(
      filterOptions: filterOptions,
      limit: limit,
      startAfter: startAfter,
    );

  /// Retrieves a stream of featured contests from Firestore.
  ///
  /// This method fetches contests marked as "featured" and having an end date in the future.
  /// It orders the results by end date and limits the number of contests returned.
  ///
  /// @param limit The maximum number of featured contests to retrieve (defaults to 5).
  /// @returns A Stream of List<Contest> representing the featured contests.
  Stream<List<Contest>> getFeaturedContests({int limit = 5}) => _firestore
      .collection('contests')
      .where('featured', isEqualTo: true)
      .where('endDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
      .orderBy('endDate')
      .limit(limit)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return Contest.fromJson(data, doc.id);
        }).toList(),
      );

  Future<List<Contest>> getHighValueContests({int limit = 10}) async {
    return contestRepository.getHighValueContests(limit: limit);
  }

  Future<List<Contest>> getActiveContests({
    String? category,
    String? sortBy,
    bool ascending = true,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    return contestRepository.getActiveContests(
      category: category,
      sortBy: sortBy,
      ascending: ascending,
      limit: limit,
      startAfter: startAfter,
    );
  }
}
