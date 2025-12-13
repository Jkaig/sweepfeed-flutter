import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/comment_model.dart';
import '../../../core/security/security_utils.dart';
import '../../../core/utils/logger.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int maxCommentLength = 500;
  static const int maxRepliesDepth = 3;

  Stream<List<Comment>> getContestComments(String contestId) => _firestore
      .collection('comments')
      .where('contestId', isEqualTo: contestId)
      .where('parentCommentId', isNull: true)
      .where('isModerated', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Comment.fromFirestore).toList(),
      );

  Stream<List<Comment>> getCommentReplies(String parentCommentId) => _firestore
      .collection('comments')
      .where('parentCommentId', isEqualTo: parentCommentId)
      .where('isModerated', isEqualTo: false)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Comment.fromFirestore).toList(),
      );

  Future<Comment?> postComment({
    required String contestId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final sanitizedContent = SecurityUtils.sanitizeString(content);

      if (sanitizedContent.isEmpty) {
        throw Exception('Comment content cannot be empty after sanitization');
      }

      if (sanitizedContent.length > maxCommentLength) {
        throw Exception(
          'Comment exceeds maximum length of $maxCommentLength characters',
        );
      }

      if (SecurityUtils.containsSqlInjectionPattern(sanitizedContent)) {
        throw Exception('Invalid content detected');
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              logger.w('getUserDoc query timed out in postComment');
              throw TimeoutException('Query timed out');
            },
          );
      final userData = userDoc.data();

      final commentData = {
        'contestId': contestId,
        'userId': user.uid,
        'userName': userData?['displayName'] ?? user.displayName ?? 'Anonymous',
        'userPhotoUrl': userData?['photoUrl'] ?? user.photoURL,
        'content': sanitizedContent,
        'createdAt': FieldValue.serverTimestamp(),
        'editedAt': null,
        'likes': 0,
        'likedBy': [],
        'isReported': false,
        'isModerated': false,
        'moderationReason': null,
        'parentCommentId': parentCommentId,
        'replyCount': 0,
      };

      final docRef = await _firestore
          .collection('comments')
          .add(commentData)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              logger.w('add comment operation timed out');
              throw TimeoutException('Comment submission timed out');
            },
          );

      if (parentCommentId != null) {
        await _firestore
            .collection('comments')
            .doc(parentCommentId)
            .update({
          'replyCount': FieldValue.increment(1),
        }).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            logger.w('update replyCount timed out');
            throw TimeoutException('Update timed out');
          },
        );
      }

      final doc = await docRef.get().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              logger.w('get comment doc timed out');
              throw TimeoutException('Query timed out');
            },
          );
      return Comment.fromFirestore(doc);
    } catch (e) {
      logger.e('Error posting comment', error: e);
      rethrow;
    }
  }

  Future<void> editComment(String commentId, String newContent) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final commentDoc = await _firestore
          .collection('comments')
          .doc(commentId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              logger.w('get comment doc timed out in editComment');
              throw TimeoutException('Query timed out');
            },
          );
      if (!commentDoc.exists) throw Exception('Comment not found');

      final comment = Comment.fromFirestore(commentDoc);
      if (comment.userId != user.uid) {
        throw Exception('Not authorized to edit this comment');
      }

      final sanitizedContent = SecurityUtils.sanitizeString(newContent);

      if (sanitizedContent.isEmpty) {
        throw Exception('Comment content cannot be empty after sanitization');
      }

      if (sanitizedContent.length > maxCommentLength) {
        throw Exception(
          'Comment exceeds maximum length of $maxCommentLength characters',
        );
      }

      await _firestore
          .collection('comments')
          .doc(commentId)
          .update({
        'content': sanitizedContent,
        'editedAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          logger.w('update comment timed out');
          throw TimeoutException('Update timed out');
        },
      );
    } catch (e) {
      logger.e('Error editing comment', error: e);
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final commentDoc = await _firestore
          .collection('comments')
          .doc(commentId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              logger.w('get comment doc timed out in editComment');
              throw TimeoutException('Query timed out');
            },
          );
      if (!commentDoc.exists) throw Exception('Comment not found');

      final comment = Comment.fromFirestore(commentDoc);
      if (comment.userId != user.uid) {
        throw Exception('Not authorized to delete this comment');
      }

      // Use batch for atomic operations
      final batch = _firestore.batch();
      final commentRef = _firestore.collection('comments').doc(commentId);

      if (comment.hasReplies) {
        batch.update(commentRef, {
          'content': '[deleted]',
          'isModerated': true,
          'moderationReason': 'User deleted',
        });
      } else {
        batch.delete(commentRef);
      }

      if (comment.parentCommentId != null) {
        batch.update(
          _firestore.collection('comments').doc(comment.parentCommentId),
          {
            'replyCount': FieldValue.increment(-1),
          },
        );
      }

      await batch.commit().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              logger.w('delete comment batch commit timed out');
              throw TimeoutException('Delete operation timed out');
            },
          );
    } catch (e) {
      logger.e('Error deleting comment', error: e);
      rethrow;
    }
  }

  Future<void> toggleLike(String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final commentDoc = await _firestore
          .collection('comments')
          .doc(commentId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              logger.w('get comment doc timed out in editComment');
              throw TimeoutException('Query timed out');
            },
          );
      if (!commentDoc.exists) throw Exception('Comment not found');

      final comment = Comment.fromFirestore(commentDoc);
      final hasLiked = comment.likedBy.contains(user.uid);

      final commentRef = _firestore.collection('comments').doc(commentId);
      
      if (hasLiked) {
        await commentRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([user.uid]),
        }).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            logger.w('unlike comment timed out');
            throw TimeoutException('Update timed out');
          },
        );
      } else {
        await commentRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([user.uid]),
        }).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            logger.w('like comment timed out');
            throw TimeoutException('Update timed out');
          },
        );
      }
    } catch (e) {
      logger.e('Error toggling like', error: e);
      rethrow;
    }
  }

  Future<void> reportComment(String commentId, String reason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final reportData = {
        'commentId': commentId,
        'reportedBy': user.uid,
        'reason': SecurityUtils.sanitizeString(reason),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      // Use batch for atomic operations
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('comment_reports').doc(),
        reportData,
      );
      batch.update(
        _firestore.collection('comments').doc(commentId),
        {
          'isReported': true,
        },
      );

      await batch.commit().timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              logger.w('report comment batch commit timed out');
              throw TimeoutException('Report operation timed out');
            },
          );
    } catch (e) {
      logger.e('Error reporting comment', error: e);
      rethrow;
    }
  }

  Future<int> getCommentCount(String contestId) async {
    try {
      final snapshot = await _firestore
          .collection('comments')
          .where('contestId', isEqualTo: contestId)
          .where('isModerated', isEqualTo: false)
          .get()
          .timeout(
            const Duration(seconds: 10),
          );
      return snapshot.size;
    } catch (e) {
      logger.e('Error getting comment count', error: e);
      return 0;
    }
  }

  Future<void> moderateComment({
    required String commentId,
    required bool shouldModerate,
    String? reason,
  }) async {
    try {
      await _firestore
          .collection('comments')
          .doc(commentId)
          .update({
        'isModerated': shouldModerate,
        'moderationReason': reason,
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          logger.w('moderate comment timed out');
          throw TimeoutException('Update timed out');
        },
      );
    } catch (e) {
      logger.e('Error moderating comment', error: e);
      rethrow;
    }
  }
}
