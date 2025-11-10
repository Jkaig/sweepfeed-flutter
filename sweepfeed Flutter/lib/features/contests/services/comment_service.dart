import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/comment_model.dart';
import '../../../core/utils/security_utils.dart';

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

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
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

      final docRef = await _firestore.collection('comments').add(commentData);

      if (parentCommentId != null) {
        await _firestore.collection('comments').doc(parentCommentId).update({
          'replyCount': FieldValue.increment(1),
        });
      }

      final doc = await docRef.get();
      return Comment.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error posting comment: $e');
      rethrow;
    }
  }

  Future<void> editComment(String commentId, String newContent) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final commentDoc =
          await _firestore.collection('comments').doc(commentId).get();
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

      await _firestore.collection('comments').doc(commentId).update({
        'content': sanitizedContent,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error editing comment: $e');
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final commentDoc =
          await _firestore.collection('comments').doc(commentId).get();
      if (!commentDoc.exists) throw Exception('Comment not found');

      final comment = Comment.fromFirestore(commentDoc);
      if (comment.userId != user.uid) {
        throw Exception('Not authorized to delete this comment');
      }

      if (comment.hasReplies) {
        await _firestore.collection('comments').doc(commentId).update({
          'content': '[deleted]',
          'isModerated': true,
          'moderationReason': 'User deleted',
        });
      } else {
        await _firestore.collection('comments').doc(commentId).delete();
      }

      if (comment.parentCommentId != null) {
        await _firestore
            .collection('comments')
            .doc(comment.parentCommentId)
            .update({
          'replyCount': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      rethrow;
    }
  }

  Future<void> toggleLike(String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final commentDoc =
          await _firestore.collection('comments').doc(commentId).get();
      if (!commentDoc.exists) throw Exception('Comment not found');

      final comment = Comment.fromFirestore(commentDoc);
      final hasLiked = comment.likedBy.contains(user.uid);

      if (hasLiked) {
        await _firestore.collection('comments').doc(commentId).update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        await _firestore.collection('comments').doc(commentId).update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([user.uid]),
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
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

      await _firestore.collection('comment_reports').add(reportData);

      await _firestore.collection('comments').doc(commentId).update({
        'isReported': true,
      });
    } catch (e) {
      debugPrint('Error reporting comment: $e');
      rethrow;
    }
  }

  Future<int> getCommentCount(String contestId) async {
    try {
      final snapshot = await _firestore
          .collection('comments')
          .where('contestId', isEqualTo: contestId)
          .where('isModerated', isEqualTo: false)
          .get();
      return snapshot.size;
    } catch (e) {
      debugPrint('Error getting comment count: $e');
      return 0;
    }
  }

  Future<void> moderateComment({
    required String commentId,
    required bool shouldModerate,
    String? reason,
  }) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'isModerated': shouldModerate,
        'moderationReason': reason,
      });
    } catch (e) {
      debugPrint('Error moderating comment: $e');
      rethrow;
    }
  }
}
