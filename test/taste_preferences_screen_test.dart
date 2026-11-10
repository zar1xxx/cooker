import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/settings/taste_preferences_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PreferenceService prefService;
  late HistoryDao historyDao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();
    prefService = PreferenceService(db);
    historyDao = HistoryDao(db, preferenceService: prefService);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestScreen() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        preferenceServiceProvider.overrideWithValue(prefService),
        historyDaoProvider.overrideWithValue(historyDao),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        home: const TastePreferencesScreen(),
      ),
    );
  }

  testWidgets('renders empty profile when no history or feedback exists', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.text('Что приложение знает о ваших вкусах'), findsOneWidget);
    expect(find.text('Любимые вкусы'), findsOneWidget);
    expect(
      find.text(
        'Пока нет данных о любимых вкусах. Оценивайте блюда после готовки!',
      ),
      findsOneWidget,
    );
    expect(find.text('Нелюбимые вкусы'), findsOneWidget);
    expect(find.text('Пока нет данных о нелюбимых вкусах'), findsOneWidget);
    expect(find.text('Любимые блюда'), findsOneWidget);
    expect(find.text('Пока нет оценённых блюд в истории'), findsOneWidget);
    expect(find.text('Сбросить вкусы'), findsOneWidget);
    expect(find.text('Аллергии'), findsOneWidget);
    expect(find.text('Исключения (не ем)'), findsOneWidget);
    expect(find.text('Порции по умолчанию'), findsOneWidget);
  });

  testWidgets('renders learned liked and disliked features and top dishes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Record cooked soup with rating 5 twice (>= 2 events per R8-02)
    await historyDao.recordCooked(recipeId: 'chicken_soup_potato', rating: 5);
    await historyDao.recordCooked(recipeId: 'chicken_soup_potato', rating: 5);

    // Record cooked dessert with rating 1 twice (>= 2 events per R8-02)
    await historyDao.recordCooked(recipeId: 'apple_bake', rating: 1);
    await historyDao.recordCooked(recipeId: 'apple_bake', rating: 1);

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    // Liked feature: Soups
    expect(find.textContaining('Супы'), findsOneWidget);
    // Disliked feature: Desserts
    expect(find.textContaining('Десерты'), findsOneWidget);
    // Top dish
    expect(find.text('Куриный суп с картошкой'), findsOneWidget);
  });

  testWidgets(
    'threshold rule (R8-02): 1 event is hidden, 2 events are displayed',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1 event for soup
      await historyDao.recordCooked(recipeId: 'chicken_soup_potato', rating: 5);
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // With 1 event, threshold >= 2 is not met: Супы should not appear
      expect(find.textContaining('Супы'), findsNothing);

      // Second event for soup
      await historyDao.recordCooked(recipeId: 'chicken_soup_potato', rating: 5);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Now with 2 events: Супы appears
      expect(find.textContaining('Супы'), findsOneWidget);
    },
  );

  testWidgets('qualitative strength words and explanation source (R8-02)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Record cooked soup twice with rating 5
    await historyDao.recordCooked(recipeId: 'chicken_soup_potato', rating: 5);
    await historyDao.recordCooked(recipeId: 'chicken_soup_potato', rating: 5);

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    // AppBar title is "Мои вкусы"
    expect(find.text('Мои вкусы'), findsOneWidget);
    // Subtitle is present
    expect(find.text('Что приложение знает о ваших вкусах'), findsOneWidget);

    // No raw numbers like "(+0.40)" or "(-0.11)"
    expect(find.textContaining('+0.'), findsNothing);
    expect(find.textContaining('-0.'), findsNothing);

    // Strength word present in chip label
    expect(find.textContaining('Супы ('), findsOneWidget);

    // Explanation under chip
    expect(find.textContaining('Куриный суп с картошкой'), findsAtLeast(1));

    // "Это не так" button is present
    expect(find.widgetWithText(TextButton, 'Это не так'), findsAtLeast(1));
  });

  testWidgets('button "Это не так" resets specific feature weight (R8-02)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Record cooked soup twice
    await historyDao.recordCooked(recipeId: 'chicken_soup_potato', rating: 5);
    await historyDao.recordCooked(recipeId: 'chicken_soup_potato', rating: 5);

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.textContaining('Супы'), findsOneWidget);

    // Tap "Это не так"
    await tester.tap(find.widgetWithText(TextButton, 'Это не так').first);
    await tester.pumpAndSettle();

    // Feature is removed
    expect(find.textContaining('Супы'), findsNothing);
    expect(find.text('Признак сброшен'), findsOneWidget);
  });

  test('auto-skip per D-050 does not change taste profile (R8-02)', () async {
    final now = DateTime(2026, 11, 4, 12, 0);

    // Calculate signal for auto_skip
    final autoSkipSignal = PreferenceService.calculateSignal(
      FeedbackKind.skipped,
      reason: 'auto_skip_past_date',
    );
    expect(autoSkipSignal, 0.0);

    // Explicit user skip has signal -0.2
    final userSkipSignal = PreferenceService.calculateSignal(
      FeedbackKind.skipped,
      reason: 'user_changed_dish',
    );
    expect(userSkipSignal, -0.2);

    // Verify profile weights before and after recording auto_skip event
    final initialProfile = await prefService.getProfile();
    await prefService.recordEvent(
      recipeId: 'chicken_soup_potato',
      kind: FeedbackKind.skipped,
      reason: 'auto_skip_past_date',
      at: now.millisecondsSinceEpoch,
    );
    final updatedProfile = await prefService.getProfile();

    expect(
      updatedProfile.dishTypeWeights,
      equals(initialProfile.dishTypeWeights),
    );
    expect(
      updatedProfile.ingredientWeights,
      equals(initialProfile.ingredientWeights),
    );
  });

  testWidgets('resets taste profile on confirmation dialog', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await historyDao.recordCooked(recipeId: 'chicken_soup_potato', rating: 5);
    await historyDao.recordCooked(recipeId: 'chicken_soup_potato', rating: 5);

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.textContaining('Супы'), findsOneWidget);

    // Tap reset button
    await tester.tap(find.text('Сбросить вкусы'));
    await tester.pumpAndSettle();

    expect(find.text('Сбросить вкусы?'), findsOneWidget);
    expect(
      find.text(
        'Все накопленные оценки и вкусовые предпочтения будут сброшены. Ваши аллергии и исключения сохранятся.',
      ),
      findsOneWidget,
    );

    // Confirm dialog
    await tester.tap(find.widgetWithText(FilledButton, 'Сбросить'));
    await tester.pumpAndSettle();

    // Weights are now cleared
    expect(
      find.text(
        'Пока нет данных о любимых вкусах. Оценивайте блюда после готовки!',
      ),
      findsOneWidget,
    );
    expect(find.text('Профиль вкусов сброшен'), findsOneWidget);
  });

  testWidgets('adds and removes allergies via quick-picks and chips', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.text('Аллергии не добавлены'), findsOneWidget);

    // Open add allergy sheet
    await tester.tap(find.text('Добавить аллергию'));
    await tester.pumpAndSettle();

    expect(find.text('Популярные'), findsOneWidget);
    // Tap "Орехи" quick-pick
    await tester.tap(find.text('Орехи'));
    await tester.pumpAndSettle();

    // Allergy added as chip "Орехи"
    expect(find.widgetWithText(InputChip, 'Орехи'), findsOneWidget);

    final profile = await prefService.getProfile();
    expect(profile.allergies, contains('nuts'));

    // Remove allergy by tapping delete icon on chip
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Аллергии не добавлены'), findsOneWidget);
    final updatedProfile = await prefService.getProfile();
    expect(updatedProfile.allergies, isEmpty);
  });

  testWidgets('adds and removes exclusions via search', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.text('Исключения не добавлены'), findsOneWidget);

    // Open add exclusion sheet
    await tester.tap(find.text('Добавить исключение'));
    await tester.pumpAndSettle();

    // Enter "грибы" in search
    await tester.enterText(find.byType(TextField), 'гриб');
    await tester.pumpAndSettle();

    // Tap found item "Грибы"
    await tester.tap(find.widgetWithText(ListTile, 'Грибы'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(InputChip, 'Грибы'), findsOneWidget);

    final profile = await prefService.getProfile();
    expect(profile.excludedIngredients, contains('mushrooms'));

    // Delete exclusion chip
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Исключения не добавлены'), findsOneWidget);
    final updatedProfile = await prefService.getProfile();
    expect(updatedProfile.excludedIngredients, isEmpty);
  });

  testWidgets('changes default servings setting', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    // Change servings to 4
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    final profile = await prefService.getProfile();
    expect(profile.servingsDefault, equals(4));
  });

  test('suggestionsProvider excludes recipes with user-configured allergies and exclusions (Scenario 5)', () async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        preferenceServiceProvider.overrideWithValue(prefService),
        historyDaoProvider.overrideWithValue(historyDao),
        pantryProvider.overrideWith(
          () => _TestPantryNotifier({
            'beet',
            'garlic',
            'walnut',
            'mayonnaise',
            'potato',
            'champignon',
            'carrot',
            'onion',
            'water',
            'oil',
            'salt',
            'sour_cream',
          }),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Initially with no allergies, beet salad and mushroom soup are suggested
    var suggestions = await container.read(suggestionsProvider.future);
    expect(
      suggestions.ready.any((m) => m.entry.recipe.id == 'beet_garlic'),
      isTrue,
    );
    expect(
      suggestions.ready.any((m) => m.entry.recipe.id == 'mushroom_soup'),
      isTrue,
    );

    // Add allergy "nuts" and exclusion "mushrooms"
    await prefService.setAllergies(['nuts']);
    await prefService.setExcludedIngredients(['mushrooms']);
    container.invalidate(preferenceProfileProvider);

    // Now suggestions MUST NOT contain beet salad (walnuts -> nuts) or mushroom soup (champignon -> mushrooms)
    suggestions = await container.read(suggestionsProvider.future);
    expect(
      suggestions.ready.any((m) => m.entry.recipe.id == 'beet_garlic'),
      isFalse,
    );
    expect(
      suggestions.ready.any((m) => m.entry.recipe.id == 'mushroom_soup'),
      isFalse,
    );
  });
}

class _TestPantryNotifier extends PantryNotifier {
  _TestPantryNotifier(this._initial);
  final Set<String> _initial;

  @override
  Future<Set<String>> build() async => _initial;
}
