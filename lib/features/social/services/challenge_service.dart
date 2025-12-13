import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../auth/services/auth_service.dart' hide authServiceProvider;
import '../models/challenge.dart';

class ChallengeService {
  ChallengeService(this._firestore, this._authService);

  final FirebaseFirestore _firestore;
  final AuthService _authService;

  Future<void> createChallenge(String challengedId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    final challenge = {
      'challengerId': currentUser.uid,
      'challengedId': challengedId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 7)), // Challenges expire in 7 days
      ),
    };

    await _firestore.collection('challenges').add(challenge);
  }

  Future<void> acceptChallenge(String challengeId) async {
    await _firestore.collection('challenges').doc(challengeId).update({
      'status': 'accepted',
    });
  }

  Future<void> declineChallenge(String challengeId) async {
    await _firestore.collection('challenges').doc(challengeId).update({
      'status': 'declined',
    });
  }

  Stream<List<Challenge>> getChallenges() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('challenges')
        .where('challengedId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return Challenge(
          id: doc.id,
          challengerId: data['challengerId'] as String,
          challengedId: data['challengedId'] as String,
          status: ChallengeStatus.values
              .firstWhere((e) => e.toString() == 'ChallengeStatus.${data['status']}'),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          expiresAt: (data['expiresAt'] as Timestamp).toDate(),
        );
      }).toList(),);
  }
}

final challengeServiceProvider = Provider((ref) {
  final firestore = FirebaseFirestore.instance;
  final authService = ref.watch(authServiceProvider);
  return ChallengeService(firestore, authService);
});
