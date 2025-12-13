import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _biometricsEnabledKey = 'biometrics_enabled';
  static const String _refreshTokenKey = 'firebase_refresh_token';
  static const String _userIdKey = 'firebase_user_id';

  Future<bool> canUseBiometrics() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      logger.e('Error checking biometric availability', error: e);
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      logger.e('Error getting available biometrics', error: e);
      return [];
    }
  }

  Future<bool> authenticateWithBiometrics({String? reason}) async {
    try {
      final canAuthenticate = await canUseBiometrics();
      if (!canAuthenticate) {
        logger.w('Biometrics not available on this device');
        return false;
      }

      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        logger.w('No biometrics enrolled on this device');
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason ?? 'Authenticate to access SweepFeed',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      logger.e('Error during biometric authentication', error: e);
      return false;
    }
  }

  Future<bool> isBiometricsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricsEnabledKey) ?? false;
    } catch (e) {
      logger.e('Error checking if biometrics enabled', error: e);
      return false;
    }
  }

  Future<bool> enableBiometrics() async {
    try {
      final authenticated = await authenticateWithBiometrics(
        reason: 'Authenticate to enable biometric login',
      );

      if (!authenticated) {
        logger.w('Biometric authentication failed during enablement');
        return false;
      }

      final user = _auth.currentUser;
      if (user == null) {
        logger.e('No user logged in when trying to enable biometrics');
        return false;
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        logger.e('Failed to get ID token');
        return false;
      }

      await _secureStorage.write(key: _refreshTokenKey, value: idToken);
      await _secureStorage.write(key: _userIdKey, value: user.uid);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricsEnabledKey, true);

      logger.i(
        'Biometric authentication enabled successfully for user ${user.uid}',
      );
      return true;
    } catch (e) {
      logger.e('Error enabling biometrics', error: e);
      return false;
    }
  }

  Future<bool> disableBiometrics() async {
    try {
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userIdKey);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricsEnabledKey, false);

      logger.i('Biometric authentication disabled successfully');
      return true;
    } catch (e) {
      logger.e('Error disabling biometrics', error: e);
      return false;
    }
  }

  Future<User?> signInWithBiometrics() async {
    try {
      final isEnabled = await isBiometricsEnabled();
      if (!isEnabled) {
        logger.w('Biometrics not enabled, cannot sign in');
        return null;
      }

      final authenticated = await authenticateWithBiometrics(
        reason: 'Authenticate to sign in to SweepFeed',
      );

      if (!authenticated) {
        logger.w('Biometric authentication failed');
        return null;
      }

      final storedToken = await _secureStorage.read(key: _refreshTokenKey);
      final storedUserId = await _secureStorage.read(key: _userIdKey);

      if (storedToken == null || storedUserId == null) {
        logger.e('No stored credentials found');
        await disableBiometrics();
        return null;
      }

      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == storedUserId) {
        await currentUser.getIdToken(true);
        logger.i('User already signed in, refreshed token');
        return currentUser;
      }

      logger.i('Successfully authenticated user with biometrics');
      return _auth.currentUser;
    } catch (e) {
      logger.e('Error signing in with biometrics', error: e);
      return null;
    }
  }

  String getBiometricTypeString(List<BiometricType> biometrics) {
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (biometrics.contains(BiometricType.strong)) {
      return 'Biometric';
    } else if (biometrics.contains(BiometricType.weak)) {
      return 'Biometric';
    }
    return 'Biometric';
  }
}
