import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/admin_permissions_model.dart';
import '../../../core/models/contest.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> isUserAdmin() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data();
    // Check both old format (isAdmin) and new format (roles.admin)
    return data?['roles']?['admin'] ?? data?['isAdmin'] ?? false;
  }

  Future<bool> isSuperAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    // Check if user email is jeremykaigler@gmail.com
    return user.email?.toLowerCase() == 'jeremykaigler@gmail.com';
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

    // Get total contests
    final contestsSnapshot =
        await _firestore.collection('contests').count().get();
    final totalContests = contestsSnapshot.count;

    return {
      'totalUsers': totalUsers,
      'proUsers': proUsers,
      'activeToday': activeToday,
      'totalContests': totalContests,
    };
  }

  Future<List<Map<String, dynamic>>> getUsers({
    String? searchQuery,
    String? filterBy,
    bool? isPro,
  }) async {
    final Query query = _firestore.collection('users');

    // Note: Firestore doesn't support case-insensitive search natively
    // For better search, we'll fetch more results and filter client-side
    final snapshot = await query.limit(100).get();
    
    var users = snapshot.docs
        .map((doc) {
          final data = doc.data()! as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
            // Normalize admin status - check both formats
            'isAdmin': data['roles']?['admin'] ?? data['isAdmin'] ?? false,
          };
        })
        .toList();

    // Client-side filtering
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final queryLower = searchQuery.toLowerCase();
      users = users.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        return name.contains(queryLower) || email.contains(queryLower);
      }).toList();
    }

    if (isPro != null) {
      users = users.where((user) => (user['isPro'] ?? false) == isPro).toList();
    }

    return users.take(50).toList();
  }

  Future<void> updateUserRole(String userId, bool isAdmin) async {
    // Only superadmin can set other admins
    if (!await isSuperAdmin()) {
      throw Exception('Only superadmin can update user roles');
    }

    // Update using the roles.admin format (matching auth_service structure)
    await _firestore.collection('users').doc(userId).update({
      'roles': {
        'admin': isAdmin,
        'editor': false,
      },
      // Also update legacy isAdmin field for backward compatibility
      'isAdmin': isAdmin,
    });
  }

  Future<void> updateAdminPermissions(String userId, AdminPermissions permissions) async {
    // Only superadmin can set admin permissions
    if (!await isSuperAdmin()) {
      throw Exception('Only superadmin can update admin permissions');
    }

    await _firestore.collection('users').doc(userId).update({
      'adminPermissions': permissions.toMap(),
    });
  }

  Future<AdminPermissions> getAdminPermissions(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data();
    
    // If user is superadmin, return full permissions
    final user = _auth.currentUser;
    if (user?.email?.toLowerCase() == 'jeremykaigler@gmail.com') {
      return AdminPermissions.full;
    }

    // Check if user has admin permissions set
    if (data?['adminPermissions'] != null) {
      return AdminPermissions.fromMap(
        Map<String, dynamic>.from(data!['adminPermissions']),
      );
    }

    // Default: no permissions
    return const AdminPermissions();
  }

  Future<bool> hasPermission(String userId, String permission) async {
    final perms = await getAdminPermissions(userId);
    
    switch (permission) {
      case 'manageUsers':
        return perms.canManageUsers;
      case 'manageSupportTickets':
        return perms.canManageSupportTickets;
      case 'manageWinnerClaims':
        return perms.canManageWinnerClaims;
      case 'manageContests':
        return perms.canManageContests;
      case 'viewAnalytics':
        return perms.canViewAnalytics;
      case 'manageSettings':
        return perms.canManageSettings;
      default:
        return false;
    }
  }

  Future<void> updateUserProStatus(String userId, bool isPro) async {
    await _firestore.collection('users').doc(userId).update({
      'isPro': isPro,
    });
  }

  Future<List<Contest>> getContests({
    String? searchQuery,
    String? category,
    bool? isActive,
  }) async {
    Query query = _firestore.collection('contests');

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
        .map((doc) => Contest.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  Future<void> updateContest(
    String contestId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('contests').doc(contestId).update(data);
  }

  Future<void> deleteContest(String contestId) async {
    await _firestore.collection('contests').doc(contestId).delete();
  }
}
