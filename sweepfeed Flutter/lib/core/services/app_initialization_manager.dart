import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/reminders/services/reminder_service.dart';
import '../../firebase_options.dart';
import '../config/secure_config.dart';
import '../utils/logger.dart';
import 'notification_migration_service.dart';
import 'remote_config_service.dart';
import 'unified_notification_service.dart';

/// Manages phased initialization of the app to prevent ANR issues.
///
/// This singleton class handles the startup process in distinct phases:
/// 1. **Critical**: Essential services needed before the app can run.
/// 2. **Background**: Non-essential services that can be loaded after startup.
/// 3. **Lazy**: Services loaded on-demand when first accessed.
class AppInitializationManager {
  /// Factory constructor to return the singleton instance.
  factory AppInitializationManager() => _instance;
  AppInitializationManager._internal();

  /// The singleton instance of [AppInitializationManager].
  static final AppInitializationManager _instance =
      AppInitializationManager._internal();

  // Initialization progress tracking
  /// Notifies listeners about the progress of the initialization process (0.0 to 1.0).
  final ValueNotifier<double> initializationProgress = ValueNotifier(0.0);

  /// Notifies listeners about the current phase of initialization.
  final ValueNotifier<String> currentPhase = ValueNotifier('Starting...');

  bool _isInitialized = false;
  SharedPreferences? _prefs;
  bool _firebaseInitialized = false;

  /// The [SharedPreferences] instance, available after critical initialization.
  SharedPreferences? get prefs => _prefs;

  /// Returns `true` if the critical initialization phase is complete.
  bool get isInitialized => _isInitialized;

  /// Returns `true` if Firebase was successfully initialized.
  bool get isFirebaseInitialized => _firebaseInitialized;

  /// Phase 1: Critical initialization (must complete before app can start).
  ///
  /// Initializes dotenv, Firebase, and SharedPreferences.
  Future<void> initializeCritical() async {
    if (_isInitialized) {
      return;
    }

    try {
      currentPhase.value = 'Loading environment...';
      initializationProgress.value = 0.1;

      // Initialize SecureConfig (loads dotenv internally)
      await SecureConfig.initialize();
      logger.d('SecureConfig initialized');

      currentPhase.value = 'Initializing Firebase...';
      initializationProgress.value = 0.3;

      // Initialize Firebase with timeout protection
      if (Firebase.apps.isEmpty) {
        await _initializeFirebaseWithTimeout();
      }

      currentPhase.value = 'Loading preferences...';
      initializationProgress.value = 0.6;

      // Initialize SharedPreferences (lightweight, fast)
      _prefs = await SharedPreferences.getInstance();

      initializationProgress.value = 0.8;
      currentPhase.value = 'Starting app...';

      _isInitialized = true;
      initializationProgress.value = 1.0;

      logger.d('Critical initialization completed');
    } on Exception catch (e) {
      logger.e('Critical initialization failed: $e');
      // App can still run with limited functionality
      _isInitialized = true;
      initializationProgress.value = 1.0;
    }
  }

  /// Initialize Firebase with timeout protection.
  Future<void> _initializeFirebaseWithTimeout() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          logger.w(
            'Firebase initialization timeout - continuing without Firebase',
          );
          throw TimeoutException('Firebase initialization timeout');
        },
      );

      _firebaseInitialized = true;
      logger.d('Firebase initialized successfully');

      // Configure emulators in background if needed
      _configureEmulatorsInBackground();
    } on Exception catch (e) {
      logger.e('Firebase initialization error: $e');
      // Continue without Firebase - app can still run
    }
  }

  /// Configure Firebase emulators in background (non-blocking).
  void _configureEmulatorsInBackground() {
    const useEmulator = bool.fromEnvironment('USE_EMULATOR');

    if (!useEmulator) {
      return;
    }

    // Run in background to avoid blocking
    Future.microtask(() async {
      try {
        const host = !kIsWeb ? '10.0.2.2' : 'localhost';

        await FirebaseAuth.instance.useAuthEmulator(host, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
        await FirebaseStorage.instance.useStorageEmulator(host, 9199);

        logger.i('Firebase Emulators configured for $host');
      } on Exception catch (e) {
        logger.e('Error configuring Firebase Emulators: $e');
      }
    });
  }

  /// Phase 2: Background initialization (non-critical services).
  ///
  /// Initializes push notifications and the reminder service.
  Future<void> initializeBackground() async {
    // This runs after the app has started
    // Heavy operations are handled by isolates in IsolateDataLoader

    try {
      // Initialize analytics, crash reporting, etc.
      await Future.delayed(const Duration(milliseconds: 100));

      // Setup push notifications
      await _setupPushNotifications();

      // Initialize the reminder service
      await ReminderService().init();

      // Initialize Firebase Remote Config for A/B testing
      try {
        await remoteConfigService.initialize();
        logger.d('Remote Config initialized');
      } catch (e) {
        logger.w(
          'Remote Config initialization failed (non-critical)',
          error: e,
        );
      }

      logger.d('Background initialization completed');
    } on Exception catch (e) {
      logger.e('Background initialization error: $e');
      // Non-critical - continue running
    }
  }

  /// Setup push notifications (non-blocking).
  Future<void> _setupPushNotifications() async {
    try {
      // Only setup if Firebase is initialized
      if (!_firebaseInitialized) {
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        logger.d('No user logged in, skipping notification setup');
        return;
      }

      await notificationMigrationService
          .migrateNotificationSettings(currentUser.uid);
      logger.d('Notification settings migrated');

      await unifiedNotificationService.initialize(currentUser.uid);
      logger.d('Unified notification service initialized');
    } on Exception catch (e) {
      logger.w('Push notification setup failed: $e');
    }
  }

  /// Phase 3: Lazy initialization (on-demand services).
  ///
  /// Services that should only initialize when first accessed via providers.
  void initializeLazy() {
    // Services are initialized via lazy providers
    // This method is just a placeholder for documentation
  }

  /// Reset initialization state (useful for testing).
  @visibleForTesting
  void reset() {
    _isInitialized = false;
    _prefs = null;
    _firebaseInitialized = false;
    initializationProgress.value = 0.0;
    currentPhase.value = 'Starting...';
  }
}

/// Custom exception for initialization timeouts.
class TimeoutException implements Exception {
  /// Creates a [TimeoutException].
  TimeoutException(this.message);

  /// The error message.
  final String message;
}
