import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';
import '../models/referral_code_model.dart';

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // COMMENTS

  Future<void> postComment({
    required String contestId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    await _firestore
        .collection('contests')
        .doc(contestId)
        .collection('comments')
        .add({
      'userId': user.uid,
      'userName': userData?['name'] ?? 'Anonymous',
      'userProfilePicture': userData?['profilePictureUrl'],
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'upvotes': 0,
      'upvotedBy': [],
      'reports': 0,
      'reportedBy': [],
      'isHelpful': false,
    });
  }

  Future<void> upvoteComment({
    required String contestId,
    required String commentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final commentRef = _firestore
        .collection('contests')
        .doc(contestId)
        .collection('comments')
        .doc(commentId);

    await _firestore.runTransaction((transaction) async {
      final commentDoc = await transaction.get(commentRef);
      if (!commentDoc.exists) throw Exception('Comment not found');

      final upvotedBy =
          List<String>.from(commentDoc.data()?['upvotedBy'] ?? []);

      if (upvotedBy.contains(user.uid)) {
        // Remove upvote
        upvotedBy.remove(user.uid);
        transaction.update(commentRef, {
          'upvotedBy': upvotedBy,
          'upvotes': FieldValue.increment(-1),
        });
      } else {
        // Add upvote
        upvotedBy.add(user.uid);
        transaction.update(commentRef, {
          'upvotedBy': upvotedBy,
          'upvotes': FieldValue.increment(1),
        });

        // Mark as helpful if it reaches 10 upvotes
        if (upvotedBy.length >= 10) {
          transaction.update(commentRef, {'isHelpful': true});
        }
      }
    });
  }

  Future<void> reportComment({
    required String contestId,
    required String commentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final commentRef = _firestore
        .collection('contests')
        .doc(contestId)
        .collection('comments')
        .doc(commentId);

    await _firestore.runTransaction((transaction) async {
      final commentDoc = await transaction.get(commentRef);
      if (!commentDoc.exists) throw Exception('Comment not found');

      final reportedBy =
          List<String>.from(commentDoc.data()?['reportedBy'] ?? []);

      if (!reportedBy.contains(user.uid)) {
        reportedBy.add(user.uid);
        transaction.update(commentRef, {
          'reportedBy': reportedBy,
          'reports': FieldValue.increment(1),
        });
      }
    });
  }
        
            Stream<List<ContestComment>> getComments(String contestId) =>
                _firestore
                    .collection('contests')
                    .doc(contestId)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .where('reports', isLessThan: 5) // Hide heavily reported comments
                    .snapshots()
                    .map(
                      (snapshot) => snapshot.docs
                          .map((doc) => ContestComment.fromMap(doc.data(), doc.id))
                          .toList(),
                    );
  Stream<List<ContestComment>> getHelpfulComments(String contestId) =>
      _firestore
          .collection('contests')
          .doc(contestId)
          .collection('comments')
          .where('isHelpful', isEqualTo: true)
          .where('reports', isLessThan: 5)
          .orderBy('upvotes', descending: true)
          .limit(10)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ContestComment.fromMap(doc.data(), doc.id))
                .toList(),
          );

  // REFERRAL CODES

  Future<String> postReferralCode({
    required String contestId,
    required String code,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    // Check if user already posted a code for this contest
    final existingCode = await _firestore
        .collection('contests')
        .doc(contestId)
        .collection('referralCodes')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (existingCode.docs.isNotEmpty) {
      throw Exception(
        'You already posted a referral code for this contest',
      );
    }

    final docRef = await _firestore
        .collection('contests')
        .doc(contestId)
        .collection('referralCodes')
        .add({
      'userId': user.uid,
      'userName': userData?['name'] ?? 'Anonymous',
      'userProfilePicture': userData?['profilePictureUrl'],
      'code': code,
      'timestamp': FieldValue.serverTimestamp(),
      'uses': 0,
      'reports': 0,
      'reportedBy': [],
      'usedBy': [],
    });

    // Initialize referral chain
    await _firestore.collection('referrals').doc(docRef.id).set({
      'parentUserId': user.uid,
      'children': {},
    });

    return docRef.id;
  }

  Future<void> useReferralCode({
    required String contestId,
    required String referralCodeId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if user already used a code for this contest
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final usedCodes = List<String>.from(userData?['referralCodesUsed'] ?? []);

    // Check if this specific code was already used
    if (usedCodes.contains(referralCodeId)) {
      throw Exception('You already used this referral code');
    }

    final codeRef = _firestore
        .collection('contests')
        .doc(contestId)
        .collection('referralCodes')
        .doc(referralCodeId);

    final referralChainRef =
        _firestore.collection('referrals').doc(referralCodeId);

    await _firestore.runTransaction((transaction) async {
      final codeDoc = await transaction.get(codeRef);
      if (!codeDoc.exists) throw Exception('Referral code not found');

      final codeOwnerId = codeDoc.data()?['userId'];
      if (codeOwnerId == user.uid) {
        throw Exception('You cannot use your own referral code');
      }

      // Increment uses
      transaction.update(codeRef, {
        'uses': FieldValue.increment(1),
        'usedBy': FieldValue.arrayUnion([user.uid]),
      });

      // Add to referral chain
      transaction.set(
        referralChainRef,
        {
          'children': {
            user.uid: {
              'timestamp': FieldValue.serverTimestamp(),
            },
          },
        },
        SetOptions(merge: true),
      );

      // Add to user's used codes
      transaction.update(_firestore.collection('users').doc(user.uid), {
        'referralCodesUsed': FieldValue.arrayUnion([referralCodeId]),
      });

      // Send notification to code owner (handled by Cloud Function trigger)
    });
  }

  Future<void> reportReferralCode({
    required String contestId,
    required String referralCodeId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final codeRef = _firestore
        .collection('contests')
        .doc(contestId)
        .collection('referralCodes')
        .doc(referralCodeId);

    await _firestore.runTransaction((transaction) async {
      final codeDoc = await transaction.get(codeRef);
      if (!codeDoc.exists) throw Exception('Referral code not found');

      final reportedBy = List<String>.from(codeDoc.data()?['reportedBy'] ?? []);

      if (!reportedBy.contains(user.uid)) {
        reportedBy.add(user.uid);
        transaction.update(codeRef, {
          'reportedBy': reportedBy,
          'reports': FieldValue.increment(1),
        });
      }
    });
  }

  Stream<List<ReferralCode>> getReferralCodes(String contestId) =>
      _firestore
          .collection('contests')
          .doc(contestId)
          .collection('referralCodes')
          .orderBy('uses', descending: true)
          .where('reports', isLessThan: 5) // Hide heavily reported codes
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ReferralCode.fromMap(doc.data(), doc.id))
                .toList(),
          );

  Future<ReferralChain?> getReferralChain(String referralCodeId) async {
    final doc =
        await _firestore.collection('referrals').doc(referralCodeId).get();
    if (!doc.exists) return null;
    return ReferralChain.fromMap(doc.data()!, doc.id);
  }

  Stream<ReferralChain?> getReferralChainStream(String referralCodeId) =>
      _firestore
          .collection('referrals')
          .doc(referralCodeId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        return ReferralChain.fromMap(doc.data()!, doc.id);
      });
}

final socialService = SocialService();
