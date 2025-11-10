import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'SweepFeed'**
  String get appTitle;

  /// Morning greeting with user's name
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}!'**
  String goodMorning(String name);

  /// Label for personalized content toggle
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYou;

  /// Label for saved filters dropdown
  ///
  /// In en, this message translates to:
  /// **'My Filters'**
  String get myFilters;

  /// Option for no filter selected
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Generic error text
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Button to manage saved filters
  ///
  /// In en, this message translates to:
  /// **'Manage Filters'**
  String get manageFilters;

  /// Section header for daily checklist
  ///
  /// In en, this message translates to:
  /// **'Today\'s Checklist'**
  String get todaysChecklist;

  /// Section header for featured contests
  ///
  /// In en, this message translates to:
  /// **'Featured Today'**
  String get featuredToday;

  /// Section header for contest categories
  ///
  /// In en, this message translates to:
  /// **'Browse Categories'**
  String get browseCategories;

  /// Section header for latest contests
  ///
  /// In en, this message translates to:
  /// **'Latest Contests'**
  String get latestContests;

  /// Button to view all items in a section
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Tooltip for floating action button
  ///
  /// In en, this message translates to:
  /// **'Submit a Sweepstake'**
  String get submitSweepstake;

  /// Action to hide a contest
  ///
  /// In en, this message translates to:
  /// **'Not Interested'**
  String get notInterested;

  /// Message when a contest is hidden
  ///
  /// In en, this message translates to:
  /// **'\'{title}\' hidden.'**
  String contestHidden(String title);

  /// Action to undo hiding a contest
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Error message for failed featured contests load
  ///
  /// In en, this message translates to:
  /// **'Error loading featured contests: {error}'**
  String errorLoadingFeaturedContests(String error);

  /// Error message for failed latest contests load
  ///
  /// In en, this message translates to:
  /// **'Error loading latest contests: {error}'**
  String errorLoadingLatestContests(String error);

  /// Error message for failed categories load
  ///
  /// In en, this message translates to:
  /// **'Error loading categories'**
  String get errorLoadingCategories;

  /// Error message for failed stats load
  ///
  /// In en, this message translates to:
  /// **'Error loading stats'**
  String get errorLoadingStats;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
