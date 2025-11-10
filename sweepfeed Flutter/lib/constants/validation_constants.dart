/// Validation limits and constraints for forms and user input
class ValidationConstants {
  // Text length limits
  static const int kShortTextMaxLength = 100;
  static const int kMediumTextMaxLength = 200;
  static const int kLongTextMaxLength = 365;
  static const int kDescriptionMaxLength = 5000;
  static const int kUrlMaxLength = 2000;

  // Contest validation limits
  static const int kMaxTitleLength = 200;
  static const int kMaxDescriptionLength = 5000;
  static const int kMaxUrlLength = 2000;
  static const int kMaxPrizeValue = 10000000;
  static const int kMinPrizeValue = 10;
  static const int kMaxSponsorLength = 100;
  static const int kMaxEntryMethods = 20;

  // User preferences defaults and limits
  static const int kDefaultMaxPrizeValue = 1000000;
  static const int kDefaultAgeFilter = 18;
  static const int kDefaultDailyNotificationTime = 9;
  static const int kMinAge = 13;
  static const int kMaxAge = 100;

  // Contest duration limits
  static const int kMaxContestDurationDays = 365;

  // System limits
  static const int kMaxIntValue = 2147483647;
  static const double kDefaultFontScale = 16.0;

  // Notification limits
  static const int kFreeUserDailyNotificationLimit = 5;
}
