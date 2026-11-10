import 'package:chto_prigotovit/app/scaffold_with_nav_bar.dart';
import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/adaptive/adaptive_provider.dart';
import 'package:chto_prigotovit/core/adaptive/adaptive_spec.dart';
import 'package:chto_prigotovit/core/adaptive/ui_profile.dart';
import 'package:chto_prigotovit/core/catalog/catalog_taxonomy.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/db/daos/plan_dao.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/matching/recipe_matcher.dart';
import 'package:chto_prigotovit/core/matching/recipe_scorer.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/statistics/statistics_screen.dart';
import 'package:chto_prigotovit/features/suggestions/suggestions_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

ScoredRecipe _dummyScored(
  String id,
  String title, {
  DishType dishType = DishType.soup,
  Difficulty difficulty = Difficulty.easy,
  int totalMinutes = 20,
  int missingCount = 0,
  double tasteScore = 0.5,
}) {
  final recipe = Recipe(
    id: id,
    createdAt: 100,
    updatedAt: 100,
    title: title,
    normalizedTitle: title.toLowerCase(),
    dishType: dishType,
    dishGroup: DishGroup.fromDishType(dishType),
    difficulty: difficulty,
    cuisine: 'русская',
    totalMinutes: totalMinutes,
    activeMinutes: 10,
    servings: 2,
    description: '',
    source: RecipeSource.seed,
    fingerprint: id,
    isFavorite: false,
  );

  return ScoredRecipe(
    match: RecipeMatch(
      entry: RecipeWithIngredients(recipe: recipe, ingredients: const []),
      coverage: missingCount == 0 ? 1.0 : 0.6,
      missingIds: missingCount > 0 ? ['water'] : const [],
      missingNames: missingCount > 0 ? ['Вода'] : const [],
    ),
    scores: ScoreBreakdown(
      coverage: 1.0,
      taste: tasteScore,
      novelty: 1.0,
      fit: 1.0,
      explore: 0.5,
      total: 0.85,
    ),
  );
}

Widget _wrapWithAdaptive(
  Widget child, {
  required UiProfile profile,
  List<dynamic> overrides = const [],
}) {
  final spec = AdaptiveSpec(profile: profile, systemFontScale: 1.0);
  return ProviderScope(
    overrides: [
      uiProfileProvider.overrideWith(() => _FixedUiProfileNotifier(profile)),
      ...overrides.cast(),
    ],
    child: AdaptiveScope(
      spec: spec,
      child: MaterialApp(
        theme: AppTheme.lightFor(spec),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
}

class _FixedUiProfileNotifier extends UiProfileNotifier {
  _FixedUiProfileNotifier(this._initial);
  final UiProfile _initial;
  @override
  UiProfile build() => _initial;
}

class _FakePlanDao implements PlanDao {
  final List<String> addedRecipes = [];

  @override
  Future<MealPlanEntry> upsertEntry({
    required String date,
    required String recipeId,
    String mealSlot = 'main',
    MealPlanStatus status = MealPlanStatus.planned,
    bool locked = false,
  }) async {
    addedRecipes.add(recipeId);
    return MealPlanEntry(
      id: '1',
      recipeId: recipeId,
      date: date,
      mealSlot: mealSlot,
      status: status,
      locked: locked,
      createdAt: 0,
      updatedAt: 0,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHistoryDao implements HistoryDao {
  @override
  Future<HistoryMonthSummary> getMonthSummary({DateTime? month}) async {
    return HistoryMonthSummary(
      month: month ?? DateTime.now(),
      totalCooked: 10,
      newDishesCount: 4,
      topRatedRecipeTitle: 'Борщ',
      topRating: 4.8,
    );
  }

  @override
  Future<List<CookedEntryWithRecipe>> allWithRecipes({
    int? limit,
    int? offset,
  }) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return [
      CookedEntryWithRecipe(
        entry: CookedEntry(
          id: '1',
          createdAt: 0,
          updatedAt: 0,
          recipeId: 'borscht',
          cookedOn: today,
          rating: 5,
        ),
        recipe: const Recipe(
          id: 'borscht',
          createdAt: 0,
          updatedAt: 0,
          title: 'Борщ',
          normalizedTitle: 'борщ',
          description: 'Классический борщ',
          dishType: DishType.soup,
          dishGroup: DishGroup.soup,
          difficulty: Difficulty.medium,
          cuisine: 'русская',
          totalMinutes: 60,
          activeMinutes: 30,
          servings: 4,
          source: RecipeSource.seed,
          fingerprint: 'borscht',
          isFavorite: false,
        ),
      ),
      CookedEntryWithRecipe(
        entry: CookedEntry(
          id: '2',
          createdAt: 0,
          updatedAt: 0,
          recipeId: 'cutlets',
          cookedOn: today,
          rating: 5,
        ),
        recipe: const Recipe(
          id: 'cutlets',
          createdAt: 0,
          updatedAt: 0,
          title: 'Котлеты',
          normalizedTitle: 'котлеты',
          description: 'Домашние котлеты',
          dishType: DishType.main,
          dishGroup: DishGroup.meat,
          difficulty: Difficulty.easy,
          cuisine: 'русская',
          totalMinutes: 40,
          activeMinutes: 20,
          servings: 4,
          source: RecipeSource.seed,
          fingerprint: 'cutlets',
          isFavorite: false,
        ),
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('Full mode features (R8-18)', () {
    testWidgets('Suggestions shows search input and filters in Full mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ready = [
        _dummyScored('r1', 'Борщ домашний', totalMinutes: 45),
        _dummyScored('r2', 'Омлет с сыром', totalMinutes: 15),
      ];

      await tester.pumpWidget(
        _wrapWithAdaptive(
          const Scaffold(body: SuggestionsScreen()),
          profile: UiProfile.defaultFull(),
          overrides: [
            suggestionsProvider.overrideWith(
              (ref) => SuggestionsState(ready: ready, almostReady: const []),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // In Full mode, search input and filter chips exist
      expect(find.byKey(const Key('input_suggestions_search')), findsOneWidget);
      expect(find.byKey(const Key('chip_filter_fast')), findsOneWidget);
      expect(find.byKey(const Key('chip_filter_ready_only')), findsOneWidget);
      expect(find.byKey(const Key('select_sort_option')), findsOneWidget);

      // Search by query
      await tester.enterText(
        find.byKey(const Key('input_suggestions_search')),
        'Омлет',
      );
      await tester.pumpAndSettle();

      expect(find.text('Омлет с сыром'), findsOneWidget);
      expect(find.text('Борщ домашний'), findsNothing);

      // Clear search
      await tester.enterText(
        find.byKey(const Key('input_suggestions_search')),
        '',
      );
      await tester.pumpAndSettle();

      // Filter: До 30 мин
      await tester.tap(find.byKey(const Key('chip_filter_fast')));
      await tester.pumpAndSettle();

      expect(find.text('Омлет с сыром'), findsOneWidget);
      expect(find.text('Борщ домашний'), findsNothing);
    });

    testWidgets('Suggestions hides multi-filters in Simple mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ready = [_dummyScored('r1', 'Борщ домашний')];

      await tester.pumpWidget(
        _wrapWithAdaptive(
          const Scaffold(body: SuggestionsScreen()),
          profile: UiProfile.defaultSimple(),
          overrides: [
            suggestionsProvider.overrideWith(
              (ref) => SuggestionsState(ready: ready, almostReady: const []),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('input_suggestions_search')), findsNothing);
      expect(find.byKey(const Key('chip_filter_fast')), findsNothing);
      expect(find.byKey(const Key('select_sort_option')), findsNothing);
    });

    testWidgets('Card swiping in Full mode triggers actions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final fakePlanDao = _FakePlanDao();
      final ready = [_dummyScored('r1', 'Суп картофельный')];

      await tester.pumpWidget(
        _wrapWithAdaptive(
          const Scaffold(body: SuggestionsScreen()),
          profile: UiProfile.defaultFull(),
          overrides: [
            planDaoProvider.overrideWithValue(fakePlanDao),
            suggestionsProvider.overrideWith(
              (ref) => SuggestionsState(ready: ready, almostReady: const []),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final dismissibleFinder = find.byKey(const ValueKey('swipe_recipe_r1'));
      expect(dismissibleFinder, findsOneWidget);

      // Swipe right: adds to calendar
      await tester.drag(dismissibleFinder, const Offset(400, 0));
      await tester.pumpAndSettle();

      expect(fakePlanDao.addedRecipes, contains('r1'));
      expect(
        find.text('«Суп картофельный» добавлено в календарь'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Statistics screen shows 4 tiles in Simple mode vs details in Full mode',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeHistoryDao = _FakeHistoryDao();

        // Simple mode
        await tester.pumpWidget(
          _wrapWithAdaptive(
            const StatisticsScreen(),
            profile: UiProfile.defaultSimple(),
            overrides: [historyDaoProvider.overrideWithValue(fakeHistoryDao)],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('tile_total_cooked')), findsOneWidget);
        expect(find.byKey(const Key('tile_new_dishes')), findsOneWidget);
        expect(find.byKey(const Key('tile_favorite_dish')), findsOneWidget);
        expect(find.byKey(const Key('tile_top_rating')), findsOneWidget);
        expect(find.text('По разделам меню'), findsNothing);
        expect(find.text('Помощник ИИ'), findsNothing);

        // Full mode
        await tester.pumpWidget(
          _wrapWithAdaptive(
            const StatisticsScreen(),
            profile: UiProfile.defaultFull(),
            overrides: [historyDaoProvider.overrideWithValue(fakeHistoryDao)],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('tile_total_cooked')), findsOneWidget);
        expect(find.text('По разделам меню'), findsOneWidget);
        expect(find.text('Помощник ИИ'), findsOneWidget);
        expect(find.text('Супы'), findsOneWidget);
        expect(find.text('Вторые блюда'), findsOneWidget);
      },
    );

    testWidgets(
      'ScaffoldWithNavBar displays 4 tabs in Simple mode and 5 in Full mode',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/today',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) {
                return ScaffoldWithNavBar(navigationShell: navigationShell);
              },
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/today',
                      builder: (context, state) => const Text('Today Content'),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/pantry',
                      builder: (context, state) => const Text('Pantry Content'),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/calendar',
                      builder: (context, state) =>
                          const Text('Calendar Content'),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/history',
                      builder: (context, state) =>
                          const Text('History Content'),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/stats',
                      builder: (context, state) => const Text('Stats Content'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        // Test Simple Mode: 4 destinations
        final simpleProfile = UiProfile.defaultSimple();
        final simpleSpec = AdaptiveSpec(
          profile: simpleProfile,
          systemFontScale: 1.0,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              uiProfileProvider.overrideWith(
                () => _FixedUiProfileNotifier(simpleProfile),
              ),
            ],
            child: AdaptiveScope(
              spec: simpleSpec,
              child: MaterialApp.router(
                routerConfig: router,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Сегодня'), findsOneWidget);
        expect(find.text('Продукты'), findsOneWidget);
        expect(find.text('Календарь'), findsOneWidget);
        expect(find.text('История'), findsOneWidget);
        expect(find.text('Статистика'), findsNothing);

        // Test Full Mode: 5 destinations
        final fullProfile = UiProfile.defaultFull();
        final fullSpec = AdaptiveSpec(
          profile: fullProfile,
          systemFontScale: 1.0,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              uiProfileProvider.overrideWith(
                () => _FixedUiProfileNotifier(fullProfile),
              ),
            ],
            child: AdaptiveScope(
              spec: fullSpec,
              child: MaterialApp.router(
                routerConfig: router,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Сегодня'), findsOneWidget);
        expect(find.text('Статистика'), findsOneWidget);
      },
    );
  });
}
