import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/matching/recipe_matcher.dart';
import 'package:chto_prigotovit/core/matching/recipe_scorer.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
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

  group('Taste in scoring and compressed profile in prompts (S4-03 / TZ 5.3 & 6.4)', () {
    test(
      'RecipeScorer.withProfile maps taste profile weights to 0..1 range',
      () {
        const profile = TasteProfile(
          dishTypeWeights: {'soup': 0.5, 'dessert': -0.4},
          difficultyWeights: {},
          cuisineWeights: {},
          ingredientWeights: {},
          excludedIngredients: [],
          allergies: [],
        );

        final scorer = RecipeScorer.withProfile(
          profile,
          recipeRatings: {'custom_rated_recipe': 5.0},
        );

        const soupRecipe = Recipe(
          id: 'test_soup',
          createdAt: 0,
          updatedAt: 0,
          title: 'Тестовый суп',
          normalizedTitle: 'тестовый суп',
          dishType: DishType.soup,
          difficulty: Difficulty.easy,
          cuisine: 'русская',
          totalMinutes: 30,
          activeMinutes: 15,
          servings: 2,
          description: '',
          source: RecipeSource.seed,
          fingerprint: 'soup:',
          isFavorite: false,
        );

        const dessertRecipe = Recipe(
          id: 'test_dessert',
          createdAt: 0,
          updatedAt: 0,
          title: 'Тестовый десерт',
          normalizedTitle: 'тестовый десерт',
          dishType: DishType.dessert,
          difficulty: Difficulty.easy,
          cuisine: 'русская',
          totalMinutes: 30,
          activeMinutes: 15,
          servings: 2,
          description: '',
          source: RecipeSource.seed,
          fingerprint: 'dessert:',
          isFavorite: false,
        );

        const ratedRecipe = Recipe(
          id: 'custom_rated_recipe',
          createdAt: 0,
          updatedAt: 0,
          title: 'Оценённый рецепт',
          normalizedTitle: 'оцененный рецепт',
          dishType: DishType.main,
          difficulty: Difficulty.easy,
          cuisine: 'русская',
          totalMinutes: 30,
          activeMinutes: 15,
          servings: 2,
          description: '',
          source: RecipeSource.seed,
          fingerprint: 'main:',
          isFavorite: false,
        );

        const soupMatch = RecipeMatch(
          entry: RecipeWithIngredients(recipe: soupRecipe, ingredients: []),
          coverage: 1.0,
          missingIds: [],
          missingNames: [],
        );
        const dessertMatch = RecipeMatch(
          entry: RecipeWithIngredients(recipe: dessertRecipe, ingredients: []),
          coverage: 1.0,
          missingIds: [],
          missingNames: [],
        );
        const ratedMatch = RecipeMatch(
          entry: RecipeWithIngredients(recipe: ratedRecipe, ingredients: []),
          coverage: 1.0,
          missingIds: [],
          missingNames: [],
        );

        final soupScored = scorer.score(soupMatch);
        final dessertScored = scorer.score(dessertMatch);
        final ratedScored = scorer.score(ratedMatch);

        // soup w=0.5 -> taste=(0.5+1)/2 = 0.75
        expect(soupScored.scores.taste, closeTo(0.75, 0.01));

        // dessert w=-0.4 -> taste=(-0.4+1)/2 = 0.30
        expect(dessertScored.scores.taste, closeTo(0.30, 0.01));

        // direct rating 5 -> taste=1.0
        expect(ratedScored.scores.taste, closeTo(1.0, 0.01));

        expect(soupScored.total, greaterThan(dessertScored.total));
      },
    );

    test(
      'disliked recipe with rating 1 is excluded from suggestions',
      () async {
        final now = DateTime(2026, 11, 4, 12, 0);

        await withClock(Clock.fixed(now), () async {
          // Record rating 1 for chicken_soup_potato
          await historyDao.recordCooked(
            recipeId: 'chicken_soup_potato',
            rating: 1,
            date: now,
          );

          final dislikedIds = await historyDao.getDislikedRecipeIds();
          expect(dislikedIds.contains('chicken_soup_potato'), isTrue);
        });
      },
    );

    test(
      'suggestionsProvider uses preference profile and lifts preferred dishes',
      () async {
        final now = DateTime(2026, 11, 4, 12, 0);

        await withClock(Clock.fixed(now), () async {
          // Record 3 soup cooked events with rating 5
          await historyDao.recordCooked(
            recipeId: 'chicken_soup_potato',
            rating: 5,
            date: now,
          );
          await historyDao.recordCooked(
            recipeId: 'chicken_soup_potato',
            rating: 5,
            date: now,
          );
          await historyDao.recordCooked(
            recipeId: 'chicken_soup_potato',
            rating: 5,
            date: now,
          );

          final container = ProviderContainer(
            overrides: [
              databaseProvider.overrideWithValue(db),
              pantryProvider.overrideWith(
                () => _TestPantryNotifier({
                  'chicken',
                  'potato',
                  'onion',
                  'carrot',
                  'flour',
                  'sugar',
                  'egg',
                  'butter',
                }),
              ),
            ],
          );

          final suggestions = await container.read(suggestionsProvider.future);
          expect(suggestions.ready.isNotEmpty, isTrue);

          // Chicken soup should be at the top of suggestions
          final topRecipe = suggestions.ready.first.entry.recipe;
          expect(topRecipe.dishType, DishType.soup);
          expect(suggestions.ready.first.scores.taste, greaterThan(0.5));
        });
      },
    );
  });
}

class _TestPantryNotifier extends PantryNotifier {
  _TestPantryNotifier(this._initial);
  final Set<String> _initial;

  @override
  Future<Set<String>> build() async => _initial;
}
