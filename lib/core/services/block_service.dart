import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get list of blocked user IDs for the current user
  Future<List<String>> getBlockedUsers() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        logger.w('Cannot get blocked users: user not authenticated');
        return [];
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              logger.w('getBlockedUsers query timed out');
              throw TimeoutException('Query timed out');
            },
          );

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      logger.e('Error getting blocked users', error: e);
      return [];
    }
  }

  /// Block a user
  Future<void> blockUser(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (currentUser.uid == userId) {
        throw Exception('Cannot block yourself');
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .doc(userId)
          .set({
        'blockedAt': FieldValue.serverTimestamp(),
      });

      logger.i('User $userId blocked by ${currentUser.uid}');
    } catch (e) {
      logger.e('Error blocking user: $userId', error: e);
      rethrow;
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .doc(userId)
          .delete();

      logger.i('User $userId unblocked by ${currentUser.uid}');
    } catch (e) {
      logger.e('Error unblocking user: $userId', error: e);
      rethrow;
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('blockedUsers')
          .doc(userId)
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              logger.w('isUserBlocked query timed out');
              throw TimeoutException('isUserBlocked query timed out');
            },
          );

      return doc.exists;
    } catch (e) {
      logger.e('Error checking if user is blocked: $userId', error: e);
      return false;
    }
  }
}

final blockServiceProvider = Provider<BlockService>((ref) => BlockService());
