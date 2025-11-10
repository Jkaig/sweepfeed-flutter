import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Service to call Firebase Cloud Functions
class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Increment contest clicks
  Future<bool> incrementContestClicks(String contestId) async {
    try {
      final callable = _functions.httpsCallable('incrementContestClicks');
      final result = await callable.call(<String, dynamic>{
        'contestId': contestId,
      });

      return result.data['success'] == true;
    } catch (e) {
      debugPrint('Error incrementing contest clicks: $e');
      return false;
    }
  }

  /// Toggle contest like
  Future<bool?> toggleContestLike(String contestId) async {
    try {
      final callable = _functions.httpsCallable('toggleContestLike');
      final result = await callable.call(<String, dynamic>{
        'contestId': contestId,
      });

      if (result.data['success'] == true) {
        return result.data['liked'] as bool;
      }
      return null;
    } catch (e) {
      debugPrint('Error toggling contest like: $e');
      return null;
    }
  }

  /// Toggle contest save/bookmark
  Future<bool?> toggleContestSave(String contestId) async {
    try {
      final callable = _functions.httpsCallable('toggleContestSave');
      final result = await callable.call(<String, dynamic>{
        'contestId': contestId,
      });

      if (result.data['success'] == true) {
        return result.data['saved'] as bool;
      }
      return null;
    } catch (e) {
      debugPrint('Error toggling contest save: $e');
      return null;
    }
  }

  /// Check rate limit for an action
  Future<Map<String, dynamic>?> checkRateLimit(String action) async {
    try {
      final callable = _functions.httpsCallable('checkRateLimit');
      final result = await callable.call(<String, dynamic>{
        'action': action,
      });

      if (result.data['allowed'] == true) {
        return {
          'allowed': true,
          'remaining': result.data['remaining'] as int,
        };
      }
      return {'allowed': false};
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Rate limit error: ${e.code} - ${e.message}');

      if (e.code == 'resource-exhausted') {
        return {
          'allowed': false,
          'error': e.message ?? 'Rate limit exceeded',
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error checking rate limit: $e');
      return null;
    }
  }
}

/// Singleton instance
final cloudFunctionsService = CloudFunctionsService();
