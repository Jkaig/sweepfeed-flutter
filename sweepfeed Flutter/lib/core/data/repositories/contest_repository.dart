import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/contest.dart';
import '../../security/security_utils.dart';
import '../../utils/logger.dart';

class ContestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'contests';

  /// Build base query for active contests
  Query _buildBaseActiveQuery({String? category}) {
    Query query = _firestore.collection(_collection);
    query = query.where('status', isEqualTo: 'active');
    query = query.where('end_date', isGreaterThan: Timestamp.now());

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query;
  }

  /// Parse snapshot docs into Contest list with error handling and security validation
  List<Contest> _parseContestSnapshot(QuerySnapshot snapshot) {
    final contests = <Contest>[];
    for (final doc in snapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          logger.w('Document ${doc.id} has no data');
          continue;
        }

        // Validate data for security issues before parsing
        if (!SecurityUtils.validateContestData(data)) {
          logger.w('Contest data failed security validation: ${doc.id}');
          continue;
        }

        // Check rate limit for data processing
        if (!SecurityUtils.checkRateLimit(
          'contest_parsing',
          maxRequests: 1000,
        )) {
          logger.w('Rate limit exceeded for contest parsing');
          break;
        }

        contests.add(
          Contest.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>,
          ),
        );
      } on FormatException catch (e) {
        logger.w('Invalid data format in contest doc ${doc.id}', error: e);
      } on TypeError catch (e) {
        logger.w('Type error parsing contest doc ${doc.id}', error: e);
      } on Exception catch (e) {
        logger.w('Failed to parse contest doc ${doc.id}', error: e);
      }
    }
    return contests;
  }

  /// Execute query with timeout and error handling
  Future<QuerySnapshot> _executeQueryWithTimeout(
    Query query,
    String operation,
  ) async =>
      query.get().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          logger.w('Query timeout in $operation');
          throw TimeoutException('Firestore query timed out');
        },
      );

  Stream<List<Contest>> getActiveContestsStream({
    String? category,
    String? sortBy,
    bool ascending = true,
    int limit = 50,
  }) {
    try {
      Query query = _firestore.collection(_collection);

      query = query.where('status', isEqualTo: 'active');
      query = query.where('end_date', isGreaterThan: Timestamp.now());

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (sortBy != null && sortBy.isNotEmpty) {
        query = query.orderBy(sortBy, descending: !ascending);
      } else {
        query = query.orderBy('end_date', descending: false);
      }

      query = query.limit(limit.clamp(1, 100));

      return query.snapshots().handleError((error) {
        logger.e('Stream error in getActiveContestsStream', error: error);
        return <Contest>[];
      }).map((snapshot) {
        final contests = <Contest>[];
        for (final doc in snapshot.docs) {
          try {
            contests.add(
              Contest.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
              ),
            );
          } on FormatException catch (e) {
            logger.w('Invalid data format in contest doc ${doc.id}', error: e);
          } on TypeError catch (e) {
            logger.w('Type error parsing contest doc ${doc.id}', error: e);
          } on Exception catch (e) {
            logger.w('Failed to parse contest doc ${doc.id}', error: e);
          }
        }
        return contests;
      });
    } on FirebaseException catch (e) {
      logger.e('Firebase error creating active contests stream: ${e.code}', error: e);
      return Stream.value([]);
    } on Exception catch (e) {
      logger.e('Error creating active contests stream', error: e);
      return Stream.value([]);
    }
  }

  Future<List<Contest>> getActiveContests({
    String? category,
    String? sortBy,
    bool ascending = true,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = _buildBaseActiveQuery(category: category);

      if (sortBy != null && sortBy.isNotEmpty) {
        query = query.orderBy(sortBy, descending: !ascending);
      } else {
        query = query.orderBy('end_date', descending: false);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit.clamp(1, 100));

      final snapshot =
          await _executeQueryWithTimeout(query, 'getActiveContests');
      return _parseContestSnapshot(snapshot);
    } on FirebaseException catch (e) {
      logger.e('Firebase error getting active contests: ${e.code}', error: e);
      return [];
    } on Exception catch (e) {
      logger.e('Error getting active contests', error: e);
      return [];
    }
  }

  Future<Contest?> getContestById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return Contest.fromFirestore(doc);
    } on Exception catch (e) {
      logger.e('Error getting contest by ID: $id', error: e);
      return null;
    }
  }

  Future<List<Contest>> getHighValueContests({int limit = 10}) async {
    try {
      final query = _buildBaseActiveQuery()
          .orderBy('end_date', descending: false)
          .limit(100);

      final snapshot =
          await _executeQueryWithTimeout(query, 'getHighValueContests');
      final contests = _parseContestSnapshot(snapshot);

      contests.sort((a, b) {
        final aValue = a.prizeValueAmount ?? 0;
        final bValue = b.prizeValueAmount ?? 0;
        return bValue.compareTo(aValue);
      });

      return contests.take(limit.clamp(1, 50)).toList();
    } on FirebaseException catch (e) {
      logger.e('Firebase error getting high value contests: ${e.code}', error: e);
      return [];
    } on Exception catch (e) {
      logger.e('Error getting high value contests', error: e);
      return [];
    }
  }

  Future<List<Contest>> getEndingSoonContests({
    int limit = 10,
    int maxDaysRemaining = 7,
  }) async {
    try {
      final cutoffDate = DateTime.now().add(Duration(days: maxDaysRemaining));

      final query = _buildBaseActiveQuery()
          .where('end_date', isLessThan: Timestamp.fromDate(cutoffDate))
          .orderBy('end_date', descending: false)
          .limit(limit.clamp(1, 50));

      final snapshot =
          await _executeQueryWithTimeout(query, 'getEndingSoonContests');
      return _parseContestSnapshot(snapshot);
    } on FirebaseException catch (e) {
      logger.e('Firebase error getting ending soon contests: ${e.code}', error: e);
      return [];
    } on Exception catch (e) {
      logger.e('Error getting ending soon contests', error: e);
      return [];
    }
  }

  Future<List<String>> getAvailableCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .get();

      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      final categoryList = categories.toList()..sort();
      return categoryList;
    } on Exception catch (e) {
      logger.e('Error getting available categories', error: e);
      return [];
    }
  }

  Future<void> addContest(Contest contest) async {
    try {
      await _firestore.collection(_collection).add(contest.toFirestore());
      logger.d('Contest added: ${contest.title}');
    } on Exception catch (e) {
      logger.e('Error adding contest: ${contest.title}', error: e);
      rethrow;
    }
  }

  Future<void> updateContest(String id, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = FieldValue.serverTimestamp();
      await _firestore.collection(_collection).doc(id).update(updates);
      logger.d('Contest updated: $id');
    } on Exception catch (e) {
      logger.e('Error updating contest: $id', error: e);
      rethrow;
    }
  }

  Future<void> deleteContest(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      logger.d('Contest deleted: $id');
    } on Exception catch (e) {
      logger.e('Error deleting contest: $id', error: e);
      rethrow;
    }
  }

  Future<void> markContestAsExpired(String id) async {
    try {
      await updateContest(id, {'status': 'expired'});
      logger.d('Contest marked as expired: $id');
    } on Exception catch (e) {
      logger.e('Error marking contest as expired: $id', error: e);
      rethrow;
    }
  }

  Future<int> getActiveContestCount() async {
    try {
      final snapshot = await _buildBaseActiveQuery().count().get();

      return snapshot.count ?? 0;
    } on Exception catch (e) {
      logger.e('Error getting active contest count', error: e);
      return 0;
    }
  }
}
