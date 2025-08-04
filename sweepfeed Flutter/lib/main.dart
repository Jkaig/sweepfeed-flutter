import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/firebase_config.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/onboarding/screens/splash_screen.dart'; 
import 'features/onboarding/screens/onboarding_screen_1.dart'; // Import for AuthWrapper
import 'features/contests/screens/home_screen.dart';
import 'features/tracking/screens/tracking_screen.dart';
import 'features/notifications/screens/notification_preferences_screen.dart';
import 'features/saved/screens/saved_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/tracking/services/tracking_service.dart';
import 'features/saved/services/saved_sweepstakes_service.dart';
import 'features/contests/services/contest_service.dart';
import 'features/subscription/services/subscription_service.dart';
import 'features/subscription/services/usage_limits_service.dart';
import 'features/ads/services/ad_service.dart';
import 'features/ads/widgets/ad_banner.dart';
// import 'features/subscription/widgets/trial_banner.dart'; // Combined into ActiveTrialBanner
import 'features/subscription/widgets/active_trial_banner.dart'; // Assuming this exists or is the correct one
import 'core/navigation/navigator_key.dart';
// import 'core/services/firebase_service.dart'; // FirebaseService seems unused directly here
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/analytics/analytics_service.dart';
import 'core/theme/app_theme.dart'; // Import AppTheme
import 'core/providers/theme_provider.dart'; // Import ThemeProvider
import 'features/premium/screens/daily_entry_screen.dart';
import 'features/notifications/services/push_notification_service.dart';
import 'features/subscription/screens/subscription_screen.dart';
import 'dart:io' show Platform;
import 'package:firebase_storage/firebase_storage.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: FirebaseConfig.platformOptions,
  );

  // Check for USE_EMULATOR flag
  const useEmulator = bool.fromEnvironment('USE_EMULATOR');

  if (useEmulator) {
    // Determine host based on platform
    final String host = Platform.isAndroid ? '10.0.2.2' : 'localhost';

    // Configure Firebase to use emulators
    try {
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      print("Firebase Emulators configured for $host");
    } catch (e) {
      print("Error configuring Firebase Emulators: $e");
      // Depending on the app's requirements, you might want to handle this error
      // differently, e.g., by preventing the app from running.
    }
  }

  final prefs = await SharedPreferences.getInstance();

  // Initialize services
  final subscriptionService = SubscriptionService();
  await subscriptionService.initialize();

  final usageLimitsService = UsageLimitsService();
  await usageLimitsService.initialize();

  final adService = AdService();
  await adService.initialize();

  // Initialize PushNotificationService
  PushNotificationService();

  // Create ThemeProvider instance with SharedPreferences
  final themeProvider = ThemeProvider(prefs);
  // No need to await loadThemeMode here, it's handled in constructor

  runApp(MyApp(prefs: prefs, themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final ThemeProvider themeProvider;

  const MyApp({super.key, required this.prefs, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final analyticsService = AnalyticsService();

    return MultiProvider(
      providers: [
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider), // Use existing instance
        Provider<AnalyticsService>(create: (_) => analyticsService),
        Provider<ContestService>(
            create: (_) => ContestService(FirebaseService()), // Assuming ContestService needs FirebaseService
            lazy: false),
        ChangeNotifierProvider<TrackingService>(
          create: (_) => TrackingService(prefs),
        ),
        Provider<NotificationService>(
          create: (_) => NotificationService(prefs),
        ),
        Provider<SavedSweepstakesService>(
            create: (_) => SavedSweepstakesService(prefs)),
        ChangeNotifierProvider<SubscriptionService>(
          create: (_) => SubscriptionService(),
        ),
        ChangeNotifierProvider<UsageLimitsService>(
          create: (_) => UsageLimitsService(),
        ),
        ChangeNotifierProvider<AdService>(
          create: (_) => AdService(),
        ),
      ],
      child: Consumer<ThemeProvider>( // Consume ThemeProvider
        builder: (context, themeManager, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'SweepFeed',
            theme: AppTheme.lightTheme(), // Set light theme
            darkTheme: AppTheme.darkTheme(), // Set dark theme
            themeMode: themeManager.themeMode, // Set theme mode from provider
            navigatorObservers: [analyticsService.getAnalyticsObserver()],
            routes: {
              '/subscription': (context) => const SubscriptionScreen(),
            },
            home: const SplashScreen(), // Start with SplashScreen
          );
        },
      ),
    );
  }
}

// Wrapper to handle user authentication and async operations before MainScreen
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for the frame to render to ensure context is available for navigation
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = Provider.of<User?>(context, listen: false);
      if (user == null) {
        // If user is null, navigate to LoginScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      // User is logged in, proceed with user setup and onboarding check
      await _handleUserSetup(user);

      // Check onboarding status
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final onboardingCompleted = userDoc.data()?['onboardingCompleted'] ?? false;

      if (onboardingCompleted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // This is where SplashScreen would have already navigated to OnboardingScreen1.
        // If SplashScreen is the entry point, this AuthWrapper might need to be initiated *after* SplashScreen.
        // For now, assuming SplashScreen handles the initial navigation to OnboardingScreen1,
        // and AuthWrapper is primarily for deciding between LoginScreen and MainScreen/Onboarding.
        // The logic in SplashScreen's initState will handle the first step of onboarding.
        // If a user lands here directly (e.g. after login), and onboarding isn't complete,
        // they should also be directed to the start of onboarding.
        // However, SplashScreen is now the main entry.
        // This AuthWrapper's role changes slightly. It's now more of a decider post-splash/post-login.

        // If SplashScreen is the initial route, it will navigate to OnboardingScreen1.
        // If for some reason, the flow comes here and onboarding is not complete,
        // it implies that the SplashScreen logic should handle it.
        // This AuthWrapper might be better placed after SplashScreen if direct navigation is needed here.
        // Let's adjust main.dart to have SplashScreen as home, which navigates.
        // AuthWrapper will be used if we need to decide between Login and MainScreen AFTER splash.
        // The current setup: main.dart's home is SplashScreen.
        // SplashScreen navigates to OnboardingScreen1.
        // Onboarding screens navigate among themselves, then to PrizePreferencesScreen.
        // PrizePreferencesScreen navigates to HomeScreen (MainScreen).
        // If a user is logged in and onboarding is complete, they should go to MainScreen.
        // If not logged in, LoginScreen.
        // This AuthWrapper will be simplified or re-purposed.
        // For now, if SplashScreen is home, AuthWrapper is implicitly by-passed initially.
        // Let's assume SplashScreen is the entry point and handles the initial navigation.
        // The existing AuthWrapper is being replaced by the SplashScreen logic for initial routing.
        // The home of MaterialApp is now SplashScreen.
        // SplashScreen will check auth status internally for its navigation.
        // So, the logic within AuthWrapper for navigation might be redundant if SplashScreen handles it.

        // The `home` of `MaterialApp` is `SplashScreen`.
        // `SplashScreen` will decide whether to go to `OnboardingScreen1` or `AuthWrapper`.
        // `AuthWrapper` will then decide `LoginScreen` or `MainScreen`.

        // Let's refine SplashScreen to navigate to AuthWrapper if login is needed,
        // or OnboardingScreen1 if logged in & onboarding not complete.
        // For now, the current change sets SplashScreen as home.
        // AuthWrapper's build method will be simplified.
        // It just decides between LoginScreen and MainScreen based on user auth state.
        // The onboarding check will be implicitly handled by SplashScreen -> Onboarding flow.
      }
    });
  }

  Future<void> _handleUserSetup(User user) async {
    // Ensure context is still valid if this is called from initState or similar
    if (!mounted) return;

    Provider.of<AnalyticsService>(context, listen: false)
        .setUserProperties(userId: user.uid);
    
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    try {
      final token = await notificationService.getToken();
      if (token != null) {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDocRef.get();
        final now = FieldValue.serverTimestamp();
        
        Map<String, dynamic> updateData = { // Changed to updateData for clarity
          'fcmToken': token,
          'lastActivity': now,
        };

        if (!docSnapshot.exists || !docSnapshot.data()!.containsKey('createdAt')) {
          // New user or document missing essential fields like createdAt
          // Set initial fields including onboardingCompleted: false
          updateData.addAll({
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'createdAt': now,
            'onboardingCompleted': false, 
          });
          await userDocRef.set(updateData, SetOptions(merge: true)); 
        } else {
          // Existing user, update specific fields
          // Ensure onboardingCompleted is set if it's missing
          if (!docSnapshot.data()!.containsKey('onboardingCompleted')) {
            updateData['onboardingCompleted'] = false;
          }
          await userDocRef.update(updateData);
        }
      }
    } catch (e) {
      debugPrint("Error in _handleUserSetup: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return const LoginScreen(); 
    }
    
    // User is logged in. _handleUserSetup would have been called.
    // Now, determine navigation based on onboarding status from Firestore.
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
           debugPrint("Error fetching user document in AuthWrapper: ${snapshot.error}");
           return const LoginScreen(); // Fallback to login on error
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // This case should ideally be handled by _handleUserSetup creating the document.
          // If it still occurs, it's an inconsistent state. Fallback to login.
          debugPrint("User document not found in AuthWrapper, though user is logged in.");
          return const LoginScreen(); 
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        // Default to false if 'onboardingCompleted' is missing or null.
        final onboardingCompleted = userData?['onboardingCompleted'] as bool? ?? false;

        if (onboardingCompleted) {
          return const MainScreen();
        } else {
          // User is logged in, but onboarding is not complete.
          // SplashScreen should ideally route here, but if AuthWrapper is hit directly,
          // ensure navigation to OnboardingScreen1.
          return const OnboardingScreen1();
        }
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final subscriptionService = Provider.of<SubscriptionService>(context);
    final isPremiumUser = subscriptionService.hasBasicOrPremiumAccess;
    final showAds = !subscriptionService.isSubscribed;

    final screens = [
      const HomeScreen(),
      // Show DailyEntryScreen if premium, otherwise TrackingScreen
      isPremiumUser ? const DailyEntryScreen() : const TrackingScreen(),
      const SavedScreen(),
      const ProfileScreen(),
    ];

    final navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      // Show different item for premium
      isPremiumUser
          ? const BottomNavigationBarItem(
              icon: Icon(Icons.checklist),
              label: 'Daily List',
            )
          : const BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'My Entries',
            ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.bookmark),
        label: 'Saved',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      // Access the screen using the current index
      body: Column(
        children: [
          // Show trial banner based on subscription status
          if (!subscriptionService.isSubscribed &&
              !subscriptionService.isInTrialPeriod)
            const TrialBanner(),

          // Show active trial banner for users in trial period
          if (subscriptionService.isInTrialPeriod) const ActiveTrialBanner(),

          // Main content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),

          // Ad banner at the bottom for free users
          if (showAds) const AdBanner(height: 50), // Ensure AdBanner is compatible with theme changes
        ],
      ),
      bottomNavigationBar: BottomNavigationBar( // Ensure BottomNavigationBar is styled by theme
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: navItems, // Use dynamic nav items
      ),
    );
  }
}
