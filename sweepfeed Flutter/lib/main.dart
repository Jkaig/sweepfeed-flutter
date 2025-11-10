import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show PlatformDispatcher;
import 'package:flutter/material.dart';
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
// Feature widgets
import 'features/ads/widgets/ad_banner.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/navigation/screens/main_navigation_wrapper.dart';
import 'features/onboarding/screens/adaptive_onboarding_wrapper.dart';
// Feature screens
import 'features/onboarding/screens/splash_screen.dart';
import 'features/subscription/screens/subscription_screen.dart';
import 'features/subscription/widgets/active_trial_banner.dart';
import 'features/subscription/widgets/trial_banner.dart';

/// The main function, entry point of the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize critical services for fast app startup
    final initManager = AppInitializationManager();
    await initManager.initializeCritical();

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Initialize Notification Service
    final notificationService = NotificationService();
    await notificationService.init();
    final fcmToken = await notificationService.getFcmToken();
    logger.d('FCM Token: $fcmToken');

    // Initialize FCM service for social features
    await fcmService.initialize();

    logger.d('Critical initialization completed');

    // Start background initialization (non-blocking)
    unawaited(initManager.initializeBackground());

    // Start data loading in isolate (non-blocking)
    unawaited(IsolateDataLoader().loadContestDataAsync());
  } on Exception catch (e) {
    logger.e('Initialization error: $e');
    // Continue anyway - app can still start with basic functionality
  }

  // Get SharedPreferences instance
  final prefs =
      AppInitializationManager().prefs ?? await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWith((ref) => prefs),
      ],
      child: const MyApp(),
    ),
  );
}

/// The root widget of the application.
class MyApp extends ConsumerWidget {
  /// Constructs a [MyApp] widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      themeMode: themeManager.themeMode,
      navigatorObservers: [analyticsService.getAnalyticsObserver()],
      // localizationsDelegates: const [
      //   AppLocalizations.delegate,
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      // supportedLocales: const [
      //   Locale('en'), // English
      //   Locale('es'), // Spanish
      // ],
      routes: {
        '/subscription': (context) => const SubscriptionScreen(),
      },
      home: const ANRFreeAppWrapper(
        app: SplashScreen(),
      ),
    );
  }
}

/// Wrapper to handle user authentication and routing
class AuthWrapper extends ConsumerWidget {
  /// Constructs a [AuthWrapper] widget.
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        // User is logged in, check onboarding status
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 5)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen(message: 'Loading user data...');
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                !snapshot.data!.exists) {
              return const AdaptiveOnboardingWrapper();
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            final onboardingCompleted =
                userData?['onboardingCompleted'] as bool? ?? false;

            return onboardingCompleted
                ? const MainScreen()
                : const AdaptiveOnboardingWrapper();
          },
        );
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

/// The main screen of the application.
class MainScreen extends ConsumerStatefulWidget {
  /// Constructs a [MainScreen] widget.
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    _checkDailyLoginBonus();
  }

  /// Checks and awards the daily login bonus to the user.
  Future<void> _checkDailyLoginBonus() async {
    final currentUser = ref.read(firebaseServiceProvider).currentUser;
    if (currentUser == null) return;

    final dustBunniesService = ref.read(dustBunniesServiceProvider);
    final reward = await dustBunniesService.awardDustBunnies(
      userId: currentUser.uid,
      action: 'daily_login',
    );
    final awarded = reward.pointsAwarded > 0;

    if (awarded && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.stars, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Daily Login Bonus!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '+10 SweepPoints earned',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00D9FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionService = ref.watch(subscriptionServiceProvider);

    return Scaffold(
      body: Column(
        children: [
          // Show trial banner based on subscription status
          if (!subscriptionService.isSubscribed &&
              !subscriptionService.isInTrialPeriod)
            const TrialBanner(),

          // Show active trial banner for users in trial period
          if (subscriptionService.isInTrialPeriod) const ActiveTrialBanner(),

          // Main content - IdealHomeScreen with cyan borders design
          const Expanded(child: MainNavigationWrapper()),

          // Ad banner at the bottom for free users
          if (!subscriptionService.isSubscribed) const AdBanner(height: 50),
        ],
      ),
    );
  }
}
