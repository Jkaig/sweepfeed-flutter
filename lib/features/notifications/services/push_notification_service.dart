import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/utils/logger.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  logger.d('Handling a background message: ${message.messageId}');
}

class PushNotificationService {
  factory PushNotificationService() => _instance;

  PushNotificationService._internal() {
    initialize();
  }
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _token;

  static final PushNotificationService _instance =
      PushNotificationService._internal();

  Future<void> initialize() async {
    final settings = await _firebaseMessaging.requestPermission();

    logger.i('User granted permission: ${settings.authorizationStatus}');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) {
      logger.d('Got a message whilst in the foreground!');
      logger.d('Message data: ${message.data}');

      if (message.notification != null) {
        logger.d(
          'Message also contained a notification: ${message.notification}',
        );
      }
    });

    _token = await _firebaseMessaging.getToken();
    logger.i('FCM Token: $_token');
  }

  Future<String?> getToken() async {
    _token ??= await _firebaseMessaging.getToken();
    return _token;
  }
}
