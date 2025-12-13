import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import '../../../core/models/contest.dart';
import '../../../core/models/filter_set_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/dust_bunnies_service.dart';
import '../../../core/utils/logger.dart';
import '../../auth/services/auth_service.dart';

class ProfileService {
  ProfileService(this._gamificationService, {FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore firestore;
  final DustBunniesService _gamificationService;
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final DocumentSnapshot doc =
          await firestore.collection('userProfiles').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      } else {
        return null;
      }
    } catch (e) {
      logger.e('Error getting user profile', error: e);
      return null;
    }
  }

  Future<void> updateUserProfile(UserProfile userProfile) async {
    try {
      await firestore.collection('userProfiles').doc(userProfile.id).set(
        {
          'id': userProfile.id,
          'bio': userProfile.bio,
          'profilePictureUrl': userProfile.profilePictureUrl,
          'interests': userProfile.interests,
          'favoriteBrands': userProfile.favoriteBrands,
          'location': userProfile.location,
        },
        SetOptions(merge: true),
      );

      await _gamificationService.checkAndAwardEntryEnthusiast(userProfile.id);
    } catch (e) {
      logger.e('Error updating user profile', error: e);
      rethrow;
    }
  }

  Future<void> addNegativePreference(String userId, String category) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.update({
      'negativePreferences': FieldValue.arrayUnion([category]),
    });
  }

  Future<void> removeNegativePreference(String userId, String category) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.update({
      'negativePreferences': FieldValue.arrayRemove([category]),
    });
  }

  Future<void> updateInterests(String userId, List<String> interests) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.update({'interests': interests});
  }

  Future<void> updateCharities(String userId, List<String> charityIds) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.update({'selectedCharityIds': charityIds});
  }

  // --- Filter Set Management ---

  Stream<List<FilterSet>> getFilterSets(String userId) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('filter_sets')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => FilterSet.fromFirestore(doc.data(), doc.id))
                .toList(),
          );

  Future<void> saveFilterSet(String userId, FilterSet filterSet) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('filter_sets')
        .doc(filterSet.id) // Use the object's ID for the document ID
        .set(filterSet.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteFilterSet(String userId, String filterSetId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('filter_sets')
        .doc(filterSetId)
        .delete();
  }

  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw Exception('User not authenticated');
      }

      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        logger.w('Profile picture exceeds 5MB limit');
        return null;
      }

      final fileName = imageFile.path.split('/').last.toLowerCase();
      final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
      final hasValidExtension = validExtensions.any(fileName.endsWith);

      if (!hasValidExtension) {
        logger.w('Invalid profile picture file type: $fileName');
        return null;
      }

      final uploadFileName =
          'profile_picture_${DateTime.now().millisecondsSinceEpoch}${fileName.substring(fileName.lastIndexOf('.'))}';
      final ref = _storage.ref('user_profile_pictures/$userId/$uploadFileName');

      final uploadTask = ref.putFile(
        imageFile,
        firebase_storage.SettableMetadata(
          contentType: _getContentType(fileName),
          customMetadata: {'uploadedBy': userId},
        ),
      );
      final snapshot = await uploadTask;

      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      logger.e('Error uploading profile picture', error: e);
      return null;
    }
  }

  String _getContentType(String fileName) {
    if (fileName.endsWith('.png')) return 'image/png';
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (fileName.endsWith('.gif')) return 'image/gif';
    if (fileName.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> deleteUserAccount(AuthService authService) async {
    try {
      await authService.deleteAccount();
    } catch (e) {
      logger.e('Error deleting user account from ProfileService', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserEntriesWithContestDetails(
    String userId,
  ) async {
    final detailedEntries = <Map<String, dynamic>>[];

    try {
      final QuerySnapshot entrySnapshot = await firestore
          .collection('user_entries')
          .where('userId', isEqualTo: userId)
          .orderBy('entryDate', descending: true)
          .get();

      if (entrySnapshot.docs.isEmpty) {
        return [];
      }

      final contestIds = <String>[];
      final entryDatesMap = <String, Timestamp>{};

      for (final doc in entrySnapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        final contestId = data['contestId'] as String?;
        final entryDate = data['entryDate'] as Timestamp?;

        if (contestId != null && entryDate != null) {
          contestIds.add(contestId);
          entryDatesMap[contestId] = entryDate;
        }
      }

      if (contestIds.isEmpty) {
        return [];
      }

      final contestDocs = <DocumentSnapshot>[];
      for (var i = 0; i < contestIds.length; i += 10) {
        final sublist = contestIds.sublist(
          i,
          i + 10 > contestIds.length ? contestIds.length : i + 10,
        );
        if (sublist.isNotEmpty) {
          final QuerySnapshot contestSnapshot = await firestore
              .collection('contests')
              .where(FieldPath.documentId, whereIn: sublist)
              .get();
          contestDocs.addAll(contestSnapshot.docs);
        }
      }

      for (final contestDoc in contestDocs) {
        final contestData = contestDoc.data()! as Map<String, dynamic>;
        contestData['id'] = contestDoc.id;
        final contest = Contest.fromJson(contestData, contestDoc.id);

        final entryDate = entryDatesMap[contest.id];

        if (entryDate != null) {
          detailedEntries.add({
            'contestName': contest.title,
            'entryDate': entryDate.toDate(),
            'prize': contest.prize,
          });
        }
      }
    } catch (e) {
      logger.e('Error fetching user entries with contest details', error: e);
    }
    return detailedEntries;
  }
}