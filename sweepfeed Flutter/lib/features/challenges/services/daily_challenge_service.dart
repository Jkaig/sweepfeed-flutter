import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../constants/app_constants.dart';
import '../../../core/services/dust_bunnies_service.dart';
import '../../../core/utils/logger.dart';
import '../models/daily_challenge_model.dart';

/// Service for managing daily challenges system
/// Integrates with DustBunniesService for rewards
class DailyChallengeService extends ChangeNotifier {
  DailyChallengeService({
    FirebaseFirestore? firestore,
    DustBunniesService? dustBunniesService,
    this.analyticsCallback,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _dustBunniesService = dustBunniesService ?? DustBunniesService();

  final FirebaseFirestore _firestore;
  final DustBunniesService _dustBunniesService;
  final Function(String event, Map<String, dynamic> parameters)?
      analyticsCallback;

  // Cache for challenge definitions to reduce Firestore reads
  List<ChallengeDefinition>? _challengeDefinitionsCache;
  DateTime? _cacheTimestamp;
  static const Duration _cacheExpiry = Duration(hours: 1);

  /// Get all available challenge definitions with caching
  Future<List<ChallengeDefinition>> getChallengeDefinitions() async {
    try {
      // Return cached data if valid
      if (_challengeDefinitionsCache != null &&
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) < _cacheExpiry) {
        return _challengeDefinitionsCache!;
      }

      final query = await _firestore
          .collection('challenges')
          .where('isActive', isEqualTo: true)
          .get();

      final definitions = query.docs
          .map((doc) => ChallengeDefinition.fromFirestore(doc))
          .toList();

      // Update cache
      _challengeDefinitionsCache = definitions;
      _cacheTimestamp = DateTime.now();

      return definitions;
    } catch (e) {
      logger.e('Error getting challenge definitions', error: e);
      return [];
    }
  }

  /// Get user's current daily challenges
  Future<List<DailyChallengeDisplay>> getUserDailyChallenges(
      String userId) async {
    try {
      if (userId.isEmpty) {
        throw ArgumentError('User ID cannot be empty');
      }

      // Get user's assigned challenges for today
      final userChallengesQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_challenges')
          .where('assigned_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_getStartOfDay()))
          .get();

      if (userChallengesQuery.docs.isEmpty) {
        // No challenges assigned today, assign new ones
        return await _assignDailyChallenges(userId);
      }

      final userChallenges = userChallengesQuery.docs
          .map((doc) => UserChallenge.fromFirestore(doc))
          .toList();

      // Get challenge definitions
      final definitions = await getChallengeDefinitions();
      final definitionsMap = {for (var def in definitions) def.id: def};

      // Combine user challenges with definitions
      final displayChallenges = <DailyChallengeDisplay>[];
      for (final userChallenge in userChallenges) {
        final definition = definitionsMap[userChallenge.challengeId];
        if (definition != null) {
          displayChallenges.add(
            DailyChallengeDisplay(
              definition: definition,
              userChallenge: userChallenge,
            ),
          );
        }
      }

      return displayChallenges;
    } catch (e) {
      logger.e('Error getting user daily challenges', error: e);
      return [];
    }
  }

  /// Assign 3 random daily challenges to user
  Future<List<DailyChallengeDisplay>> _assignDailyChallenges(
      String userId) async {
    try {
      final definitions = await getChallengeDefinitions();
      if (definitions.isEmpty) {
        logger.w('No challenge definitions available');
        return [];
      }

      // Select 3 random challenges with balanced difficulty
      final selectedChallenges = _selectBalancedChallenges(definitions, 3);

      final userChallengesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('user_challenges');

      final displayChallenges = <DailyChallengeDisplay>[];
      final now = DateTime.now();

      // Create user challenge documents
      for (final definition in selectedChallenges) {
        final userChallenge = UserChallenge(
          id: '', // Will be set by Firestore
          challengeId: definition.id,
          userId: userId,
          progress: 0,
          completed: false,
          assignedAt: now,
        );

        final docRef = await userChallengesRef.add(userChallenge.toFirestore());

        final finalUserChallenge = userChallenge.copyWith(id: docRef.id);

        displayChallenges.add(
          DailyChallengeDisplay(
            definition: definition,
            userChallenge: finalUserChallenge,
          ),
        );
      }

      _trackAnalytics('daily_challenges_assigned', {
        'userId': userId,
        'challengeCount': selectedChallenges.length,
        'challengeIds': selectedChallenges.map((c) => c.id).toList(),
      });

      logger.i(
          'Assigned ${selectedChallenges.length} daily challenges to user $userId');

      return displayChallenges;
    } catch (e) {
      logger.e('Error assigning daily challenges', error: e);
      return [];
    }
  }

  /// Select balanced challenges (mix of difficulties)
  List<ChallengeDefinition> _selectBalancedChallenges(
    List<ChallengeDefinition> allChallenges,
    int count,
  ) {
    if (allChallenges.length <= count) {
      return allChallenges;
    }

    // Group by difficulty
    final easyChals = allChallenges
        .where((c) => c.difficulty == ChallengeDifficulty.easy.value)
        .toList();
    final mediumChals = allChallenges
        .where((c) => c.difficulty == ChallengeDifficulty.medium.value)
        .toList();
    final hardChals = allChallenges
        .where((c) => c.difficulty == ChallengeDifficulty.hard.value)
        .toList();

    final selected = <ChallengeDefinition>[];
    final random = math.Random();

    // Try to select 1 easy, 1 medium, 1 hard
    if (easyChals.isNotEmpty) {
      selected.add(easyChals[random.nextInt(easyChals.length)]);
    }
    if (mediumChals.isNotEmpty) {
      selected.add(mediumChals[random.nextInt(mediumChals.length)]);
    }
    if (hardChals.isNotEmpty) {
      selected.add(hardChals[random.nextInt(hardChals.length)]);
    }

    // Fill remaining slots randomly
    while (selected.length < count) {
      final remaining = allChallenges
          .where((c) => !selected.any((s) => s.id == c.id))
          .toList();
      if (remaining.isEmpty) break;

      selected.add(remaining[random.nextInt(remaining.length)]);
    }

    return selected;
  }

  /// Update challenge progress for a specific user action
  Future<ChallengeActionResult> updateChallengeProgress({
    required String userId,
    required ChallengeType actionType,
    int incrementBy = 1,
  }) async {
    try {
      if (userId.isEmpty) {
        throw ArgumentError('User ID cannot be empty');
      }

      // Find relevant incomplete challenges for this action type
      final userChallengesQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_challenges')
          .where('assigned_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_getStartOfDay()))
          .where('completed', isEqualTo: false)
          .get();

      if (userChallengesQuery.docs.isEmpty) {
        // No active challenges
        return const ChallengeActionResult(
          success: true,
          challengeId: '',
          message: 'No active challenges to update',
        );
      }

      // Get challenge definitions to match action type
      final definitions = await getChallengeDefinitions();
      final relevantDefinitions =
          definitions.where((def) => def.type == actionType.value).toList();

      if (relevantDefinitions.isEmpty) {
        return ChallengeActionResult(
          success: true,
          challengeId: '',
          message: 'No challenges for action type: ${actionType.value}',
        );
      }

      // Find user challenge that matches action type
      UserChallenge? targetUserChallenge;
      String? targetDocId;

      for (final doc in userChallengesQuery.docs) {
        final userChallenge = UserChallenge.fromFirestore(doc);
        final matchingDef = relevantDefinitions.firstWhere(
            (def) => def.id == userChallenge.challengeId,
            orElse: () => relevantDefinitions.first);

        if (matchingDef.id == userChallenge.challengeId) {
          targetUserChallenge = userChallenge;
          targetDocId = doc.id;
          break;
        }
      }

      if (targetUserChallenge == null || targetDocId == null) {
        return ChallengeActionResult(
          success: true,
          challengeId: '',
          message: 'No matching challenge found for action type',
        );
      }

      // Get the challenge definition to check target
      final challengeDef = relevantDefinitions
          .firstWhere((def) => def.id == targetUserChallenge!.challengeId);

      // Update progress atomically
      final userChallengeRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('user_challenges')
          .doc(targetDocId);

      ChallengeActionResult? result;

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userChallengeRef);
        if (!doc.exists) return;

        final currentChallenge = UserChallenge.fromFirestore(doc);
        final newProgress = (currentChallenge.progress + incrementBy)
            .clamp(0, challengeDef.target);
        final isCompleted = newProgress >= challengeDef.target;

        final updateData = <String, dynamic>{
          'progress': newProgress,
          'completed': isCompleted,
        };

        if (isCompleted && !currentChallenge.completed) {
          updateData['completed_at'] = FieldValue.serverTimestamp();
        }

        transaction.update(userChallengeRef, updateData);

        result = ChallengeActionResult(
          success: true,
          challengeId: challengeDef.id,
          newProgress: newProgress,
          completed: isCompleted,
          message: isCompleted
              ? 'Challenge completed: ${challengeDef.title}'
              : 'Progress updated: $newProgress/${challengeDef.target}',
        );
      });

      _trackAnalytics('challenge_progress_updated', {
        'userId': userId,
        'challengeId': result?.challengeId ?? '',
        'actionType': actionType.value,
        'newProgress': result?.newProgress ?? 0,
        'completed': result?.completed ?? false,
      });

      notifyListeners();

      return result ??
          ChallengeActionResult(
            success: false,
            challengeId: '',
            error: 'Transaction failed',
          );
    } catch (e) {
      logger.e('Error updating challenge progress', error: e);
      return ChallengeActionResult(
        success: false,
        challengeId: '',
        error: e.toString(),
      );
    }
  }

  /// Claim reward for completed challenge
  Future<ChallengeActionResult> claimChallengeReward({
    required String userId,
    required String userChallengeId,
  }) async {
    try {
      if (userId.isEmpty || userChallengeId.isEmpty) {
        throw ArgumentError('User ID and challenge ID cannot be empty');
      }

      final userChallengeRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('user_challenges')
          .doc(userChallengeId);

      ChallengeActionResult? result;

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userChallengeRef);
        if (!doc.exists) {
          result = ChallengeActionResult(
            success: false,
            challengeId: '',
            error: 'Challenge not found',
          );
          return;
        }

        final userChallenge = UserChallenge.fromFirestore(doc);

        // Validate challenge can be claimed
        if (!userChallenge.completed) {
          result = ChallengeActionResult(
            success: false,
            challengeId: userChallenge.challengeId,
            error: 'Challenge not completed',
          );
          return;
        }

        if (userChallenge.isClaimed) {
          result = ChallengeActionResult(
            success: false,
            challengeId: userChallenge.challengeId,
            error: 'Reward already claimed',
          );
          return;
        }

        // Get challenge definition for reward amount
        final definitions = await getChallengeDefinitions();
        final challengeDef = definitions.firstWhere(
          (def) => def.id == userChallenge.challengeId,
          orElse: () => throw Exception('Challenge definition not found'),
        );

        // Mark as claimed
        transaction.update(userChallengeRef, {
          'claimed_at': FieldValue.serverTimestamp(),
        });

        result = ChallengeActionResult(
          success: true,
          challengeId: challengeDef.id,
          pointsAwarded: challengeDef.reward,
          message: 'Claimed ${challengeDef.reward} DustBunnies!',
        );
      });

      // Award DustBunnies outside transaction
      if (result?.success == true && result!.pointsAwarded > 0) {
        await _dustBunniesService.awardDustBunnies(
          userId: userId,
          action: 'daily_challenge_complete',
          customAmount: result!.pointsAwarded,
        );
      }

      _trackAnalytics('challenge_reward_claimed', {
        'userId': userId,
        'challengeId': result?.challengeId ?? '',
        'pointsAwarded': result?.pointsAwarded ?? 0,
      });

      notifyListeners();

      return result ??
          ChallengeActionResult(
            success: false,
            challengeId: '',
            error: 'Unknown error',
          );
    } catch (e) {
      logger.e('Error claiming challenge reward', error: e);
      return ChallengeActionResult(
        success: false,
        challengeId: '',
        error: e.toString(),
      );
    }
  }

  /// Get start of current day for challenge filtering
  DateTime _getStartOfDay() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Track analytics if callback provided
  void _trackAnalytics(String event, Map<String, dynamic> parameters) {
    analyticsCallback?.call(event, parameters);
  }

  /// Clear cache (useful for testing or manual refresh)
  void clearCache() {
    _challengeDefinitionsCache = null;
    _cacheTimestamp = null;
  }

  /// Initialize challenge definitions in Firestore (for setup)
  Future<void> initializeChallengeDefinitions() async {
    try {
      final challengesRef = _firestore.collection('challenges');

      // Define default challenges
      final defaultChallenges = [
        // Easy challenges
        ChallengeDefinition(
          id: 'enter_contest_1',
          type: ChallengeType.enterContest.value,
          target: 1,
          reward: DustBunniesConstants.kDailyChallengeBaseReward,
          difficulty: ChallengeDifficulty.easy.value,
          title: 'Enter 1 Contest',
          description: 'Enter any contest to complete this challenge',
          iconCodePoint: 0xe913, // Icons.star_border
        ),
        ChallengeDefinition(
          id: 'save_contest_1',
          type: ChallengeType.saveContest.value,
          target: 1,
          reward: DustBunniesConstants.kDailyChallengeSecondaryReward,
          difficulty: ChallengeDifficulty.easy.value,
          title: 'Save 1 Contest',
          description: 'Save a contest for later',
          iconCodePoint: 0xe867, // Icons.bookmark_border
        ),

        // Medium challenges
        ChallengeDefinition(
          id: 'enter_contest_3',
          type: ChallengeType.enterContest.value,
          target: 3,
          reward: DustBunniesConstants.kDailyChallengeBaseReward * 2,
          difficulty: ChallengeDifficulty.medium.value,
          title: 'Enter 3 Contests',
          description: 'Enter 3 different contests today',
          iconCodePoint: 0xe913, // Icons.star_border
        ),
        ChallengeDefinition(
          id: 'save_contest_3',
          type: ChallengeType.saveContest.value,
          target: 3,
          reward: DustBunniesConstants.kDailyChallengeSecondaryReward * 2,
          difficulty: ChallengeDifficulty.medium.value,
          title: 'Save 3 Contests',
          description: 'Save 3 contests to your favorites',
          iconCodePoint: 0xe867, // Icons.bookmark_border
        ),

        // Hard challenges
        ChallengeDefinition(
          id: 'enter_contest_5',
          type: ChallengeType.enterContest.value,
          target: 5,
          reward: DustBunniesConstants.kDailyChallengeBaseReward * 3,
          difficulty: ChallengeDifficulty.hard.value,
          title: 'Enter 5 Contests',
          description: 'Enter 5 different contests today',
          iconCodePoint: 0xe913, // Icons.star_border
        ),
        ChallengeDefinition(
          id: 'share_contest_1',
          type: ChallengeType.shareContest.value,
          target: 1,
          reward: DustBunniesConstants.kDailyChallengeSecondaryReward * 3,
          difficulty: ChallengeDifficulty.hard.value,
          title: 'Share a Contest',
          description: 'Share a contest with friends',
          iconCodePoint: 0xe540, // Icons.share_outlined
        ),
      ];

      // Add challenges to Firestore (only if they don't exist)
      for (final challenge in defaultChallenges) {
        final docRef = challengesRef.doc(challenge.id);
        final doc = await docRef.get();

        if (!doc.exists) {
          await docRef.set(challenge.toFirestore());
          logger.i('Created challenge definition: ${challenge.id}');
        }
      }

      // Clear cache to force refresh
      clearCache();

      logger.i('Challenge definitions initialized successfully');
    } catch (e) {
      logger.e('Error initializing challenge definitions', error: e);
    }
  }
}
