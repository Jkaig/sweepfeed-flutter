import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
// For debugPrint

class ChecklistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getDateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  DocumentReference _getDailyChecklistDocRef(String userId, DateTime date) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyChecklists')
          .doc(_getDateKey(date));

  Future<Map<String, bool>> getCompletionStatus(
    String userId,
    DateTime date,
  ) async {
    try {
      final doc = await _getDailyChecklistDocRef(userId, date).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()! as Map<String, dynamic>; // Explicit cast
        if (data.containsKey('completedContests')) {
          return Map<String, bool>.from(data['completedContests'] as Map);
        }
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<void> updateCompletionStatus(
    String userId,
    String contestId,
    bool isCompleted,
    DateTime date,
  ) async {
    try {
      await _getDailyChecklistDocRef(userId, date).set(
        {
          'completedContests': {
            contestId: isCompleted,
          },
        },
        SetOptions(mergeFields: ['completedContests.$contestId']),
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<Set<String>> getHiddenItems(String userId, DateTime date) async {
    try {
      final doc = await _getDailyChecklistDocRef(userId, date).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()! as Map<String, dynamic>; // Explicit cast
        if (data.containsKey('hiddenContests')) {
          return Set<String>.from(data['hiddenContests'] as List);
        }
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<void> hideItem(String userId, String contestId, DateTime date) async {
    try {
      await _getDailyChecklistDocRef(userId, date).set(
        {
          'hiddenContests': FieldValue.arrayUnion([contestId]),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> unhideItem(
    String userId,
    String contestId,
    DateTime date,
  ) async {
    try {
      await _getDailyChecklistDocRef(userId, date).update({
        'hiddenContests': FieldValue.arrayRemove([contestId]),
      });
    } catch (e) {
      // Handle error
    }
  }
}
