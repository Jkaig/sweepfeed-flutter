import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/logger.dart';

/// Service to check if user has unlocked premium features from shop
class FeatureUnlockService {
  FeatureUnlockService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Check if user has unlocked a specific feature
  Future<bool> hasUnlockedFeature(String featureId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Check in user's inventory
      final inventoryDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .doc(featureId)
          .get();

      if (inventoryDoc.exists) {
        return true;
      }

      // Also check in user's unlocked features list
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final unlockedFeatures = data?['unlockedFeatures'] as List<dynamic>?;
        if (unlockedFeatures != null && unlockedFeatures.contains(featureId)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      logger.e('Error checking feature unlock status', error: e);
      return false;
    }
  }

  /// Unlock a feature for the user (called after purchase)
  Future<void> unlockFeature(String featureId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Add to inventory
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .doc(featureId)
          .set({
        'featureId': featureId,
        'unlockedAt': FieldValue.serverTimestamp(),
        'type': 'utility',
      });

      // Also add to unlocked features list
      await _firestore.collection('users').doc(user.uid).update({
        'unlockedFeatures': FieldValue.arrayUnion([featureId]),
      });

      logger.i('Unlocked feature $featureId for user ${user.uid}');
    } catch (e) {
      logger.e('Error unlocking feature', error: e);
      rethrow;
    }
  }

  /// Check if user has unlocked search feature
  Future<bool> hasUnlockedSearch() async {
    return hasUnlockedFeature('tool_search_pro');
  }

  /// Check if user has unlocked sort feature
  Future<bool> hasUnlockedSort() async {
    return hasUnlockedFeature('tool_sort_ending_soon');
  }

  /// Stream of unlock status for a feature
  Stream<bool> watchFeatureUnlock(String featureId) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('inventory')
        .doc(featureId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
