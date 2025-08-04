import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }

  Future<DocumentSnapshot> getDocument(
      String collection, String documentId) async {
    try {
      return await _firestore.collection(collection).doc(documentId).get();
    } catch (e) {
      debugPrint('Error getting document: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> streamCollection(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  Future<DocumentReference> addDocument(
      String collection, Map<String, dynamic> data) async {
    try {
      return await _firestore.collection(collection).add(data);
    } catch (e) {
      debugPrint('Error adding document: $e');
      rethrow;
    }
  }

  Future<void> updateDocument(
      String collection, String documentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      debugPrint('Error updating document: $e');
      rethrow;
    }
  }

  Future<void> deleteDocument(String collection, String documentId) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      debugPrint('Error deleting document: $e');
      rethrow;
    }
  }

  Future<DocumentSnapshot> getUserData(String userId) async {
    return await getDocument('users', userId);
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    return await updateDocument('users', userId, data);
  }

  Future<QuerySnapshot> getAllSweepstakes(
      {int limit = 20, DocumentSnapshot? startAfter, String? category}) async {
    try {
      Query query = _firestore.collection('sweepstakes').where('isActive', isEqualTo: true);

       if(category != null && category.isNotEmpty){
        query = query.where('categories', arrayContains: category);
      }

       query = query.orderBy('endDate', descending: false).limit(limit);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }      return await query.get();
    } catch (e) {
      debugPrint('Error getting active sweepstakes: $e');
      rethrow;
    }
  }
  Future<void> updateUserPreferences(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      debugPrint('Error updating user preferences: $e');
      rethrow;
    }
  }

  Future<DocumentSnapshot> getUserPreferences(String userId) async {
    try {
      return await _firestore.collection('users').doc(userId).get();
    } catch (e) {
      debugPrint('Error getting user preferences: $e');
      rethrow;
    }
  }

  Future<void> addUserEngagedSweepstakes(String userId, String sweepstakesId, List<String> categories, String? brand) async {
    final userDoc = await getUserPreferences(userId);
    Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
    List<String> engagedSweepstakes = data['engagedSweepstakes'] ?? [];
    List<String> favoriteCategories = data['favoriteCategories'] ?? [];
    List<String> favoriteBrands = data['favoriteBrands'] ?? [];

    if (!engagedSweepstakes.contains(sweepstakesId)) {
      engagedSweepstakes.add(sweepstakesId);
    }
    for(var category in categories){
        if(!favoriteCategories.contains(category)){
            favoriteCategories.add(category);
        }
    }
    if(brand != null && !favoriteBrands.contains(brand)){
        favoriteBrands.add(brand);
    }

    await updateUserPreferences(userId, {
      'engagedSweepstakes': engagedSweepstakes,
      'favoriteCategories': favoriteCategories,
      'favoriteBrands': favoriteBrands,
      'lastEngagedAt': Timestamp.now()
    });
  }

  Future<QuerySnapshot> getSweepstakesForUser(
      {required String userId, int limit = 20, DocumentSnapshot? startAfter}) async {
    try {
        final userDoc = await getUserPreferences(userId);
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        List<String> favoriteCategories = data['favoriteCategories'] ?? [];

        Query query = _firestore.collection('sweepstakes').where('isActive', isEqualTo: true);
        
        if(favoriteCategories.isNotEmpty){
            query = query.where('categories', arrayContainsAny: favoriteCategories);
        }

        query = query.orderBy('endDate', descending: false).limit(limit);
        if (startAfter != null) {
          query = query.startAfterDocument(startAfter);
        }
        return await query.get();
    } catch (e) {
      debugPrint('Error getting active sweepstakes: $e');
      rethrow;
    }
  }

  Future<void> saveSweepstakes(String userId, String sweepstakesId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_sweepstakes')
          .doc(sweepstakesId)
          .set({
        'sweepstakesId': sweepstakesId,
        'savedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error saving sweepstakes: $e');
      rethrow;
    }
  }

  Future<void> removeSavedSweepstakes(
      String userId, String sweepstakesId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_sweepstakes')
          .doc(sweepstakesId)
          .delete();
    } catch (e) {
      debugPrint('Error removing saved sweepstakes: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getSavedSweepstakes(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_sweepstakes')
        .snapshots();
  }

  Future<bool> isUserSubscribed(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

      if (data == null) return false;

      bool isSubscribed = data['isSubscribed'] ?? false;
      Timestamp? expiresAt = data['subscriptionExpiresAt'];

      if (!isSubscribed || expiresAt == null) return false;

      return expiresAt.toDate().isAfter(DateTime.now());
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      return false;
    }
  }
  Future<String> getImageUrl(String path) async {
    try {
      return await storage.ref(path).getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }
}
