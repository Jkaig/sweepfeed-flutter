import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../utils/logger.dart';
import 'unified_notification_service.dart';

class HighValueSweepstake {
  HighValueSweepstake({
    required this.id,
    required this.title,
    required this.prizeValue,
    required this.createdAt,
    required this.endDate,
    required this.category,
    this.vipNotificationSent = false,
    this.vipNotificationTime,
    this.publicNotificationTime,
  });

  factory HighValueSweepstake.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return HighValueSweepstake(
      id: doc.id,
      title: data['title'] as String,
      prizeValue: (data['prizeValue'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      category: data['category'] as String? ?? 'general',
      vipNotificationSent: data['vipNotificationSent'] as bool? ?? false,
      vipNotificationTime: data['vipNotificationTime'] != null
          ? (data['vipNotificationTime'] as Timestamp).toDate()
          : null,
      publicNotificationTime: data['publicNotificationTime'] != null
          ? (data['publicNotificationTime'] as Timestamp).toDate()
          : null,
    );
  }
  final String id;
  final String title;
  final double prizeValue;
  final DateTime createdAt;
  final DateTime endDate;
  final String category;
  final bool vipNotificationSent;
  final DateTime? vipNotificationTime;
  final DateTime? publicNotificationTime;

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'prizeValue': prizeValue,
        'createdAt': Timestamp.fromDate(createdAt),
        'endDate': Timestamp.fromDate(endDate),
        'category': category,
        'vipNotificationSent': vipNotificationSent,
        'vipNotificationTime': vipNotificationTime != null
            ? Timestamp.fromDate(vipNotificationTime!)
            : null,
        'publicNotificationTime': publicNotificationTime != null
            ? Timestamp.fromDate(publicNotificationTime!)
            : null,
      };
}

/// Optimized VIP notification service addressing performance bottlenecks
///
/// Key optimizations:
/// - Batch database reads for user settings
/// - Parallel notification processing
/// - Pagination for large user sets
/// - Efficient Firestore batch writes
/// - Smart caching to reduce redundant queries
class OptimizedVipNotificationService {
  factory OptimizedVipNotificationService() => _instance;
  OptimizedVipNotificationService._internal();
  static final OptimizedVipNotificationService _instance =
      OptimizedVipNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const double HIGH_VALUE_THRESHOLD = 500.0;
  static const double ULTRA_HIGH_VALUE_THRESHOLD = 5000.0;

  static const Duration VIP_EARLY_ACCESS_WINDOW = Duration(hours: 24);
  static const Duration PREMIUM_EARLY_ACCESS_WINDOW = Duration(hours: 12);

  // Performance optimization constants
  static const int MAX_BATCH_SIZE = 500; // Firestore batch limit
  static const int PAGINATION_SIZE = 100; // Users per page
  static const int MAX_CONCURRENT_NOTIFICATIONS = 50; // Parallel limit

  // Cache for user settings to avoid repeated database reads
  final Map<String, NotificationSettings> _settingsCache = {};
  final Map<String, bool> _categoryPreferencesCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration CACHE_DURATION = Duration(minutes: 15);

  Future<void> detectAndNotifyHighValueSweepstake({
    required String sweepstakeId,
    required String title,
    required double prizeValue,
    required DateTime endDate,
    required String category,
  }) async {
    try {
      if (!_isHighValue(prizeValue)) {
        logger.d('Sweepstake not high-value enough: \$$prizeValue');
        return;
      }

      final highValueSweep = HighValueSweepstake(
        id: sweepstakeId,
        title: title,
        prizeValue: prizeValue,
        createdAt: DateTime.now(),
        endDate: endDate,
        category: category,
      );

      await _saveHighValueSweepstake(highValueSweep);

      // Process VIP notifications with optimizations
      final vipResults = await _sendOptimizedVipNotifications(highValueSweep);

      // Process Premium notifications if ultra high value
      if (prizeValue >= ULTRA_HIGH_VALUE_THRESHOLD) {
        // Use background processing for Premium notifications
        _sendPremiumNotificationsInBackground(highValueSweep);
      }

      logger.i(
        'High-value sweepstake notifications sent: $title (\$$prizeValue) - VIP: ${vipResults['sent']}/${vipResults['total']}',
      );
    } catch (e) {
      logger.e('Error processing high-value sweepstake notification', error: e);
      rethrow;
    }
  }

  bool _isHighValue(double prizeValue) => prizeValue >= HIGH_VALUE_THRESHOLD;

  bool _isUltraHighValue(double prizeValue) =>
      prizeValue >= ULTRA_HIGH_VALUE_THRESHOLD;

  Future<void> _saveHighValueSweepstake(HighValueSweepstake sweepstake) async {
    try {
      await _firestore
          .collection('high_value_contests')
          .doc(sweepstake.id)
          .set(sweepstake.toFirestore());

      logger.d('High-value sweepstake saved: ${sweepstake.id}');
    } catch (e) {
      logger.e('Error saving high-value sweepstake', error: e);
      rethrow;
    }
  }

  /// Optimized VIP notification sending with batching and parallel processing
  Future<Map<String, int>> _sendOptimizedVipNotifications(
    HighValueSweepstake sweepstake,
  ) async {
    try {
      final stopwatch = Stopwatch()..start();
      var totalUsers = 0;
      var sentCount = 0;
      var errorCount = 0;

      // Clear cache if it's stale
      _clearCacheIfStale();

      // Get VIP users with pagination
      await for (final List<UserProfile> userBatch in _getVipUsersPaginated()) {
        totalUsers += userBatch.length;

        if (userBatch.isEmpty) break;

        // Batch load settings for all users in this batch
        final userIds = userBatch.map((u) => u.id).toList();
        await _batchLoadUserSettings(userIds);
        await _batchLoadCategoryPreferences(userIds, sweepstake.category);

        // Process notifications in parallel with concurrency limit
        final results =
            await _processUserBatchInParallel(userBatch, sweepstake);
        sentCount += results['sent']!;
        errorCount += results['errors']!;

        logger.d(
          'Processed VIP batch: ${userBatch.length} users, sent: ${results['sent']}, errors: ${results['errors']}',
        );
      }

      // Update sweepstake with results using batch write
      await _updateSweepstakeResults(sweepstake.id, sentCount, totalUsers);

      stopwatch.stop();
      logger.i(
        'VIP notifications completed in ${stopwatch.elapsedMilliseconds}ms - Total: $totalUsers, Sent: $sentCount, Errors: $errorCount',
      );

      return {
        'total': totalUsers,
        'sent': sentCount,
        'errors': errorCount,
      };
    } catch (e) {
      logger.e('Error sending optimized VIP notifications', error: e);
      rethrow;
    }
  }

  /// Get VIP users with pagination to handle large datasets
  Stream<List<UserProfile>> _getVipUsersPaginated() async* {
    final Query query = _firestore
        .collection('users')
        .where('tier', isEqualTo: 'vip')
        .limit(PAGINATION_SIZE);

    DocumentSnapshot? lastDoc;

    while (true) {
      final currentQuery =
          lastDoc != null ? query.startAfterDocument(lastDoc) : query;

      final snapshot = await currentQuery.get();

      if (snapshot.docs.isEmpty) break;

      final users = snapshot.docs.map(UserProfile.fromFirestore).toList();

      yield users;

      lastDoc = snapshot.docs.last;

      // If we got less than the page size, we're done
      if (snapshot.docs.length < PAGINATION_SIZE) break;
    }
  }

  /// Batch load user settings to avoid individual database reads
  Future<void> _batchLoadUserSettings(List<String> userIds) async {
    try {
      // Filter out users already in cache
      final uncachedUsers =
          userIds.where((id) => !_settingsCache.containsKey(id)).toList();

      if (uncachedUsers.isEmpty) return;

      // Use Firestore 'in' query to batch load (max 10 at a time)
      final batches = _createBatches(uncachedUsers, 10);

      for (final batch in batches) {
        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          try {
            final settings = NotificationSettings.fromFirestore(doc.data());
            _settingsCache[doc.id] = settings;
          } catch (e) {
            logger.w('Error parsing settings for user ${doc.id}: $e');
            // Use default settings for this user
            _settingsCache[doc.id] = NotificationSettings.fromFirestore({});
          }
        }
      }

      logger.d('Batch loaded settings for ${uncachedUsers.length} users');
    } catch (e) {
      logger.e('Error batch loading user settings', error: e);
    }
  }

  /// Batch load category preferences for users
  Future<void> _batchLoadCategoryPreferences(
    List<String> userIds,
    String category,
  ) async {
    try {
      final uncachedUsers = userIds
          .where(
            (id) => !_categoryPreferencesCache.containsKey('${id}_$category'),
          )
          .toList();

      if (uncachedUsers.isEmpty) return;

      final batches = _createBatches(uncachedUsers, 10);

      for (final batch in batches) {
        final snapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final interests = data['interests'] as List<dynamic>?;
          final wantsCategory = interests?.contains(category) ?? true;

          _categoryPreferencesCache['${doc.id}_$category'] = wantsCategory;
        }
      }

      logger.d(
        'Batch loaded category preferences for ${uncachedUsers.length} users',
      );
    } catch (e) {
      logger.e('Error batch loading category preferences', error: e);
    }
  }

  /// Process a batch of users in parallel with concurrency control
  Future<Map<String, int>> _processUserBatchInParallel(
    List<UserProfile> users,
    HighValueSweepstake sweepstake,
  ) async {
    var sent = 0;
    var errors = 0;

    // Create futures for parallel processing
    final futures = <Future<bool>>[];

    for (final user in users) {
      futures.add(_processUserNotification(user, sweepstake));

      // Limit concurrency to prevent overwhelming the system
      if (futures.length >= MAX_CONCURRENT_NOTIFICATIONS) {
        final results = await Future.wait(futures);
        sent += results.where((r) => r).length;
        errors += results.where((r) => !r).length;
        futures.clear();
      }
    }

    // Process remaining futures
    if (futures.isNotEmpty) {
      final results = await Future.wait(futures);
      sent += results.where((r) => r).length;
      errors += results.where((r) => !r).length;
    }

    return {'sent': sent, 'errors': errors};
  }

  /// Process notification for a single user
  Future<bool> _processUserNotification(
    UserProfile user,
    HighValueSweepstake sweepstake,
  ) async {
    try {
      // Get cached settings
      final settings = _settingsCache[user.id];
      if (settings == null) {
        logger.w('No settings found for user: ${user.id}');
        return false;
      }

      // Check if user wants this notification
      if (!settings.push.enabled || settings.push.types['highValue'] != true) {
        return false;
      }

      // Check category preference
      final wantsCategory =
          _categoryPreferencesCache['${user.id}_${sweepstake.category}'] ??
              true;
      if (!wantsCategory) {
        return false;
      }

      // Queue the notification (using optimized batch writes)
      await _queuePriorityNotification(
        userId: user.id,
        sweepstakeId: sweepstake.id,
        title: '🔥 VIP EXCLUSIVE: ${sweepstake.title}',
        body:
            'WIN \$${sweepstake.prizeValue.toStringAsFixed(0)}! 24-hour early access',
        priority: 'max',
        data: {
          'type': 'vip_high_value',
          'sweepstake_id': sweepstake.id,
          'prize_value': sweepstake.prizeValue.toString(),
          'early_access': 'true',
        },
      );

      return true;
    } catch (e) {
      logger.e('Error processing notification for user ${user.id}', error: e);
      return false;
    }
  }

  /// Optimized notification queueing with batch writes
  Future<void> _queuePriorityNotification({
    required String userId,
    required String sweepstakeId,
    required String title,
    required String body,
    required String priority,
    required Map<String, String> data,
  }) async {
    try {
      // Get user's secure FCM token
      final fcmToken = await unifiedNotificationService.getSecureToken(userId);

      if (fcmToken == null) {
        logger.w('No FCM token for user: $userId');
        return;
      }

      // Use batch write for better performance
      final batch = _firestore.batch();

      // Add to notification queue
      final queueRef = _firestore.collection('notification_queue').doc();
      batch.set(queueRef, {
        'userId': userId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'priority': priority,
        'data': data,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Add to notification history
      final historyRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notification_history')
          .doc();
      batch.set(historyRef, {
        'sweepstakeId': sweepstakeId,
        'type': data['type'],
        'sentAt': FieldValue.serverTimestamp(),
        'title': title,
        'body': body,
      });

      await batch.commit();
      logger.d('Priority notification queued for user: $userId');
    } catch (e) {
      logger.e('Error queueing priority notification', error: e);
      rethrow;
    }
  }

  /// Background processing for Premium notifications
  void _sendPremiumNotificationsInBackground(HighValueSweepstake sweepstake) {
    Future.delayed(PREMIUM_EARLY_ACCESS_WINDOW, () async {
      try {
        await _sendOptimizedPremiumNotifications(sweepstake);
      } catch (e) {
        logger.e(
          'Error in background Premium notification processing',
          error: e,
        );
      }
    });
  }

  /// Optimized Premium notification sending
  Future<Map<String, int>> _sendOptimizedPremiumNotifications(
    HighValueSweepstake sweepstake,
  ) async {
    try {
      final stopwatch = Stopwatch()..start();
      var totalUsers = 0;
      var sentCount = 0;
      var errorCount = 0;

      // Get active Premium users with pagination
      await for (final List<UserProfile> userBatch
          in _getPremiumUsersPaginated()) {
        totalUsers += userBatch.length;

        if (userBatch.isEmpty) break;

        // Batch load settings for all users in this batch
        final userIds = userBatch.map((u) => u.id).toList();
        await _batchLoadUserSettings(userIds);
        await _batchLoadCategoryPreferences(userIds, sweepstake.category);

        // Process notifications in parallel
        final results = await _processPremiumUserBatch(userBatch, sweepstake);
        sentCount += results['sent']!;
        errorCount += results['errors']!;

        logger.d(
          'Processed Premium batch: ${userBatch.length} users, sent: ${results['sent']}, errors: ${results['errors']}',
        );
      }

      stopwatch.stop();
      logger.i(
        'Premium notifications completed in ${stopwatch.elapsedMilliseconds}ms - Total: $totalUsers, Sent: $sentCount, Errors: $errorCount',
      );

      return {
        'total': totalUsers,
        'sent': sentCount,
        'errors': errorCount,
      };
    } catch (e) {
      logger.e('Error sending optimized Premium notifications', error: e);
      rethrow;
    }
  }

  /// Get active Premium users with pagination and server-side filtering
  Stream<List<UserProfile>> _getPremiumUsersPaginated() async* {
    final now = Timestamp.now();

    final Query query = _firestore
        .collection('users')
        .where('tier', isEqualTo: 'premium')
        .where('premiumUntil', isGreaterThan: now) // Server-side filtering
        .limit(PAGINATION_SIZE);

    DocumentSnapshot? lastDoc;

    while (true) {
      final currentQuery =
          lastDoc != null ? query.startAfterDocument(lastDoc) : query;

      final snapshot = await currentQuery.get();

      if (snapshot.docs.isEmpty) break;

      final users = snapshot.docs.map(UserProfile.fromFirestore).toList();

      yield users;

      lastDoc = snapshot.docs.last;

      if (snapshot.docs.length < PAGINATION_SIZE) break;
    }
  }

  /// Process Premium user batch notifications
  Future<Map<String, int>> _processPremiumUserBatch(
    List<UserProfile> users,
    HighValueSweepstake sweepstake,
  ) async {
    var sent = 0;
    var errors = 0;

    final futures = <Future<bool>>[];

    for (final user in users) {
      futures.add(_processPremiumUserNotification(user, sweepstake));

      if (futures.length >= MAX_CONCURRENT_NOTIFICATIONS) {
        final results = await Future.wait(futures);
        sent += results.where((r) => r).length;
        errors += results.where((r) => !r).length;
        futures.clear();
      }
    }

    if (futures.isNotEmpty) {
      final results = await Future.wait(futures);
      sent += results.where((r) => r).length;
      errors += results.where((r) => !r).length;
    }

    return {'sent': sent, 'errors': errors};
  }

  /// Process Premium user notification
  Future<bool> _processPremiumUserNotification(
    UserProfile user,
    HighValueSweepstake sweepstake,
  ) async {
    try {
      final settings = _settingsCache[user.id];
      if (settings == null) return false;

      if (!settings.push.enabled || settings.push.types['highValue'] != true) {
        return false;
      }

      final wantsCategory =
          _categoryPreferencesCache['${user.id}_${sweepstake.category}'] ??
              true;
      if (!wantsCategory) return false;

      await _queuePriorityNotification(
        userId: user.id,
        sweepstakeId: sweepstake.id,
        title: '⭐ Premium Alert: ${sweepstake.title}',
        body:
            'WIN \$${sweepstake.prizeValue.toStringAsFixed(0)}! Premium early access',
        priority: 'high',
        data: {
          'type': 'premium_high_value',
          'sweepstake_id': sweepstake.id,
          'prize_value': sweepstake.prizeValue.toString(),
        },
      );

      return true;
    } catch (e) {
      logger.e(
        'Error processing Premium notification for user ${user.id}',
        error: e,
      );
      return false;
    }
  }

  /// Update sweepstake with notification results
  Future<void> _updateSweepstakeResults(
    String sweepstakeId,
    int sentCount,
    int totalUsers,
  ) async {
    try {
      await _firestore
          .collection('high_value_contests')
          .doc(sweepstakeId)
          .update({
        'vipNotificationSent': true,
        'vipNotificationTime': FieldValue.serverTimestamp(),
        'vipNotificationCount': sentCount,
        'totalVipUsers': totalUsers,
        'notificationEfficiency': sentCount / totalUsers,
      });
    } catch (e) {
      logger.e('Error updating sweepstake results', error: e);
    }
  }

  /// Clear cache if it's stale
  void _clearCacheIfStale() {
    if (_lastCacheUpdate == null ||
        DateTime.now().difference(_lastCacheUpdate!) > CACHE_DURATION) {
      _settingsCache.clear();
      _categoryPreferencesCache.clear();
      _lastCacheUpdate = DateTime.now();
      logger.d('Cache cleared and refreshed');
    }
  }

  /// Create batches from a list
  List<List<T>> _createBatches<T>(List<T> items, int batchSize) {
    final batches = <List<T>>[];
    for (var i = 0; i < items.length; i += batchSize) {
      batches.add(
        items.sublist(
          i,
          (i + batchSize > items.length) ? items.length : i + batchSize,
        ),
      );
    }
    return batches;
  }

  /// Get performance statistics
  Future<Map<String, dynamic>> getPerformanceStats() async {
    try {
      return {
        'cacheSize': _settingsCache.length,
        'categoryPreferencesCacheSize': _categoryPreferencesCache.length,
        'lastCacheUpdate': _lastCacheUpdate?.toIso8601String(),
        'paginationSize': PAGINATION_SIZE,
        'maxConcurrentNotifications': MAX_CONCURRENT_NOTIFICATIONS,
        'cacheDuration': CACHE_DURATION.inMinutes,
      };
    } catch (e) {
      logger.e('Error getting performance stats', error: e);
      return {'error': e.toString()};
    }
  }

  /// Clear all caches (for testing or manual refresh)
  void clearAllCaches() {
    _settingsCache.clear();
    _categoryPreferencesCache.clear();
    _lastCacheUpdate = null;
    logger.i('All caches cleared manually');
  }
}

final optimizedVipNotificationService = OptimizedVipNotificationService();
