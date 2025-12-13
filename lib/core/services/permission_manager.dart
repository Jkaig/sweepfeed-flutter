import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';
import 'unified_notification_service.dart';

class PermissionManager {
  factory PermissionManager() => _instance;
  PermissionManager._internal();
  static final PermissionManager _instance = PermissionManager._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<NotificationPermissionStatus> checkStatus() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return _convertAuthStatus(settings.authorizationStatus);
    } catch (e) {
      logger.e('Error checking permission status', error: e);
      return NotificationPermissionStatus.notDetermined;
    }
  }

  Future<NotificationPermissionStatus> request() async {
    try {
      // Use permission_handler for better status (especially permanently denied detection)
      // This is preferred over FirebaseMessaging.requestPermission() as it gives us granular control
      // to guide users to settings.
      final status = await Permission.notification.request();

      final parsedStatus = _convertPermissionStatus(status);
      await _savePermissionStatus(parsedStatus);

      logger.i('Notification permission status: ${parsedStatus.toString()}');
      return parsedStatus;
    } catch (e) {
      logger.e('Error requesting notification permission', error: e);
      return NotificationPermissionStatus.denied;
    }
  }

  NotificationPermissionStatus _convertPermissionStatus(PermissionStatus status) {
    if (status.isGranted) return NotificationPermissionStatus.granted;
    if (status.isDenied) return NotificationPermissionStatus.denied;
    if (status.isPermanentlyDenied) return NotificationPermissionStatus.permanentlyDenied;
    return NotificationPermissionStatus.notDetermined;
  }


  NotificationPermissionStatus _convertAuthStatus(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return NotificationPermissionStatus.granted;
      case AuthorizationStatus.denied:
        return NotificationPermissionStatus.denied;
      case AuthorizationStatus.notDetermined:
        return NotificationPermissionStatus.notDetermined;
      default:
        return NotificationPermissionStatus.denied;
    }
  }

  Future<void> _savePermissionStatus(
    NotificationPermissionStatus status,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        logger.w('No user logged in, cannot save permission status');
        return;
      }

      await _firestore.collection('users').doc(userId).set(
        {
          'notificationSettings': {
            'permissionStatus': status.toString().split('.').last,
            'permissionLastChecked': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );

      logger.i('Permission status saved: ${status.toString()}');
    } catch (e) {
      logger.e('Error saving permission status', error: e);
    }
  }

  Future<NotificationPermissionStatus> getStoredStatus(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();

      if (data == null) return NotificationPermissionStatus.notDetermined;

      final statusStr =
          data['notificationSettings']?['permissionStatus'] as String?;
      return _parsePermissionStatus(statusStr);
    } catch (e) {
      logger.e('Error getting stored permission status', error: e);
      return NotificationPermissionStatus.notDetermined;
    }
  }

  NotificationPermissionStatus _parsePermissionStatus(String? status) {
    switch (status) {
      case 'granted':
        return NotificationPermissionStatus.granted;
      case 'denied':
        return NotificationPermissionStatus.denied;
      case 'permanentlyDenied':
        return NotificationPermissionStatus.permanentlyDenied;
      default:
        return NotificationPermissionStatus.notDetermined;
    }
  }

  bool shouldShowPermissionPrompt(NotificationPermissionStatus status) =>
      status == NotificationPermissionStatus.notDetermined;

  bool shouldShowSettingsPrompt(NotificationPermissionStatus status) =>
      status == NotificationPermissionStatus.denied ||
      status == NotificationPermissionStatus.permanentlyDenied;

  String getPermissionStatusMessage(NotificationPermissionStatus status) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return 'Notifications are enabled';
      case NotificationPermissionStatus.denied:
        return 'Notifications are disabled. Tap to enable in settings.';
      case NotificationPermissionStatus.permanentlyDenied:
        return 'Notifications are permanently disabled. Please enable in system settings.';
      case NotificationPermissionStatus.notDetermined:
        return 'Enable notifications to receive updates about new contests';
    }
  }

  String getPermissionStatusIcon(NotificationPermissionStatus status) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return '✓';
      case NotificationPermissionStatus.denied:
      case NotificationPermissionStatus.permanentlyDenied:
        return '✗';
      case NotificationPermissionStatus.notDetermined:
        return '?';
    }
  }
}

final permissionManager = PermissionManager();
