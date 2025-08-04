import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/navigation/navigator_key.dart';
import '../../contests/screens/contest_detail_screen.dart';

class NotificationService {
  static const String _prefsKey = 'notification_preferences';
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance; 
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SharedPreferences _prefs;

  NotificationService(this._prefs) {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Request permission for notifications
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);

    // Handle incoming messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification
    await _showLocalNotification(
      title: message.notification?.title ?? 'New Sweepstakes',
      body: message.notification?.body ?? 'Check out this new opportunity!',
      payload: json.encode(message.data),
    );
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    print("Handling notification tap: ${message.data}");
    // Extract contestId from data payload
    final contestId = message.data['contestId'] as String?;

    if (contestId != null) {
      // Use the global navigator key to navigate
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ContestDetailScreen(contestId: contestId),
        ),
      );
    } else {
      print("Notification tap data did not contain a contestId.");
      // Handle other notification types or general navigation if needed
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'sweepfeed_channel',
      'SweepFeed Notifications',
      channelDescription: 'Notifications for sweepstakes updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

 // Notification Preferences
  Future<void> savePreference(String key, bool value) async {
    await _prefs.setBool(key, value);
  }
  
  Future<bool> loadPreference(String key) async {
    return _prefs.getBool(key) ?? true; // Default to true if not set
  }
    Future<Map<String, bool>> loadPreferences() async {
    final preferences = <String, bool>{};
    preferences['new_sweepstakes'] = await loadPreference('new_sweepstakes');
    preferences['ending_soon'] = await loadPreference('ending_soon');
    return preferences;
  }

  // Topic Subscription
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Token Management
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> deleteToken() async {
    await _firebaseMessaging.deleteToken();
  }
}
