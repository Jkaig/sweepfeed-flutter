import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sweepfeed_app/core/models/comment.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Comment>> getCommentsForSweepstake(String sweepstakeId) async {
    try {
      QuerySnapshot commentSnapshot = await _firestore
          .collection('comments')
          .where('sweepstakeId', isEqualTo: sweepstakeId)
          .orderBy('timestamp', descending: true)
          .get();

      return commentSnapshot.docs
          .map((doc) => Comment.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error getting comments: $e");
      return [];
    }
  }

  Future<void> postComment(
    String userId,
    String sweepstakeId,
    String text, {
    String? parentCommentId,
  }) async {
    try {
      String commentId = _firestore.collection('comments').doc().id;

      await _firestore.collection('comments').doc(commentId).set({
        'id': commentId,
        'userId': userId,
        'sweepstakeId': sweepstakeId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'parentCommentId': parentCommentId,
      });
    } catch (e) {
      print("Error posting comment: $e");
      rethrow;
    }
  }

  Future<void> replyToComment(
    String userId,
    String sweepstakeId,
    String text,
    String parentCommentId,
  ) async {
    await postComment(
      userId,
      sweepstakeId,
      text,
      parentCommentId: parentCommentId,
    );
  }
}