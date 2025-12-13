import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../utils/logger.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  FirebaseFirestore get firestore => _firestore;

  Stream<List<DocumentSnapshot>> getEnteredContests(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('entries')
          .snapshots()
          .handleError((error) {
        logger.e('Error in getEnteredContests stream', error: error);
        return <DocumentSnapshot>[];
      }).map((snapshot) => snapshot.docs);

  Future<void> recordError(
    exception,
    StackTrace? stack, {
    context,
  }) async {
    await FirebaseCrashlytics.instance
        .recordError(exception, stack, reason: context);
  }

  Future<void> recordFlutterError(
    FlutterErrorDetails flutterErrorDetails,
  ) async {
    await FirebaseCrashlytics.instance.recordFlutterError(flutterErrorDetails);
  }
}
