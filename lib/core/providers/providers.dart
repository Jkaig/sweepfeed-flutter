import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/biometric_auth_service.dart';
import '../../core/services/messaging_service.dart';
import '../../core/services/referral_service.dart';
import '../../core/services/streak_service.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/services/enhanced_auth_service.dart';
import '../../features/challenges/models/daily_challenge_model.dart';
import '../../features/challenges/services/daily_challenge_service.dart';
import '../../features/contests/models/advanced_filter_model.dart';
import '../../features/contests/models/contest_filter.dart';
import '../../features/contests/services/contest_preferences_service.dart';
import '../../features/contests/services/contest_service.dart';
import '../../features/contests/services/entry_service.dart';
import '../../features/entries/services/entry_management_service.dart';
import '../../features/gamification/models/badge_model.dart' as gamification_badge;
import '../../features/gamification/services/achievement_service.dart';
import '../../features/gamification/services/reward_service.dart';
import '../../features/main/services/main_screen_service.dart';
import '../../features/mystery/services/mystery_box_service.dart';
import '../../features/profile/services/profile_service.dart';
import '../../features/reminders/services/live_activity_service.dart';
import '../../features/reminders/services/reminder_service.dart';
import '../../features/saved/services/saved_contests_service.dart';
import '../../features/subscription/models/subscription_tiers.dart';
import '../../features/subscription/services/revenue_cat_service.dart';
import '../../features/subscription/services/subscription_service.dart';
import '../../features/subscription/services/tier_management_service.dart';
import '../models/category_model.dart';
import '../models/charity_model.dart';
import '../models/contest.dart';
import '../models/filter_set_model.dart';
import '../models/reward_model.dart';
import '../models/settings_model.dart';
import '../models/user_model.dart';
import '../notifiers/app_settings_notifier.dart';
import '../services/ai_greeting_service.dart';
import '../services/analytics_service.dart';
import '../services/charity_service.dart';
import '../services/dust_bunnies_service.dart';
import '../services/feature_unlock_service.dart';
import '../services/firebase_service.dart';
import '../services/friend_service.dart';
import '../services/gamification_service.dart';
import '../services/notification_service.dart';
import '../services/permission_manager.dart';
import '../services/personalization_engine.dart';
import '../services/unified_notification_service.dart';
import '../services/user_preferences_service.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';
import 'contest_providers.dart';

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
final authServiceProvider = Provider<AuthService>((ref) {
  final authService = AuthService(ref);
  ref.onDispose(() => authService.dispose());
  return authService;
});

// Enhanced Auth Service Provider
final enhancedAuthServiceProvider = Provider<EnhancedAuthService>((ref) {
  return EnhancedAuthService();
});

// Biometric Auth Service Provider
final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

/// Provides an instance of the StreakService.
final streakServiceProvider = ChangeNotifierProvider<StreakService>((ref) {
  final dustBunniesService = ref.watch(dustBunniesServiceProvider);
  return StreakService(dustBunniesService);
});

/// Provides an instance of the UserService for managing user data.
final userServiceProvider = Provider<UserService>((ref) => UserService());

/// Provides an instance of the AIGreetingService for generating personalized greetings.
final aiGreetingServiceProvider =
    Provider<AIGreetingService>((ref) => AIGreetingService());

/// Provides an instance of the DustBunniesService for managing gamification elements.
final dustBunniesServiceProvider =
    Provider<DustBunniesService>(DustBunniesService.new);

/// Provides an instance of the ProfileService for managing user profile data.
final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService(
    ref.watch(dustBunniesServiceProvider),
    firestore: ref.watch(firestoreProvider),
  ),
);

/// Provides an instance of the CharityService for retrieving charity information.
final charityServiceProvider = Provider<CharityService>(
    (ref) => CharityService(ref.watch(firestoreProvider)));

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

/// Provides RevenueCatService
final revenueCatServiceProvider =
    ChangeNotifierProvider<RevenueCatService>((ref) {
      final service = RevenueCatService(ref);
      
      // Auto-initialize RevenueCat when user logs in
      final authState = ref.watch(authStateChangesProvider);
      authState.whenData((user) {
        if (user != null) {
          // User logged in - initialize RevenueCat
          service.initialize(user.uid).catchError((e) {
            logger.w('Failed to initialize RevenueCat for user ${user.uid}: $e');
          });
        }
      });
      
      return service;
    });

/// Provides a ChangeNotifier for managing subscription-related logic.
final subscriptionServiceProvider =
        ChangeNotifierProvider<SubscriptionService>((ref) {
          final revenueCatService = ref.watch(revenueCatServiceProvider);
          return SubscriptionService(ref, revenueCatService);
        });

/// Provides a StateNotifier for tracking contests.
final trackingServiceProvider =
    StateNotifierProvider<TrackingService, List<Contest>>(
        (ref) => TrackingService(),);

/// A StateNotifier that manages a list of tracked Contests.
class TrackingService extends StateNotifier<List<Contest>> {
  /// Creates a TrackingService with an empty list of contests.
  TrackingService() : super([]);

  /// Filters the tracked sweepstakes based on some criteria.
  List<Contest> filterTrackedSweepstakes() => [];

  /// Gets a list of daily entry contests.
  List<Contest> getDailyEntries() => [];

  /// Gets a list of contests ending soon.
  List<Contest> getEndingSoon() => [];

  /// Removes a tracked entry by its ID.
  Future<void> untrackEntry(String entryId) async {
    // Placeholder implementation
  }
}

/// Provides an instance of the FirebaseService for interacting with Firebase.
final firebaseServiceProvider =
    Provider<FirebaseService>((ref) => FirebaseService());


/// Provides an instance of the ContestService for managing contest data.
/// Note: contestRepositoryProvider is defined in core/providers/contest_providers.dart
final contestServiceProvider = Provider<ContestService>(
  (ref) => ContestService(
    ref.watch(firebaseServiceProvider),
    ref.watch(contestRepositoryProvider),
  ),
);

/// Provides an instance of the EntryService for managing contest entries.
final entryServiceProvider = Provider<EntryService>(
  (ref) => EntryService(
    gamificationService: ref.watch(dustBunniesServiceProvider),
    reminderService: ref.watch(reminderServiceProvider),
  ),
);

final entryManagementServiceProvider = Provider<EntryManagementService>((ref) {
  final dustBunniesService = ref.watch(dustBunniesServiceProvider);
  final dailyChallengeService = ref.watch(dailyChallengeServiceProvider);
  return EntryManagementService(dustBunniesService, dailyChallengeService);
});

/// Provides an instance of the FeatureUnlockService for checking unlocked features.
final featureUnlockServiceProvider = Provider<FeatureUnlockService>(
  (ref) => FeatureUnlockService(),
);

/// Provides an instance of the ReminderService for scheduling reminders.
final reminderServiceProvider = Provider<ReminderService>((ref) {
  final unlockService = ref.watch(featureUnlockServiceProvider);
  return ReminderService(unlockService);
});

/// Provides an instance of the UnifiedNotificationService for handling notifications.
final unifiedNotificationServiceProvider =
    Provider<UnifiedNotificationService>((ref) => UnifiedNotificationService());

/// Provides an instance of the PermissionManager for handling permissions.
final permissionManagerProvider =
    Provider<PermissionManager>((ref) => PermissionManager());

/// Provides an instance of the AnalyticsService for tracking analytics events.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) => FirebaseAnalyticsService());

final userPreferencesServiceProvider =
    Provider<UserPreferencesService>((ref) => UserPreferencesService());

// Main Screen Service Provider
final mainScreenServiceProvider = Provider<MainScreenService>((ref) {
  return MainScreenService(ref);
});

// Tier Management Service Provider  
final tierManagementServiceProvider = Provider<TierManagementService>((ref) {
  return TierManagementService(ref);
});

// Firebase Messaging Provider
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final personalizationEngineProvider =
    Provider<PersonalizationEngine>((ref) => PersonalizationEngine());

/// Provides an instance of NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

/// An alias for the UnifiedNotificationService provider.
final unifiedNotificationServiceProviderAlias = unifiedNotificationServiceProvider;

/// Provides a StateNotifier for managing selected interests.
final selectedInterestsProvider =
    StateNotifierProvider<SelectedInterestsNotifier, List<String>>(
        (ref) => SelectedInterestsNotifier(),);

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

/// Provides an instance of the SavedContestsService for managing saved contests.
final savedContestsServiceProvider =
    ChangeNotifierProvider<SavedContestsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.when(
    data: (prefs) => SavedContestsService(prefs),
    loading: () => throw Exception('SharedPreferences not ready'),
    error: (error, stack) =>
        throw Exception('Failed to load SharedPreferences: $error'),
  );
});

/// Provides an instance of the ContestPreferencesService for managing contest preferences.
final contestPreferencesServiceProvider =
    Provider<ContestPreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final userPrefsService = ref.watch(userPreferencesServiceProvider);
  return prefs.when(
    data: (prefs) => ContestPreferencesService(prefs, userPrefsService),
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
    ChangeNotifierProvider<UsageLimitsService>((ref) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  final userProfile = ref.watch(userProfileProvider);
  final savedContestsService = ref.watch(savedContestsServiceProvider);
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return sharedPreferences.when(
    data: (prefs) => UsageLimitsService(
      subscriptionService,
      userProfile.value,
      savedContestsService,
      prefs,
    ),
    loading: () => UsageLimitsService(
      subscriptionService,
      userProfile.value,
      savedContestsService,
      null,
    ),
    error: (_, __) => UsageLimitsService(
      subscriptionService,
      userProfile.value,
      savedContestsService,
      null,
    ),
  );
});

/// A service for managing usage limits based on subscription tier.
class UsageLimitsService with ChangeNotifier {
  UsageLimitsService(
    this._subscriptionService,
    this._userProfile,
    this._savedContestsService,
    this._prefs,
  ) {
    // Initialize asynchronously - service will work with defaults until initialized
    _initialize().catchError((error) {
      logger.e('Error initializing UsageLimitsService', error: error);
    });
  }

  final SubscriptionService _subscriptionService;
  final UserProfile? _userProfile;
  final SavedContestsService _savedContestsService;
  final SharedPreferences? _prefs;

  static const String _dailyViewsKey = 'daily_contest_views';
  static const String _dailyViewsDateKey = 'daily_contest_views_date';

  int _todayViewsCount = 0;
  DateTime? _viewsDate;

  Future<void> _initialize() async {
    if (_prefs == null) return;
    
    // Load views count, but reset if it's from a different day
    _todayViewsCount = _prefs.getInt(_dailyViewsKey) ?? 0;
    final viewsDateStr = _prefs.getString(_dailyViewsDateKey);

    if (viewsDateStr != null) {
      _viewsDate = DateTime.parse(viewsDateStr);

      // Check if views count is from today
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final viewsDay = DateTime(
        _viewsDate?.year ?? now.year,
        _viewsDate?.month ?? now.month,
        _viewsDate?.day ?? now.day,
      );

      if (viewsDay.isBefore(today)) {
        // Reset views count for a new day
        _todayViewsCount = 0;
        _viewsDate = now;
        await _saveViewsCount();
      }
    } else {
      _viewsDate = DateTime.now();
      await _saveViewsCount();
    }
    notifyListeners();
  }

  Future<void> _saveViewsCount() async {
    if (_prefs == null) return;
    await _prefs.setInt(_dailyViewsKey, _todayViewsCount);
    await _prefs.setString(_dailyViewsDateKey, _viewsDate!.toIso8601String());
  }

  /// Records a contest view and checks if limit is reached
  Future<bool> recordContestView() async {
    final limit = maxContestViewsPerDay;
    
    // Premium/Basic users have unlimited views
    if (limit == null) {
      return true;
    }

    // Check if already at limit
    if (_todayViewsCount >= limit) {
      return false;
    }

    _todayViewsCount++;
    await _saveViewsCount();
    notifyListeners();
    return true;
  }

  /// Returns the current number of views today
  int get todayViewsCount => _todayViewsCount;

  /// Returns whether the user has reached the view limit.
  bool get hasReachedViewLimit {
    final limit = maxContestViewsPerDay;
    if (limit == null) return false; // Unlimited
    return _todayViewsCount >= limit;
  }

  /// Returns the remaining views for today
  int? get remainingViewsToday {
    final limit = maxContestViewsPerDay;
    if (limit == null) return null; // Unlimited
    return (limit - _todayViewsCount).clamp(0, limit);
  }

  /// Returns whether the user has reached the saved items limit.
  bool get hasReachedSavedItemsLimit {
    final limit = maxSavedContests;
    if (limit == null) return false; // Unlimited
    return _savedContestsService.savedContests.length >= limit;
  }

  /// Returns the current number of saved contests
  int get currentSavedContestsCount => _savedContestsService.savedContests.length;

  /// Returns the remaining slots for saved contests
  int? get remainingSavedContests {
    final limit = maxSavedContests;
    if (limit == null) return null; // Unlimited
    return (limit - currentSavedContestsCount).clamp(0, limit);
  }

  /// Returns the maximum number of contest views per day for the current tier.
  int? get maxContestViewsPerDay {
    return _subscriptionService.currentTier.dailyContestViewLimit;
  }

  /// Returns the maximum number of saved contests for the current tier.
  int? get maxSavedContests {
    return _subscriptionService.currentTier.maxSavedContests;
  }

  /// Resets daily view count (called when day changes or user upgrades)
  Future<void> resetDailyViews() async {
    _todayViewsCount = 0;
    _viewsDate = DateTime.now();
    await _saveViewsCount();
    notifyListeners();
  }
}

/// Provides a Future that resolves to a list of categories.
final categoriesProvider = FutureProvider<List<Category>>(
  (ref) async => [
    Category(id: '1', name: 'Cash', emoji: '💵'),
    Category(id: '2', name: 'Cars', emoji: '🚗'),
    Category(id: '3', name: 'Home Improvement', emoji: '🏠'),
    Category(id: '4', name: 'Vacations', emoji: '✈️'),
    Category(id: '5', name: 'Electronics', emoji: '📱'),
    Category(id: '6', name: 'Gift Cards', emoji: '🎁'),
    Category(id: '7', name: 'Shopping Sprees', emoji: '🛍️'),
    Category(id: '8', name: 'Appliances', emoji: '🍳'),
    Category(id: '9', name: 'Gaming', emoji: '🎮'),
    Category(id: '10', name: 'Jewelry', emoji: '💎'),
  ],
);

final gamificationServiceProvider =
    Provider<GamificationService>((ref) => GamificationService());

final rewardServiceProvider = Provider<RewardService>((ref) => RewardService());

/// Provides a Future that resolves to a list of rewards.
final rewardsProvider = FutureProvider<List<Reward>>((ref) async {
  final rewardService = ref.watch(rewardServiceProvider);
  return rewardService.getRewards();
});

/// Provides a Future that resolves to a leaderboard.
final leaderboardProvider =
    FutureProvider<List<LeaderboardEntry>>((ref) async {
  final dustBunniesService = ref.watch(dustBunniesServiceProvider);
  return dustBunniesService.getLeaderboard();
});

/// Provides a Future that resolves to the current user's rank in the leaderboard.
final userRankProvider = FutureProvider.family<int, String>((ref, userId) async {
  final dustBunniesService = ref.watch(dustBunniesServiceProvider);
  return dustBunniesService.getUserRank(userId);
});

/// Provides a Future that resolves to a friends leaderboard.
final friendsLeaderboardProvider =
    FutureProvider<List<UserProfile>>((ref) async {
  final friendService = ref.watch(friendServiceProvider);
  return friendService.getFriendsLeaderboard();
});

/// Provides a StateProvider for the search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provides a StateProvider for the active contest filter.
final activeContestFilterProvider = StateProvider<String>((ref) => 'all');

/// Provides a StateProvider for the selected contest filter.
final selectedFilterProvider = StateProvider<ContestFilter?>((ref) => null);

/// Provides a StateProvider for the advanced filter.
final advancedFilterProvider = StateProvider<AdvancedFilter?>((ref) => null);

/// Provides a StreamProvider that resolves to a list of saved filters.
final savedFiltersProvider = StreamProvider<List<FilterSet>>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user != null) {
    return profileService.getFilterSets(user.uid);
  }
  return Stream.value([]);
});

/// StreamProvider for real-time DustBunnies balance
final userDustBunniesBalanceProvider = StreamProvider.family<int, String>((ref, userId) {
  if (userId.isEmpty) {
    return Stream.value(0);
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) {
      return 0;
    }
    final data = snapshot.data()!;
    final dbData = data['dustBunniesSystem'] as Map<String, dynamic>? ??
        data['sweepPointsSystem'] as Map<String, dynamic>? ??
        data['xpSystem'] as Map<String, dynamic>? ??
        {};
    return (dbData['currentDB'] as num?)?.toInt() ??
        (dbData['currentSP'] as num?)?.toInt() ??
        (dbData['currentXP'] as num?)?.toInt() ??
        0;
  });
});

final dailyChallengeServiceProvider =
    Provider<DailyChallengeService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final dustBunniesService = ref.watch(dustBunniesServiceProvider);
  final analyticsService = ref.watch(analyticsServiceProvider);
  return DailyChallengeService(
    firestore: firestore,
    dustBunniesService: dustBunniesService,
    analyticsCallback: (event, params) =>
        analyticsService.logEvent(eventName: event, parameters: params),
  );
});

final mysteryBoxServiceProvider =
    ChangeNotifierProvider<MysteryBoxService>((ref) {
  final dustBunniesService = ref.watch(dustBunniesServiceProvider);
  return MysteryBoxService(dustBunniesService);
});

/// Provides a Future that resolves to a list of daily challenges.
final dailyChallengesProvider =
    FutureProvider<List<DailyChallengeDisplay>>((ref) async {
  final dailyChallengeService = ref.watch(dailyChallengeServiceProvider);
  return dailyChallengeService.getUserDailyChallenges(
      ref.watch(firebaseAuthProvider).currentUser!.uid);
});

final achievementServiceProvider =
    Provider<AchievementService>((ref) => AchievementService());

/// Provides a Future that resolves to a list of achievements.

final achievementsProvider =

    FutureProvider<List<gamification_badge.Badge>>((ref) async {

  final achievementService = ref.watch(achievementServiceProvider);

  return (await achievementService.getAchievements())

      .cast<gamification_badge.Badge>();

});

/// Provides a Future that resolves to a list of popular contests.
final popularContestsProvider = FutureProvider<List<Contest>>((ref) async {
  final contestService = ref.watch(contestServiceProvider);
  return contestService.getHighValueContests();
});

/// Provides a Future that resolves to a list of latest contests.
final latestContestsProvider = FutureProvider<List<Contest>>((ref) async {
  final contestService = ref.watch(contestServiceProvider);
  return contestService.getActiveContests(sortBy: 'start_date', ascending: false);
});

/// Provides an instance of the MessagingService for handling messaging.
final messagingServiceProvider =
    Provider<MessagingService>((ref) => MessagingService());

/// Provides an instance of the ReferralService for handling referrals.
final referralServiceProvider =
    Provider<ReferralService>((ref) => ReferralService());

/// Provides an instance of the LiveActivityService for managing live activities.
final liveActivityServiceProvider =
    Provider<LiveActivityService>((ref) => LiveActivityService());

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

// Provider to check for entry tracker unlock
final entryTrackerUnlockProvider = StreamProvider<bool>((ref) {
  final unlockService = ref.watch(featureUnlockServiceProvider);
  return unlockService.watchFeatureUnlock('tool_entry_tracker');
});

// Provider to check for daily reminder unlock
final dailyReminderUnlockProvider = StreamProvider<bool>((ref) {
  final unlockService = ref.watch(featureUnlockServiceProvider);
  return unlockService.watchFeatureUnlock('tool_daily_reminder');
});