import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> awardDustBunnies(String userId, int dustBunnies) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'dustBunniesBalance': FieldValue.increment(dustBunnies),
      });
    } catch (e) {
      logger.e('Error awarding dustbunnies', error: e);
    }
  }

  Future<void> unlockAchievement(String userId, String achievementId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'achievements': FieldValue.arrayUnion([achievementId]),
      });
    } catch (e) {
      logger.e('Error unlocking achievement', error: e);
    }
  }

  Future<bool> claimReward(String userId, String rewardId, int dustBunnies) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'dustBunniesBalance': FieldValue.increment(-dustBunnies),
        'claimedRewards': FieldValue.arrayUnion([rewardId]),
      });
      return true;
    } catch (e) {
      logger.e('Error claiming reward', error: e);
      return false;
    }
  }
}
