import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/utils/logger.dart';

class EnhancedAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  final LocalAuthentication _localAuth = LocalAuthentication();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static const int maxAttemptsPerHour = 5;
  static const int otpTimeout = 60; // seconds

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Enhanced Email Magic Link with Security
  Future<void> sendSecureMagicLink(String email, BuildContext context) async {
    try {
      // Validate email format
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      // Rate limiting check
      if (!await _checkRateLimit(email, 'magic_link')) {
        throw Exception('Too many attempts. Please wait before trying again.');
      }

      // Generate session-specific data
      final sessionId = _generateSecureSessionId();
      await _storeSessionData(sessionId, email);

      // Configure action code settings
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://sweepfeed.app/auth?session=$sessionId',
        handleCodeInApp: true,
        iOSBundleId: 'com.sweepfeed.app',
        androidPackageName: 'com.sweepfeed.app',
        androidInstallApp: true,
        androidMinimumVersion: '21',
      );

      // Send magic link
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      // Store email and timestamp for retrieval
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pendingAuthEmail', email);
      await prefs.setInt(
        'magicLinkSentTime',
        DateTime.now().millisecondsSinceEpoch,
      );

      // Track attempt for rate limiting
      await _trackAuthAttempt(email, 'magic_link');

      // Log security event
      await _logSecurityEvent('magic_link_sent', {
        'email': email,
        'sessionId': sessionId,
      });
    } catch (e) {
      await _logSecurityEvent('magic_link_failed', {
        'email': email,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Verify Email Magic Link with Expiry Check
  Future<UserCredential?> verifyEmailLink(String emailLink) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('pendingAuthEmail');
      final linkSentTime = prefs.getInt('magicLinkSentTime');

      if (email == null || linkSentTime == null) {
        throw Exception('No pending email authentication');
      }

      // Check if link has expired (30 minutes)
      final now = DateTime.now().millisecondsSinceEpoch;
      const thirtyMinutes = 30 * 60 * 1000;
      if (now - linkSentTime > thirtyMinutes) {
        await prefs.remove('pendingAuthEmail');
        await prefs.remove('magicLinkSentTime');
        throw Exception(
          'Authentication link has expired. Please request a new one.',
        );
      }

      // Verify the link
      if (_auth.isSignInWithEmailLink(emailLink)) {
        final credential = await _auth.signInWithEmailLink(
          email: email,
          emailLink: emailLink,
        );

        // Clear pending email and timestamp immediately after use (one-time use)
        await prefs.remove('pendingAuthEmail');
        await prefs.remove('magicLinkSentTime');

        // Initialize secure session
        await _initializeSecureSession(credential.user!);

        // Log successful authentication
        await _logSecurityEvent('magic_link_success', {
          'userId': credential.user!.uid,
          'linkAge': (now - linkSentTime) / 1000, // seconds
        });

        return credential;
      }

      throw Exception('Invalid authentication link');
    } catch (e) {
      await _logSecurityEvent('magic_link_verification_failed', {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Enhanced Phone OTP with Security
  Future<void> sendSecureOTP(String phoneNumber, BuildContext context) async {
    try {
      // Validate phone number format
      if (!_isValidPhoneNumber(phoneNumber)) {
        throw Exception('Invalid phone number format');
      }

      // Rate limiting check
      if (!await _checkRateLimit(phoneNumber, 'phone_otp')) {
        throw Exception('Too many OTP requests. Please wait.');
      }

      String? verificationId;

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: otpTimeout),
        verificationCompleted: (credential) async {
          // Auto-verification on Android
          _handleAutoVerification(credential, phoneNumber);
        },
        verificationFailed: (e) {
          _handleVerificationFailure(e, phoneNumber, context);
        },
        codeSent: (verId, resendToken) {
          verificationId = verId;
          _handleCodeSent(verId, resendToken, phoneNumber, context);
        },
        codeAutoRetrievalTimeout: (verId) {
          verificationId = verId;
          _handleTimeout(verId, phoneNumber);
        },
      );

      // Track attempt
      await _trackAuthAttempt(phoneNumber, 'phone_otp');
    } catch (e) {
      await _logSecurityEvent('otp_failed', {
        'phone': phoneNumber,
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Verify OTP Code
  Future<UserCredential?> verifyOTP(
    String verificationId,
    String smsCode,
  ) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Initialize secure session
      await _initializeSecureSession(userCredential.user!);

      return userCredential;
    } catch (e) {
      await _logSecurityEvent('otp_verification_failed', {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Google Sign In with Enhanced Security
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in cancelled');
      }

      // Obtain auth details
      final googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // Initialize secure session
      await _initializeSecureSession(userCredential.user!);

      // Log authentication
      await _logSecurityEvent('google_signin_success', {
        'userId': userCredential.user!.uid,
      });

      return userCredential;
    } catch (e) {
      await _logSecurityEvent('google_signin_failed', {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Apple Sign In with Enhanced Security
  Future<UserCredential?> signInWithApple() async {
    try {
      // Check if Apple Sign In is available
      if (!await SignInWithApple.isAvailable()) {
        throw Exception('Apple Sign In not available');
      }

      // Request credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: _generateNonce(),
      );

      // Create OAuth credential
      final oAuthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(oAuthCredential);

      // Update user profile if first time
      if (appleCredential.givenName != null) {
        await userCredential.user!.updateDisplayName(
          '${appleCredential.givenName} ${appleCredential.familyName}',
        );
      }

      // Initialize secure session
      await _initializeSecureSession(userCredential.user!);

      // Log authentication
      await _logSecurityEvent('apple_signin_success', {
        'userId': userCredential.user!.uid,
      });

      return userCredential;
    } catch (e) {
      await _logSecurityEvent('apple_signin_failed', {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Enable Biometric Authentication
  Future<bool> enableBiometricAuth() async {
    try {
      // Check availability
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        return false;
      }

      // Get available biometrics
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        return false;
      }

      // Authenticate
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Enable biometric login for quick access',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        // Store biometric preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometricEnabled', true);

        // Log event
        await _logSecurityEvent('biometric_enabled', {
          'userId': currentUser?.uid,
          'types': availableBiometrics.map((e) => e.toString()).toList(),
        });

        return true;
      }

      return false;
    } catch (e) {
      await _logSecurityEvent('biometric_setup_failed', {
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Authenticate with Biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final biometricEnabled = prefs.getBool('biometricEnabled') ?? false;

      if (!biometricEnabled) {
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access SweepFeed',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        await _logSecurityEvent('biometric_auth_success', {
          'userId': currentUser?.uid,
        });
      }

      return didAuthenticate;
    } catch (e) {
      await _logSecurityEvent('biometric_auth_failed', {
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Demo Mode Sign In (No authentication required)
  Future<UserCredential?> signInDemoMode() async {
    try {
      // Create or get demo user
      final demoEmail =
          'demo_${DateTime.now().millisecondsSinceEpoch}@sweepfeed.demo';

      // Sign in anonymously
      final userCredential = await _auth.signInAnonymously();

      // Update user document with demo flag
      await _firestore.collection('users').doc(userCredential.user!.uid).set(
        {
          'email': demoEmail,
          'isDemo': true,
          'createdAt': FieldValue.serverTimestamp(),
          'demoExpiry':
              Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
        },
        SetOptions(merge: true),
      );

      // Log demo access
      await _logSecurityEvent('demo_mode_activated', {
        'userId': userCredential.user!.uid,
      });

      return userCredential;
    } catch (e) {
      logger.e('Demo mode sign in failed', error: e);
      rethrow;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      // Clear session
      await _clearSession();

      // Sign out from providers
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);

      // Clear stored preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pendingAuthEmail');

      // Log sign out
      await _logSecurityEvent('user_signed_out', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      logger.e('Sign out failed', error: e);
      rethrow;
    }
  }

  // Helper Methods

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  bool _isValidPhoneNumber(String phone) =>
      RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phone);

  String _generateSecureSessionId() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  String _generateNonce() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    final nonce = base64Url.encode(values);
    return sha256.convert(utf8.encode(nonce)).toString();
  }

  Future<void> _storeSessionData(String sessionId, String email) async {
    await _firestore.collection('auth_sessions').doc(sessionId).set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt':
          Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 30))),
    });
  }

  Future<bool> _checkRateLimit(String identifier, String action) async {
    try {
      // Validate inputs
      if (identifier.isEmpty || action.isEmpty) {
        throw const ValidationError(
            'Identifier and action are required for rate limiting');
      }

      final doc = await _firestore
          .collection('rate_limits')
          .doc('${identifier}_$action')
          .get();

      if (!doc.exists) {
        return true;
      }

      final data = doc.data()!;
      final attempts = data['attempts'] as int? ?? 0;
      final lastAttempt = (data['lastAttempt'] as Timestamp?)?.toDate();

      if (lastAttempt != null) {
        final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
        if (lastAttempt.isBefore(hourAgo)) {
          // Reset counter
          await _firestore
              .collection('rate_limits')
              .doc('${identifier}_$action')
              .set({
            'attempts': 1,
            'lastAttempt': FieldValue.serverTimestamp(),
          });
          return true;
        }
      }

      return attempts < maxAttemptsPerHour;
    } on FirebaseException catch (e) {
      logger.e('Firebase error checking rate limit', error: e);
      // Return false (deny access) on error to be safe
      return false;
    } catch (e) {
      logger.e('Unexpected error checking rate limit', error: e);
      // Return false (deny access) on error to be safe
      return false;
    }
  }

  Future<void> _trackAuthAttempt(String identifier, String action) async {
    await _firestore.collection('rate_limits').doc('${identifier}_$action').set(
      {
        'attempts': FieldValue.increment(1),
        'lastAttempt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _initializeSecureSession(User user) async {
    try {
      // Validate user
      if (user.uid.isEmpty) {
        throw const ValidationError(
            'Valid user required for session initialization');
      }

      final sessionId = _generateSecureSessionId();
      final deviceFingerprint = await _generateDeviceFingerprint();

      await _firestore.collection('sessions').doc(sessionId).set({
        'userId': user.uid,
        'deviceFingerprint': deviceFingerprint,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'isActive': true,
        'authMethod': user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : 'anonymous',
      });

      // Store session ID locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sessionId', sessionId);

      logger.i(
          'Secure session initialized successfully. userId: ${user.uid}, sessionId: $sessionId');
    } on FirebaseException catch (e) {
      logger.e('Firebase error initializing secure session', error: e);
      throw FirestoreError(
        'Failed to initialize secure session. Please try again.',
        rawError: e,
        context: '_initializeSecureSession',
      );
    } catch (e) {
      logger.e('Unexpected error initializing secure session', error: e);
      throw AppError.fromException(
        e,
        context: '_initializeSecureSession',
        customMessage: 'Failed to initialize secure session. Please try again.',
      );
    }
  }

  Future<String> _generateDeviceFingerprint() async {
    try {
      var fingerprint = '';

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        fingerprint = '${androidInfo.model}_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        fingerprint = '${iosInfo.model}_${iosInfo.identifierForVendor}';
      } else {
        // Fallback for other platforms
        fingerprint =
            'unknown_platform_${DateTime.now().millisecondsSinceEpoch}';
      }

      if (fingerprint.isEmpty) {
        // Fallback if device info is not available
        fingerprint = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
      }

      return sha256.convert(utf8.encode(fingerprint)).toString();
    } catch (e) {
      logger.w('Failed to generate device fingerprint, using fallback',
          error: e);
      // Return a fallback fingerprint rather than failing
      final fallback =
          'error_fallback_${DateTime.now().millisecondsSinceEpoch}';
      return sha256.convert(utf8.encode(fallback)).toString();
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionId');

    if (sessionId != null) {
      await _firestore.collection('sessions').doc(sessionId).update({
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
      });

      await prefs.remove('sessionId');
    }
  }

  Future<void> _logSecurityEvent(
    String event,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('security_logs').add({
        'event': event,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': currentUser?.uid,
        'deviceInfo': await _generateDeviceFingerprint(),
      });
    } catch (e) {
      logger.e('CRITICAL: Failed to log security event', error: e);
      // CRITICAL: Always re-throw security logging failures
      // Security events MUST be logged or the operation should fail
      throw FirestoreError(
        'Security logging failed - operation cannot proceed',
        rawError: e,
        context: '_logSecurityEvent',
      );
    }
  }

  Future<void> _handleAutoVerification(
    PhoneAuthCredential credential,
    String phone,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      await _initializeSecureSession(userCredential.user!);
      await _logSecurityEvent('phone_auto_verified', {'phone': phone});
    } catch (e) {
      logger.e('Auto verification failed', error: e);
    }
  }

  void _handleVerificationFailure(
    FirebaseAuthException e,
    String phone,
    BuildContext context,
  ) {
    var message = 'Phone verification failed';

    if (e.code == 'invalid-phone-number') {
      message = 'The phone number is invalid';
    } else if (e.code == 'too-many-requests') {
      message = 'Too many requests. Please try again later';
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

    _logSecurityEvent('phone_verification_failed', {
      'phone': phone,
      'error': e.code,
    });
  }

  void _handleCodeSent(
    String verificationId,
    int? resendToken,
    String phone,
    BuildContext context,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Verification code sent')));

    _logSecurityEvent('phone_code_sent', {
      'phone': phone,
      'verificationId': verificationId,
    });
  }

  void _handleTimeout(String verificationId, String phone) {
    _logSecurityEvent('phone_verification_timeout', {
      'phone': phone,
      'verificationId': verificationId,
    });
  }
}
