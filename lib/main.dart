import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/navigation/navigator_key.dart';
import 'core/providers/providers.dart';
import 'core/services/app_initialization_manager.dart';
import 'core/services/fcm_service.dart';
import 'core/services/isolate_data_loader.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
// Core services and utilities
import 'core/utils/logger.dart';
import 'core/widgets/anr_free_loading_screen.dart';
import 'core/widgets/confetti_overlay.dart'; // Added import
import 'features/auth/screens/login_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/services/email_magic_link_handler.dart';
// Main Screen (Moved to feature)
import 'features/navigation/screens/main_screen.dart';
import 'features/onboarding/screens/adaptive_onboarding_wrapper.dart';
// Feature screens
// Feature screens
import 'features/onboarding/screens/splash_screen.dart';
import 'features/subscription/screens/subscription_screen.dart';
import 'l10n/app_localizations.dart';

/// The main function, entry point of the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize critical services for fast app startup
  final initManager = AppInitializationManager();
  SharedPreferences? prefs;

  try {
    await initManager.initializeCritical();
    prefs = initManager.prefs;

    // Set up error handlers only if Firebase was successfully initialized
    if (initManager.isFirebaseInitialized) {
      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    // Initialize Notification Service
    final notificationService = NotificationService();
    await notificationService.init();
    final fcmToken = await notificationService.getFcmToken();
    logger.d('FCM Token: $fcmToken');

    // Initialize FCM service for social features
    await fcmService.initialize();

    // Initialize email magic link handler (will be fully initialized when context is available)
    final emailMagicLinkHandler = EmailMagicLinkHandler();
    // Note: Full initialization with context happens in MyApp widget

    logger.d('Critical initialization completed');

    // Start background initialization (non-blocking)
    // ReminderService will be initialized when ProviderScope is available
    unawaited(initManager.initializeBackground());

    // Start data loading in isolate (non-blocking)
    unawaited(IsolateDataLoader().loadContestDataAsync());
  } on Exception catch (e) {
    logger.e('Initialization error: $e');
    // Continue anyway - app can still start with basic functionality
  }

  // Get SharedPreferences instance (reuse from initManager or create new)
  prefs ??= initManager.prefs ?? await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWith((ref) => Future.value(prefs!)),
      ],
      child: const MyApp(),
    ),
  );
}

/// The root widget of the application.
class MyApp extends ConsumerStatefulWidget {
  /// Constructs a [MyApp] widget.
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final EmailMagicLinkHandler _emailMagicLinkHandler = EmailMagicLinkHandler();

  @override
  void initState() {
    super.initState();
    // Initialize email magic link handler after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailMagicLinkHandler.initialize(context);
    });
  }

  @override
  void dispose() {
    _emailMagicLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = ref.watch(themeProvider);
    final analyticsService = ref.watch(analyticsServiceProvider);
    final appSettings = ref.watch(appSettingsProvider);

    final fontScale = appSettings.fontSize / 16.0;

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SweepFeed',
      theme: AppTheme.lightTheme(
        accentColor: appSettings.accentColorValue,
        fontScale: fontScale,
      ),
      darkTheme: AppTheme.darkTheme(
        accentColor: appSettings.accentColorValue,
        fontScale: fontScale,
      ),
      themeMode: themeManager,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
      ],
      routes: {
        '/subscription': (context) => const SubscriptionScreen(),
      },
      home: const ConfettiOverlay( // Wrapped with ConfettiOverlay
        child: ANRFreeAppWrapper(
          app: SplashScreen(),
        ),
      ),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        if (state == AuthState.authenticated) {
          return const MainScreen();
        } else if (state == AuthState.unauthenticated) {
          return const LoginScreen();
        } else if (state == AuthState.onboarding) {
          return const AdaptiveOnboardingWrapper();
        } else if (state == AuthState.loading) {
          return const _LoadingScreen(message: 'Checking authentication...');
        } else {
          return const LoginScreen();
        }
      },
      loading: () =>
          const _LoadingScreen(message: 'Checking authentication...'),
      error: (error, stack) => const LoginScreen(),
    );
  }
}

/// Reusable loading screen widget
class _LoadingScreen extends StatelessWidget {
  /// Constructs a [_LoadingScreen] widget.
  const _LoadingScreen({required this.message});

  /// The message to display on the loading screen.
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      );
}
