import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/models/winner_model.dart';
import '../../../core/utils/logger.dart';

class WinnerVerificationService {
  factory WinnerVerificationService() => _instance;
  WinnerVerificationService._internal();
  static final WinnerVerificationService _instance =
      WinnerVerificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference get _winnersCollection =>
      _firestore.collection('winners');
  CollectionReference get _verificationCollection =>
      _firestore.collection('winner_verifications');

  /// Submit an external win claim
  Future<void> submitExternalWin({
    required String contestName,
    required String prizeDescription,
    required double prizeValue,
    required File proofImage,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // 1. Upload proof image
      final fileName =
          'external_win_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('verification_documents/${user.uid}/$fileName');
      
      final uploadTask = await ref.putFile(proofImage);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 2. Create winner record with 'pending' status and 'external' type
      final now = DateTime.now();
      final winnerData = {
        'userId': user.uid,
        'contestTitle': contestName,
        'prizeDescription': prizeDescription,
        'prizeValue': prizeValue,
        'winDate': Timestamp.fromDate(now),
        'status': 'pending_review', // Specific status for external claims
        'claimMethod': 'external',
        'isExternal': true,
        'proofImageUrl': downloadUrl,
        'userNotes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userName': user.displayName ?? 'Anonymous',
        'userAvatar': user.photoURL,
      };

      final docRef = await _winnersCollection.add(winnerData);

      // 3. Log event
      await _logWinnerEvent(docRef.id, 'external_win_submitted', {
        'contestName': contestName,
        'prizeValue': prizeValue,
      });

      logger.i('External win submitted: ${docRef.id}');
    } catch (e) {
      logger.e('Error submitting external win', error: e);
      rethrow;
    }
  }

  /// Announce a new winner
  Future<Winner> announceWinner({
    required String userId,
    required String contestId,
    required String contestTitle,
    required String prizeDescription,
    required double prizeValue,
    required PrizeClaimMethod claimMethod,
    List<String> requiredDocuments = const [],
  }) async {
    final now = DateTime.now();
    final claimDeadline = now.add(const Duration(days: 30)); // 30 days to claim

    final winner = Winner(
      id: '',
      userId: userId,
      contestId: contestId,
      contestTitle: contestTitle,
      prizeDescription: prizeDescription,
      prizeValue: prizeValue,
      winDate: now,
      claimDeadline: claimDeadline,
      status: WinnerStatus.pending,
      claimMethod: claimMethod,
      requiredDocuments: requiredDocuments,
      createdAt: now,
      updatedAt: now,
    );

    // Save to Firestore
    final docRef = await _winnersCollection.add(winner.toFirestore());
    final savedWinner = winner.copyWith(id: docRef.id);

    // Send notification to winner
    await _sendWinnerNotification(savedWinner);

    // Log winner announcement
    await _logWinnerEvent(savedWinner.id, 'winner_announced', {
      'contestId': contestId,
      'prizeValue': prizeValue,
    });

    return savedWinner;
  }

  /// Get all winners for a user
  Future<List<Winner>> getUserWinners(String userId) async {
    final snapshot = await _winnersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('winDate', descending: true)
        .get();

    return snapshot.docs.map(Winner.fromFirestore).toList();
  }

  /// Get pending winners (for admin)
  Future<List<Winner>> getPendingWinners() async {
    final snapshot = await _winnersCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('winDate', descending: false)
        .get();

    return snapshot.docs.map(Winner.fromFirestore).toList();
  }

  /// Get all winners (for admin)
  Future<List<Winner>> getAllWinners() async {
    final snapshot = await _winnersCollection
        .orderBy('winDate', descending: true)
        .get();

    return snapshot.docs.map(Winner.fromFirestore).toList();
  }

  /// Update winner status (public method for admin)
  Future<void> updateWinnerStatus(
    String winnerId,
    WinnerStatus status, {
    String? reason,
  }) async {
    await _updateWinnerStatus(winnerId, status, reason: reason);
  }

  /// Submit verification documents
  Future<bool> submitVerificationDocument({
    required String winnerId,
    required String documentType,
    required File documentFile,
  }) async {
    try {
      // Upload document to Firebase Storage
      final fileName =
          '${winnerId}_${documentType}_${DateTime.now().millisecondsSinceEpoch}';
      final ref =
          _storage.ref().child('verification_documents/$winnerId/$fileName');

      final uploadTask = await ref.putFile(documentFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update winner document
      await _winnersCollection.doc(winnerId).update({
        'submittedDocuments': FieldValue.arrayUnion([documentType]),
        'verificationData.$documentType': {
          'url': downloadUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
          'fileName': fileName,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log verification document submission
      await _logWinnerEvent(winnerId, 'document_submitted', {
        'documentType': documentType,
        'fileName': fileName,
      });

      // Check if verification is complete
      final winner = await getWinner(winnerId);
      if (winner != null && winner.isVerificationComplete) {
        await _updateWinnerStatus(winnerId, WinnerStatus.verified);
      }

      return true;
    } catch (e) {
      // Handle and log errors appropriately
      return false;
    }
  }

  /// Update winner status
  Future<void> _updateWinnerStatus(
    String winnerId,
    WinnerStatus status, {
    String? reason,
  }) async {
    await _winnersCollection.doc(winnerId).update({
      'status': status.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
      if (reason != null) 'rejectionReason': reason,
    });

    // Send status update notification
    final winner = await getWinner(winnerId);
    if (winner != null) {
      await _sendStatusUpdateNotification(winner, status, reason);
    }

    // Log status change
    await _logWinnerEvent(winnerId, 'status_updated', {
      'newStatus': status.toString(),
      'reason': reason,
    });
  }

  /// Get single winner
  Future<Winner?> getWinner(String winnerId) async {
    final doc = await _winnersCollection.doc(winnerId).get();
    if (doc.exists) {
      return Winner.fromFirestore(doc);
    }
    return null;
  }

  /// Verify winner (admin function)
  Future<void> verifyWinner(String winnerId, {String? notes}) async {
    await _updateWinnerStatus(winnerId, WinnerStatus.verified);

    if (notes != null) {
      await _winnersCollection.doc(winnerId).update({
        'verificationData.adminNotes': notes,
      });
    }
  }

  /// Reject winner verification (admin function)
  Future<void> rejectWinnerVerification(String winnerId, String reason) async {
    await _updateWinnerStatus(winnerId, WinnerStatus.disputed, reason: reason);
  }

  /// Mark prize as claimed
  Future<void> markPrizeClaimed({
    required String winnerId,
    required Map<String, dynamic> claimData,
  }) async {
    await _winnersCollection.doc(winnerId).update({
      'status': WinnerStatus.claimed.toString().split('.').last,
      'claimData': claimData,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log prize claim
    await _logWinnerEvent(winnerId, 'prize_claimed', claimData);

    // Send claim confirmation notification
    final winner = await getWinner(winnerId);
    if (winner != null) {
      await _sendPrizeClaimedNotification(winner);
    }
  }

  /// Get winner statistics
  Future<Map<String, dynamic>> getWinnerStatistics() async {
    final allWinnersSnapshot = await _winnersCollection.get();
    final winners = allWinnersSnapshot.docs.map(Winner.fromFirestore).toList();

    final totalWinners = winners.length;
    final pendingVerification = winners.where((w) => w.isPending).length;
    final verified = winners.where((w) => w.isVerified).length;
    final claimed = winners.where((w) => w.isClaimed).length;
    final disputed = winners.where((w) => w.isDisputed).length;
    final expired = winners.where((w) => w.isExpired).length;

    final totalPrizeValue =
        winners.fold<double>(0, (sum, winner) => sum + winner.prizeValue);
    final claimedPrizeValue = winners
        .where((w) => w.isClaimed)
        .fold<double>(0, (sum, winner) => sum + winner.prizeValue);

    return {
      'totalWinners': totalWinners,
      'pendingVerification': pendingVerification,
      'verified': verified,
      'claimed': claimed,
      'disputed': disputed,
      'expired': expired,
      'totalPrizeValue': totalPrizeValue,
      'claimedPrizeValue': claimedPrizeValue,
      'claimRate': totalWinners > 0 ? (claimed / totalWinners) * 100 : 0,
    };
  }

  /// Check for expired claims and update status
  Future<void> processExpiredClaims() async {
    final now = DateTime.now();
    final expiredSnapshot = await _winnersCollection
        .where('claimDeadline', isLessThan: Timestamp.fromDate(now))
        .where('status', whereIn: ['pending', 'verified']).get();

    for (final doc in expiredSnapshot.docs) {
      await _updateWinnerStatus(doc.id, WinnerStatus.expired);
    }
  }

  /// Helper to send a notification by adding it to the user's notification collection
  Future<void> _sendNotification(String userId, String title, String body, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'title': title,
        'body': body,
        'data': data,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'winner_update', // Used for icon/color logic in UI
      });
      logger.i('Notification sent to user $userId: $title');
    } catch (e) {
      logger.e('Error sending notification to user $userId', error: e);
    }
  }

  /// Sends a notification to the user about their win.
  Future<void> _sendWinnerNotification(Winner winner) async {
    await _sendNotification(
      winner.userId,
      '🎉 You Won!',
      'Congratulations! You won ${winner.prizeDescription} in ${winner.contestTitle}. Tap to claim.',
      {'winnerId': winner.id, 'contestId': winner.contestId},
    );
  }

  /// Sends a notification to the user about a status update.
  Future<void> _sendStatusUpdateNotification(
    Winner winner,
    WinnerStatus status,
    String? reason,
  ) async {
    String title;
    String body;

    switch (status) {
      case WinnerStatus.verified:
        title = 'Verification Approved ✅';
        body = 'Your documents have been verified! We are preparing your prize.';
        break;
      case WinnerStatus.disputed:
        title = 'Verification Issue ⚠️';
        body = 'There is an issue with your verification: $reason. Please check the app.';
        break;
      case WinnerStatus.claimed:
        title = 'Prize Claimed 🎁';
        body = 'Your prize is on its way!';
        break;
      case WinnerStatus.expired:
        title = 'Claim Expired ⏰';
        body = 'The claim period for your prize has ended.';
        break;
      default:
        title = 'Status Update';
        body = 'Your prize status has been updated to: ${status.name}';
    }

    await _sendNotification(
      winner.userId,
      title,
      body,
      {'winnerId': winner.id, 'status': status.toString()},
    );
  }

  /// Sends a notification that the prize has been claimed.
  Future<void> _sendPrizeClaimedNotification(Winner winner) async {
    await _sendNotification(
      winner.userId,
      'Prize On The Way! 🚚',
      'We have processed your claim for ${winner.prizeDescription}.',
      {'winnerId': winner.id},
    );
  }

  /// Log winner events for audit trail
  Future<void> _logWinnerEvent(
    String winnerId,
    String eventType,
    Map<String, dynamic> data,
  ) async {
    await _verificationCollection.add({
      'winnerId': winnerId,
      'eventType': eventType,
      'data': data,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': _auth.currentUser?.uid,
    });
  }

  /// Get verification history for a winner
  Future<List<Map<String, dynamic>>> getVerificationHistory(
    String winnerId,
  ) async {
    final snapshot = await _verificationCollection
        .where('winnerId', isEqualTo: winnerId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => {
            'id': doc.id,
            ...doc.data()! as Map<String, dynamic>,
          },
        )
        .toList();
  }

  /// Dispute resolution
  Future<void> initiateDispute({
    required String winnerId,
    required String reason,
    required String userStatement,
  }) async {
    await _winnersCollection.doc(winnerId).update({
      'status': WinnerStatus.disputed.toString().split('.').last,
      'disputeData': {
        'reason': reason,
        'userStatement': userStatement,
        'initiatedAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _logWinnerEvent(winnerId, 'dispute_initiated', {
      'reason': reason,
      'userStatement': userStatement,
    });
  }

  /// Resolve dispute
  Future<void> resolveDispute({
    required String winnerId,
    required WinnerStatus resolution,
    required String adminNotes,
  }) async {
    await _winnersCollection.doc(winnerId).update({
      'status': resolution.toString().split('.').last,
      'disputeData.resolvedAt': FieldValue.serverTimestamp(),
      'disputeData.resolution': resolution.toString(),
      'disputeData.adminNotes': adminNotes,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _logWinnerEvent(winnerId, 'dispute_resolved', {
      'resolution': resolution.toString(),
      'adminNotes': adminNotes,
    });
  }
}
