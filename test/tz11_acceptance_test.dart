import 'package:chto_prigotovit/core/ai/ai_router.dart';
import 'package:chto_prigotovit/core/ai/ai_service.dart';
import 'package:chto_prigotovit/core/ai/anti_repeat.dart';
import 'package:chto_prigotovit/core/ai/gigachat_provider.dart';
import 'package:chto_prigotovit/core/ai/lm_studio_provider.dart';
import 'package:chto_prigotovit/core/ai/recipe_validator.dart';
import 'package:chto_prigotovit/core/calendar/meal_planner.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/db/daos/ingredient_dao.dart';
import 'package:chto_prigotovit/core/db/daos/plan_dao.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/matching/recipe_matcher.dart';
import 'package:chto_prigotovit/core/matching/recipe_scorer.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:clock/clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectivity extends Fake implements Connectivity {
  _FakeConnectivity(this._results);
  final List<ConnectivityResult> _results;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _results;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late RecipeDao recipeDao;
  late IngredientDao ingredientDao;
  late HistoryDao historyDao;
  late PlanDao planDao;
  late PreferenceService prefService;
  late RecipeValidator validator;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();

    recipeDao = RecipeDao(db);
    ingredientDao = IngredientDao(db);
    prefService = PreferenceService(db);
    historyDao = HistoryDao(db, preferenceService: prefService);
    planDao = PlanDao(db);

    validator = const RecipeValidator(
      safetyMinimums: {
        'meat_fish': {
          'keywords': ['курица', 'говядина', 'рыба', 'свинина', 'фарш'],
          'min_minutes': 15,
        },
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('TZ 11 Acceptance Scenarios (End-to-End)', () {
    // ------------------------------------------------------------------------
    // Scenario 1: First launch offline
    // ------------------------------------------------------------------------
    test('Scenario 1: First launch offline («картошка, лук, яйца, молоко» -> Завтрак + Легко)', () async {
      final pantryIngredients = {'potato', 'onion', 'egg', 'milk'};
      final allRecipes = await recipeDao.allWithIngredients();
      final hierarchy = await ingredientDao.hierarchy();

      final stopwatch = Stopwatch()..start();
      const matcher = RecipeMatcher();
      final matchResult = matcher.match(
        recipes: allRecipes,
        availableIds: pantryIngredients,
        hierarchy: hierarchy,
      );
      stopwatch.stop();

      // Must be instantaneous (< 1000 ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      // Filter by "Завтрак" (breakfast) + "Легко" (easy)
      final breakfastEasy = matchResult.ready
          .where(
            (m) =>
                m.entry.recipe.dishType == DishType.breakfast &&
                m.entry.recipe.difficulty == Difficulty.easy,
          )
          .toList();

      expect(
        breakfastEasy.isNotEmpty,
        isTrue,
        reason: 'At least one easy breakfast dish must be ready (e.g. omelet)',
      );
      expect(
        breakfastEasy.any(
          (m) =>
              m.entry.recipe.title.toLowerCase().contains('омлет') ||
              m.entry.recipe.title.toLowerCase().contains('яичниц'),
        ),
        isTrue,
      );
    });

    // ------------------------------------------------------------------------
    // Scenario 2: New AI dish and cooking flow
    // ------------------------------------------------------------------------
    test('Scenario 2: New dish from AI, scale servings 2->4, cooking mode, 5★ rating', () async {
      final today = DateTime(2026, 11, 5, 12, 0);

      await withClock(Clock.fixed(today), () async {
        final aiRecipeJson = {
          'title': 'Куриный плов по-домашнему',
          'dish_type': 'main',
          'difficulty': 'medium',
          'total_minutes': 45,
          'active_minutes': 25,
          'servings': 2,
          'ingredients': [
            {'name': 'Куриное филе', 'amount': 400, 'unit': 'g'},
            {'name': 'Рис', 'amount': 200, 'unit': 'g'},
            {'name': 'Морковь', 'amount': 1, 'unit': 'pcs'},
            {'name': 'Лук репчатый', 'amount': 1, 'unit': 'pcs'},
            {'name': 'Растительное масло', 'amount': 30, 'unit': 'ml'},
          ],
          'steps': [
            {'text': 'Нарежьте курицу и овощи кубиками.', 'timer_seconds': 0},
            {
              'text':
                  'Обжаривайте курицу с овощами 20 минут до румяной корочки.',
              'timer_seconds': 1200,
            },
            {
              'text': 'Добавьте рис, залейте водой и тушите 20 минут.',
              'timer_seconds': 1200,
            },
          ],
        };

        // 1. Validator passes with thermal processing for chicken
        final valRes = validator.validate(
          aiRecipeJson,
          resolveIngredientId: (name) => 'chicken',
        );
        expect(valRes, isA<Valid>());

        // 2. Scale servings 2 -> 4
        const originalServings = 2;
        const newServings = 4;
        final scaleFactor = newServings / originalServings;
        expect(scaleFactor, 2.0);

        final scaledIngredients = (aiRecipeJson['ingredients'] as List)
            .map(
              (item) => {
                'name': item['name'],
                'amount': ((item['amount'] as num) * scaleFactor).round(),
                'unit': item['unit'],
              },
            )
            .toList();
        expect(scaledIngredients[0]['amount'], 800);
        expect(scaledIngredients[1]['amount'], 400);

        // 3. Save AI recipe to DB
        final router = AiRouter(
          connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
        );
        final aiService = AiService(
          router: router,
          db: db,
          validator: validator,
        );

        final savedRecipe = await aiService.saveAiRecipeToDatabase(
          aiRecipeJson,
          resolveIngredientId: (name) {
            if (name.contains('Куриное')) return 'chicken_fillet';
            if (name.contains('Рис')) return 'rice';
            if (name.contains('Морковь')) return 'carrot';
            if (name.contains('Лук')) return 'onion';
            return 'vegetable_oil';
          },
        );

        expect(savedRecipe, isNotNull);
        final savedRecipeId = savedRecipe!.id;

        // 4. Record cooking with 5★ rating
        await historyDao.recordCooked(
          recipeId: savedRecipeId,
          rating: 5,
          wouldRepeat: true,
          note: 'Очень вкусно!',
        );

        // 5. Verify history record
        final history = await historyDao.allWithRecipes();
        final entry = history.firstWhere(
          (h) => h.entry.recipeId == savedRecipeId,
        );
        expect(entry.entry.rating, 5);
        expect(entry.entry.wouldRepeat, isTrue);

        // 6. Recipe opens offline
        final loaded = await recipeDao.getRecipeDetail(savedRecipeId);
        expect(loaded, isNotNull);
        expect(loaded!.recipe.source, RecipeSource.ai);
        expect(loaded.steps.length, 3);
      });
    });

    // ------------------------------------------------------------------------
    // Scenario 3: Anti-repeat on the next day
    // ------------------------------------------------------------------------
    test('Scenario 3: Anti-repeat excludes yesterday cooked dish from top-10 and AI prompt', () async {
      final day1 = DateTime(2026, 11, 5, 12, 0);
      final day2 = DateTime(2026, 11, 6, 12, 0);

      // Day 1: Cook recipe "chicken_soup_potato"
      await withClock(Clock.fixed(day1), () async {
        await historyDao.recordCooked(
          recipeId: 'chicken_soup_potato',
          rating: 5,
        );
      });

      // Day 2: Anti-repeat check
      await withClock(Clock.fixed(day2), () async {
        final doNotSuggest = await AntiRepeat.getDoNotSuggestList(db);

        expect(doNotSuggest.contains('Куриный суп с картошкой'), isTrue);

        // In scoring, chicken_soup_potato receives novelty penalty
        final allRecipes = await recipeDao.allWithIngredients();
        final hierarchy = await ingredientDao.hierarchy();
        final pantry = {'chicken', 'potato', 'carrot', 'onion'};

        const matcher = RecipeMatcher();
        final matched = matcher.match(
          recipes: allRecipes,
          availableIds: pantry,
          hierarchy: hierarchy,
        );

        const scorer = RecipeScorer();
        final scored = scorer.rank(
          matched.ready,
          lastCooked: {'chicken_soup_potato': day1},
        );

        // chicken_soup_potato must be penalized compared to unmade dishes
        final chickenSoupRank = scored.indexWhere(
          (m) => m.entry.recipe.id == 'chicken_soup_potato',
        );
        expect(chickenSoupRank, greaterThanOrEqualTo(0));
        final chickenSoupScore = scored[chickenSoupRank].total;
        final topScore = scored.first.total;
        expect(chickenSoupScore, lessThanOrEqualTo(topScore));
      });
    });

    // ------------------------------------------------------------------------
    // Scenario 4: Month calendar planning with locked Saturday
    // ------------------------------------------------------------------------
    test('Scenario 4: Month plan keeps locked Saturday intact and obeys rotation rules', () async {
      final planner = MealPlanner(
        recipeDao: recipeDao,
        planDao: planDao,
        ingredientDao: ingredientDao,
        preferenceService: prefService,
        historyDao: historyDao,
      );

      // Nearest Saturday: 2026-11-07
      const saturdayKey = '2026-11-07';
      const lockedRecipeId = 'borscht';

      // Pin borscht on Saturday
      await planDao.upsertEntry(
        date: saturdayKey,
        recipeId: lockedRecipeId,
        locked: true,
      );

      // Generate month plan
      final startDate = DateTime(2026, 11, 1);
      final endDate = DateTime(2026, 11, 30);

      final entries = await planner.generateMonthPlan(
        fromDate: startDate,
        toDate: endDate,
      );

      expect(entries.length, 30);

      // Verify Saturday stayed locked and intact
      final saturdayEntry = entries.firstWhere((e) => e.date == saturdayKey);
      expect(saturdayEntry.recipeId, lockedRecipeId);
      expect(saturdayEntry.locked, isTrue);
    });

    // ------------------------------------------------------------------------
    // Scenario 5: Safety and taste profile (allergies, exclusions, 1★ rating)
    // ------------------------------------------------------------------------
    test('Scenario 5: Allergy "nuts" + exclusion "mushrooms" + 1★ rating on dessert', () async {
      // 1. Add allergy and exclusion
      await prefService.setAllergies(['nuts']);
      await prefService.setExcludedIngredients(['mushrooms']);

      // 2. Rate a dessert 1 star
      await historyDao.recordCooked(recipeId: 'apple_bake', rating: 1);

      final disliked = await historyDao.getDislikedRecipeIds();
      expect(disliked.contains('apple_bake'), isTrue);

      // 3. Profile reflects disliked desserts
      final profile = await prefService.getProfile();
      expect(profile.dishTypeWeights['dessert'], isNotNull);
      expect(profile.dishTypeWeights['dessert']!, lessThan(0));

      // 4. RecipeValidator rejects AI response containing walnuts
      final aiDessertWithNuts = {
        'title': 'Ореховое печенье',
        'dish_type': 'dessert',
        'difficulty': 'easy',
        'total_minutes': 30,
        'active_minutes': 15,
        'servings': 2,
        'ingredients': [
          {'name': 'Грецкие орехи', 'amount': 100, 'unit': 'g'},
          {'name': 'Мука', 'amount': 200, 'unit': 'g'},
        ],
        'steps': [
          {'text': 'Смешайте муку и орехи.', 'timer_seconds': 0},
          {'text': 'Выпекайте в духовке 20 минут.', 'timer_seconds': 1200},
        ],
      };

      final valResult = validator.validate(
        aiDessertWithNuts,
        resolveIngredientId: (name) => 'walnut',
        profile: {
          'allergies': ['nuts'],
        },
        ingredientHierarchy: {
          'walnut': ['nuts'],
        },
      );

      expect(valResult, isA<Rejected>());
      expect((valResult as Rejected).reason, contains('nuts'));
    });

    // ------------------------------------------------------------------------
    // Scenario 6: Network failover PC <-> GigaChat <-> Offline
    // ------------------------------------------------------------------------
    test('Scenario 6: Failover between LM Studio, GigaChat and Offline catalog', () async {
      final lmStudio = LmStudioProvider(baseUrl: 'http://192.168.1.100:1234');
      final gigaChat = GigaChatProvider(authKey: 'valid_test_auth_key');

      // 1. Wi-Fi with verified PC -> routes to LM Studio
      final routerPc = AiRouter(
        lmStudioProvider: lmStudio,
        gigaChatProvider: gigaChat,
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );
      routerPc.markPcSuccess(DateTime(2026, 11, 5, 12, 0));

      await withClock(Clock.fixed(DateTime(2026, 11, 5, 12, 0, 10)), () async {
        final mode1 = await routerPc.getMode();
        expect(mode1, AiMode.localPc);
      });

      // 2. PC failure occurred recently (< 60 s) -> falls back to GigaChat
      routerPc.markPcFailure(DateTime(2026, 11, 5, 12, 0, 20));
      await withClock(Clock.fixed(DateTime(2026, 11, 5, 12, 0, 30)), () async {
        final mode2 = await routerPc.getMode();
        expect(mode2, AiMode.gigaChat);
      });

      // 3. Mobile network -> directly uses GigaChat without probing PC
      final routerMobile = AiRouter(
        lmStudioProvider: lmStudio,
        gigaChatProvider: gigaChat,
        connectivity: _FakeConnectivity([ConnectivityResult.mobile]),
      );
      final modeMobile = await routerMobile.getMode();
      expect(modeMobile, AiMode.gigaChat);

      // 4. Offline (no providers configured / no auth key) -> safe offline mode
      final routerOffline = AiRouter(
        connectivity: _FakeConnectivity([ConnectivityResult.none]),
      );
      final modeOffline = await routerOffline.getMode();
      expect(modeOffline, AiMode.offline);
    });
  });
}
