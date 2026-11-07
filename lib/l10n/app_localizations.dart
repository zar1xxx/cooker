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

  /// Заголовок экрана рецепта
  ///
  /// In ru, this message translates to:
  /// **'Рецепт'**
  String get recipeScreenTitle;

  /// Количество порций
  ///
  /// In ru, this message translates to:
  /// **'Порции: {count}'**
  String recipeServingsLabel(int count);

  /// Семантика кнопки уменьшения порций
  ///
  /// In ru, this message translates to:
  /// **'Уменьшить количество порций'**
  String get recipeServingsDecrease;

  /// Семантика кнопки увеличения порций
  ///
  /// In ru, this message translates to:
  /// **'Увеличить количество порций'**
  String get recipeServingsIncrease;

  /// Заголовок секции ингредиентов
  ///
  /// In ru, this message translates to:
  /// **'Ингредиенты'**
  String get recipeIngredientsHeader;

  /// Подзаголовок секции ингредиентов
  ///
  /// In ru, this message translates to:
  /// **'Зелёная отметка — есть дома'**
  String get recipeIngredientsSubtitle;

  /// Заголовок секции шагов рецепта
  ///
  /// In ru, this message translates to:
  /// **'Шаги приготовления'**
  String get recipeStepsHeader;

  /// Заголовок советов
  ///
  /// In ru, this message translates to:
  /// **'Советы'**
  String get recipeTipsHeader;

  /// Префикс совета к шагу
  ///
  /// In ru, this message translates to:
  /// **'Совет: '**
  String get recipeTipPrefix;

  /// Главная кнопка перехода в режим готовки
  ///
  /// In ru, this message translates to:
  /// **'Начать готовить'**
  String get recipeStartCooking;

  /// Кнопка добавления в избранное
  ///
  /// In ru, this message translates to:
  /// **'В избранное'**
  String get recipeFavoriteAdd;

  /// Кнопка удаление из избранного
  ///
  /// In ru, this message translates to:
  /// **'В избранном'**
  String get recipeFavoriteIn;

  /// Кнопка планирования в календаре
  ///
  /// In ru, this message translates to:
  /// **'Поставить в календарь'**
  String get recipeAddToCalendar;

  /// Уведомление о добавлении в календарь
  ///
  /// In ru, this message translates to:
  /// **'Блюдо запланировано в календаре'**
  String get recipeAddedToCalendar;

  /// Уведомление о добавлении в избранное
  ///
  /// In ru, this message translates to:
  /// **'Рецепт добавлен в избранное'**
  String get recipeFavoriteAdded;

  /// Уведомление об удалении из избранного
  ///
  /// In ru, this message translates to:
  /// **'Рецепт удалён из избранного'**
  String get recipeFavoriteRemoved;

  /// Статус ингредиента: есть в запасах
  ///
  /// In ru, this message translates to:
  /// **'Есть дома'**
  String get recipeIngredientInPantry;

  /// Статус ингредиента: нет в запасах
  ///
  /// In ru, this message translates to:
  /// **'Нужно купить'**
  String get recipeIngredientMissing;

  /// Метка опционального ингредиента
  ///
  /// In ru, this message translates to:
  /// **'(по желанию)'**
  String get recipeOptional;

  /// Таймер шага в минутах
  ///
  /// In ru, this message translates to:
  /// **'⏱ {minutes} мин'**
  String recipeStepTimer(int minutes);

  /// Номер шага
  ///
  /// In ru, this message translates to:
  /// **'Шаг {number}'**
  String recipeStepNumber(int number);

  /// Сообщение если рецепт отсутствует
  ///
  /// In ru, this message translates to:
  /// **'Рецепт не найден'**
  String get recipeNotFound;

  /// Кухня блюда
  ///
  /// In ru, this message translates to:
  /// **'Кухня: {cuisine}'**
  String recipeCuisineLabel(String cuisine);

  /// Единица измерения: граммы
  ///
  /// In ru, this message translates to:
  /// **'г'**
  String get recipeUnitGram;

  /// Единица измерения: килограммы
  ///
  /// In ru, this message translates to:
  /// **'кг'**
  String get recipeUnitKilogram;

  /// Единица измерения: миллилитры
  ///
  /// In ru, this message translates to:
  /// **'мл'**
  String get recipeUnitMilliliter;

  /// Единица измерения: литры
  ///
  /// In ru, this message translates to:
  /// **'л'**
  String get recipeUnitLiter;

  /// Единица измерения: штуки
  ///
  /// In ru, this message translates to:
  /// **'шт.'**
  String get recipeUnitPieces;

  /// Единица измерения: столовые ложки
  ///
  /// In ru, this message translates to:
  /// **'ст. л.'**
  String get recipeUnitTbsp;

  /// Единица измерения: чайные ложки
  ///
  /// In ru, this message translates to:
  /// **'ч. л.'**
  String get recipeUnitTsp;

  /// Единица измерения: по вкусу
  ///
  /// In ru, this message translates to:
  /// **'по вкусу'**
  String get recipeUnitToTaste;

  /// Единица измерения: щепотка
  ///
  /// In ru, this message translates to:
  /// **'щепотка'**
  String get recipeUnitPinch;

  /// Единица измерения: зубчик
  ///
  /// In ru, this message translates to:
  /// **'зубчик'**
  String get recipeUnitClove;

  /// Заголовок экрана режима готовки
  ///
  /// In ru, this message translates to:
  /// **'Приготовление'**
  String get cookingScreenTitle;

  /// Индикатор прогресса шагов готовки
  ///
  /// In ru, this message translates to:
  /// **'Шаг {current} из {total}'**
  String cookingStepProgress(int current, int total);

  /// Кнопка перехода к предыдущему шагу
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get cookingButtonPrevious;

  /// Кнопка перехода к следующему шагу
  ///
  /// In ru, this message translates to:
  /// **'Дальше'**
  String get cookingButtonNext;

  /// Кнопка завершения готовки на последнем шаге
  ///
  /// In ru, this message translates to:
  /// **'Готово!'**
  String get cookingButtonFinish;

  /// Кнопка голосового чтения шага
  ///
  /// In ru, this message translates to:
  /// **'Прочитать вслух'**
  String get cookingTtsSpeak;

  /// Кнопка остановки голосового чтения
  ///
  /// In ru, this message translates to:
  /// **'Остановить чтение'**
  String get cookingTtsStop;

  /// Кнопка запуска таймера
  ///
  /// In ru, this message translates to:
  /// **'Запустить таймер'**
  String get cookingTimerStart;

  /// Кнопка паузы таймера
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get cookingTimerPause;

  /// Кнопка возобновления таймера
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get cookingTimerResume;

  /// Кнопка сброса таймера
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get cookingTimerReset;

  /// Сообщение об окончании времени таймера
  ///
  /// In ru, this message translates to:
  /// **'Время вышло!'**
  String get cookingTimerDone;

  /// No description provided for @cookingNoSteps.
  ///
  /// In ru, this message translates to:
  /// **'В этом рецепте нет описания шагов'**
  String get cookingNoSteps;

  /// Заголовок диалога оценки блюда
  ///
  /// In ru, this message translates to:
  /// **'Как получилось?'**
  String get cookingRateTitle;

  /// Подзаголовок диалога оценки блюда
  ///
  /// In ru, this message translates to:
  /// **'Поставьте оценку блюду'**
  String get cookingRateSubtitle;

  /// Кнопка сохранения оценки блюда
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get cookingRateSave;

  /// Кнопка завершения без оценки
  ///
  /// In ru, this message translates to:
  /// **'Без оценки'**
  String get cookingRateSkip;

  /// Описание оценки 1 звезда
  ///
  /// In ru, this message translates to:
  /// **'Плохо'**
  String get cookingRate1;

  /// Описание оценки 2 звезды
  ///
  /// In ru, this message translates to:
  /// **'Так себе'**
  String get cookingRate2;

  /// Описание оценки 3 звезды
  ///
  /// In ru, this message translates to:
  /// **'Нормально'**
  String get cookingRate3;

  /// Описание оценки 4 звезды
  ///
  /// In ru, this message translates to:
  /// **'Вкусно'**
  String get cookingRate4;

  /// Описание оценки 5 звёзд
  ///
  /// In ru, this message translates to:
  /// **'Очень вкусно!'**
  String get cookingRate5;

  /// Подсказка для поля ввода заметки к блюду
  ///
  /// In ru, this message translates to:
  /// **'Заметка (по желанию)'**
  String get cookingRateNoteHint;

  /// Чекбокс желания приготовить блюдо снова
  ///
  /// In ru, this message translates to:
  /// **'Хочу приготовить снова'**
  String get cookingRateRepeat;

  /// Уведомление об успешной записи в историю
  ///
  /// In ru, this message translates to:
  /// **'Блюдо записано в историю'**
  String get cookingSavedToHistory;

  /// Заголовок при пустой истории
  ///
  /// In ru, this message translates to:
  /// **'Вы ещё ничего не приготовили'**
  String get historyEmptyTitle;

  /// Подзаголовок при пустой истории
  ///
  /// In ru, this message translates to:
  /// **'Здесь сохраняются все приготовленные блюда с оценками и заметками'**
  String get historyEmptySubtitle;

  /// Кнопка перехода к подбору рецептов при пустой истории
  ///
  /// In ru, this message translates to:
  /// **'Подобрать рецепт'**
  String get historyEmptyAction;

  /// Заголовок группы блюд за сегодня
  ///
  /// In ru, this message translates to:
  /// **'Сегодня, {date}'**
  String historyDateToday(String date);

  /// Заголовок группы блюд за вчера
  ///
  /// In ru, this message translates to:
  /// **'Вчера, {date}'**
  String historyDateYesterday(String date);

  /// Отображение оценки звёздами
  ///
  /// In ru, this message translates to:
  /// **'Оценка: {rating} из 5'**
  String historyRatingStars(int rating);

  /// Отображение блюда без оценки
  ///
  /// In ru, this message translates to:
  /// **'Без оценки'**
  String get historyRatingUnrated;

  /// Бейдж желания повторить блюдо
  ///
  /// In ru, this message translates to:
  /// **'Хочу повторить'**
  String get historyWouldRepeat;

  /// Кнопка просмотра рецепта из истории
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть рецепт'**
  String get historyCookAgain;

  /// Заметка к приготовленному блюду
  ///
  /// In ru, this message translates to:
  /// **'Заметка: {note}'**
  String historyNote(String note);

  /// Время готовки блюда в истории
  ///
  /// In ru, this message translates to:
  /// **'{minutes} мин'**
  String historyCookingTime(int minutes);

  /// Подсказка в строке поиска истории
  ///
  /// In ru, this message translates to:
  /// **'Поиск по названию или заметке...'**
  String get historySearchHint;

  /// Семантическое описание кнопки очистки поиска
  ///
  /// In ru, this message translates to:
  /// **'Очистить поиск'**
  String get historySearchClear;

  /// Фильтр показа всех блюд в истории
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get historyFilterAll;

  /// Фильтр блюд с высокими оценками или отметкой Хочу повторить
  ///
  /// In ru, this message translates to:
  /// **'Любимые (4–5 ★)'**
  String get historyFilterFavorites;

  /// Заголовок карточки сводки за месяц
  ///
  /// In ru, this message translates to:
  /// **'Сводка за {month}'**
  String historyMonthSummaryTitle(String month);

  /// Количество приготовленных блюд в сводке
  ///
  /// In ru, this message translates to:
  /// **'Приготовлено: {count}'**
  String historySummaryCooked(int count);

  /// Количество новых блюд в сводке
  ///
  /// In ru, this message translates to:
  /// **'Новых блюд: {count}'**
  String historySummaryNew(int count);

  /// Название самого высокооценённого блюда в сводке
  ///
  /// In ru, this message translates to:
  /// **'Любимое: {title}'**
  String historySummaryTopRated(String title);

  /// Сообщение в сводке, если в этом месяце нет оценок
  ///
  /// In ru, this message translates to:
  /// **'Пока без оценок'**
  String get historySummaryNoRatings;

  /// Кнопка добавления блюда в историю вручную
  ///
  /// In ru, this message translates to:
  /// **'Записать блюдо'**
  String get historyAddButton;

  /// Заголовок диалога ручного добавления в историю
  ///
  /// In ru, this message translates to:
  /// **'Записать приготовленное'**
  String get historyAddModalTitle;

  /// Подпись поля названия блюда
  ///
  /// In ru, this message translates to:
  /// **'Название блюда'**
  String get historyAddDishNameLabel;

  /// Подсказка к полю названия блюда
  ///
  /// In ru, this message translates to:
  /// **'Например, Домашние оладьи'**
  String get historyAddDishNameHint;

  /// Подпись выбора типа блюда
  ///
  /// In ru, this message translates to:
  /// **'Тип блюда'**
  String get historyAddDishTypeLabel;

  /// Подпись выбора даты приготовления
  ///
  /// In ru, this message translates to:
  /// **'Дата приготовления'**
  String get historyAddDateLabel;

  /// Подпись блока оценки
  ///
  /// In ru, this message translates to:
  /// **'Оценка блюда'**
  String get historyAddRatingLabel;

  /// Переключатель Хочу приготовить снова
  ///
  /// In ru, this message translates to:
  /// **'Хочу приготовить снова'**
  String get historyAddWouldRepeatLabel;

  /// Подпись поля заметки
  ///
  /// In ru, this message translates to:
  /// **'Заметка (необязательно)'**
  String get historyAddNoteLabel;

  /// Подсказка к полю заметки
  ///
  /// In ru, this message translates to:
  /// **'Что понравилось или изменить в следующий раз...'**
  String get historyAddNoteHint;

  /// Кнопка сохранения в историю
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get historyAddSaveButton;

  /// Кнопка отмены добавления в историю
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get historyAddCancelButton;

  /// Подпись действия удаления записи из истории
  ///
  /// In ru, this message translates to:
  /// **'Удалить запись'**
  String get historyDeleteButton;

  /// Текст всплывающего уведомления при удалении
  ///
  /// In ru, this message translates to:
  /// **'Запись удалена из истории'**
  String get historyDeletedSnackbar;

  /// Кнопка отмены удаления в уведомлении
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get historyUndoDelete;

  /// Подпись действия изменения оценки
  ///
  /// In ru, this message translates to:
  /// **'Изменить оценку'**
  String get historyEditRating;

  /// Сообщение при отсутствии результатов фильтрации/поиска
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено по вашему запросу'**
  String get historyNoFilteredResults;

  /// Семантическое описание перехода к предыдущему месяцу в сводке
  ///
  /// In ru, this message translates to:
  /// **'Предыдущий месяц'**
  String get historyPreviousMonth;

  /// Семантическое описание перехода к следующему месяцу в сводке
  ///
  /// In ru, this message translates to:
  /// **'Следующий месяц'**
  String get historyNextMonth;

  /// Кнопка запроса новых вариантов от ИИ
  ///
  /// In ru, this message translates to:
  /// **'Другие варианты'**
  String get dishesOtherVariants;

  /// Индикатор активного режима ИИ: LM Studio на ПК
  ///
  /// In ru, this message translates to:
  /// **'Помощник: домашний ПК'**
  String get aiAssistantPc;

  /// Индикатор активного режима ИИ: GigaChat
  ///
  /// In ru, this message translates to:
  /// **'Помощник: GigaChat'**
  String get aiAssistantGigaChat;

  /// Индикатор активного режима ИИ: офлайн
  ///
  /// In ru, this message translates to:
  /// **'Без помощника'**
  String get aiAssistantOffline;

  /// Заголовок блока предложений от ИИ
  ///
  /// In ru, this message translates to:
  /// **'Предложения от помощника'**
  String get dishesFromAssistant;

  /// Предупреждение о рецепте от ИИ по ТЗ 9.1
  ///
  /// In ru, this message translates to:
  /// **'Рецепт придуман помощником. Проверяйте готовность мяса и рыбы'**
  String get dishesAiDisclaimer;

  /// Заголовок экрана настроек ИИ
  ///
  /// In ru, this message translates to:
  /// **'Настройки помощника (ИИ)'**
  String get aiSettingsTitle;

  /// Секция настроек LM Studio
  ///
  /// In ru, this message translates to:
  /// **'Домашний компьютер (LM Studio)'**
  String get aiSettingsPcSection;

  /// Подзаголовок секции LM Studio
  ///
  /// In ru, this message translates to:
  /// **'Основной режим. Работает через домашний Wi-Fi'**
  String get aiSettingsPcSubtitle;

  /// Поле адреса компьютера
  ///
  /// In ru, this message translates to:
  /// **'Адрес компьютера (IP)'**
  String get aiSettingsPcHost;

  /// Поле порта компьютера
  ///
  /// In ru, this message translates to:
  /// **'Порт'**
  String get aiSettingsPcPort;

  /// Кнопка поиска компьютера в сети
  ///
  /// In ru, this message translates to:
  /// **'Найти компьютер'**
  String get aiSettingsFindPc;

  /// Статус поиска компьютера
  ///
  /// In ru, this message translates to:
  /// **'Поиск компьютера в сети...'**
  String get aiSettingsFindingPc;

  /// Сообщение об успешном обнаружении ПК
  ///
  /// In ru, this message translates to:
  /// **'Компьютер найден: {host}'**
  String aiSettingsPcFound(String host);

  /// Сообщение об ошибке поиска ПК
  ///
  /// In ru, this message translates to:
  /// **'Компьютер не найден в сети Wi-Fi'**
  String get aiSettingsPcNotFound;

  /// Поле выбора модели
  ///
  /// In ru, this message translates to:
  /// **'Модель нейросети'**
  String get aiSettingsModel;

  /// Кнопка обновления моделей с ПК
  ///
  /// In ru, this message translates to:
  /// **'Обновить список моделей'**
  String get aiSettingsRefreshModels;

  /// Секция настроек GigaChat
  ///
  /// In ru, this message translates to:
  /// **'GigaChat (Сбер)'**
  String get aiSettingsGigaChatSection;

  /// Подзаголовок секции GigaChat
  ///
  /// In ru, this message translates to:
  /// **'Запасной облачный режим, если компьютер выключен'**
  String get aiSettingsGigaChatSubtitle;

  /// Поле ввода ключа GigaChat
  ///
  /// In ru, this message translates to:
  /// **'Авторизационные данные (Client Secret)'**
  String get aiSettingsGigaChatKey;

  /// Кнопка проверки связи с провайдерами
  ///
  /// In ru, this message translates to:
  /// **'Проверить связь'**
  String get aiSettingsCheckConnection;

  /// Индикатор проверки связи
  ///
  /// In ru, this message translates to:
  /// **'Проверка...'**
  String get aiSettingsChecking;

  /// Статус ПК: доступен
  ///
  /// In ru, this message translates to:
  /// **'Домашний ПК: подключён'**
  String get aiSettingsStatusPcOk;

  /// Статус ПК: недоступен
  ///
  /// In ru, this message translates to:
  /// **'Домашний ПК: не отвечает'**
  String get aiSettingsStatusPcFails;

  /// Статус GigaChat: доступен
  ///
  /// In ru, this message translates to:
  /// **'GigaChat: подключён'**
  String get aiSettingsStatusGigaChatOk;

  /// Статус GigaChat: ошибка
  ///
  /// In ru, this message translates to:
  /// **'GigaChat: ошибка авторизации'**
  String get aiSettingsStatusGigaChatFails;

  /// Статус GigaChat: не настроен
  ///
  /// In ru, this message translates to:
  /// **'GigaChat: ключ не введён'**
  String get aiSettingsStatusGigaChatNotConfigured;

  /// Текущий активный режим ИИ
  ///
  /// In ru, this message translates to:
  /// **'Активный режим: {mode}'**
  String aiSettingsActiveMode(String mode);

  /// Заголовок счётчика токенов
  ///
  /// In ru, this message translates to:
  /// **'Расход токенов GigaChat'**
  String get aiSettingsTokenUsageTitle;

  /// Количество использованных токенов
  ///
  /// In ru, this message translates to:
  /// **'{count} токенов в этом месяце'**
  String aiSettingsTokenCount(int count);

  /// Кнопка сохранения настроек
  ///
  /// In ru, this message translates to:
  /// **'Сохранить настройки'**
  String get aiSettingsSave;

  /// Уведомление об успешном сохранении
  ///
  /// In ru, this message translates to:
  /// **'Настройки успешно сохранены'**
  String get aiSettingsSaved;

  /// Заголовок плашки когда помощник недоступен
  ///
  /// In ru, this message translates to:
  /// **'Помощник сейчас не отвечает'**
  String get aiNotRespondingTitle;

  /// Пояснение почему помощник не отвечает
  ///
  /// In ru, this message translates to:
  /// **'{reason}'**
  String aiNotRespondingSubtitle(String reason);

  /// Заголовок плашки когда ИИ не настроен
  ///
  /// In ru, this message translates to:
  /// **'Помощник не настроен'**
  String get aiNotConfiguredTitle;

  /// Пояснение что нужно настроить ИИ
  ///
  /// In ru, this message translates to:
  /// **'Подключите компьютер или укажите ключ GigaChat, чтобы получать новые рецепты'**
  String get aiNotConfiguredSubtitle;

  /// Кнопка перехода в настройки помощника
  ///
  /// In ru, this message translates to:
  /// **'Настроить'**
  String get aiConfigureButton;

  /// Кнопка повторной попытки запроса к ИИ
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get aiRetryButton;

  /// Заголовок диалога ошибки загрузки рецепта от ИИ
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить рецепт'**
  String get aiErrorDialogTitle;

  /// Текст диалога ошибки загрузки рецепта
  ///
  /// In ru, this message translates to:
  /// **'Помощник не смог подготовить рецепт: {reason}. Вы можете выбрать похожее блюдо из каталога.'**
  String aiErrorDialogMessage(String reason);

  /// Кнопка закрытия диалога ошибки
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get aiErrorDialogClose;

  /// Кнопка перехода к каталогу при ошибке ИИ
  ///
  /// In ru, this message translates to:
  /// **'Похожие из каталога'**
  String get aiErrorDialogShowCatalog;

  /// Подсказка для кнопки настроек помощника в AppBar
  ///
  /// In ru, this message translates to:
  /// **'Настройки помощника'**
  String get aiSettingsTooltip;

  /// Заголовок экрана проверки помощника
  ///
  /// In ru, this message translates to:
  /// **'Проверка помощника'**
  String get aiDiagnosticsTitle;

  /// Подзаголовок экрана проверки помощника
  ///
  /// In ru, this message translates to:
  /// **'Пошаговая проверка подключения к компьютеру и GigaChat'**
  String get aiDiagnosticsSubtitle;

  /// Кнопка запуска диагностики
  ///
  /// In ru, this message translates to:
  /// **'Запустить проверку'**
  String get aiDiagnosticsRun;

  /// Индикатор выполнения проверки
  ///
  /// In ru, this message translates to:
  /// **'Выполняется проверка...'**
  String get aiDiagnosticsRunning;

  /// Заголовок списка последних запросов
  ///
  /// In ru, this message translates to:
  /// **'Последние 10 запросов'**
  String get aiDiagnosticsHistoryTitle;

  /// Сообщение при пустом списке запросов
  ///
  /// In ru, this message translates to:
  /// **'Запросов пока нет'**
  String get aiDiagnosticsHistoryEmpty;

  /// Кнопка перехода на экран диагностики в настройках
  ///
  /// In ru, this message translates to:
  /// **'Проверка помощника'**
  String get aiDiagnosticsBtnOpen;

  /// Подзаголовок кнопки диагностики
  ///
  /// In ru, this message translates to:
  /// **'Проверить Wi-Fi, компьютер, GigaChat и историю запросов'**
  String get aiDiagnosticsBtnOpenSubtitle;

  /// Заголовок экрана вкусов и предпочтений
  ///
  /// In ru, this message translates to:
  /// **'Что приложение знает о ваших вкусах'**
  String get tasteScreenTitle;

  /// Подзаголовок настроек вкусов
  ///
  /// In ru, this message translates to:
  /// **'Аллергии, нелюбимые продукты и обученные вкусы'**
  String get tasteScreenSubtitle;

  /// Пояснение о работе вкусового профиля
  ///
  /// In ru, this message translates to:
  /// **'Приложение запоминает ваши оценки. Блюда с оценкой 5 предлагаются чаще, а с оценкой 1 исключаются навсегда.'**
  String get tasteAboutCard;

  /// Заголовок секции любимых вкусов
  ///
  /// In ru, this message translates to:
  /// **'Любимые вкусы'**
  String get tasteLikedSectionTitle;

  /// Текст при отсутствии любимых признаков
  ///
  /// In ru, this message translates to:
  /// **'Пока нет данных о любимых вкусах. Оценивайте блюда после готовки!'**
  String get tasteLikedEmpty;

  /// Заголовок секции нелюбимых вкусов
  ///
  /// In ru, this message translates to:
  /// **'Нелюбимые вкусы'**
  String get tasteDislikedSectionTitle;

  /// Текст при отсутствии нелюбимых признаков
  ///
  /// In ru, this message translates to:
  /// **'Пока нет данных о нелюбимых вкусах'**
  String get tasteDislikedEmpty;

  /// Заголовок секции любимых блюд
  ///
  /// In ru, this message translates to:
  /// **'Любимые блюда'**
  String get tasteTopDishesTitle;

  /// Текст при отсутствии оценённых блюд
  ///
  /// In ru, this message translates to:
  /// **'Пока нет оценённых блюд в истории'**
  String get tasteTopDishesEmpty;

  /// Кнопка сброса профиля вкусов
  ///
  /// In ru, this message translates to:
  /// **'Сбросить вкусы'**
  String get tasteResetButton;

  /// Заголовок диалога сброса вкусов
  ///
  /// In ru, this message translates to:
  /// **'Сбросить вкусы?'**
  String get tasteResetDialogTitle;

  /// Текст предупреждения при сбросе вкусов
  ///
  /// In ru, this message translates to:
  /// **'Все накопленные оценки и вкусовые предпочтения будут сброшены. Ваши аллергии и исключения сохранятся.'**
  String get tasteResetDialogMessage;

  /// Кнопка отмены сброса
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get tasteResetDialogCancel;

  /// Кнопка подтверждения сброса
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get tasteResetDialogConfirm;

  /// Сообщение об успешном сбросе вкусов
  ///
  /// In ru, this message translates to:
  /// **'Профиль вкусов сброшен'**
  String get tasteResetSuccess;

  /// Заголовок секции аллергий
  ///
  /// In ru, this message translates to:
  /// **'Аллергии'**
  String get tasteAllergiesTitle;

  /// Пояснение к аллергиям
  ///
  /// In ru, this message translates to:
  /// **'Рецепты с этими продуктами никогда не будут предложены'**
  String get tasteAllergiesSubtitle;

  /// Текст при пустом списке аллергий
  ///
  /// In ru, this message translates to:
  /// **'Аллергии не добавлены'**
  String get tasteAllergiesEmpty;

  /// Кнопка добавления аллергии
  ///
  /// In ru, this message translates to:
  /// **'Добавить аллергию'**
  String get tasteAddAllergyButton;

  /// Заголовок секции исключений
  ///
  /// In ru, this message translates to:
  /// **'Исключения (не ем)'**
  String get tasteExclusionsTitle;

  /// Пояснение к исключениям
  ///
  /// In ru, this message translates to:
  /// **'Продукты, которые вы просто не хотите готовить'**
  String get tasteExclusionsSubtitle;

  /// Текст при пустом списке исключений
  ///
  /// In ru, this message translates to:
  /// **'Исключения не добавлены'**
  String get tasteExclusionsEmpty;

  /// Кнопка добавления исключения
  ///
  /// In ru, this message translates to:
  /// **'Добавить исключение'**
  String get tasteAddExclusionButton;

  /// Заголовок секции порций по умолчанию
  ///
  /// In ru, this message translates to:
  /// **'Порции по умолчанию'**
  String get tasteServingsTitle;

  /// Пояснение к порциям по умолчанию
  ///
  /// In ru, this message translates to:
  /// **'Количество порций при открытии рецепта'**
  String get tasteServingsSubtitle;

  /// Заголовок выбора продукта
  ///
  /// In ru, this message translates to:
  /// **'Выберите продукт'**
  String get tasteSelectIngredientTitle;

  /// Подсказка поиска продукта
  ///
  /// In ru, this message translates to:
  /// **'Поиск продукта...'**
  String get tasteSearchIngredientHint;

  /// Секция популярных продуктов
  ///
  /// In ru, this message translates to:
  /// **'Популярные'**
  String get tastePopularSection;

  /// Добавление произвольного продукта
  ///
  /// In ru, this message translates to:
  /// **'Добавить «{name}»'**
  String tasteAddCustomItem(String name);

  /// Заголовок экрана резервной копии
  ///
  /// In ru, this message translates to:
  /// **'Резервная копия'**
  String get backupScreenTitle;

  /// Подзаголовок настроек резервной копии
  ///
  /// In ru, this message translates to:
  /// **'Экспорт и импорт истории и вкусов'**
  String get backupScreenSubtitle;

  /// Пояснение о безопасности резервной копии
  ///
  /// In ru, this message translates to:
  /// **'Резервная копия сохраняет всю историю приготовленных блюд, оценки, аллергии и вкусы. Секретные ключи в копию не входят.'**
  String get backupAboutCard;

  /// Заголовок секции экспорта
  ///
  /// In ru, this message translates to:
  /// **'Экспорт (сохранить)'**
  String get backupExportSection;

  /// Кнопка копирования резервной копии
  ///
  /// In ru, this message translates to:
  /// **'Скопировать резервную копию'**
  String get backupExportButton;

  /// Уведомление об успешном копировании копии
  ///
  /// In ru, this message translates to:
  /// **'Резервная копия скопирована в буфер обмена ({kb} КБ)'**
  String backupExportSuccess(String kb);

  /// Сводка экспорта
  ///
  /// In ru, this message translates to:
  /// **'В копии: {cooked} записей истории, {recipes} рецептов'**
  String backupExportSummary(int cooked, int recipes);

  /// Заголовок секции импорта
  ///
  /// In ru, this message translates to:
  /// **'Импорт (восстановить)'**
  String get backupImportSection;

  /// Подзаголовок секции импорта
  ///
  /// In ru, this message translates to:
  /// **'Вставьте текст резервной копии, сохранённый ранее'**
  String get backupImportSubtitle;

  /// Подсказка в поле ввода копии
  ///
  /// In ru, this message translates to:
  /// **'Вставьте сюда текст резервной копии JSON...'**
  String get backupImportHint;

  /// Кнопка вставки из буфера
  ///
  /// In ru, this message translates to:
  /// **'Вставить из буфера'**
  String get backupPasteButton;

  /// Кнопка запуска восстановления
  ///
  /// In ru, this message translates to:
  /// **'Восстановить данные'**
  String get backupImportButton;

  /// Заголовок подтверждения восстановления
  ///
  /// In ru, this message translates to:
  /// **'Восстановить данные?'**
  String get backupImportConfirmTitle;

  /// Текст подтверждения восстановления
  ///
  /// In ru, this message translates to:
  /// **'История, блюда и настройки будут восстановлены из копии. Продолжить?'**
  String get backupImportConfirmMessage;

  /// Кнопка подтверждения
  ///
  /// In ru, this message translates to:
  /// **'Восстановить'**
  String get backupImportConfirm;

  /// Кнопка отмены
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get backupImportCancel;

  /// Уведомление об успешном восстановлении
  ///
  /// In ru, this message translates to:
  /// **'Данные успешно восстановлены: {count} записей истории'**
  String backupImportSuccess(int count);

  /// Сообщение об ошибке при импорте
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при восстановлении: {error}'**
  String backupImportError(String error);

  /// Ошибка при пустом поле ввода копии
  ///
  /// In ru, this message translates to:
  /// **'Пожалуйста, вставьте текст резервной копии'**
  String get backupEmptyInputError;

  /// Кнопка составления плана на месяц
  ///
  /// In ru, this message translates to:
  /// **'Составить план на месяц'**
  String get calendarMakeMonthPlan;

  /// Кнопка замены блюда в календаре
  ///
  /// In ru, this message translates to:
  /// **'Заменить'**
  String get calendarReplaceDish;

  /// Кнопка закрепления блюда на день
  ///
  /// In ru, this message translates to:
  /// **'Закрепить'**
  String get calendarLockDish;

  /// Кнопка снятия закрепления блюда
  ///
  /// In ru, this message translates to:
  /// **'Открепить'**
  String get calendarUnlockDish;

  /// Бейдж закреплённого блюда
  ///
  /// In ru, this message translates to:
  /// **'Закреплено'**
  String get calendarLockedBadge;

  /// Статус запланированного блюда
  ///
  /// In ru, this message translates to:
  /// **'Запланировано'**
  String get calendarStatusPlanned;

  /// Статус приготовленного блюда
  ///
  /// In ru, this message translates to:
  /// **'Приготовлено'**
  String get calendarStatusCooked;

  /// Статус пропущенного блюда
  ///
  /// In ru, this message translates to:
  /// **'Пропущено'**
  String get calendarStatusSkipped;

  /// Текст в пустой день календаря
  ///
  /// In ru, this message translates to:
  /// **'На этот день ничего не запланировано'**
  String get calendarEmptyDay;

  /// Кнопка выбора блюда в календарь
  ///
  /// In ru, this message translates to:
  /// **'Выбрать блюдо'**
  String get calendarChooseDish;

  /// Кнопка перехода к рецепту из календаря
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть рецепт'**
  String get calendarViewRecipe;

  /// Кнопка начала готовки из календаря
  ///
  /// In ru, this message translates to:
  /// **'Готовить'**
  String get calendarStartCooking;

  /// Кнопка отметки о приготовлении блюда
  ///
  /// In ru, this message translates to:
  /// **'Отметить приготовленным'**
  String get calendarMarkCooked;

  /// Отметка о наличии всех ингредиентов
  ///
  /// In ru, this message translates to:
  /// **'Все продукты есть дома'**
  String get calendarAllIngredientsAvailable;

  /// Список недостающих ингредиентов
  ///
  /// In ru, this message translates to:
  /// **'Не хватает: {items}'**
  String calendarMissingIngredients(String items);

  /// Кнопка замены на доступное из запасов блюдо
  ///
  /// In ru, this message translates to:
  /// **'Заменить на то, что можно из имеющегося'**
  String get calendarReplaceWithAvailable;

  /// Префикс даты для сегодняшнего дня
  ///
  /// In ru, this message translates to:
  /// **'Сегодня, {date}'**
  String calendarTodayPrefix(String date);

  /// Префикс даты для завтрашнего дня
  ///
  /// In ru, this message translates to:
  /// **'Завтра, {date}'**
  String calendarTomorrowPrefix(String date);

  /// Префикс даты для вчерашнего дня
  ///
  /// In ru, this message translates to:
  /// **'Вчера, {date}'**
  String calendarYesterdayPrefix(String date);

  /// Заголовок карточки сегодняшнего блюда
  ///
  /// In ru, this message translates to:
  /// **'Блюдо дня'**
  String get todayDishOfTheDay;

  /// Заголовок пустого состояния на экране Сегодня
  ///
  /// In ru, this message translates to:
  /// **'На сегодня блюдо не выбрано'**
  String get todayNoDishPlanned;

  /// Подзаголовок пустого состояния на экране Сегодня
  ///
  /// In ru, this message translates to:
  /// **'Выберите блюдо из каталога или подберите из того, что есть дома'**
  String get todayNoDishPlannedSubtitle;

  /// Кнопка перехода к подбору из запасов на экране Сегодня
  ///
  /// In ru, this message translates to:
  /// **'Подобрать из того, что есть'**
  String get todayPickFromPantry;

  /// Кнопка выбора блюда из каталога на экране Сегодня
  ///
  /// In ru, this message translates to:
  /// **'Выбрать блюдо'**
  String get todayChooseDish;

  /// Кнопка запуска режима готовки для блюда дня
  ///
  /// In ru, this message translates to:
  /// **'Готовить'**
  String get todayStartCooking;

  /// Кнопка замены блюда дня на экране Сегодня
  ///
  /// In ru, this message translates to:
  /// **'Другое блюдо'**
  String get todayAnotherDish;

  /// Кнопка просмотра рецепта блюда дня
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть рецепт'**
  String get todayViewRecipe;

  /// Кнопка перехода в календарь с экрана Сегодня
  ///
  /// In ru, this message translates to:
  /// **'Открыть календарь'**
  String get todayOpenCalendar;

  /// Заголовок секции ежедневного уведомления в настройках
  ///
  /// In ru, this message translates to:
  /// **'Уведомление о блюде дня'**
  String get dailyNotificationSection;

  /// Переключатель ежедневного уведомления
  ///
  /// In ru, this message translates to:
  /// **'Ежедневное напоминание'**
  String get dailyNotificationSwitch;

  /// Подзаголовок ежедневного уведомления
  ///
  /// In ru, this message translates to:
  /// **'Напоминать о запланированном на сегодня блюде'**
  String get dailyNotificationSubtitle;

  /// Время ежедневного уведомления
  ///
  /// In ru, this message translates to:
  /// **'Время напоминания'**
  String get dailyNotificationTime;
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
