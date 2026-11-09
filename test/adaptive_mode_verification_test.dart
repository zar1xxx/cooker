import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/adaptive/adaptive_provider.dart';
import 'package:chto_prigotovit/core/adaptive/adaptive_spec.dart';
import 'package:chto_prigotovit/core/adaptive/ui_profile.dart';
import 'package:chto_prigotovit/core/adaptive/ui_profile_service.dart';
import 'package:chto_prigotovit/core/catalog/catalog_taxonomy.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/plan_dao.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/matching/recipe_matcher.dart';
import 'package:chto_prigotovit/core/matching/recipe_scorer.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/settings/appearance_settings_screen.dart';
import 'package:chto_prigotovit/features/settings/mode_onboarding_screen.dart';
import 'package:chto_prigotovit/features/suggestions/suggestions_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ScoredRecipe _dummyScored(
  String id,
  String title, {
  DishType dishType = DishType.soup,
  Difficulty difficulty = Difficulty.easy,
  int totalMinutes = 25,
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
      coverage: 1.0,
      missingIds: const [],
      missingNames: const [],
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

class _FixedUiProfileNotifier extends UiProfileNotifier {
  _FixedUiProfileNotifier(this._initial);
  final UiProfile _initial;
  @override
  UiProfile build() => _initial;
}

class _FakePlanDao implements PlanDao {
  final List<String> added = [];

  @override
  Future<MealPlanEntry> upsertEntry({
    required String date,
    required String recipeId,
    String mealSlot = 'main',
    MealPlanStatus status = MealPlanStatus.planned,
    bool locked = false,
  }) async {
    added.add(recipeId);
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

class _FakePreferenceService implements PreferenceService {
  final List<String> recordedRejections = [];

  @override
  Future<TasteProfile> recordEvent({
    required String? recipeId,
    required FeedbackKind kind,
    String? reason,
    int? at,
  }) async {
    if (recipeId != null) recordedRejections.add(recipeId);
    return const TasteProfile(
      dishTypeWeights: {},
      difficultyWeights: {},
      cuisineWeights: {},
      ingredientWeights: {},
      excludedIngredients: [],
      allergies: [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('Adaptive Mode Verification (R8-19 / D-057)', () {
    testWidgets(
      'FullOnly elements are absent in Simple mode and present in Full mode',
      (tester) async {
        const simpleSpec = AdaptiveSpec.defaultSimple;
        const fullSpec = AdaptiveSpec.defaultFull;

        // Simple mode
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightFor(simpleSpec),
            home: const AdaptiveScope(
              spec: simpleSpec,
              child: Scaffold(
                body: Column(
                  children: [
                    FullOnly(child: Text('FullModeExclusiveWidget')),
                    SimpleOnly(child: Text('SimpleModeExclusiveWidget')),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('FullModeExclusiveWidget'), findsNothing);
        expect(find.text('SimpleModeExclusiveWidget'), findsOneWidget);

        // Full mode
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightFor(fullSpec),
            home: const AdaptiveScope(
              spec: fullSpec,
              child: Scaffold(
                body: Column(
                  children: [
                    FullOnly(child: Text('FullModeExclusiveWidget')),
                    SimpleOnly(child: Text('SimpleModeExclusiveWidget')),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('FullModeExclusiveWidget'), findsOneWidget);
        expect(find.text('SimpleModeExclusiveWidget'), findsNothing);
      },
    );

    testWidgets('Scenario S8-11: First launch mode onboarding selection', (
      tester,
    ) async {
      final service = UiProfileService();
      final container = ProviderContainer(
        overrides: [uiProfileServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AdaptiveScope(
            spec: AdaptiveSpec.defaultSimple,
            child: MaterialApp(
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: ModeOnboardingScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check cards exist
      expect(find.text('Просто и крупно'), findsOneWidget);
      expect(find.text('Все возможности'), findsOneWidget);
      expect(find.text('Решу потом'), findsOneWidget);

      // Select "Все возможности"
      await tester.tap(find.text('Все возможности'));
      await tester.pumpAndSettle();

      // Tap "Выбрать этот режим"
      await tester.ensureVisible(find.text('Выбрать этот режим'));
      await tester.tap(find.text('Выбрать этот режим'));
      await tester.pumpAndSettle();

      // Verified: mode is full and onboarding is complete
      expect(container.read(uiProfileProvider).mode, UiMode.full);
      expect(container.read(uiProfileProvider).hasCompletedOnboarding, isTrue);
    });

    testWidgets(
      'Scenario S8-12: Mode toggle in Appearance Settings switches immediately',
      (tester) async {
        final service = UiProfileService();
        final container = ProviderContainer(
          overrides: [uiProfileServiceProvider.overrideWithValue(service)],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const AdaptiveScope(
              spec: AdaptiveSpec.defaultSimple,
              child: MaterialApp(
                localizationsDelegates: [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: AppearanceSettingsScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Starts in Simple
        expect(container.read(uiProfileProvider).mode, UiMode.simple);

        // Tap "Все возможности"
        await tester.tap(find.text('Все возможности'));
        await tester.pumpAndSettle();

        // Switches immediately to Full mode
        expect(container.read(uiProfileProvider).mode, UiMode.full);

        // Tap "Просто и крупно"
        await tester.tap(find.text('Просто и крупно'));
        await tester.pumpAndSettle();

        // Switches immediately back to Simple mode
        expect(container.read(uiProfileProvider).mode, UiMode.simple);
      },
    );

    testWidgets(
      'Scenario S8-13: Full mode multiple filters, sorting, and swipe with undo',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakePlanDao = _FakePlanDao();
        final fakePrefService = _FakePreferenceService();
        final ready = [
          _dummyScored('r1', 'Борщ мясной', totalMinutes: 50),
          _dummyScored('r2', 'Омлет с зеленью', totalMinutes: 15),
        ];

        final fullProfile = UiProfile.defaultFull();
        final spec = AdaptiveSpec(profile: fullProfile, systemFontScale: 1.0);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              uiProfileProvider.overrideWith(
                () => _FixedUiProfileNotifier(fullProfile),
              ),
              planDaoProvider.overrideWithValue(fakePlanDao),
              preferenceServiceProvider.overrideWithValue(fakePrefService),
              suggestionsProvider.overrideWith(
                (ref) => SuggestionsState(ready: ready, almostReady: const []),
              ),
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
                home: const Scaffold(body: SuggestionsScreen()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Check multi-filters present
        expect(
          find.byKey(const Key('input_suggestions_search')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('chip_filter_fast')), findsOneWidget);
        expect(find.byKey(const Key('select_sort_option')), findsOneWidget);

        // 2. Filter: "До 30 мин"
        await tester.tap(find.byKey(const Key('chip_filter_fast')));
        await tester.pumpAndSettle();

        expect(find.text('Омлет с зеленью'), findsOneWidget);
        expect(find.text('Борщ мясной'), findsNothing);

        // Untap filter
        await tester.tap(find.byKey(const Key('chip_filter_fast')));
        await tester.pumpAndSettle();

        expect(find.text('Борщ мясной'), findsOneWidget);

        // 3. Swipe left to dismiss with undo
        final cardFinder = find.byKey(const ValueKey('swipe_recipe_r2'));
        expect(cardFinder, findsOneWidget);

        // Swipe left
        await tester.drag(cardFinder, const Offset(-400, 0));
        await tester.pumpAndSettle();

        // Preference recorded
        expect(fakePrefService.recordedRejections, contains('r2'));

        // Undo SnackBar visible
        expect(find.text('Отменить'), findsOneWidget);

        // Tap Undo
        await tester.tap(find.text('Отменить'));
        await tester.pumpAndSettle();

        // Restored!
        expect(find.text('Омлет с зеленью'), findsOneWidget);
      },
    );
  });
}
