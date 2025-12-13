import 'package:contacts_service_plus/contacts_service_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

class AppContactsService {
  /// Check current permission status without requesting
  Future<PermissionStatus> checkPermissionStatus() async {
    try {
      return await Permission.contacts.status;
    } catch (e) {
      logger.e('Error checking contacts permission', error: e);
      return PermissionStatus.denied;
    }
  }

  /// Request contacts permission
  Future<PermissionStatus> requestPermission() async {
    try {
      return await Permission.contacts.request();
    } catch (e) {
      logger.e('Error requesting contacts permission', error: e);
      return PermissionStatus.denied;
    }
  }

  /// Open app settings if permission is permanently denied
  Future<bool> openSettings() async {
    try {
      return openAppSettings();
    } catch (e) {
      logger.e('Error opening app settings', error: e);
      return false;
    }
  }

  /// Get contacts if permission is granted
  Future<List<Contact>> getContacts() async {
    try {
      final status = await checkPermissionStatus();
      if (status.isGranted) {
        return ContactsService.getContacts();
      } else {
        logger.w('Contacts permission not granted. Status: $status');
        return [];
      }
    } catch (e) {
      logger.e('Error getting contacts', error: e);
      return [];
    }
  }

  /// Get contacts with automatic permission request
  Future<List<Contact>> getContactsWithPermission() async {
    final status = await requestPermission();
    if (status.isGranted) {
      return await getContacts();
    }
    return [];
  }
}

final contactsServiceProvider = Provider<AppContactsService>((ref) => AppContactsService());
