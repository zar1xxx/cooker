import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ru.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('ru')];

  /// Название приложения
  ///
  /// In ru, this message translates to:
  /// **'Что приготовить?'**
  String get appTitle;

  /// Вкладка 'Сегодня'
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get tabToday;

  /// Вкладка 'Что есть дома'
  ///
  /// In ru, this message translates to:
  /// **'Что есть дома'**
  String get tabPantry;

  /// Вкладка 'Календарь'
  ///
  /// In ru, this message translates to:
  /// **'Календарь'**
  String get tabCalendar;

  /// Вкладка 'История'
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get tabHistory;

  /// Заголовок экрана Сегодня
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get screenTodayTitle;

  /// Заголовок экрана Что есть дома
  ///
  /// In ru, this message translates to:
  /// **'Что есть дома'**
  String get screenPantryTitle;

  /// Заголовок экрана Календарь
  ///
  /// In ru, this message translates to:
  /// **'Календарь'**
  String get screenCalendarTitle;

  /// Заголовок экрана История
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get screenHistoryTitle;

  /// Подсказка в строке поиска продуктов
  ///
  /// In ru, this message translates to:
  /// **'Найти продукт...'**
  String get pantrySearchHint;

  /// Кнопка голосового ввода
  ///
  /// In ru, this message translates to:
  /// **'Голос'**
  String get pantryVoiceSearch;

  /// Сообщение о недоступности голосового ввода
  ///
  /// In ru, this message translates to:
  /// **'Голосовой ввод недоступен на этом устройстве'**
  String get pantryVoiceUnavailable;

  /// Заголовок секции популярных продуктов
  ///
  /// In ru, this message translates to:
  /// **'Часто выбираете'**
  String get pantryFrequentSection;

  /// Заголовок секции категорий
  ///
  /// In ru, this message translates to:
  /// **'Категории продуктов'**
  String get pantryCategoriesSection;

  /// Кнопка перехода к подобранным блюдам
  ///
  /// In ru, this message translates to:
  /// **'Показать блюда ({count})'**
  String pantryShowDishes(int count);

  /// Текст при пустом поиске
  ///
  /// In ru, this message translates to:
  /// **'Ничего не нашлось'**
  String get pantryNothingFound;

  /// Кнопка добавления незнакомого продукта
  ///
  /// In ru, this message translates to:
  /// **'Добавить «{name}» как новый продукт'**
  String pantryAddCustom(String name);

  /// Количество выбранных продуктов в категории
  ///
  /// In ru, this message translates to:
  /// **'Выбрано: {count}'**
  String pantrySelectedCount(int count);

  /// Кнопка очистки поиска
  ///
  /// In ru, this message translates to:
  /// **'Очистить поиск'**
  String get pantryClearSearch;

  /// Кнопка закрытия
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get pantryClose;

  /// Категория Овощи
  ///
  /// In ru, this message translates to:
  /// **'Овощи'**
  String get categoryVegetables;

  /// Категория Фрукты и ягоды
  ///
  /// In ru, this message translates to:
  /// **'Фрукты и ягоды'**
  String get categoryFruits;

  /// Категория Мясо
  ///
  /// In ru, this message translates to:
  /// **'Мясо'**
  String get categoryMeat;

  /// Категория Птица
  ///
  /// In ru, this message translates to:
  /// **'Птица'**
  String get categoryPoultry;

  /// Категория Рыба
  ///
  /// In ru, this message translates to:
  /// **'Рыба и морепродукты'**
  String get categoryFish;

  /// Категория Молочное и яйца
  ///
  /// In ru, this message translates to:
  /// **'Молочное и яйца'**
  String get categoryDairy;

  /// Категория Крупы
  ///
  /// In ru, this message translates to:
  /// **'Крупы и макароны'**
  String get categoryGrains;

  /// Категория Мука и хлеб
  ///
  /// In ru, this message translates to:
  /// **'Мука и хлеб'**
  String get categoryBakery;

  /// Категория Бобовые
  ///
  /// In ru, this message translates to:
  /// **'Бобовые'**
  String get categoryLegumes;

  /// Категория Грибы
  ///
  /// In ru, this message translates to:
  /// **'Грибы'**
  String get categoryMushrooms;

  /// Категория Консервы
  ///
  /// In ru, this message translates to:
  /// **'Консервы'**
  String get categoryCanned;

  /// Категория Специи
  ///
  /// In ru, this message translates to:
  /// **'Специи и соусы'**
  String get categorySpices;

  /// Категория Орехи
  ///
  /// In ru, this message translates to:
  /// **'Орехи и семечки'**
  String get categoryNuts;

  /// Категория Сладкое
  ///
  /// In ru, this message translates to:
  /// **'Сладкое'**
  String get categorySweets;

  /// Категория Зелень
  ///
  /// In ru, this message translates to:
  /// **'Зелень'**
  String get categoryGreens;

  /// Заголовок экрана Блюда
  ///
  /// In ru, this message translates to:
  /// **'Подходящие блюда'**
  String get dishesScreenTitle;

  /// Секция блюд без недостающих ингредиентов
  ///
  /// In ru, this message translates to:
  /// **'Можно приготовить сейчас'**
  String get dishesCanCookNow;

  /// Секция блюд с 1-2 недостающими продуктами
  ///
  /// In ru, this message translates to:
  /// **'Не хватает 1–2 продуктов'**
  String get dishesMissingFew;

  /// Список недостающих ингредиентов на карточке
  ///
  /// In ru, this message translates to:
  /// **'Не хватает: {items}'**
  String dishesMissing(String items);

  /// Фильтр: все типы блюд
  ///
  /// In ru, this message translates to:
  /// **'Все типы'**
  String get dishesFilterAllTypes;

  /// Фильтр: любая сложность
  ///
  /// In ru, this message translates to:
  /// **'Любая сложность'**
  String get dishesFilterAllDifficulties;

  /// Фильтр: легко
  ///
  /// In ru, this message translates to:
  /// **'Легко'**
  String get dishesFilterEasy;

  /// Фильтр: средне
  ///
  /// In ru, this message translates to:
  /// **'Средне'**
  String get dishesFilterMedium;

  /// Фильтр: сложно
  ///
  /// In ru, this message translates to:
  /// **'Сложно'**
  String get dishesFilterHard;

  /// Бейдж Новое от ИИ
  ///
  /// In ru, this message translates to:
  /// **'Новое'**
  String get dishesBadgeNew;

  /// Кнопка Не хочу на карточке
  ///
  /// In ru, this message translates to:
  /// **'Не хочу'**
  String get dishesActionReject;

  /// Кнопка Открыть рецепт
  ///
  /// In ru, this message translates to:
  /// **'Открыть рецепт'**
  String get dishesActionOpen;

  /// Текст при отсутствии подходящих блюд
  ///
  /// In ru, this message translates to:
  /// **'Нет подходящих блюд из выбранных продуктов'**
  String get dishesEmpty;

  /// Длительность приготовления в минутах
  ///
  /// In ru, this message translates to:
  /// **'{minutes} мин'**
  String dishesMinutes(int minutes);

  /// Кнопка отмены скрытия блюда
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get dishesUndoReject;

  /// Уведомление при нажатии Не хочу
  ///
  /// In ru, this message translates to:
  /// **'Блюдо скрыто'**
  String get dishesRejectedSnackbar;

  /// Тип блюда: суп
  ///
  /// In ru, this message translates to:
  /// **'Суп'**
  String get dishTypeSoup;

  /// Тип блюда: второе
  ///
  /// In ru, this message translates to:
  /// **'Второе'**
  String get dishTypeMain;

  /// Тип блюда: гарнир
  ///
  /// In ru, this message translates to:
  /// **'Гарнир'**
  String get dishTypeSide;

  /// Тип блюда: салат
  ///
  /// In ru, this message translates to:
  /// **'Салат'**
  String get dishTypeSalad;

  /// Тип блюда: завтрак
  ///
  /// In ru, this message translates to:
  /// **'Завтрак'**
  String get dishTypeBreakfast;

  /// Тип блюда: закуска
  ///
  /// In ru, this message translates to:
  /// **'Закуска'**
  String get dishTypeSnack;

  /// Тип блюда: выпечка
  ///
  /// In ru, this message translates to:
  /// **'Выпечка'**
  String get dishTypeBaking;

  /// Тип блюда: десерт
  ///
  /// In ru, this message translates to:
  /// **'Десерт'**
  String get dishTypeDessert;

  /// Тип блюда: напиток
  ///
  /// In ru, this message translates to:
  /// **'Напиток'**
  String get dishTypeDrink;

  /// Тип блюда: заготовки
  ///
  /// In ru, this message translates to:
  /// **'Заготовки'**
  String get dishTypePreserve;
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
      <String>['ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
