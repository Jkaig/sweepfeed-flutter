import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // Send a friend request
  Future<String> sendFriendRequest(String toUserId) async {
    if (_currentUserId == null || _currentUserId == toUserId) return 'error';

    // Check if current user is blocked by the target user
    final isBlocked = await _isBlockedBy(toUserId);
    if (isBlocked) return 'blocked';

    final requestRef = _firestore
        .collection('users')
        .doc(toUserId)
        .collection('friend_requests')
        .doc(_currentUserId);

    await requestRef.set({
      'from': _currentUserId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    return 'success';
  }

  // Check if current user is blocked by another user
  Future<bool> _isBlockedBy(String userId) async {
    if (_currentUserId == null) return false;

    final blockDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('blocked_users')
        .doc(_currentUserId)
        .get();

    return blockDoc.exists;
  }

  // Block a user
  Future<String> blockUser(String userId) async {
    if (_currentUserId == null) return 'error';

    final batch = _firestore.batch();

    // 1. Add to blocked users list
    final blockRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('blocked_users')
        .doc(userId);
    batch.set(blockRef, {
      'blockedAt': FieldValue.serverTimestamp(),
      'reason': 'spam', // can be expanded later
    });

    // 2. Remove from friends if they were friends
    final friendRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .doc(userId);
    batch.delete(friendRef);

    // 3. Remove from other user's friends list
    final otherFriendRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc(_currentUserId);
    batch.delete(otherFriendRef);

    // 4. Delete any pending friend requests
    final requestRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friend_requests')
        .doc(userId);
    batch.delete(requestRef);

    await batch.commit();
    return 'success';
  }

  // Unblock a user
  Future<String> unblockUser(String userId) async {
    if (_currentUserId == null) return 'error';

    final blockRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('blocked_users')
        .doc(userId);

    await blockRef.delete();
    return 'success';
  }

  // Check if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    if (_currentUserId == null) return false;

    final blockDoc = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('blocked_users')
        .doc(userId)
        .get();

    return blockDoc.exists;
  }

  // Report a user
  Future<String> reportUser({
    required String userId,
    required String reason,
    String? additionalDetails,
  }) async {
    if (_currentUserId == null) return 'error';

    final reportRef = _firestore.collection('reports').doc();

    await reportRef.set({
      'reporterId': _currentUserId,
      'reportedUserId': userId,
      'reason': reason,
      'additionalDetails': additionalDetails,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'type': 'user_report',
    });

    return 'success';
  }

  // Get blocked users list
  Stream<QuerySnapshot> getBlockedUsers() {
    if (_currentUserId == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('blocked_users')
        .snapshots();
  }

  // Accept a friend request
  Future<String> acceptFriendRequest(String fromUserId) async {
    if (_currentUserId == null) return 'error';

    // Use a batch write to perform multiple operations atomically
    final batch = _firestore.batch();

    // 1. Add to the current user's friends list
    final currentUserFriendRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .doc(fromUserId);
    batch
        .set(currentUserFriendRef, {'timestamp': FieldValue.serverTimestamp()});

    // 2. Add to the other user's friends list
    final otherUserFriendRef = _firestore
        .collection('users')
        .doc(fromUserId)
        .collection('friends')
        .doc(_currentUserId);
    batch.set(otherUserFriendRef, {'timestamp': FieldValue.serverTimestamp()});

    // 3. Delete the friend request
    final requestRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friend_requests')
        .doc(fromUserId);
    batch.delete(requestRef);

    await batch.commit();
    return 'success';
  }

  // Decline or cancel a friend request
  Future<void> declineFriendRequest(String otherUserId) async {
    if (_currentUserId == null) return;

    // This can be used to decline a received request or cancel a sent one
    final requestRef = _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friend_requests')
        .doc(otherUserId);

    await requestRef.delete();
  }

  // Stream friend requests for the current user
  Stream<QuerySnapshot> getFriendRequests() {
    if (_currentUserId == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friend_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Stream friends for the current user
  Stream<QuerySnapshot> getFriends() {
    if (_currentUserId == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .snapshots();
  }

  // Get a leaderboard of the user and their friends
  Future<List<UserProfile>> getFriendsLeaderboard() async {
    if (_currentUserId == null) return [];

    // 1. Get the list of friend IDs
    final friendsSnapshot = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .get();

    final friendIds = friendsSnapshot.docs.map((doc) => doc.id).toList();

    // 2. Add the current user's ID to the list
    final allUserIds = [...friendIds, _currentUserId];

    if (allUserIds.length <= 1) {
      final currentUserDoc =
          await _firestore.collection('users').doc(_currentUserId).get();
      if (currentUserDoc.exists) {
        return [UserProfile.fromFirestore(currentUserDoc)];
      }
      return [];
    }

    // 3. Fetch all user profiles at once using a 'whereIn' query
    final usersSnapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: allUserIds)
        .get();

    final users = usersSnapshot.docs.map(UserProfile.fromFirestore).toList();

    // 4. Sort the users by points
    users.sort((a, b) => (b.points ?? 0).compareTo(a.points ?? 0));

    return users;
  }
}
