import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/contests/models/advanced_filter_model.dart';
import '../../features/contests/models/contest_filter.dart';
import '../../features/contests/services/contest_preferences_service.dart';
import '../../features/contests/services/contest_service.dart';
import '../../features/contests/services/entry_service.dart';
import '../../features/contests/services/sweepstake_service.dart';
import '../../features/profile/services/profile_service.dart';
import '../../features/reminders/services/reminder_service.dart';
import '../../features/saved/services/saved_sweepstakes_service.dart';
import '../../features/subscription/services/subscription_service.dart';
import '../models/category_model.dart';
import '../models/charity_model.dart';
import '../models/sweepstake.dart';
import '../models/user_model.dart';
import '../services/ai_greeting_service.dart';
import '../services/analytics_service.dart';
import '../services/charity_service.dart';
import '../services/firebase_service.dart';
import '../services/friend_service.dart';
import '../services/dust_bunnies_service.dart';
import '../services/gamification_service.dart';
import '../services/permission_manager.dart';
import '../services/unified_notification_service.dart';
import '../services/user_service.dart';
import '../models/settings_model.dart';
import '../notifiers/app_settings_notifier.dart';

/// Provides an instance of Firebase Authentication.
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

/// Provides an instance of Firebase Firestore.
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

/// Provides a Future that resolves to an instance of SharedPreferences.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) async => SharedPreferences.getInstance(),
);

/// Provides an instance of the AuthService for user authentication.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provides an instance of the UserService for managing user data.
final userServiceProvider = Provider<UserService>((ref) => UserService());

/// Provides an instance of the AIGreetingService for generating personalized greetings.
final aiGreetingServiceProvider =
    Provider<AIGreetingService>((ref) => AIGreetingService());

/// Provides an instance of the DustBunniesService for managing gamification elements.
final dustBunniesServiceProvider =
    Provider<DustBunniesService>((ref) => DustBunniesService());

/// Provides an instance of the GamificationService.
@Deprecated(
    'Use dustBunniesServiceProvider instead. Will be removed in Q2 2026.')
final gamificationServiceProvider = Provider<GamificationService>(
    (ref) => GamificationService(ref.watch(authServiceProvider)));

/// Provides an instance of the ProfileService for managing user profile data.
final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService(
    ref.watch(dustBunniesServiceProvider),
    firestore: ref.watch(firestoreProvider),
  ),
);

/// Provides an instance of the CharityService for retrieving charity information.
final charityServiceProvider =
    Provider<CharityService>((ref) => CharityService());

/// Provides a Future that resolves to a list of available charities.
final charitiesProvider = FutureProvider<List<Charity>>((ref) async {
  final charityService = ref.watch(charityServiceProvider);
  return charityService.getAvailableCharities();
});

/// Provides a stream of the current user's profile.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userService = ref.watch(userServiceProvider);
  final user = authService.currentUser;
  if (user != null) {
    return userService.getUserProfileStream(user.uid);
  }
  return Stream.value(null);
});

/// Provides a StateNotifier for managing app settings.
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(),
);

/// Provides a StateNotifier for managing the app's theme.
final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) => ThemeNotifier());

/// A StateNotifier that manages the app's theme mode.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  /// Creates a ThemeNotifier with the system theme mode as the initial state.
  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// Loads the theme mode from SharedPreferences.
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString('theme_mode') ?? 'system';
      state = _stringToThemeMode(themeModeString);
    } catch (e) {
      logger.e('Error loading theme mode', error: e);
      state = ThemeMode.system;
    }
  }

  /// Sets the theme mode and persists it to SharedPreferences.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', _themeModeToString(mode));
    } catch (e) {
      logger.e('Error saving theme mode', error: e);
    }
  }

  /// Returns the current theme mode.
  ThemeMode get themeMode => state;

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _stringToThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

/// Provides a stream of authentication state changes.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// Provides a ChangeNotifier for managing subscription-related logic.
final subscriptionServiceProvider =
    ChangeNotifierProvider<SubscriptionService>(SubscriptionService.new);

/// Provides a StateNotifier for tracking sweepstakes.
final trackingServiceProvider =
    StateNotifierProvider<TrackingService, List<Sweepstakes>>(
        (ref) => TrackingService());

/// A StateNotifier that manages a list of tracked Sweepstakes.
class TrackingService extends StateNotifier<List<Sweepstakes>> {
  /// Creates a TrackingService with an empty list of sweepstakes.
  TrackingService() : super([]);

  /// Filters the tracked sweepstakes based on some criteria.
  List<Sweepstakes> filterTrackedSweepstakes() => [];

  /// Gets a list of daily entry sweepstakes.
  List<Sweepstakes> getDailyEntries() => [];

  /// Gets a list of sweepstakes ending soon.
  List<Sweepstakes> getEndingSoon() => [];

  /// Removes a tracked entry by its ID.
  Future<void> untrackEntry(String entryId) async {
    // Placeholder implementation
  }
}

/// Provides an instance of the FirebaseService for interacting with Firebase.
final firebaseServiceProvider =
    Provider<FirebaseService>((ref) => FirebaseService());

/// Provides an instance of the SweepstakeService for managing sweepstakes data.
final sweepstakeServiceProvider =
    Provider<SweepstakeService>((ref) => SweepstakeService());

/// Provides an instance of the ContestService for managing contest data.
final contestServiceProvider = Provider<ContestService>(
  (ref) => ContestService(
    ref.watch(firebaseServiceProvider),
    ref.watch(sweepstakeServiceProvider),
  ),
);

/// Provides an instance of the EntryService for managing contest entries.
final entryServiceProvider = Provider<EntryService>(
  (ref) => EntryService(
    gamificationService: ref.watch(dustBunniesServiceProvider),
    reminderService: ref.watch(reminderServiceProvider),
  ),
);

/// Provides an instance of the ReminderService for scheduling reminders.
final reminderServiceProvider =
    Provider<ReminderService>((ref) => ReminderService());

/// Provides an instance of the UnifiedNotificationService for handling notifications.
final unifiedNotificationServiceProvider =
    Provider<UnifiedNotificationService>((ref) => UnifiedNotificationService());

/// Provides an instance of the PermissionManager for handling permissions.
final permissionManagerProvider =
    Provider<PermissionManager>((ref) => PermissionManager());

/// Provides an instance of the AnalyticsService for tracking analytics events.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return FirebaseAnalyticsService();
});

/// An alias for the UnifiedNotificationService provider.
final notificationServiceProvider = unifiedNotificationServiceProvider;

/// Provides a StateNotifier for managing selected interests.
final selectedInterestsProvider =
    StateNotifierProvider<SelectedInterestsNotifier, List<String>>(
        (ref) => SelectedInterestsNotifier());

/// A StateNotifier that manages a list of selected interests.
class SelectedInterestsNotifier extends StateNotifier<List<String>> {
  /// Creates a SelectedInterestsNotifier with an empty list.
  SelectedInterestsNotifier() : super([]);

  /// Toggles the selection of an interest.
  void toggle(String interest) {
    if (state.contains(interest)) {
      state = state.where((item) => item != interest).toList();
    } else {
      state = [...state, interest];
    }
  }

  /// Clears the list of selected interests.
  void clear() {
    state = [];
  }

  /// Sets all interests.
  void setAll(List<String> interests) {
    state = interests;
  }
}

/// Provides an instance of the SavedSweepstakesService for managing saved sweepstakes.
final savedSweepstakesServiceProvider =
    Provider<SavedSweepstakesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.when(
    data: SavedSweepstakesService.new,
    loading: () => throw Exception('SharedPreferences not ready'),
    error: (error, stack) =>
        throw Exception('Failed to load SharedPreferences: $error'),
  );
});

/// Provides an instance of the ContestPreferencesService for managing contest preferences.
final contestPreferencesServiceProvider =
    Provider<ContestPreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.when(
    data: ContestPreferencesService.new,
    loading: () => throw Exception('SharedPreferences not ready'),
    error: (error, stack) =>
        throw Exception('Failed to load SharedPreferences: $error'),
  );
});

/// Provides an instance of the FriendService for managing friend-related data.
final friendServiceProvider = Provider<FriendService>((ref) => FriendService());

/// Placeholder provider for critical services readiness.
final criticalServicesReadyProvider = StateProvider<bool>((ref) => true);

/// Placeholder provider for initialization progress.
final initializationProgressProvider = StateProvider<double>((ref) => 1.0);

/// Placeholder provider for data loading completion status.
final dataLoadingCompleteProvider = StateProvider<bool>((ref) => true);

/// Provides an instance of the UsageLimitsService for managing usage limits.
final usageLimitsServiceProvider =
    Provider<UsageLimitsService>((ref) => UsageLimitsService());

/// A placeholder service for managing usage limits.
class UsageLimitsService {
  /// Returns whether the user has reached the view limit.
  bool get hasReachedViewLimit => false;

  /// Returns whether the user has reached the saved items limit.
  bool get hasReachedSavedItemsLimit => false;

  /// Returns the maximum number of free tier views per day.
  int get maxFreeTierViewsPerDay => 50;

  /// Returns the maximum number of free tier saved items.
  int get maxFreeTierSavedItems => 10;
}

/// Provides a Future that resolves to a list of categories.
final categoriesProvider = FutureProvider<List<Category>>(
  (ref) async => [
    Category(id: '1', name: 'Entertainment', emoji: '🎬'),
    Category(id: '2', name: 'Travel', emoji: '✈️'),
    Category(id: '3', name: 'Electronics', emoji: '📱'),
    Category(id: '4', name: 'Fashion', emoji: '👗'),
    Category(id: '5', name: 'Food', emoji: '🍕'),
  ],
);

/// Provides a Future that resolves to a list of rewards.
final rewardsProvider = FutureProvider<List<dynamic>>((ref) async => []);

/// Provides a Future that resolves to a leaderboard.
final leaderboardProvider = FutureProvider<List<dynamic>>((ref) async => []);

/// Provides a Future that resolves to a friends leaderboard.
final friendsLeaderboardProvider =
    FutureProvider<List<dynamic>>((ref) async => []);

/// Provides a StateProvider for the search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provides a StateProvider for the active contest filter.
final activeContestFilterProvider = StateProvider<String>((ref) => 'all');

/// Provides a StateProvider for the selected contest filter.
final selectedFilterProvider = StateProvider<ContestFilter?>((ref) => null);

/// Provides a StateProvider for the advanced filter.
final advancedFilterProvider = StateProvider<AdvancedFilter?>((ref) => null);

/// Provides a Future that resolves to a list of saved filters.
final savedFiltersProvider = FutureProvider<List<String>>((ref) async => []);

/// Provides a Future that resolves to a list of daily challenges.
final dailyChallengesProvider =
    FutureProvider<List<dynamic>>((ref) async => []);

/// Provides a Future that resolves to a list of achievements.
final achievementsProvider = FutureProvider<List<dynamic>>((ref) async => []);

/// Provides a Future that resolves to a list of popular contests.
final popularContestsProvider =
    FutureProvider<List<dynamic>>((ref) async => []);

/// Provides a Future that resolves to a list of latest contests.
final latestContestsProvider = FutureProvider<List<dynamic>>((ref) async => []);

/// Provides an instance of the MessagingService for handling messaging.
final messagingServiceProvider =
    Provider<MessagingService>((ref) => MessagingService());

/// Provides an instance of the ReferralService for handling referrals.
final referralServiceProvider =
    Provider<ReferralService>((ref) => ReferralService());

/// A placeholder service for handling messaging.
class MessagingService {
  /// Gets a stream of messages for a given chat ID.
  Stream<QuerySnapshot> getMessages(String chatId) => FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots();

  /// Sends a message to a given chat ID.
  Future<void> sendMessage(String chatId, String message) async {}

  /// Gets or creates a chat between two users.
  Future<String> getOrCreateChat(String userId1, [String? userId2]) async => '';
}

/// A placeholder service for handling referrals.
class ReferralService {
  /// Generates a referral link for a given user ID.
  Future<String> generateReferralLink(String userId) async => '';
}

/// Provides an instance of the LiveActivityService for managing live activities.
final liveActivityServiceProvider =
    Provider<LiveActivityService>((ref) => LiveActivityService());

/// A placeholder service for managing live activities.
class LiveActivityService {
  /// Starts a live activity for a given contest ID.
  Future<void> startLiveActivity(String contestId) async {}
}

/// Provides a FutureProvider family to fetch a user profile by ID.
final userProfileFamilyProvider =
    FutureProvider.family<UserProfile?, String>((ref, userId) async {
  // Placeholder implementation - would fetch user profile by ID
  return UserProfile(
    id: userId,
    reference: FirebaseFirestore.instance.collection('users').doc(userId),
    email: 'user@example.com',
    name: 'User Name',
  );
});
