import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> awardPoints(String userId, int points) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'points': FieldValue.increment(points),
      });
    } catch (e) {
      logger.e('Error awarding points', error: e);
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

  Future<bool> claimReward(String userId, String rewardId, int points) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'points': FieldValue.increment(-points),
        'claimedRewards': FieldValue.arrayUnion([rewardId]),
      });
      return true;
    } catch (e) {
      logger.e('Error claiming reward', error: e);
      return false;
    }
  }
}
