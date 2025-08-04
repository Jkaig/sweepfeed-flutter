import 'dart:io'; 
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sweepfeed_app/core/models/user_profile.dart';
import 'package:sweepfeed_app/core/services/gamification_service.dart';
import '../../../core/models/contest_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GamificationService _gamificationService = GamificationService();
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('userProfiles').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      } else {
        return null;
      }
    } catch (e) {
      print("Error getting user profile: $e");
      return null;
    }
  }

  Future<void> updateUserProfile(UserProfile userProfile) async {
    try {
      await _firestore
          .collection('userProfiles')
          .doc(userProfile.id)
          .set({
        'id': userProfile.id,
        'bio': userProfile.bio,
        'profilePictureUrl': userProfile.profilePictureUrl,
        'interests': userProfile.interests,
        'favoriteBrands': userProfile.favoriteBrands,
        'location': userProfile.location,
      }, SetOptions(merge: true));

      await _gamificationService.checkAndAwardSharpshooter(userProfile.id);
      
    } catch (e) {
      print("Error updating user profile: $e");
      rethrow;
    }
  }

  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final String fileName = 'profile_picture_${DateTime.now().millisecondsSinceEpoch}';
      final firebase_storage.Reference ref =
          _storage.ref('user_profile_pictures/$userId/$fileName');

      final firebase_storage.UploadTask uploadTask = ref.putFile(imageFile);
      final firebase_storage.TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading profile picture: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUserEntriesWithContestDetails(String userId) async {
    List<Map<String, dynamic>> detailedEntries = [];

    try {
      QuerySnapshot entrySnapshot = await _firestore
          .collection('user_entries')
          .where('userId', isEqualTo: userId)
          .orderBy('entryDate', descending: true)
          .get();

      if (entrySnapshot.docs.isEmpty) {
        return [];
      }

      List<String> contestIds = [];
      Map<String, Timestamp> entryDatesMap = {};

      for (var doc in entrySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
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

      List<DocumentSnapshot> contestDocs = [];
      for (int i = 0; i < contestIds.length; i += 10) {
        List<String> sublist = contestIds.sublist(i, i + 10 > contestIds.length ? contestIds.length : i + 10);
        if (sublist.isNotEmpty) {
          QuerySnapshot contestSnapshot = await _firestore
              .collection('contests')
              .where(FieldPath.documentId, whereIn: sublist)
              .get();
          contestDocs.addAll(contestSnapshot.docs);
        }
      }
      
      for (var contestDoc in contestDocs) {
        final contestData = contestDoc.data() as Map<String, dynamic>;
        contestData['id'] = contestDoc.id;
        final contest = Contest.fromJson(contestData);

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
      print("Error fetching user entries with contest details: $e");
    }
    return detailedEntries;
  }
}
