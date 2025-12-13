import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../features/notifications/models/notification.dart';
import 'unified_notification_service.dart';

/// NotificationService - Wrapper/alias for UnifiedNotificationService
/// This provides backward compatibility for code that references NotificationService
class NotificationService {
  final UnifiedNotificationService _service = unifiedNotificationService;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize the notification service
  Future<void> init() async {
    // Basic initialization - UnifiedNotificationService.initialize requires userId
    // which should be called after user login
  }

  /// Get FCM token
  Future<String?> getFcmToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      return null;
    }
  }

  /// Get notifications for the current user
  Future<List<Notification>> getNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Notification(
          id: doc.id,
          title: data['title'] ?? '',
          body: data['body'] ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['read'] ?? false,
          type: data['type'] ?? 'general',
          data: data['data'] ?? {},
        );
      }).toList();
    } catch (e) {
    return [];
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      // Ignore errors
    }
  }

  /// Save FCM token to database
  Future<void> saveTokenToDatabase(String userId) async {
    try {
      final token = await getFcmToken();
      if (token != null) {
        // Delegate to unified service
        await _service.initialize(userId);
      }
    } catch (e) {
      // Log error but don't throw
    }
  }
}
