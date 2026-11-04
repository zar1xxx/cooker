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

  @override
  String get pantrySearchHint => 'Найти продукт...';

  @override
  String get pantryVoiceSearch => 'Голос';

  @override
  String get pantryVoiceUnavailable =>
      'Голосовой ввод недоступен на этом устройстве';

  @override
  String get pantryFrequentSection => 'Часто выбираете';

  @override
  String get pantryCategoriesSection => 'Категории продуктов';

  @override
  String pantryShowDishes(int count) {
    return 'Показать блюда ($count)';
  }

  @override
  String get pantryNothingFound => 'Ничего не нашлось';

  @override
  String pantryAddCustom(String name) {
    return 'Добавить «$name» как новый продукт';
  }

  @override
  String pantrySelectedCount(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get pantryClearSearch => 'Очистить поиск';

  @override
  String get pantryClose => 'Закрыть';

  @override
  String get categoryVegetables => 'Овощи';

  @override
  String get categoryFruits => 'Фрукты и ягоды';

  @override
  String get categoryMeat => 'Мясо';

  @override
  String get categoryPoultry => 'Птица';

  @override
  String get categoryFish => 'Рыба и морепродукты';

  @override
  String get categoryDairy => 'Молочное и яйца';

  @override
  String get categoryGrains => 'Крупы и макароны';

  @override
  String get categoryBakery => 'Мука и хлеб';

  @override
  String get categoryLegumes => 'Бобовые';

  @override
  String get categoryMushrooms => 'Грибы';

  @override
  String get categoryCanned => 'Консервы';

  @override
  String get categorySpices => 'Специи и соусы';

  @override
  String get categoryNuts => 'Орехи и семечки';

  @override
  String get categorySweets => 'Сладкое';

  @override
  String get categoryGreens => 'Зелень';

  @override
  String get dishesScreenTitle => 'Подходящие блюда';

  @override
  String get dishesCanCookNow => 'Можно приготовить сейчас';

  @override
  String get dishesMissingFew => 'Не хватает 1–2 продуктов';

  @override
  String dishesMissing(String items) {
    return 'Не хватает: $items';
  }

  @override
  String get dishesFilterAllTypes => 'Все типы';

  @override
  String get dishesFilterAllDifficulties => 'Любая сложность';

  @override
  String get dishesFilterEasy => 'Легко';

  @override
  String get dishesFilterMedium => 'Средне';

  @override
  String get dishesFilterHard => 'Сложно';

  @override
  String get dishesBadgeNew => 'Новое';

  @override
  String get dishesActionReject => 'Не хочу';

  @override
  String get dishesActionOpen => 'Открыть рецепт';

  @override
  String get dishesEmpty => 'Нет подходящих блюд из выбранных продуктов';

  @override
  String dishesMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String get dishesUndoReject => 'Отменить';

  @override
  String get dishesRejectedSnackbar => 'Блюдо скрыто';

  @override
  String get dishTypeSoup => 'Суп';

  @override
  String get dishTypeMain => 'Второе';

  @override
  String get dishTypeSide => 'Гарнир';

  @override
  String get dishTypeSalad => 'Салат';

  @override
  String get dishTypeBreakfast => 'Завтрак';

  @override
  String get dishTypeSnack => 'Закуска';

  @override
  String get dishTypeBaking => 'Выпечка';

  @override
  String get dishTypeDessert => 'Десерт';

  @override
  String get dishTypeDrink => 'Напиток';

  @override
  String get dishTypePreserve => 'Заготовки';
}
