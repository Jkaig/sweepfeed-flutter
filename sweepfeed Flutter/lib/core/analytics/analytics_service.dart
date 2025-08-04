import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Get the observer for route tracking
  FirebaseAnalyticsObserver getAnalyticsObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // --- User Properties ---
  Future<void> setUserProperties(
      {required String userId, String? userRole}) async {
    await _analytics.setUserId(id: userId);
    if (userRole != null) {
      await _analytics.setUserProperty(name: 'user_role', value: userRole);
    }
    // Add other relevant user properties
  }

  // --- Custom Events ---

  // Example: Log screen view
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(
      screenName: screenName,
    );
  }

  // Example: Log button tap
  Future<void> logButtonTap(String buttonName) async {
    await _analytics.logEvent(
      name: 'button_tap',
      parameters: {'button_name': buttonName},
    );
  }

  // Example: Log search event
  Future<void> logSearch(String searchTerm) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  // Example: Log contest saved/unsaved
  Future<void> logContestSaved(String contestId, bool saved) async {
    await _analytics.logEvent(
      name: saved ? 'contest_saved' : 'contest_unsaved',
      parameters: {'contest_id': contestId},
    );
  }

  // Example: Log filter applied
  Future<void> logFiltersApplied(Map<String, dynamic> filters) async {
    // Convert filter values to strings for analytics
    final Map<String, String> stringFilters = filters.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    await _analytics.logEvent(
      name: 'filters_applied',
      parameters: stringFilters,
    );
  }

  // Add more specific event logging methods as needed
  // e.g., logLogin, logSignUp, logSubscriptionView, logPurchase
}
