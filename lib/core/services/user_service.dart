import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      logger.e('Error getting user profile', error: e);
      return null;
    }
  }

  Stream<UserProfile?> getUserProfileStream(String userId) => _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return UserProfile.fromFirestore(snapshot);
      }
      return null;
    }).handleError((error) {
      logger.e('Error in user profile stream', error: error);
      return null;
    });

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update(data);
    } catch (e) {
      logger.e('Error updating user profile', error: e);
    }
  }

  Future<UserProfile?> getCurrentUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return null;
      }
      return await getUserProfile(currentUser.uid);
    } catch (e) {
      logger.e('Error getting current user data', error: e);
      return null;
    }
  }

  Future<void> markOnboardingComplete(String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .set({'onboardingCompleted': true}, SetOptions(merge: true));
    
    // Verify the update was successful
    final verifyDoc = await _firestore.collection('users').doc(userId).get();
    final verified = verifyDoc.data()?['onboardingCompleted'] as bool? ?? false;
    
    if (!verified) {
      logger.e('Failed to save onboardingCompleted flag for user $userId');
      throw Exception('Failed to save onboarding completion status');
    }
    
    logger.i('Successfully saved onboardingCompleted=true for user $userId');
  }
}
