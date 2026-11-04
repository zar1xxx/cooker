import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
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

    // Record cooked soup with rating 5
    await historyDao.recordCooked(recipeId: 'chicken_soup_potato', rating: 5);

    // Record cooked dessert with rating 1
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

  testWidgets('resets taste profile on confirmation dialog', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

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
