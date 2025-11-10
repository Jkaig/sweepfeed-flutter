import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInteractionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // Toggle a like on a contest
  Future<void> toggleLike(String contestId, bool isCurrentlyLiked) async {
    if (_currentUserId == null) return;

    final userRef = _firestore.collection('users').doc(_currentUserId);
    final contestRef = _firestore.collection('contests').doc(contestId);

    final batch = _firestore.batch();

    // Update the contest's like count
    batch.update(contestRef, {
      'likes': FieldValue.increment(isCurrentlyLiked ? -1 : 1),
    });

    // Add/remove from the user's list of liked contests
    batch.update(userRef, {
      'likedContests': isCurrentlyLiked
          ? FieldValue.arrayRemove([contestId])
          : FieldValue.arrayUnion([contestId]),
    });

    await batch.commit();
  }

  // Toggle a save on a contest
  Future<void> toggleSave(String contestId, bool isCurrentlySaved) async {
    if (_currentUserId == null) return;

    final userRef = _firestore.collection('users').doc(_currentUserId);

    await userRef.update({
      'savedContests': isCurrentlySaved
          ? FieldValue.arrayRemove([contestId])
          : FieldValue.arrayUnion([contestId]),
    });
  }
}
