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

class VipNotificationService {
  factory VipNotificationService() => _instance;
  VipNotificationService._internal();
  static final VipNotificationService _instance =
      VipNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const double HIGH_VALUE_THRESHOLD = 500.0;
  static const double ULTRA_HIGH_VALUE_THRESHOLD = 5000.0;

  static const Duration VIP_EARLY_ACCESS_WINDOW = Duration(hours: 24);
  static const Duration PREMIUM_EARLY_ACCESS_WINDOW = Duration(hours: 12);

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

      await _sendVipInstantNotifications(highValueSweep);

      if (prizeValue >= ULTRA_HIGH_VALUE_THRESHOLD) {
        await _sendPremiumNotifications(highValueSweep);
      }

      logger.i(
        'High-value sweepstake notifications sent: $title (\$$prizeValue)',
      );
    } catch (e) {
      logger.e('Error processing high-value sweepstake notification', error: e);
    }
  }

  bool _isHighValue(double prizeValue) => prizeValue >= HIGH_VALUE_THRESHOLD;

  bool _isUltraHighValue(double prizeValue) =>
      prizeValue >= ULTRA_HIGH_VALUE_THRESHOLD;

  Future<void> _saveHighValueSweepstake(HighValueSweepstake sweepstake) async {
    try {
      await _firestore
          .collection('high_value_sweepstakes')
          .doc(sweepstake.id)
          .set(sweepstake.toFirestore());

      logger.d('High-value sweepstake saved: ${sweepstake.id}');
    } catch (e) {
      logger.e('Error saving high-value sweepstake', error: e);
    }
  }

  Future<void> _sendVipInstantNotifications(
    HighValueSweepstake sweepstake,
  ) async {
    try {
      final vipUsers = await _getVipUsers();

      logger.i('Sending INSTANT notifications to ${vipUsers.length} VIP users');

      var sentCount = 0;
      for (final user in vipUsers) {
        final settings = await unifiedNotificationService.getSettings(user.id);

        if (settings.push.enabled &&
            settings.push.types['highValue'] == true &&
            await _userWantsCategory(user.id, sweepstake.category)) {
          await _sendPriorityNotification(
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

          sentCount++;
        }
      }

      await _firestore
          .collection('high_value_sweepstakes')
          .doc(sweepstake.id)
          .update({
        'vipNotificationSent': true,
        'vipNotificationTime': FieldValue.serverTimestamp(),
        'vipNotificationCount': sentCount,
      });

      logger.i('VIP notifications sent: $sentCount');
    } catch (e) {
      logger.e('Error sending VIP notifications', error: e);
    }
  }

  Future<void> _sendPremiumNotifications(HighValueSweepstake sweepstake) async {
    try {
      await Future.delayed(PREMIUM_EARLY_ACCESS_WINDOW);

      final premiumUsers = await _getPremiumUsers();

      logger.i(
        'Sending notifications to ${premiumUsers.length} Premium users after ${PREMIUM_EARLY_ACCESS_WINDOW.inHours}h',
      );

      var sentCount = 0;
      for (final user in premiumUsers) {
        final settings = await unifiedNotificationService.getSettings(user.id);

        if (settings.push.enabled &&
            settings.push.types['highValue'] == true &&
            await _userWantsCategory(user.id, sweepstake.category)) {
          await _sendPriorityNotification(
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

          sentCount++;
        }
      }

      logger.i('Premium notifications sent: $sentCount');
    } catch (e) {
      logger.e('Error sending Premium notifications', error: e);
    }
  }

  Future<void> _sendPriorityNotification({
    required String userId,
    required String sweepstakeId,
    required String title,
    required String body,
    required String priority,
    required Map<String, String> data,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        logger.w('No FCM token for user: $userId');
        return;
      }

      await _firestore.collection('notification_queue').add({
        'userId': userId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'priority': priority,
        'data': data,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notification_history')
          .add({
        'sweepstakeId': sweepstakeId,
        'type': data['type'],
        'sentAt': FieldValue.serverTimestamp(),
        'title': title,
        'body': body,
      });

      logger.d('Priority notification queued for user: $userId');
    } catch (e) {
      logger.e('Error sending priority notification', error: e);
    }
  }

  Future<List<UserProfile>> _getVipUsers() async {
    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .where('tier', isEqualTo: 'vip')
          .get();

      return usersSnapshot.docs.map(UserProfile.fromFirestore).toList();
    } catch (e) {
      logger.e('Error getting VIP users', error: e);
      return [];
    }
  }

  Future<List<UserProfile>> _getPremiumUsers() async {
    try {
      final now = Timestamp.now();

      final usersSnapshot = await _firestore
          .collection('users')
          .where('tier', isEqualTo: 'premium')
          .get();

      final activeUsers =
          usersSnapshot.docs.map(UserProfile.fromFirestore).where((user) {
        if (user.premiumUntil == null) return false;
        return user.premiumUntil!.toDate().isAfter(DateTime.now());
      }).toList();

      return activeUsers;
    } catch (e) {
      logger.e('Error getting Premium users', error: e);
      return [];
    }
  }

  Future<bool> _userWantsCategory(String userId, String category) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData == null) return true;

      final interests = userData['interests'] as List<dynamic>?;
      if (interests == null || interests.isEmpty) return true;

      return interests.contains(category);
    } catch (e) {
      logger.e('Error checking user category preference', error: e);
      return true;
    }
  }

  Future<bool> isInVipEarlyAccessWindow(String sweepstakeId) async {
    try {
      final doc = await _firestore
          .collection('high_value_sweepstakes')
          .doc(sweepstakeId)
          .get();

      if (!doc.exists) return false;

      final sweepstake = HighValueSweepstake.fromFirestore(doc);

      if (sweepstake.vipNotificationTime == null) return false;

      final windowEnd =
          sweepstake.vipNotificationTime!.add(VIP_EARLY_ACCESS_WINDOW);
      return DateTime.now().isBefore(windowEnd);
    } catch (e) {
      logger.e('Error checking VIP early access window', error: e);
      return false;
    }
  }

  Future<bool> canUserAccessSweepstake(
    String userId,
    String sweepstakeId,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final user = UserProfile.fromFirestore(userDoc);

      if (user.tier == 'vip') return true;

      final isInWindow = await isInVipEarlyAccessWindow(sweepstakeId);

      if (isInWindow) {
        logger.i(
          'Sweepstake $sweepstakeId is in VIP early access window. User ${user.tier} blocked.',
        );
        return false;
      }

      return true;
    } catch (e) {
      logger.e('Error checking sweepstake access', error: e);
      return true;
    }
  }

  Future<Map<String, dynamic>> getVipNotificationStats() async {
    try {
      final highValueSweeps = await _firestore
          .collection('high_value_sweepstakes')
          .where('vipNotificationSent', isEqualTo: true)
          .get();

      final stats = {
        'totalHighValueSweepstakes': highValueSweeps.size,
        'averagePrizeValue': 0.0,
        'totalVipNotifications': 0,
        'last24Hours': 0,
      };

      if (highValueSweeps.docs.isEmpty) return stats;

      double totalValue = 0;
      var totalNotifications = 0;
      var last24Hours = 0;

      final cutoff = DateTime.now().subtract(const Duration(hours: 24));

      for (final doc in highValueSweeps.docs) {
        final data = doc.data();
        totalValue += (data['prizeValue'] as num).toDouble();
        totalNotifications += data['vipNotificationCount'] as int? ?? 0;

        final sentTime = (data['vipNotificationTime'] as Timestamp?)?.toDate();
        if (sentTime != null && sentTime.isAfter(cutoff)) {
          last24Hours++;
        }
      }

      stats['averagePrizeValue'] = totalValue / highValueSweeps.size;
      stats['totalVipNotifications'] = totalNotifications;
      stats['last24Hours'] = last24Hours;

      return stats;
    } catch (e) {
      logger.e('Error getting VIP notification stats', error: e);
      return {};
    }
  }
}

final vipNotificationService = VipNotificationService();
