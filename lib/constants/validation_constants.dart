/// Validation limits and constraints for forms and user input
class ValidationConstants {
  // Text length limits
  /// Maximum length for short text fields.
  static const int kShortTextMaxLength = 100;
  /// Maximum length for medium text fields.
  static const int kMediumTextMaxLength = 200;
  /// Maximum length for long text fields.
  static const int kLongTextMaxLength = 365;
  /// Maximum length for description fields.
  static const int kDescriptionMaxLength = 5000;
  /// Maximum length for URL fields.
  static const int kUrlMaxLength = 2000;

  // Contest validation limits
  /// Maximum length for contest titles.
  static const int kMaxTitleLength = 200;
  /// Maximum length for contest descriptions.
  static const int kMaxDescriptionLength = 5000;
  /// Maximum length for contest URLs.
  static const int kMaxUrlLength = 2000;
  /// Maximum value for a contest prize.
  static const int kMaxPrizeValue = 10000000;
  /// Minimum value for a contest prize.
  static const int kMinPrizeValue = 10;
  /// Maximum length for a sponsor's name.
  static const int kMaxSponsorLength = 100;
  /// Maximum number of entry methods for a contest.
  static const int kMaxEntryMethods = 20;

  // User preferences defaults and limits
  /// Default maximum prize value for user preferences.
  static const int kDefaultMaxPrizeValue = 1000000;
  /// Default age for user preferences filter.
  static const int kDefaultAgeFilter = 18;
  /// Default time for daily notifications.
  static const int kDefaultDailyNotificationTime = 9;
  /// Minimum age for users.
  static const int kMinAge = 13;
  /// Maximum age for users.
  static const int kMaxAge = 100;

  // Contest duration limits
  /// Maximum duration of a contest in days.
  static const int kMaxContestDurationDays = 365;

  // System limits
  /// The maximum value for an integer.
  static const int kMaxIntValue = 2147483647;
  /// The default font scale.
  static const double kDefaultFontScale = 16.0;

  // Notification limits
  /// The daily notification limit for free users.
  static const int kFreeUserDailyNotificationLimit = 5;
}
