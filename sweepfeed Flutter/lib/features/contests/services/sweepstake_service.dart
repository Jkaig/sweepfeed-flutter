import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/contest_model.dart';
import '../../../core/utils/logger.dart';

/// A service class responsible for handling sweepstake data operations
/// using Firebase Firestore. It provides methods for retrieving, filtering,
/// and submitting contests.
class SweepstakeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retrieves a stream of contests from Firestore, applying optional filters and limits.
  ///
  /// This method fetches contests from the 'sweepstakes' collection, allowing filtering
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
    Query query = _firestore.collection('sweepstakes');

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

  /// Retrieves a contest from Firestore by its ID.
  ///
  /// @param contestId The ID of the contest to retrieve.
  /// @returns A Future<Contest?> that completes with the Contest object if found,
  ///          or null if the contest does not exist.  Returns null also on error.
  Future<Contest?> getContestById(String contestId) async {
    try {
      final doc =
          await _firestore.collection('sweepstakes').doc(contestId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return Contest.fromJson(data, doc.id);
      }
      return null;
    } catch (e) {
      logger.e('Error fetching contest', error: e);
      return null;
    }
  }

  /// Retrieves a list of premium contests from Firestore.
  ///
  /// @returns A Future<List<Contest>> that completes with a list of premium Contest objects.
  ///          Returns an empty list in case of an error.
  Future<List<Contest>> getPremiumContests() async {
    try {
      final snapshot = await _firestore
          .collection('sweepstakes')
          .where('isPremium', isEqualTo: true)
          .get();
      return snapshot.docs.map(Contest.fromFirestore).toList();
    } catch (e) {
      logger.e('Error fetching premium contests', error: e);
      return [];
    }
  }

  /// Fetches a list of contests from Firestore by their IDs.
  ///
  /// This method retrieves contests in batches of 10 due to Firestore's `whereIn` limitation.
  ///
  /// @param contestIds A list of contest IDs to retrieve.
  /// @returns A Future<List<Contest>> that completes with a list of Contest objects.
  ///          Returns an empty list if no contest ids provided or in case of error.
  Future<List<Contest>> fetchContestsByIds(List<String> contestIds) async {
    if (contestIds.isEmpty) {
      return [];
    }

    try {
      final contests = <Contest>[];
      for (var i = 0; i < contestIds.length; i += 10) {
        final sublist = contestIds.sublist(
          i,
          i + 10 > contestIds.length ? contestIds.length : i + 10,
        );

        final snapshot = await _firestore
            .collection('sweepstakes')
            .where(FieldPath.documentId, whereIn: sublist)
            .get();

        contests.addAll(
          snapshot.docs.map((doc) {
            final data = doc.data();
            return Contest.fromJson(data, doc.id);
          }).toList(),
        );
      }

      return contests;
    } catch (e) {
      logger.e('Error fetching contests by IDs', error: e);
      return [];
    }
  }

  /// Retrieves a stream of featured contests from Firestore.
  ///
  /// This method fetches contests marked as "featured" and having an end date in the future.
  /// It orders the results by end date and limits the number of contests returned.
  ///
  /// @param limit The maximum number of featured contests to retrieve (defaults to 5).
  /// @returns A Stream of List<Contest> representing the featured contests.
  Stream<List<Contest>> getFeaturedContests({int limit = 5}) => _firestore
      .collection('sweepstakes')
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

  /// Submits a contest for review to Firestore.
  ///
  /// This method adds contest data to the 'pendingContests' collection,
  /// along with metadata such as the submitter's user ID, submission timestamp,
  /// and initial status ('pending').
  ///
  /// @param contestData A map containing the contest data to submit.
  /// @param userId The ID of the user submitting the contest.
  /// @throws An exception if the submission fails.
  Future<void> submitContestForReview(
    Map<String, dynamic> contestData,
    String userId,
  ) async {
    try {
      final submissionData = {
        ...contestData,
        'submittedBy': userId,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, approved, rejected
      };
      submissionData.putIfAbsent('badges', () => []);
      submissionData.putIfAbsent('isPremium', () => false);
      submissionData.putIfAbsent(
        'createdAt',
        FieldValue.serverTimestamp,
      );

      await _firestore.collection('pendingContests').add(submissionData);
      logger.i('Contest submitted for review: ${submissionData['title']}');
    } catch (e) {
      logger.e('Error submitting contest for review', error: e);
      rethrow;
    }
  }
}
