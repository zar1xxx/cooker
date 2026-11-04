// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Что приготовить?';

  @override
  String get tabToday => 'Сегодня';

  @override
  String get tabPantry => 'Что есть дома';

  @override
  String get tabCalendar => 'Календарь';

  @override
  String get tabHistory => 'История';

  @override
  String get screenTodayTitle => 'Сегодня';

  @override
  String get screenPantryTitle => 'Что есть дома';

  @override
  String get screenCalendarTitle => 'Календарь';

  @override
  String get screenHistoryTitle => 'История';
}
