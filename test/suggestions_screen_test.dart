import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/catalog/catalog_taxonomy.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/matching/recipe_matcher.dart';
import 'package:chto_prigotovit/core/matching/recipe_scorer.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/suggestions/suggestions_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ScoredRecipe _dummyScored(
  String id,
  String title, {
  DishType dishType = DishType.soup,
  Difficulty difficulty = Difficulty.easy,
  int totalMinutes = 30,
  int missingCount = 0,
  List<String> missingNames = const [],
  RecipeSource source = RecipeSource.seed,
}) {
  final recipe = Recipe(
    id: id,
    createdAt: 0,
    updatedAt: 0,
    title: title,
    normalizedTitle: title.toLowerCase(),
    dishType: dishType,
    dishGroup: DishGroup.fromDishType(dishType),
    difficulty: difficulty,
    cuisine: 'русская',
    totalMinutes: totalMinutes,
    activeMinutes: 15,
    servings: 2,
    description: '',
    source: source,
    fingerprint: id,
    isFavorite: false,
  );

  return ScoredRecipe(
    match: RecipeMatch(
      entry: RecipeWithIngredients(recipe: recipe, ingredients: const []),
      coverage: missingCount == 0 ? 1.0 : 0.6,
      missingIds: missingNames,
      missingNames: missingNames,
    ),
    scores: const ScoreBreakdown(
      coverage: 1.0,
      taste: 0.5,
      novelty: 1.0,
      fit: 1.0,
      explore: 0.5,
      total: 0.85,
    ),
  );
}

Widget _createSuggestionsWidget({
  required List<ScoredRecipe> ready,
  required List<ScoredRecipe> almostReady,
}) {
  return ProviderScope(
    overrides: [
      suggestionsProvider.overrideWith(
        (ref) => SuggestionsState(ready: ready, almostReady: almostReady),
      ),
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
      home: const SuggestionsScreen(),
    ),
  );
}

void main() {
  group('SuggestionsScreen (S1-07 / TZ 5.2, 5.4, 7.2)', () {
    testWidgets('renders filter chips and two sections with cards', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ready = [
        _dummyScored(
          'soup_1',
          'Борщ сибирский',
          dishType: DishType.soup,
          difficulty: Difficulty.easy,
          totalMinutes: 45,
        ),
      ];
      final almost = [
        _dummyScored(
          'main_1',
          'Жаркое с грибами',
          dishType: DishType.main,
          difficulty: Difficulty.medium,
          totalMinutes: 60,
          missingCount: 1,
          missingNames: ['Грибы'],
        ),
      ];

      await tester.pumpWidget(
        _createSuggestionsWidget(ready: ready, almostReady: almost),
      );
      await tester.pumpAndSettle();

      // Filter chips
      expect(find.text('Все типы'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Суп'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Второе'), findsOneWidget);
      expect(find.text('Любая сложность'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Легко'), findsOneWidget);

      // Section titles
      expect(find.text('Можно приготовить сейчас'), findsOneWidget);
      expect(find.text('Не хватает 1–2 продуктов'), findsOneWidget);

      // Card 1
      expect(find.text('Борщ сибирский'), findsOneWidget);
      expect(find.text('45 мин'), findsOneWidget);

      // Card 2
      expect(find.text('Жаркое с грибами'), findsOneWidget);
      expect(find.text('Не хватает: Грибы'), findsOneWidget);
      expect(find.text('60 мин'), findsOneWidget);

      // Action buttons
      expect(find.text('Не хочу'), findsNWidgets(2));
      expect(find.text('Открыть рецепт'), findsNWidgets(2));
    });

    testWidgets('filter chips filter displayed dishes', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ready = [
        _dummyScored('soup_1', 'Куриный суп', dishType: DishType.soup),
        _dummyScored('main_1', 'Котлеты домашние', dishType: DishType.main),
      ];

      await tester.pumpWidget(
        _createSuggestionsWidget(ready: ready, almostReady: const []),
      );
      await tester.pumpAndSettle();

      expect(find.text('Куриный суп'), findsOneWidget);
      expect(find.text('Котлеты домашние'), findsOneWidget);

      // Tap filter "Суп"
      await tester.tap(find.widgetWithText(FilterChip, 'Суп'));
      await tester.pumpAndSettle();

      expect(find.text('Куриный суп'), findsOneWidget);
      expect(find.text('Котлеты домашние'), findsNothing);

      // Tap filter "Все типы" to reset
      await tester.tap(find.widgetWithText(FilterChip, 'Все типы'));
      await tester.pumpAndSettle();

      expect(find.text('Куриный суп'), findsOneWidget);
      expect(find.text('Котлеты домашние'), findsOneWidget);
    });

    testWidgets('rejecting a dish hides it and allows undo', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ready = [
        _dummyScored('soup_1', 'Борщ домашний', dishType: DishType.soup),
      ];

      await tester.pumpWidget(
        _createSuggestionsWidget(ready: ready, almostReady: const []),
      );
      await tester.pumpAndSettle();

      expect(find.text('Борщ домашний'), findsOneWidget);

      // Tap "Не хочу"
      await tester.tap(find.text('Не хочу'));
      await tester.pumpAndSettle();

      // Card is hidden
      expect(find.text('Борщ домашний'), findsNothing);
      expect(find.text('Блюдо скрыто'), findsOneWidget);
      expect(find.text('Отменить'), findsOneWidget);

      // Tap "Отменить"
      await tester.tap(find.text('Отменить'));
      await tester.pumpAndSettle();

      // Card is restored
      expect(find.text('Борщ домашний'), findsOneWidget);
    });
  });
}
