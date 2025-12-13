// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SweepFeed';

  @override
  String goodMorning(String name) {
    return 'Good morning, $name!';
  }

  @override
  String get forYou => 'For You';

  @override
  String get myFilters => 'My Filters';

  @override
  String get none => 'None';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get manageFilters => 'Manage Filters';

  @override
  String get todaysChecklist => 'Today\'s Checklist';

  @override
  String get featuredToday => 'Featured Today';

  @override
  String get browseCategories => 'Browse Categories';

  @override
  String get latestContests => 'Latest Contests';

  @override
  String get viewAll => 'View All';

  @override
  String get submitSweepstake => 'Submit a Sweepstake';

  @override
  String get notInterested => 'Not Interested';

  @override
  String contestHidden(String title) {
    return '\'$title\' hidden.';
  }

  @override
  String get undo => 'Undo';

  @override
  String errorLoadingFeaturedContests(String error) {
    return 'Error loading featured contests: $error';
  }

  @override
  String errorLoadingLatestContests(String error) {
    return 'Error loading latest contests: $error';
  }

  @override
  String get errorLoadingCategories => 'Error loading categories';

  @override
  String get errorLoadingStats => 'Error loading stats';
}
