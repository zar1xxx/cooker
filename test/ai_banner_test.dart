import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/ai/ai_failure.dart';
import 'package:chto_prigotovit/core/ai/ai_service.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/ingredient_dao.dart';
import 'package:drift/native.dart';
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

ScoredRecipe _dummyScored(String id, String title) {
  final recipe = Recipe(
    id: id,
    createdAt: 0,
    updatedAt: 0,
    title: title,
    normalizedTitle: title.toLowerCase(),
    dishType: DishType.soup,
    difficulty: Difficulty.easy,
    cuisine: 'русская',
    totalMinutes: 30,
    activeMinutes: 15,
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

void main() {
  group('R3-02: AI Failure Banners on SuggestionsScreen', () {
    testWidgets(
      'renders "Помощник не настроен" banner when AI is not configured',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final ready = [_dummyScored('soup_1', 'Борщ')];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              suggestionsProvider.overrideWith(
                (ref) => SuggestionsState(ready: ready, almostReady: const []),
              ),
              aiDishesProvider.overrideWith(
                () => _FakeAiDishesNotifier(
                  const AiResult.failure(AiFailure.notConfigured()),
                ),
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
          ),
        );
        await tester.pumpAndSettle();

        // Catalog dish is visible
        expect(find.text('Борщ'), findsOneWidget);

        // Not configured banner is displayed under the catalog
        expect(
          find.byKey(const Key('ai_not_configured_banner')),
          findsOneWidget,
        );
        expect(find.text('Помощник не настроен'), findsOneWidget);
        expect(find.byKey(const Key('btn_configure_ai')), findsOneWidget);
        expect(find.text('Настроить'), findsOneWidget);

        // Settings gear in AppBar
        expect(find.byKey(const Key('btn_ai_settings_appbar')), findsOneWidget);
      },
    );

    testWidgets(
      'renders "Помощник сейчас не отвечает" banner with retry button on network error',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final ready = [_dummyScored('soup_1', 'Борщ')];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              suggestionsProvider.overrideWith(
                (ref) => SuggestionsState(ready: ready, almostReady: const []),
              ),
              aiDishesProvider.overrideWith(
                () => _FakeAiDishesNotifier(
                  const AiResult.failure(AiFailure.pcNotFound()),
                ),
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
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ai_error_banner')), findsOneWidget);
        expect(find.text('Помощник сейчас не отвечает'), findsOneWidget);
        expect(find.text('Компьютер не найден в сети'), findsOneWidget);
        expect(find.byKey(const Key('btn_retry_ai')), findsOneWidget);
        expect(find.text('Повторить'), findsOneWidget);
        expect(find.byKey(const Key('btn_ai_banner_settings')), findsOneWidget);
      },
    );

    testWidgets(
      'R5-03: shows "Компьютер долго отвечает" banner with retry button on timeout',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final ready = [_dummyScored('soup_1', 'Борщ')];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              suggestionsProvider.overrideWith(
                (ref) => SuggestionsState(ready: ready, almostReady: const []),
              ),
              aiDishesProvider.overrideWith(
                () => _FakeAiDishesNotifier(
                  const AiResult.failure(AiFailure.timeout()),
                ),
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
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ai_error_banner')), findsOneWidget);
        expect(find.text('Компьютер долго отвечает'), findsOneWidget);
        expect(find.byKey(const Key('btn_retry_ai')), findsOneWidget);
        expect(find.text('Повторить'), findsOneWidget);
      },
    );

    testWidgets('tapping AI dish opens error dialog when fullRecipe fails', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const aiDish = AiDishSuggestion(
        title: 'Пирожки с капустой',
        dishType: 'pastry',
        difficulty: 'medium',
        totalMinutes: 45,
        mainIngredients: ['мука', 'капуста'],
        missing: [],
        why: 'Очень вкусно',
        raw: {},
      );

      final ready = [_dummyScored('soup_1', 'Борщ')];
      final db = AppDatabase(NativeDatabase.memory(), seed: false);
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            suggestionsProvider.overrideWith(
              (ref) => SuggestionsState(ready: ready, almostReady: const []),
            ),
            aiDishesProvider.overrideWith(
              () => _FakeAiDishesNotifier(const AiResult.success([aiDish])),
            ),
            aiServiceProvider.overrideWith((ref) async => _FakeAiService()),
            pantryProvider.overrideWith(_FakePantryNotifier.new),
            ingredientDaoProvider.overrideWithValue(_FakeIngredientDao()),
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
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Пирожки с капустой'), findsOneWidget);

      // Tap the AI dish card
      await tester.tap(find.text('Пирожки с капустой'));
      await tester.pumpAndSettle();

      // The error dialog is shown with clear message and dismiss button
      expect(find.text('Не удалось загрузить рецепт'), findsOneWidget);
      expect(find.textContaining('Превышено время ожидания'), findsOneWidget);
      expect(find.text('Понятно'), findsOneWidget);

      // Tap dismiss button
      await tester.tap(find.text('Понятно'));
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить рецепт'), findsNothing);
    });
  });
}

class _FakeAiService extends Fake implements AiService {
  @override
  Future<AiResult<Map<String, dynamic>>> fullRecipe({
    required String title,
    required String dishType,
    required String difficulty,
    required List<String> mainIngredients,
    required List<String> availableIngredients,
    int servings = 2,
    List<String> forbiddenIngredients = const [],
    Map<String, dynamic>? profile,
    Map<String, List<String>>? ingredientHierarchy,
    String? Function(String name)? resolveIngredientId,
    Map<String, List<String>>? forbiddenTerms,
  }) async {
    return const AiResult.failure(AiFailure.timeout());
  }
}

class _FakePantryNotifier extends PantryNotifier {
  @override
  Future<Set<String>> build() async => const {'flour'};
}

class _FakeIngredientDao extends Fake implements IngredientDao {
  @override
  Future<List<Ingredient>> byIds(Iterable<String> ids) async => const [];
}

class _FakeAiDishesNotifier extends AiDishesNotifier {
  _FakeAiDishesNotifier(this._initialResult);
  final AiResult<List<AiDishSuggestion>> _initialResult;

  @override
  Future<AiResult<List<AiDishSuggestion>>> build() async => _initialResult;
}
