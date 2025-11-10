import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> isUserAdmin() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data()?['isAdmin'] ?? false;
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    // Get total users count
    final usersSnapshot = await _firestore.collection('users').count().get();
    final totalUsers = usersSnapshot.count;

    // Get pro users count
    final proUsersSnapshot = await _firestore
        .collection('users')
        .where('isPro', isEqualTo: true)
        .count()
        .get();
    final proUsers = proUsersSnapshot.count;

    // Get active users today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activeUsersSnapshot = await _firestore
        .collection('users')
        .where('lastActive', isGreaterThanOrEqualTo: today)
        .count()
        .get();
    final activeToday = activeUsersSnapshot.count;

    // Get total sweepstakes
    final sweepstakesSnapshot =
        await _firestore.collection('sweepstakes').count().get();
    final totalSweepstakes = sweepstakesSnapshot.count;

    return {
      'totalUsers': totalUsers,
      'proUsers': proUsers,
      'activeToday': activeToday,
      'totalSweepstakes': totalSweepstakes,
    };
  }

  Future<List<Map<String, dynamic>>> getUsers({
    String? searchQuery,
    String? filterBy,
    bool? isPro,
  }) async {
    Query query = _firestore.collection('users');

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThan: '${searchQuery}z');
    }

    if (isPro != null) {
      query = query.where('isPro', isEqualTo: isPro);
    }

    final snapshot = await query.limit(50).get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()! as Map<String, dynamic>})
        .toList();
  }

  Future<void> updateUserRole(String userId, bool isAdmin) async {
    await _firestore.collection('users').doc(userId).update({
      'isAdmin': isAdmin,
    });
  }

  Future<void> updateUserProStatus(String userId, bool isPro) async {
    await _firestore.collection('users').doc(userId).update({
      'isPro': isPro,
    });
  }

  Future<List<Map<String, dynamic>>> getSweepstakes({
    String? searchQuery,
    String? category,
    bool? isActive,
  }) async {
    Query query = _firestore.collection('sweepstakes');

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query
          .where('title', isGreaterThanOrEqualTo: searchQuery)
          .where('title', isLessThan: '${searchQuery}z');
    }

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (isActive != null) {
      final now = Timestamp.now();
      if (isActive) {
        query = query.where('endDate', isGreaterThan: now);
      } else {
        query = query.where('endDate', isLessThan: now);
      }
    }

    final snapshot = await query.limit(50).get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()! as Map<String, dynamic>})
        .toList();
  }

  Future<void> updateSweepstake(
    String sweepstakeId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('sweepstakes').doc(sweepstakeId).update(data);
  }

  Future<void> deleteSweepstake(String sweepstakeId) async {
    await _firestore.collection('sweepstakes').doc(sweepstakeId).delete();
  }
}
