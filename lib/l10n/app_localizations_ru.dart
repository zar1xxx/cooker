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

  @override
  String get recipeScreenTitle => 'Рецепт';

  @override
  String recipeServingsLabel(int count) {
    return 'Порции: $count';
  }

  @override
  String get recipeServingsDecrease => 'Уменьшить количество порций';

  @override
  String get recipeServingsIncrease => 'Увеличить количество порций';

  @override
  String get recipeIngredientsHeader => 'Ингредиенты';

  @override
  String get recipeIngredientsSubtitle => 'Зелёная отметка — есть дома';

  @override
  String get recipeStepsHeader => 'Шаги приготовления';

  @override
  String get recipeTipsHeader => 'Советы';

  @override
  String get recipeTipPrefix => 'Совет: ';

  @override
  String get recipeStartCooking => 'Начать готовить';

  @override
  String get recipeFavoriteAdd => 'В избранное';

  @override
  String get recipeFavoriteIn => 'В избранном';

  @override
  String get recipeAddToCalendar => 'Поставить в календарь';

  @override
  String get recipeAddedToCalendar => 'Блюдо запланировано в календаре';

  @override
  String get recipeFavoriteAdded => 'Рецепт добавлен в избранное';

  @override
  String get recipeFavoriteRemoved => 'Рецепт удалён из избранного';

  @override
  String get recipeIngredientInPantry => 'Есть дома';

  @override
  String get recipeIngredientMissing => 'Нужно купить';

  @override
  String get recipeOptional => '(по желанию)';

  @override
  String recipeStepTimer(int minutes) {
    return '⏱ $minutes мин';
  }

  @override
  String recipeStepNumber(int number) {
    return 'Шаг $number';
  }

  @override
  String get recipeNotFound => 'Рецепт не найден';

  @override
  String recipeCuisineLabel(String cuisine) {
    return 'Кухня: $cuisine';
  }

  @override
  String get recipeUnitGram => 'г';

  @override
  String get recipeUnitKilogram => 'кг';

  @override
  String get recipeUnitMilliliter => 'мл';

  @override
  String get recipeUnitLiter => 'л';

  @override
  String get recipeUnitPieces => 'шт.';

  @override
  String get recipeUnitTbsp => 'ст. л.';

  @override
  String get recipeUnitTsp => 'ч. л.';

  @override
  String get recipeUnitToTaste => 'по вкусу';

  @override
  String get recipeUnitPinch => 'щепотка';

  @override
  String get recipeUnitClove => 'зубчик';

  @override
  String get cookingScreenTitle => 'Приготовление';

  @override
  String cookingStepProgress(int current, int total) {
    return 'Шаг $current из $total';
  }

  @override
  String get cookingButtonPrevious => 'Назад';

  @override
  String get cookingButtonNext => 'Дальше';

  @override
  String get cookingButtonFinish => 'Готово!';

  @override
  String get cookingTtsSpeak => 'Прочитать вслух';

  @override
  String get cookingTtsStop => 'Остановить чтение';

  @override
  String get cookingTimerStart => 'Запустить таймер';

  @override
  String get cookingTimerPause => 'Пауза';

  @override
  String get cookingTimerResume => 'Продолжить';

  @override
  String get cookingTimerReset => 'Сбросить';

  @override
  String get cookingTimerDone => 'Время вышло!';

  @override
  String get cookingNoSteps => 'В этом рецепте нет описания шагов';

  @override
  String get cookingRateTitle => 'Как получилось?';

  @override
  String get cookingRateSubtitle => 'Поставьте оценку блюду';

  @override
  String get cookingRateSave => 'Сохранить';

  @override
  String get cookingRateSkip => 'Без оценки';

  @override
  String get cookingRate1 => 'Плохо';

  @override
  String get cookingRate2 => 'Так себе';

  @override
  String get cookingRate3 => 'Нормально';

  @override
  String get cookingRate4 => 'Вкусно';

  @override
  String get cookingRate5 => 'Очень вкусно!';

  @override
  String get cookingRateNoteHint => 'Заметка (по желанию)';

  @override
  String get cookingRateRepeat => 'Хочу приготовить снова';

  @override
  String get cookingSavedToHistory => 'Блюдо записано в историю';

  @override
  String get historyEmptyTitle => 'Вы ещё ничего не приготовили';

  @override
  String get historyEmptySubtitle =>
      'Здесь сохраняются все приготовленные блюда с оценками и заметками';

  @override
  String get historyEmptyAction => 'Подобрать рецепт';

  @override
  String historyDateToday(String date) {
    return 'Сегодня, $date';
  }

  @override
  String historyDateYesterday(String date) {
    return 'Вчера, $date';
  }

  @override
  String historyRatingStars(int rating) {
    return 'Оценка: $rating из 5';
  }

  @override
  String get historyRatingUnrated => 'Без оценки';

  @override
  String get historyWouldRepeat => 'Хочу повторить';

  @override
  String get historyCookAgain => 'Посмотреть рецепт';

  @override
  String historyNote(String note) {
    return 'Заметка: $note';
  }

  @override
  String historyCookingTime(int minutes) {
    return '$minutes мин';
  }

  @override
  String get historySearchHint => 'Поиск по названию или заметке...';

  @override
  String get historySearchClear => 'Очистить поиск';

  @override
  String get historyFilterAll => 'Все';

  @override
  String get historyFilterFavorites => 'Любимые (4–5 ★)';

  @override
  String historyMonthSummaryTitle(String month) {
    return 'Сводка за $month';
  }

  @override
  String historySummaryCooked(int count) {
    return 'Приготовлено: $count';
  }

  @override
  String historySummaryNew(int count) {
    return 'Новых блюд: $count';
  }

  @override
  String historySummaryTopRated(String title) {
    return 'Любимое: $title';
  }

  @override
  String get historySummaryNoRatings => 'Пока без оценок';

  @override
  String get historyAddButton => 'Записать блюдо';

  @override
  String get historyAddModalTitle => 'Записать приготовленное';

  @override
  String get historyAddDishNameLabel => 'Название блюда';

  @override
  String get historyAddDishNameHint => 'Например, Домашние оладьи';

  @override
  String get historyAddDishTypeLabel => 'Тип блюда';

  @override
  String get historyAddDateLabel => 'Дата приготовления';

  @override
  String get historyAddRatingLabel => 'Оценка блюда';

  @override
  String get historyAddWouldRepeatLabel => 'Хочу приготовить снова';

  @override
  String get historyAddNoteLabel => 'Заметка (необязательно)';

  @override
  String get historyAddNoteHint =>
      'Что понравилось или изменить в следующий раз...';

  @override
  String get historyAddSaveButton => 'Сохранить';

  @override
  String get historyAddCancelButton => 'Отмена';

  @override
  String get historyDeleteButton => 'Удалить запись';

  @override
  String get historyDeletedSnackbar => 'Запись удалена из истории';

  @override
  String get historyUndoDelete => 'Отменить';

  @override
  String get historyEditRating => 'Изменить оценку';

  @override
  String get historyNoFilteredResults => 'Ничего не найдено по вашему запросу';

  @override
  String get historyPreviousMonth => 'Предыдущий месяц';

  @override
  String get historyNextMonth => 'Следующий месяц';

  @override
  String get dishesOtherVariants => 'Другие варианты';

  @override
  String get aiAssistantPc => 'Помощник: домашний ПК';

  @override
  String get aiAssistantGigaChat => 'Помощник: GigaChat';

  @override
  String get aiAssistantOffline => 'Без помощника';

  @override
  String get dishesFromAssistant => 'Предложения от помощника';

  @override
  String get dishesAiDisclaimer =>
      'Рецепт придуман помощником. Проверяйте готовность мяса и рыбы';

  @override
  String get aiSettingsTitle => 'Настройки помощника (ИИ)';

  @override
  String get aiSettingsPcSection => 'Домашний компьютер (LM Studio)';

  @override
  String get aiSettingsPcSubtitle =>
      'Основной режим. Работает через домашний Wi-Fi';

  @override
  String get aiSettingsPcHost => 'Адрес компьютера (IP)';

  @override
  String get aiSettingsPcPort => 'Порт';

  @override
  String get aiSettingsFindPc => 'Найти компьютер';

  @override
  String get aiSettingsFindingPc => 'Поиск компьютера в сети...';

  @override
  String aiSettingsPcFound(String host) {
    return 'Компьютер найден: $host';
  }

  @override
  String get aiSettingsPcNotFound => 'Компьютер не найден в сети Wi-Fi';

  @override
  String get aiSettingsModel => 'Модель нейросети';

  @override
  String get aiSettingsRefreshModels => 'Обновить список моделей';

  @override
  String get aiSettingsGigaChatSection => 'GigaChat (Сбер)';

  @override
  String get aiSettingsGigaChatSubtitle =>
      'Запасной облачный режим, если компьютер выключен';

  @override
  String get aiSettingsGigaChatKey => 'Авторизационные данные (Client Secret)';

  @override
  String get aiSettingsCheckConnection => 'Проверить связь';

  @override
  String get aiSettingsChecking => 'Проверка...';

  @override
  String get aiSettingsStatusPcOk => 'Домашний ПК: подключён';

  @override
  String get aiSettingsStatusPcFails => 'Домашний ПК: не отвечает';

  @override
  String get aiSettingsStatusGigaChatOk => 'GigaChat: подключён';

  @override
  String get aiSettingsStatusGigaChatFails => 'GigaChat: ошибка авторизации';

  @override
  String get aiSettingsStatusGigaChatNotConfigured =>
      'GigaChat: ключ не введён';

  @override
  String aiSettingsActiveMode(String mode) {
    return 'Активный режим: $mode';
  }

  @override
  String get aiSettingsTokenUsageTitle => 'Расход токенов GigaChat';

  @override
  String aiSettingsTokenCount(int count) {
    return '$count токенов в этом месяце';
  }

  @override
  String get aiSettingsSave => 'Сохранить настройки';

  @override
  String get aiSettingsSaved => 'Настройки успешно сохранены';

  @override
  String get aiNotRespondingTitle => 'Помощник сейчас не отвечает';

  @override
  String aiNotRespondingSubtitle(String reason) {
    return '$reason';
  }

  @override
  String get aiNotConfiguredTitle => 'Помощник не настроен';

  @override
  String get aiNotConfiguredSubtitle =>
      'Подключите компьютер или укажите ключ GigaChat, чтобы получать новые рецепты';

  @override
  String get aiConfigureButton => 'Настроить';

  @override
  String get aiRetryButton => 'Повторить';

  @override
  String get aiErrorDialogTitle => 'Не удалось загрузить рецепт';

  @override
  String aiErrorDialogMessage(String reason) {
    return 'Помощник не смог подготовить рецепт: $reason. Вы можете выбрать похожее блюдо из каталога.';
  }

  @override
  String get aiErrorDialogClose => 'Понятно';

  @override
  String get aiErrorDialogShowCatalog => 'Похожие из каталога';

  @override
  String get aiSettingsTooltip => 'Настройки помощника';

  @override
  String get aiDiagnosticsTitle => 'Проверка помощника';

  @override
  String get aiDiagnosticsSubtitle =>
      'Пошаговая проверка подключения к компьютеру и GigaChat';

  @override
  String get aiDiagnosticsRun => 'Запустить проверку';

  @override
  String get aiDiagnosticsRunning => 'Выполняется проверка...';

  @override
  String get aiDiagnosticsHistoryTitle => 'Последние 10 запросов';

  @override
  String get aiDiagnosticsHistoryEmpty => 'Запросов пока нет';

  @override
  String get aiDiagnosticsBtnOpen => 'Проверка помощника';

  @override
  String get aiDiagnosticsBtnOpenSubtitle =>
      'Проверить Wi-Fi, компьютер, GigaChat и историю запросов';

  @override
  String get tasteScreenTitle => 'Что приложение знает о ваших вкусах';

  @override
  String get tasteScreenSubtitle =>
      'Аллергии, нелюбимые продукты и обученные вкусы';

  @override
  String get tasteAboutCard =>
      'Приложение запоминает ваши оценки. Блюда с оценкой 5 предлагаются чаще, а с оценкой 1 исключаются навсегда.';

  @override
  String get tasteLikedSectionTitle => 'Любимые вкусы';

  @override
  String get tasteLikedEmpty =>
      'Пока нет данных о любимых вкусах. Оценивайте блюда после готовки!';

  @override
  String get tasteDislikedSectionTitle => 'Нелюбимые вкусы';

  @override
  String get tasteDislikedEmpty => 'Пока нет данных о нелюбимых вкусах';

  @override
  String get tasteTopDishesTitle => 'Любимые блюда';

  @override
  String get tasteTopDishesEmpty => 'Пока нет оценённых блюд в истории';

  @override
  String get tasteResetButton => 'Сбросить вкусы';

  @override
  String get tasteResetDialogTitle => 'Сбросить вкусы?';

  @override
  String get tasteResetDialogMessage =>
      'Все накопленные оценки и вкусовые предпочтения будут сброшены. Ваши аллергии и исключения сохранятся.';

  @override
  String get tasteResetDialogCancel => 'Отмена';

  @override
  String get tasteResetDialogConfirm => 'Сбросить';

  @override
  String get tasteResetSuccess => 'Профиль вкусов сброшен';

  @override
  String get tasteAllergiesTitle => 'Аллергии';

  @override
  String get tasteAllergiesSubtitle =>
      'Рецепты с этими продуктами никогда не будут предложены';

  @override
  String get tasteAllergiesEmpty => 'Аллергии не добавлены';

  @override
  String get tasteAddAllergyButton => 'Добавить аллергию';

  @override
  String get tasteExclusionsTitle => 'Исключения (не ем)';

  @override
  String get tasteExclusionsSubtitle =>
      'Продукты, которые вы просто не хотите готовить';

  @override
  String get tasteExclusionsEmpty => 'Исключения не добавлены';

  @override
  String get tasteAddExclusionButton => 'Добавить исключение';

  @override
  String get tasteServingsTitle => 'Порции по умолчанию';

  @override
  String get tasteServingsSubtitle => 'Количество порций при открытии рецепта';

  @override
  String get tasteSelectIngredientTitle => 'Выберите продукт';

  @override
  String get tasteSearchIngredientHint => 'Поиск продукта...';

  @override
  String get tastePopularSection => 'Популярные';

  @override
  String tasteAddCustomItem(String name) {
    return 'Добавить «$name»';
  }

  @override
  String get backupScreenTitle => 'Резервная копия';

  @override
  String get backupScreenSubtitle => 'Экспорт и импорт истории и вкусов';

  @override
  String get backupAboutCard =>
      'Резервная копия сохраняет всю историю приготовленных блюд, оценки, аллергии и вкусы. Секретные ключи в копию не входят.';

  @override
  String get backupExportSection => 'Экспорт (сохранить)';

  @override
  String get backupExportButton => 'Скопировать резервную копию';

  @override
  String backupExportSuccess(String kb) {
    return 'Резервная копия скопирована в буфер обмена ($kb КБ)';
  }

  @override
  String backupExportSummary(int cooked, int recipes) {
    return 'В копии: $cooked записей истории, $recipes рецептов';
  }

  @override
  String get backupImportSection => 'Импорт (восстановить)';

  @override
  String get backupImportSubtitle =>
      'Вставьте текст резервной копии, сохранённый ранее';

  @override
  String get backupImportHint => 'Вставьте сюда текст резервной копии JSON...';

  @override
  String get backupPasteButton => 'Вставить из буфера';

  @override
  String get backupImportButton => 'Восстановить данные';

  @override
  String get backupImportConfirmTitle => 'Восстановить данные?';

  @override
  String get backupImportConfirmMessage =>
      'История, блюда и настройки будут восстановлены из копии. Продолжить?';

  @override
  String get backupImportConfirm => 'Восстановить';

  @override
  String get backupImportCancel => 'Отмена';

  @override
  String backupImportSuccess(int count) {
    return 'Данные успешно восстановлены: $count записей истории';
  }

  @override
  String backupImportError(String error) {
    return 'Ошибка при восстановлении: $error';
  }

  @override
  String get backupEmptyInputError =>
      'Пожалуйста, вставьте текст резервной копии';

  @override
  String get calendarMakeMonthPlan => 'Составить план на месяц';

  @override
  String get calendarReplaceDish => 'Заменить';

  @override
  String get calendarLockDish => 'Закрепить';

  @override
  String get calendarUnlockDish => 'Открепить';

  @override
  String get calendarLockedBadge => 'Закреплено';

  @override
  String get calendarStatusPlanned => 'Запланировано';

  @override
  String get calendarStatusCooked => 'Приготовлено';

  @override
  String get calendarStatusSkipped => 'Пропущено';

  @override
  String get calendarEmptyDay => 'На этот день ничего не запланировано';

  @override
  String get calendarChooseDish => 'Выбрать блюдо';

  @override
  String get calendarViewRecipe => 'Посмотреть рецепт';

  @override
  String get calendarStartCooking => 'Готовить';

  @override
  String get calendarMarkCooked => 'Отметить приготовленным';

  @override
  String get calendarAllIngredientsAvailable => 'Все продукты есть дома';

  @override
  String calendarMissingIngredients(String items) {
    return 'Не хватает: $items';
  }

  @override
  String get calendarReplaceWithAvailable =>
      'Заменить на то, что можно из имеющегося';

  @override
  String calendarTodayPrefix(String date) {
    return 'Сегодня, $date';
  }

  @override
  String calendarTomorrowPrefix(String date) {
    return 'Завтра, $date';
  }

  @override
  String calendarYesterdayPrefix(String date) {
    return 'Вчера, $date';
  }

  @override
  String get todayDishOfTheDay => 'Блюдо дня';

  @override
  String get todayNoDishPlanned => 'На сегодня блюдо не выбрано';

  @override
  String get todayNoDishPlannedSubtitle =>
      'Выберите блюдо из каталога или подберите из того, что есть дома';

  @override
  String get todayPickFromPantry => 'Подобрать из того, что есть';

  @override
  String get todayChooseDish => 'Выбрать блюдо';

  @override
  String get todayStartCooking => 'Готовить';

  @override
  String get todayAnotherDish => 'Другое блюдо';

  @override
  String get todayViewRecipe => 'Посмотреть рецепт';

  @override
  String get todayOpenCalendar => 'Открыть календарь';

  @override
  String get dailyNotificationSection => 'Уведомление о блюде дня';

  @override
  String get dailyNotificationSwitch => 'Ежедневное напоминание';

  @override
  String get dailyNotificationSubtitle =>
      'Напоминать о запланированном на сегодня блюде';

  @override
  String get dailyNotificationTime => 'Время напоминания';
}
