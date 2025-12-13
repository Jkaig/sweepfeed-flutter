import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/profile/models/user_preferences_model.dart';
import '../models/contest.dart';
import '../models/recommendation_reason.dart';
import '../utils/logger.dart';

/// Advanced personalization engine using collaborative filtering,
/// content-based filtering, and behavioral analysis
class PersonalizationEngine {
  factory PersonalizationEngine() => _instance;
  PersonalizationEngine._();
  static final PersonalizationEngine _instance = PersonalizationEngine._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// User interest profile with weighted preferences
  Future<Map<String, double>> getUserInterestProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return _getDefaultProfile();

      final data = userDoc.data()!;
      final interests = data['interests'] as Map<String, dynamic>? ?? {};
      final engagement = interests['engagement'] as Map<String, dynamic>? ?? {};

      // Build weighted interest profile
      final profile = <String, double>{};

      // 1. Explicit preferences (highest weight: 1.0)
      final categories = List<String>.from(interests['categories'] ?? []);
      for (final category in categories) {
        profile[category] = (profile[category] ?? 0.0) + 1.0;
      }

      // 2. Category click frequency (weight: 0.8)
      final clickCounts = engagement['categoryClickCount'] as Map<String, dynamic>? ?? {};
      for (final entry in clickCounts.entries) {
        final count = (entry.value as num?)?.toDouble() ?? 0.0;
        profile[entry.key] = (profile[entry.key] ?? 0.0) + (count * 0.8);
      }

      // 3. Viewed contests analysis (weight: 0.6)
      final viewed = List<String>.from(interests['viewedSweepstakes'] ?? []);
      for (final contestId in viewed) {
        final contestDoc = await _firestore.collection('contests').doc(contestId).get();
        if (contestDoc.exists) {
          final contestData = contestDoc.data()!;
          final category = contestData['category'] as String?;
          if (category != null) {
            profile[category] = (profile[category] ?? 0.0) + 0.6;
          }
        }
      }

      // 4. Saved contests analysis (weight: 0.9 - high intent)
      final savedSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedContests')
          .get();
      for (final doc in savedSnapshot.docs) {
        final contestId = doc.id;
        final contestDoc = await _firestore.collection('contests').doc(contestId).get();
        if (contestDoc.exists) {
          final contestData = contestDoc.data()!;
          final category = contestData['category'] as String?;
          if (category != null) {
            profile[category] = (profile[category] ?? 0.0) + 0.9;
          }
        }
      }

      // 5. Entered contests analysis (weight: 0.7 - action taken)
      final enteredSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('enteredContests')
          .get();
      for (final doc in enteredSnapshot.docs) {
        final entryData = doc.data();
        final contestId = entryData['contestId'] as String?;
        if (contestId != null) {
          final contestDoc = await _firestore.collection('contests').doc(contestId).get();
          if (contestDoc.exists) {
            final contestData = contestDoc.data()!;
            final category = contestData['category'] as String?;
            if (category != null) {
              profile[category] = (profile[category] ?? 0.0) + 0.7;
            }
          }
        }
      }

      // 6. Prize value preferences (weight: 0.5)
      final priceRanges = interests['priceRanges'] as Map<String, dynamic>? ?? {};
      final minValue = (priceRanges['min'] as num?)?.toDouble() ?? 0.0;
      final maxValue = (priceRanges['max'] as num?)?.toDouble() ?? 1000.0;
      profile['_preferredMinValue'] = minValue;
      profile['_preferredMaxValue'] = maxValue;

      // Normalize profile (sum to 1.0)
      final total = profile.values.fold(0.0, (sum, value) => sum + value);
      if (total > 0) {
        for (final key in profile.keys) {
          profile[key] = profile[key]! / total;
        }
      }

      return profile.isEmpty ? _getDefaultProfile() : profile;
    } catch (e) {
      logger.e('Error building user interest profile', error: e);
      return _getDefaultProfile();
    }
  }

  /// Default interest profile for new users
  Map<String, double> _getDefaultProfile() => {
      'Cash': 0.3,
      'Electronics': 0.2,
      'Travel': 0.2,
      'Gift Cards': 0.15,
      'Fashion': 0.15,
      '_preferredMinValue': 0.0,
      '_preferredMaxValue': 10000.0,
    };

  /// Collaborative filtering: Find similar users and recommend what they like
  Future<List<String>> getCollaborativeRecommendations(String userId, {int limit = 10}) async {
    try {
      final userProfile = await getUserInterestProfile(userId);
      if (userProfile.isEmpty) return [];

      // Get all users (in production, use more efficient query)
      final usersSnapshot = await _firestore.collection('users').limit(100).get();
      final similarUsers = <MapEntry<String, double>>[];

      for (final userDoc in usersSnapshot.docs) {
        if (userDoc.id == userId) continue;

        final otherProfile = await getUserInterestProfile(userDoc.id);
        final similarity = _calculateCosineSimilarity(userProfile, otherProfile);

        if (similarity > 0.3) { // Threshold for similarity
          similarUsers.add(MapEntry(userDoc.id, similarity));
        }
      }

      // Sort by similarity
      similarUsers.sort((a, b) => b.value.compareTo(a.value));

      // Get contests liked by similar users
      final recommendedContestIds = <String, double>{};
      for (final entry in similarUsers.take(5)) {
        final similarUserId = entry.key;
        final savedSnapshot = await _firestore
            .collection('users')
            .doc(similarUserId)
            .collection('savedContests')
            .get();

        for (final doc in savedSnapshot.docs) {
          final contestId = doc.id;
          final similarity = entry.value;
          recommendedContestIds[contestId] =
              (recommendedContestIds[contestId] ?? 0.0) + similarity;
        }
      }

      // Sort by recommendation score
      final sorted = recommendedContestIds.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.take(limit).map((e) => e.key).toList();
    } catch (e) {
      logger.e('Error getting collaborative recommendations', error: e);
      return [];
    }
  }

  /// Content-based filtering: Recommend based on contest features
  Future<List<String>> getContentBasedRecommendations(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final userProfile = await getUserInterestProfile(userId);
      if (userProfile.isEmpty) return [];

      final preferredMinValue = userProfile['_preferredMinValue'] ?? 0.0;
      final preferredMaxValue = userProfile['_preferredMaxValue'] ?? 1000.0;

      // Get all active contests
      final contestsSnapshot = await _firestore
          .collection('contests')
          .where('status', isEqualTo: 'active')
          .limit(100)
          .get();

      final scoredContests = <MapEntry<String, double>>[];

      for (final doc in contestsSnapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String? ?? '';
        final value = (data['value'] as num?)?.toDouble() ?? 0.0;

        // Calculate relevance score
        var score = 0.0;

        // Category match
        if (userProfile.containsKey(category)) {
          score += userProfile[category]! * 0.6;
        }

        // Value range match
        if (value >= preferredMinValue && value <= preferredMaxValue) {
          score += 0.4;
        }

        // Boost for high-value contests
        if (value > 500) {
          score += 0.2;
        }

        if (score > 0.1) {
          scoredContests.add(MapEntry(doc.id, score));
        }
      }

      // Sort by score
      scoredContests.sort((a, b) => b.value.compareTo(a.value));

      return scoredContests.take(limit).map((e) => e.key).toList();
    } catch (e) {
      logger.e('Error getting content-based recommendations', error: e);
      return [];
    }
  }

  /// Hybrid recommendation: Combine collaborative + content-based
  Future<List<String>> getHybridRecommendations(String userId, {int limit = 10}) async {
    try {
      final collaborative = await getCollaborativeRecommendations(userId, limit: limit * 2);
      final contentBased = await getContentBasedRecommendations(userId, limit: limit * 2);

      // Combine and deduplicate
      final combined = <String, double>{};

      // Weight collaborative more (0.6) vs content-based (0.4)
      for (var i = 0; i < collaborative.length; i++) {
        final contestId = collaborative[i];
        final score = (collaborative.length - i) / collaborative.length * 0.6;
        combined[contestId] = (combined[contestId] ?? 0.0) + score;
      }

      for (var i = 0; i < contentBased.length; i++) {
        final contestId = contentBased[i];
        final score = (contentBased.length - i) / contentBased.length * 0.4;
        combined[contestId] = (combined[contestId] ?? 0.0) + score;
      }

      // Sort by combined score
      final sorted = combined.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.take(limit).map((e) => e.key).toList();
    } catch (e) {
      logger.e('Error getting hybrid recommendations', error: e);
      return [];
    }
  }

  /// Track user interaction for learning
  Future<void> trackInteraction({
    required String userId,
    required String contestId,
    required String interactionType, // 'view', 'save', 'enter', 'share', 'dismiss'
    int? timeSpentSeconds,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update user engagement
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'interests.engagement.lastActivity': FieldValue.serverTimestamp(),
        'interests.engagement.timeSpent': FieldValue.increment(timeSpentSeconds ?? 0),
      });

      // Get contest category
      final contestDoc = await _firestore.collection('contests').doc(contestId).get();
      if (contestDoc.exists) {
        final category = contestDoc.data()?['category'] as String?;
        if (category != null) {
          batch.update(userRef, {
            'interests.engagement.categoryClickCount.$category': FieldValue.increment(1),
            'interests.engagement.lastCategoryView.$category': FieldValue.serverTimestamp(),
          });
        }
      }

      // Track interaction in userActivity collection
      final activityRef = _firestore
          .collection('userActivity')
          .doc(userId)
          .collection('interactions')
          .doc();
      batch.set(activityRef, {
        'contestId': contestId,
        'interactionType': interactionType,
        'timeSpentSeconds': timeSpentSeconds,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update viewed contests (keep last 50)
      if (interactionType == 'view') {
        final userDoc = await userRef.get();
        final viewed = List<String>.from(
            userDoc.data()?['interests']?['viewedSweepstakes'] ?? [],);
        viewed.remove(contestId); // Remove if exists
        viewed.insert(0, contestId); // Add to front
        if (viewed.length > 50) viewed.removeLast(); // Keep last 50

        batch.update(userRef, {
          'interests.viewedSweepstakes': viewed,
        });
      }

      await batch.commit();
    } catch (e) {
      logger.e('Error tracking interaction', error: e);
    }
  }

  /// Calculate user engagement score (0.0 to 1.0)
  Future<double> calculateEngagementScore(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0.0;

      final data = userDoc.data()!;
      final interests = data['interests'] as Map<String, dynamic>? ?? {};
      final engagement = interests['engagement'] as Map<String, dynamic>? ?? {};

      var score = 0.0;

      // Time spent (max 0.3)
      final timeSpent = (engagement['timeSpent'] as num?)?.toDouble() ?? 0.0;
      score += min(timeSpent / 1000.0, 0.3); // Normalize to 0.3 max

      // Category diversity (max 0.2)
      final clickCounts = engagement['categoryClickCount'] as Map<String, dynamic>? ?? {};
      final uniqueCategories = clickCounts.keys.length;
      score += min(uniqueCategories / 10.0, 0.2);

      // Activity frequency (max 0.3)
      final lastActivity = engagement['lastActivity'] as Timestamp?;
      if (lastActivity != null) {
        final daysSinceActivity = DateTime.now().difference(lastActivity.toDate()).inDays;
        if (daysSinceActivity == 0) {
          score += 0.3; // Active today
        } else if (daysSinceActivity <= 3) {
          score += 0.2; // Active this week
        } else if (daysSinceActivity <= 7) {
          score += 0.1; // Active this month
        }
      }

      // Saved contests (max 0.1)
      final savedCount = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedContests')
          .count()
          .get();
      score += min((savedCount.count ?? 0) / 20.0, 0.1);

      // Entered contests (max 0.1)
      final enteredCount = await _firestore
          .collection('users')
          .doc(userId)
          .collection('enteredContests')
          .count()
          .get();
      score += min((enteredCount.count ?? 0) / 50.0, 0.1);

      return min(score, 1.0);
    } catch (e) {
      logger.e('Error calculating engagement score', error: e);
      return 0.0;
    }
  }

  /// Calculate cosine similarity between two profiles
  double _calculateCosineSimilarity(
    Map<String, double> profile1,
    Map<String, double> profile2,
  ) {
    if (profile1.isEmpty || profile2.isEmpty) return 0.0;

    final allKeys = {...profile1.keys, ...profile2.keys};
    var dotProduct = 0.0;
    var norm1 = 0.0;
    var norm2 = 0.0;

    for (final key in allKeys) {
      if (key.startsWith('_')) continue; // Skip internal keys

      final val1 = profile1[key] ?? 0.0;
      final val2 = profile2[key] ?? 0.0;

      dotProduct += val1 * val2;
      norm1 += val1 * val1;
      norm2 += val2 * val2;
    }

    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;

    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  // Higher weights mean these factors are more influential.
  static const double _explicitInterestWeight = 2.0;
  static const double _categoryViewWeight = 0.5;
  static const double _sponsorViewWeight = 0.3;
  static const double _categoryEntryWeight = 1.5;
  static const double _sponsorEntryWeight = 1.0;
  static const double _newnessWeight = 0.8; // Score multiplier for new contests
  static const double _trendingWeight = 1.2; // Score multiplier for trending contests
  static const double _dislikePenalty = -5.0; // Strong penalty for disliked items

  List<(_ScoredContest, RecommendationReason)> rankContests({
    required List<Contest> contests,
    required UserPreferences preferences,
  }) {
    final scoredContests = contests.map((contest) {
      final result = _calculateScore(contest, preferences);
      return (
        _ScoredContest(contest, result.score),
        result.reason,
      );
    }).toList();

    scoredContests.sort((a, b) => b.$1.score.compareTo(a.$1.score));

    return scoredContests;
  }

  ({double score, RecommendationReason reason}) _calculateScore(
      Contest contest, UserPreferences preferences,) {
    double score = 0;
    var reason =
        RecommendationReason(type: RecommendationType.popular);

    // --- Explicit Interests ---
    if (preferences.explicitInterests.contains(contest.category)) {
      score += _explicitInterestWeight;
      reason = RecommendationReason(
        type: RecommendationType.explicitInterest,
        details: contest.category,
      );
    }

    // --- Implicit Interests (from Views & Entries) ---
    final categoryInterest =
        preferences.implicitCategoryInterests[contest.category];
    if (categoryInterest != null &&
        categoryInterest.score * _categoryEntryWeight > score) {
      score += categoryInterest.score * _categoryEntryWeight;
      reason = RecommendationReason(
        type: RecommendationType.implicitInterest,
        details: contest.category,
      );
    }

    final sponsorInterest =
        preferences.implicitSponsorInterests[contest.sponsor];
    if (sponsorInterest != null &&
        sponsorInterest.score * _sponsorEntryWeight > score) {
      score += sponsorInterest.score * _sponsorEntryWeight;
      reason = RecommendationReason(
        type: RecommendationType.implicitInterest,
        details: contest.sponsor,
      );
    }

    // --- Negative Feedback ---
    if (preferences.dislikedCategories.contains(contest.category)) {
      score += _dislikePenalty;
    }
    if (preferences.dislikedSponsors.contains(contest.sponsor)) {
      score += _dislikePenalty;
    }

    // --- Contextual Boosts ---
    if (contest.createdAt
        .isAfter(DateTime.now().subtract(const Duration(days: 3)))) {
      score *= _newnessWeight;
      reason = RecommendationReason(type: RecommendationType.newContent);
    }

    if (contest.trendingScore != null &&
        contest.trendingScore! > 0 &&
        score < (1 + (contest.trendingScore! / 100) * _trendingWeight)) {
      score *= 1 + (contest.trendingScore! / 100) * _trendingWeight;
      reason = RecommendationReason(type: RecommendationType.trending);
    }

    return (score: score, reason: reason);
  }
}

class _ScoredContest {
  _ScoredContest(this.contest, this.score);

  final Contest contest;
  final double score;
}

