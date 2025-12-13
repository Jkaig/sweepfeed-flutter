import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/profile/models/user_preferences_model.dart';
import '../utils/logger.dart';
import 'personalization_engine.dart';

class UserPreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PersonalizationEngine _personalizationEngine = PersonalizationEngine();

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _preferencesCollection =>
      _firestore.collection('users').doc(_userId).collection('preferences');

  Stream<UserPreferences> getPreferences() {
    if (_userId == null) return Stream.value(UserPreferences());

    return _preferencesCollection.doc('main').snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserPreferences.fromMap(doc.data()!);
      }
      return UserPreferences();
    }).handleError((error) {
      logger.e('Error getting user preferences', error: error);
      return UserPreferences();
    });
  }

  Future<void> updateExplicitInterests(Set<String> interests) async {
    if (_userId == null) return;
    try {
      await _preferencesCollection.doc('main').set(
        {'explicitInterests': interests.toList()},
        SetOptions(merge: true),
      );
    } catch (e) {
      logger.e('Error updating explicit interests', error: e);
    }
  }

  Future<void> trackContestView(String contestId, String category, String sponsor) async {
    if (_userId == null) return;
    _personalizationEngine.trackInteraction(
      userId: _userId!,
      contestId: contestId,
      interactionType: 'view',
    );
    _trackImplicitInterest(
        category: category, sponsor: sponsor, viewWeight: 1.0,);
  }

  Future<void> trackContestEntry(String contestId, String category, String sponsor) async {
    if (_userId == null) return;
    _personalizationEngine.trackInteraction(
      userId: _userId!,
      contestId: contestId,
      interactionType: 'enter',
    );
    _trackImplicitInterest(
        category: category, sponsor: sponsor, entryWeight: 3.0,);
  }

  Future<void> _trackImplicitInterest({
    required String category,
    required String sponsor,
    double viewWeight = 0.0,
    double entryWeight = 0.0,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final docRef = _preferencesCollection.doc('main');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final prefs =
            doc.exists ? UserPreferences.fromMap(doc.data()!) : UserPreferences();

        // Update category interest
        final currentCategoryInterest =
            prefs.implicitCategoryInterests[_sanitize(category)] ??
                TrackedInterest(lastUpdated: now);
        final newCategoryScore = currentCategoryInterest.score + viewWeight + entryWeight;

        // Update sponsor interest
        final currentSponsorInterest =
            prefs.implicitSponsorInterests[_sanitize(sponsor)] ??
                TrackedInterest(lastUpdated: now);
        final newSponsorScore = currentSponsorInterest.score + viewWeight + entryWeight;

        transaction.set(
          docRef,
          {
            'implicitCategoryInterests': {
              _sanitize(category): {
                'score': newCategoryScore,
                'lastUpdated': now,
              },
            },
            'implicitSponsorInterests': {
              _sanitize(sponsor): {
                'score': newSponsorScore,
                'lastUpdated': now,
              },
            },
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      logger.e('Error tracking implicit interest', error: e);
    }
  }

  Future<void> trackNegativeInteraction(
      {required String category, required String sponsor,}) async {
    if (_userId == null) return;
    try {
      await _preferencesCollection.doc('main').set(
        {
          'dislikedCategories': FieldValue.arrayUnion([category]),
          'dislikedSponsors': FieldValue.arrayUnion([sponsor]),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      logger.e('Error tracking negative interaction', error: e);
    }
  }

  // Firestore field paths cannot contain certain characters.
  String _sanitize(String field) => field.replaceAll(RegExp(r'[.\\[\]*]'), '_');
}
