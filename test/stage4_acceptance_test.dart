import 'package:chto_prigotovit/core/ai/recipe_validator.dart';
import 'package:chto_prigotovit/core/backup/backup_service.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/db/daos/ingredient_dao.dart';
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

class _TestPantryNotifier extends PantryNotifier {
  _TestPantryNotifier(this._initial);
  final Set<String> _initial;

  @override
  Future<Set<String>> build() async => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PreferenceService prefService;
  late HistoryDao historyDao;
  late RecipeDao recipeDao;
  late BackupService backupService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();
    prefService = PreferenceService(db);
    historyDao = HistoryDao(db, preferenceService: prefService);
    recipeDao = RecipeDao(db);
    backupService = BackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Stage 4 Acceptance Tests (S4-06 / TZ 10, 11 Scenario 5)', () {
    test('Criterion 1: Three soups on 5, two desserts on 2 -> w(soup) > 0 > w(dessert) and lifts soups in ranking', () async {
      final fixedNow = DateTime(2026, 11, 4, 12, 0);

      await withClock(Clock.fixed(fixedNow), () async {
        // Three soups cooked with rating 5
        await historyDao.recordCooked(
          recipeId: 'chicken_soup_potato',
          rating: 5,
          date: fixedNow,
        );
        await historyDao.recordCooked(
          recipeId: 'borscht',
          rating: 5,
          date: fixedNow.subtract(const Duration(days: 1)),
        );
        await historyDao.recordCooked(
          recipeId: 'pea_soup',
          rating: 5,
          date: fixedNow.subtract(const Duration(days: 2)),
        );

        // Two desserts cooked with rating 2
        await historyDao.recordCooked(
          recipeId: 'apple_bake',
          rating: 2,
          date: fixedNow.subtract(const Duration(days: 3)),
        );
        await historyDao.recordCooked(
          recipeId: 'cottage_cheese_apple',
          rating: 2,
          date: fixedNow.subtract(const Duration(days: 4)),
        );

        // Check calculated weights in preference profile
        final profile = await prefService.getProfile();
        final wSoup = profile.dishTypeWeights['soup'];
        final wDessert = profile.dishTypeWeights['dessert'];

        expect(wSoup, isNotNull);
        expect(wDessert, isNotNull);
        expect(wSoup! > 0, isTrue, reason: 'w(soup) must be strictly positive');
        expect(
          wDessert! < 0,
          reason: 'w(dessert) must be strictly negative',
          isTrue,
        );
        expect(
          wSoup > wDessert,
          reason: 'w(soup) must be greater than w(dessert)',
          isTrue,
        );

        // Test ranking: soup vs dessert with identical 100% coverage
        final soupDetail = await recipeDao.getRecipeDetail(
          'chicken_soup_potato',
        );
        final dessertDetail = await recipeDao.getRecipeDetail('apple_bake');

        expect(soupDetail, isNotNull);
        expect(dessertDetail, isNotNull);

        final soupMatch = RecipeMatch(
          entry: RecipeWithIngredients(
            recipe: soupDetail!.recipe,
            ingredients: soupDetail.ingredients,
          ),
          coverage: 1.0,
          missingIds: const [],
          missingNames: const [],
        );

        final dessertMatch = RecipeMatch(
          entry: RecipeWithIngredients(
            recipe: dessertDetail!.recipe,
            ingredients: dessertDetail.ingredients,
          ),
          coverage: 1.0,
          missingIds: const [],
          missingNames: const [],
        );

        final recipeRatings = await historyDao.getAverageRatingsByRecipe();
        final scorer = RecipeScorer.withProfile(
          profile,
          recipeRatings: recipeRatings,
        );

        final ranked = scorer.rank([dessertMatch, soupMatch]);
        expect(
          ranked.first.entry.recipe.dishType,
          equals(DishType.soup),
          reason:
              'Soup must be ranked higher than dessert due to taste component',
        );
      });
    });

    test('Criterion 2: Dish with rating 1 is never suggested', () async {
      final fixedNow = DateTime(2026, 11, 4, 12, 0);

      await withClock(Clock.fixed(fixedNow), () async {
        // Record baked apples with rating 1 (disliked)
        await historyDao.recordCooked(
          recipeId: 'apple_bake',
          rating: 1,
          date: fixedNow,
        );

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            preferenceServiceProvider.overrideWithValue(prefService),
            historyDaoProvider.overrideWithValue(historyDao),
            pantryProvider.overrideWith(
              () => _TestPantryNotifier({'apple', 'honey', 'walnut'}),
            ),
          ],
        );
        addTearDown(container.dispose);

        final suggestions = await container.read(suggestionsProvider.future);

        // Verify apple_bake is in neither ready nor almostReady
        final inReady = suggestions.ready.any(
          (m) => m.entry.recipe.id == 'apple_bake',
        );
        final inAlmost = suggestions.almostReady.any(
          (m) => m.entry.recipe.id == 'apple_bake',
        );

        expect(
          inReady,
          isFalse,
          reason: 'Dish with rating 1 must not appear in ready suggestions',
        );
        expect(
          inAlmost,
          isFalse,
          reason:
              'Dish with rating 1 must not appear in almostReady suggestions',
        );
      });
    });

    test('Criterion 3: Export -> clean install -> Import restores history, recipes, and preferences completely', () async {
      final fixedNow = DateTime(2026, 11, 4, 12, 0);

      await withClock(Clock.fixed(fixedNow), () async {
        // 1. Create manual user recipe
        await historyDao.addManualEntry(
          title: 'Бабушкины оладьи',
          dishType: DishType.baking,
          difficulty: Difficulty.easy,
          rating: 5,
          note: 'Пышные и сладкие',
          date: fixedNow,
        );

        // 2. Add curated recipe history
        await historyDao.recordCooked(
          recipeId: 'borscht',
          rating: 5,
          wouldRepeat: true,
          note: 'Настоящий красный борщ',
          date: fixedNow.subtract(const Duration(days: 1)),
        );
        await historyDao.recordCooked(
          recipeId: 'chicken_soup_potato',
          rating: 4,
          wouldRepeat: true,
          note: 'Обычный суп',
          date: fixedNow.subtract(const Duration(days: 2)),
        );

        // 3. Configure preferences
        await prefService.setAllergies(['nuts', 'fish']);
        await prefService.setExcludedIngredients(['cilantro']);
        await prefService.setServingsDefault(4);
        await prefService.recalculateProfile();

        // 4. Export database
        final backupJson = await backupService.exportBackupJson();
        expect(backupJson, isNotEmpty);

        // Verify zero secrets/passwords exist in JSON (Rule 7)
        expect(backupJson.toLowerCase().contains('gigachat'), isFalse);
        expect(backupJson.toLowerCase().contains('secret'), isFalse);
        expect(backupJson.toLowerCase().contains('token'), isFalse);

        // 5. Clean installation simulation on clean database
        final cleanDb = AppDatabase(NativeDatabase.memory(), seed: true);
        await cleanDb.customSelect('SELECT 1').get();
        final cleanBackup = BackupService(cleanDb);
        final cleanPref = PreferenceService(cleanDb);
        final cleanHistory = HistoryDao(cleanDb, preferenceService: cleanPref);

        try {
          // Confirm clean DB has 0 history entries
          expect(await cleanHistory.allWithRecipes(), isEmpty);

          // Import backup
          final summary = await cleanBackup.importBackupJson(backupJson);
          expect(summary.cookedEntries, 3);
          expect(summary.recipes, greaterThanOrEqualTo(1));

          // Verify full history restored
          final restoredHistory = await cleanHistory.allWithRecipes();
          expect(restoredHistory.length, 3);

          // Verify user recipe restored
          final userRecipeEntry = restoredHistory.firstWhere(
            (e) => e.recipe?.title == 'Бабушкины оладьи',
          );
          expect(userRecipeEntry.recipe!.source, RecipeSource.user);
          expect(userRecipeEntry.entry.rating, 5);
          expect(userRecipeEntry.entry.note, 'Пышные и сладкие');

          // Verify curated recipe history
          final borschtEntry = restoredHistory.firstWhere(
            (e) => e.entry.recipeId == 'borscht',
          );
          expect(borschtEntry.entry.rating, 5);
          expect(borschtEntry.entry.wouldRepeat, isTrue);
          expect(borschtEntry.entry.note, 'Настоящий красный борщ');

          // Verify preferences restored
          final restoredProfile = await cleanPref.getProfile();
          expect(restoredProfile.allergies, containsAll(['nuts', 'fish']));
          expect(restoredProfile.excludedIngredients, contains('cilantro'));
          expect(restoredProfile.servingsDefault, 4);
          expect(restoredProfile.dishTypeWeights.isNotEmpty, isTrue);
        } finally {
          await cleanDb.close();
        }
      });
    });

    test('Criterion 4: Scenario 5 (End-to-End Safety and Preferences)', () async {
      final fixedNow = DateTime(2026, 11, 4, 12, 0);

      await withClock(Clock.fixed(fixedNow), () async {
        // 1. Add allergy "nuts" and exclude "mushrooms"
        await prefService.setAllergies(['nuts']);
        await prefService.setExcludedIngredients(['mushrooms']);

        // 2. Rate dessert with 1
        await historyDao.recordCooked(
          recipeId: 'apple_bake',
          rating: 1,
          date: fixedNow,
        );

        // 3. Verify in compressed profile that desserts went down
        final compressed = await prefService.getCompressedProfile();
        final dislikedKeys = compressed.topDislikedFeatures
            .map((e) => e.key)
            .toList();
        expect(
          dislikedKeys.contains('dessert'),
          isTrue,
          reason: 'Dessert must appear in disliked features after rating 1',
        );

        // 4. Query suggestions with full pantry
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
                'champignon',
                'potato',
                'carrot',
                'onion',
                'water',
                'oil',
                'salt',
                'sour_cream',
                'apple',
                'honey',
              }),
            ),
          ],
        );
        addTearDown(container.dispose);

        final suggestions = await container.read(suggestionsProvider.future);
        final allSuggestedIds = [
          ...suggestions.ready.map((m) => m.entry.recipe.id),
          ...suggestions.almostReady.map((m) => m.entry.recipe.id),
        ];

        // Expected: No nuts (beet_garlic contains walnut -> child of nuts)
        expect(
          allSuggestedIds.contains('beet_garlic'),
          isFalse,
          reason: 'Salad with walnuts must be excluded due to nuts allergy',
        );

        // Expected: No mushrooms (mushroom_soup contains champignon -> child of mushrooms)
        expect(
          allSuggestedIds.contains('mushroom_soup'),
          isFalse,
          reason:
              'Soup with mushrooms must be excluded due to mushrooms exclusion',
        );

        // Expected: Dessert with rating 1 does not appear
        expect(
          allSuggestedIds.contains('apple_bake'),
          isFalse,
          reason: 'Dessert with rating 1 must not appear in suggestions',
        );

        // 5. Verify AI RecipeValidator also enforces this per ТЗ 9.1
        final validator = await RecipeValidator.fromAsset();
        final hierarchy = await refDaoHierarchy(db);

        // AI recipe with walnut should be Rejected
        final walnutAiRecipe = {
          'title': 'Ореховое печенье',
          'dish_type': 'dessert',
          'difficulty': 'easy',
          'total_minutes': 30,
          'ingredients': [
            {'name': 'грецкие орехи', 'amount': 100, 'unit': 'g'},
            {'name': 'мука', 'amount': 200, 'unit': 'g'},
          ],
          'steps': [
            {'text': 'Измельчите грецкие орехи.'},
            {'text': 'Выпекайте 20 минут.', 'timer_seconds': 1200},
          ],
        };

        final validation = validator.validate(
          walnutAiRecipe,
          profile: {
            'allergies': ['nuts'],
            'excluded_ingredients': ['mushrooms'],
          },
          ingredientHierarchy: hierarchy,
          resolveIngredientId: (name) =>
              name == 'грецкие орехи' ? 'walnut' : 'flour',
        );

        expect(
          validation,
          isA<Rejected>(),
          reason:
              'AI recipe containing descendant of allergen must be Rejected',
        );
      });
    });
  });
}

Future<Map<String, List<String>>> refDaoHierarchy(AppDatabase db) async {
  final dao = IngredientDao(db);
  return dao.hierarchy();
}
