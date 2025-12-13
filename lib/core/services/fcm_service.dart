import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../utils/logger.dart';

/// Service to manage Firebase Cloud Messaging tokens and notifications
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    // Request permission for iOS
    final settings = await _messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      logger.d('User granted FCM permission');
      await _saveToken();
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      logger.d('User granted provisional FCM permission');
      await _saveToken();
    } else {
      logger.d('User declined FCM permission');
    }

    // Handle token refresh
    _messaging.onTokenRefresh.listen(_handleTokenRefresh);

    // Set up foreground notification handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Get FCM token and save to Firestore
  Future<void> _saveToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        logger.d('No user logged in, skipping FCM token save');
        return;
      }

      final token = await _messaging.getToken();
      if (token == null) {
        logger.w('FCM token is null');
        return;
      }

      logger.d('FCM Token obtained');

      // Save token to Firestore
      await _firestore.collection('users').doc(user.uid).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      logger.d('FCM token saved to Firestore');
    } catch (e) {
      logger.e('Error saving FCM token', error: e);
    }
  }

  /// Handle token refresh
  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      logger.d('FCM token refreshed');

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': newToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      logger.d('New FCM token saved to Firestore');
    } catch (e) {
      logger.e('Error updating FCM token', error: e);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    logger.d('Received foreground FCM message: ${message.messageId}');

    if (message.notification != null) {
      logger.d('FCM message contains notification: ${message.notification?.title}');
      // You can show a custom notification UI here
    }
  }

  /// Delete token when user logs out
  Future<void> deleteToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      }

      await _messaging.deleteToken();
      logger.d('FCM token deleted');
    } catch (e) {
      logger.e('Error deleting FCM token', error: e);
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      logger.d('Subscribed to FCM topic: $topic');
    } catch (e) {
      logger.e('Error subscribing to FCM topic: $topic', error: e);
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      logger.d('Unsubscribed from FCM topic: $topic');
    } catch (e) {
      logger.e('Error unsubscribing from FCM topic: $topic', error: e);
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Note: Logger may not be available in background isolate
  // Use debugPrint here as it's safe and will be stripped in release
  debugPrint('Handling background FCM message: ${message.messageId}');
}

/// Singleton instance
final fcmService = FCMService();
