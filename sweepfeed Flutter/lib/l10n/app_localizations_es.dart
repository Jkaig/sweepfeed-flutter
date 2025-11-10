// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'SweepFeed';

  @override
  String goodMorning(String name) {
    return '¡Buenos días, $name!';
  }

  @override
  String get forYou => 'Para Ti';

  @override
  String get myFilters => 'Mis Filtros';

  @override
  String get none => 'Ninguno';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get manageFilters => 'Gestionar Filtros';

  @override
  String get todaysChecklist => 'Lista de Hoy';

  @override
  String get featuredToday => 'Destacados Hoy';

  @override
  String get browseCategories => 'Explorar Categorías';

  @override
  String get latestContests => 'Últimos Concursos';

  @override
  String get viewAll => 'Ver Todo';

  @override
  String get submitSweepstake => 'Enviar un Sorteo';

  @override
  String get notInterested => 'No Interesado';

  @override
  String contestHidden(String title) {
    return '\'$title\' oculto.';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String errorLoadingFeaturedContests(String error) {
    return 'Error cargando concursos destacados: $error';
  }

  @override
  String errorLoadingLatestContests(String error) {
    return 'Error cargando últimos concursos: $error';
  }

  @override
  String get errorLoadingCategories => 'Error cargando categorías';

  @override
  String get errorLoadingStats => 'Error cargando estadísticas';
}
