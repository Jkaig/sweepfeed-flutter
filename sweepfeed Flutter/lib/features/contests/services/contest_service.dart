import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/contest_model.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/logger.dart';
import 'sweepstake_service.dart';

/// A service class for managing contests, including fetching, saving, entering,
/// and submitting contests, as well as retrieving user entry statistics.
class ContestService {
  /// Constructs a [ContestService].
  ///
  /// Requires [firebaseService] for interacting with Firebase services and
  /// [sweepstakeService] for managing sweepstakes related data.
  ContestService(this.firebaseService, this.sweepstakeService);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The Firebase service used for interacting with Firebase.
  final FirebaseService firebaseService;

  /// The Sweepstake service used for managing sweepstakes data.
  final SweepstakeService sweepstakeService;

  /// Retrieves a stream of saved contests for a given user.
  ///
  /// @param userId The ID of the user.
  /// @returns A stream of [Contest] objects that have been saved by the user.
  Stream<List<Contest>> getSavedContests(String userId) => _firestore
          .collection('users')
          .doc(userId)
          .collection('savedContests')
          .snapshots()
          .asyncMap((snapshot) async {
        final contests = <Contest>[];
        for (final doc in snapshot.docs) {
          final contestId = doc.id;
          final contest = await sweepstakeService.getContestById(contestId);
          if (contest != null) {
            contests.add(contest);
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
      .collection('sweepstakes')
      .where(
        'endDate',
        isGreaterThan: Timestamp.now(),
      )
      .orderBy('endDate', descending: false)
      .limit(limit)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          return Contest.fromFirestore(doc);
        }).toList(),
      );

  /// Retrieves a stream of the most popular contests, ordered by entry count.
  ///
  /// Only active contests (where the end date is in the future) are included.
  ///
  /// @param limit The maximum number of contests to retrieve. Defaults to 10.
  /// @returns A stream of [Contest] objects that are currently active and ordered by entry count.
  Stream<List<Contest>> getPopularContests({int limit = 10}) => _firestore
      .collection('sweepstakes')
      .where('endDate', isGreaterThan: Timestamp.now())
      .orderBy('entryCount', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Contest.fromFirestore).toList(),
      );

  /// Retrieves a stream of contests that a user has entered.
  ///
  /// @param userId The ID of the user.
  /// @returns A stream of [Contest] objects that the user has entered.
  Stream<List<Contest>> getEnteredContests(String userId) =>
      firebaseService.getEnteredSweepstakes(userId).asyncMap((snapshot) async {
        final contests = <Contest>[];
        for (final doc in snapshot) {
          final contestId = doc.id;
          final contest = await sweepstakeService.getContestById(contestId);
          if (contest != null) {
            contests.add(contest);
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
  /// @param sweepstakesId The ID of the sweepstakes entered.
  /// @returns A [Future] that completes when the entry is recorded.
  /// @throws Exception if the user is not logged in.
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

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('entryHistory')
        .add({
      'enteredAt': now,
      'sweepstakesId': sweepstakesId,
    });

    await _firestore.collection('users').doc(userId).update({
      'totalEntries': FieldValue.increment(1),
      'lastEntryDate': now,
    });
  }

  /// Retrieves a contest by its ID.
  ///
  /// @param contestId The ID of the contest to retrieve.
  /// @returns A [Future] that completes with the [Contest] object if found, otherwise null.
  Future<Contest?> getContestById(String contestId) async {
    try {
      final doc =
          await _firestore.collection('sweepstakes').doc(contestId).get();
      if (doc.exists) {
        return Contest.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logger.e('Error getting contest by ID', error: e);
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
          .collection('sweepstakes')
          .where('isPremium', isEqualTo: true)
          .where('endDate', isGreaterThan: Timestamp.now())
          .limit(limit)
          .get();

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
  /// @param query The search query string.
  /// @param limit The maximum number of results to return. Defaults to 20.
  /// @returns A [Future] that completes with a list of [Contest] objects matching the query.
  Future<List<Contest>> searchContests(String query, {int limit = 20}) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      final snapshot = await _firestore
          .collection('sweepstakes')
          .where('endDate', isGreaterThan: Timestamp.now())
          .limit(limit)
          .get();

      final results = snapshot.docs
          .map(Contest.fromFirestore)
          .where(
            (contest) =>
                contest.title.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      return results;
    } catch (e) {
      logger.e('Error searching contests', error: e);
      return [];
    }
  }
}
