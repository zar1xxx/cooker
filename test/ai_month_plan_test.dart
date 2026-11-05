import 'dart:convert';
import 'dart:io';

import 'package:chto_prigotovit/core/ai/ai_router.dart';
import 'package:chto_prigotovit/core/ai/ai_service.dart';
import 'package:chto_prigotovit/core/ai/recipe_validator.dart';
import 'package:chto_prigotovit/core/calendar/meal_planner.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/db/daos/ingredient_dao.dart';
import 'package:chto_prigotovit/core/db/daos/plan_dao.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePlanAiService extends AiService {
  FakePlanAiService({
    required super.router,
    required super.validator,
    super.db,
    this.planGenerator,
  });

  Future<List<AiPlanDay>?> Function(
    String from,
    String to,
    List<String> history,
  )?
  planGenerator;
  final List<List<String>> recordedHistories = [];

  @override
  Future<List<AiPlanDay>?> generatePlanWeek({
    required String dateFrom,
    required String dateTo,
    List<String> lockedDays = const [],
    List<String> history30d = const [],
    List<String> forbiddenIngredients = const [],
    List<String> likes = const [],
    List<String> dislikes = const [],
    Map<String, double>? dishTypeShares,
    bool soupsDisliked = false,
    Map<String, dynamic>? profile,
    Map<String, List<String>>? ingredientHierarchy,
    String? Function(String name)? resolveIngredientId,
    Map<String, List<String>>? forbiddenTerms,
  }) async {
    recordedHistories.add(List.from(history30d));
    if (planGenerator != null) {
      return planGenerator!(dateFrom, dateTo, history30d);
    }
    return null;
  }
}

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late RecipeDao recipeDao;
  late PlanDao planDao;
  late IngredientDao ingredientDao;
  late PreferenceService preferenceService;
  late HistoryDao historyDao;
  late MealPlanner mealPlanner;
  late RecipeValidator validator;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();

    recipeDao = RecipeDao(db);
    planDao = PlanDao(db);
    ingredientDao = IngredientDao(db);
    preferenceService = PreferenceService(db);
    historyDao = HistoryDao(db, preferenceService: preferenceService);
    validator = RecipeValidator(
      safetyMinimums: _loadJson('spec/ai/safety_minimums.json'),
    );

    mealPlanner = MealPlanner(
      recipeDao: recipeDao,
      planDao: planDao,
      ingredientDao: ingredientDao,
      preferenceService: preferenceService,
      historyDao: historyDao,
      db: db,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('AiMealPlanner (S5-03 / TZ 8.1)', () {
    test('valid AI week plan is accepted and scheduled', () async {
      final monday = DateTime(2026, 11, 2);
      final sunday = DateTime(2026, 11, 8);

      final fakeAi = FakePlanAiService(
        router: AiRouter(),
        validator: validator,
        db: db,
        planGenerator: (from, to, history) async => [
          const AiPlanDay(
            date: '2026-11-02',
            title: 'Борщ с говядиной',
            dishType: 'soup',
            difficulty: 'medium',
            mainIngredients: ['говядина', 'свёкла', 'капуста'],
            raw: {},
          ),
          const AiPlanDay(
            date: '2026-11-03',
            title: 'Гречка с курицей',
            dishType: 'main',
            difficulty: 'easy',
            mainIngredients: ['гречка', 'курица'],
            raw: {},
          ),
          const AiPlanDay(
            date: '2026-11-04',
            title: 'Котлеты домашние',
            dishType: 'main',
            difficulty: 'medium',
            mainIngredients: ['фарш', 'картофель'],
            raw: {},
          ),
          const AiPlanDay(
            date: '2026-11-05',
            title: 'Уха из рыбы',
            dishType: 'soup',
            difficulty: 'easy',
            mainIngredients: ['рыба', 'картофель'],
            raw: {},
          ),
          const AiPlanDay(
            date: '2026-11-06',
            title: 'Макароны по-флотски',
            dishType: 'main',
            difficulty: 'easy',
            mainIngredients: ['макароны', 'фарш'],
            raw: {},
          ),
          const AiPlanDay(
            date: '2026-11-07',
            title: 'Плов с курицей',
            dishType: 'main',
            difficulty: 'medium',
            mainIngredients: ['рис', 'курица'],
            raw: {},
          ),
          const AiPlanDay(
            date: '2026-11-08',
            title: 'Сырники из творога',
            dishType: 'breakfast',
            difficulty: 'easy',
            mainIngredients: ['творог', 'яйца'],
            raw: {},
          ),
        ],
      );

      final planned = await mealPlanner.generateMonthPlan(
        fromDate: monday,
        toDate: sunday,
        aiService: fakeAi,
      );

      expect(planned.length, 7);

      final entries = await planDao.getEntriesForRange(
        '2026-11-02',
        '2026-11-08',
      );
      expect(entries.length, 7);
      expect(entries.first.recipe?.title, contains('Борщ'));
      expect(entries[1].recipe?.title, contains('Гречка'));
    });

    test('Rule 2 violation (3 chicken days in a row) has 3rd day replaced by local choice', () async {
      final monday = DateTime(2026, 11, 2);
      final wednesday = DateTime(2026, 11, 4);

      final fakeAi = FakePlanAiService(
        router: AiRouter(),
        validator: validator,
        db: db,
        planGenerator: (from, to, history) async => [
          const AiPlanDay(
            date: '2026-11-02',
            title: 'Куриный суп',
            dishType: 'soup',
            difficulty: 'easy',
            mainIngredients: ['курица', 'морковь'],
            raw: {},
          ),
          const AiPlanDay(
            date: '2026-11-03',
            title: 'Курица запечённая',
            dishType: 'main',
            difficulty: 'medium',
            mainIngredients: ['курица', 'картофель'],
            raw: {},
          ),
          const AiPlanDay(
            date: '2026-11-04',
            title: 'Куриные котлеты', // 3rd consecutive chicken day -> violates Rule 2
            dishType: 'main',
            difficulty: 'medium',
            mainIngredients: ['курица'],
            raw: {},
          ),
        ],
      );

      await mealPlanner.generateMonthPlan(
        fromDate: monday,
        toDate: wednesday,
        aiService: fakeAi,
      );

      final entries = await planDao.getEntriesForRange(
        '2026-11-02',
        '2026-11-04',
      );
      expect(entries.length, 3);
      // Day 3 must NOT be "Куриные котлеты" because 3 days in a row with chicken is forbidden
      expect(entries[2].recipe?.title, isNot(equals('Куриные котлеты')));
      expect(entries[2].recipe?.title, isNotEmpty);
    });

    test('Rule 4 violation (consecutive hard dishes) has 2nd hard day replaced by local choice', () async {
      final monday = DateTime(2026, 11, 2);
      final tuesday = DateTime(2026, 11, 3);

      final fakeAi = FakePlanAiService(
        router: AiRouter(),
        validator: validator,
        db: db,
        planGenerator: (from, to, history) async => [
          const AiPlanDay(
            date: '2026-11-02',
            title: 'Сложный пирог',
            dishType: 'baking',
            difficulty: 'hard',
            mainIngredients: ['мука', 'яйца'],
            raw: {},
          ),
          const AiPlanDay(
            date: '2026-11-03',
            title: 'Сложное жаркое', // consecutive hard day -> violates Rule 4
            dishType: 'main',
            difficulty: 'hard',
            mainIngredients: ['говядина', 'картофель'],
            raw: {},
          ),
        ],
      );

      await mealPlanner.generateMonthPlan(
        fromDate: monday,
        toDate: tuesday,
        aiService: fakeAi,
      );

      final entries = await planDao.getEntriesForRange(
        '2026-11-02',
        '2026-11-03',
      );
      expect(entries.length, 2);
      // Tuesday must NOT be hard
      expect(entries[1].recipe?.difficulty, isNot(equals(Difficulty.hard)));
    });

    test(
      'AI proposal containing allergen is replaced with safe local choice',
      () async {
        await preferenceService.setAllergies(['walnut']);

        final monday = DateTime(2026, 11, 2);
        final mondayEnd = DateTime(2026, 11, 2);

        final fakeAi = FakePlanAiService(
          router: AiRouter(),
          validator: validator,
          db: db,
          planGenerator: (from, to, history) async => [
            const AiPlanDay(
              date: '2026-11-02',
              title: 'Ореховое печенье',
              dishType: 'dessert',
              difficulty: 'easy',
              mainIngredients: ['walnut', 'мука'],
              raw: {},
            ),
          ],
        );

        await mealPlanner.generateMonthPlan(
          fromDate: monday,
          toDate: mondayEnd,
          aiService: fakeAi,
        );

        final entries = await planDao.getEntriesForRange(
          '2026-11-02',
          '2026-11-02',
        );
        expect(entries.length, 1);
        expect(entries.first.recipe?.title, isNot(equals('Ореховое печенье')));
      },
    );

    test(
      'AI failure or offline smoothly generates entire plan from local catalog',
      () async {
        final monday = DateTime(2026, 11, 2);
        final sunday = DateTime(2026, 11, 8);

        final failingAi = FakePlanAiService(
          router: AiRouter(),
          validator: validator,
          db: db,
          planGenerator: (from, to, history) async => null, // AI fails
        );

        final planned = await mealPlanner.generateMonthPlan(
          fromDate: monday,
          toDate: sunday,
          aiService: failingAi,
        );

        expect(planned.length, 7);
        final entries = await planDao.getEntriesForRange(
          '2026-11-02',
          '2026-11-08',
        );
        expect(entries.length, 7);
        for (final e in entries) {
          expect(e.recipe, isNotNull);
        }
      },
    );

    test('locked day is preserved when AI generates week plan', () async {
      final monday = DateTime(2026, 11, 2);
      final sunday = DateTime(2026, 11, 8);

      // Lock Tuesday with specific recipe
      final allWithIng = await recipeDao.allWithIngredients();
      final lockedRecipe = allWithIng.firstWhere(
        (r) => r.recipe.dishType == DishType.soup,
      );

      await planDao.upsertEntry(
        date: '2026-11-03',
        recipeId: lockedRecipe.recipe.id,
        status: MealPlanStatus.planned,
        locked: true,
      );

      final fakeAi = FakePlanAiService(
        router: AiRouter(),
        validator: validator,
        db: db,
        planGenerator: (from, to, history) async => [
          const AiPlanDay(
            date: '2026-11-02',
            title: 'Понедельничный обед',
            dishType: 'main',
            difficulty: 'easy',
            mainIngredients: ['картофель'],
            raw: {},
          ),
          const AiPlanDay(
            date: '2026-11-03',
            title: 'AI вторник',
            dishType: 'main',
            difficulty: 'easy',
            mainIngredients: ['рис'],
            raw: {},
          ),
          const AiPlanDay(
            date: '2026-11-04',
            title: 'Среда обед',
            dishType: 'soup',
            difficulty: 'easy',
            mainIngredients: ['капуста'],
            raw: {},
          ),
        ],
      );

      await mealPlanner.generateMonthPlan(
        fromDate: monday,
        toDate: sunday,
        aiService: fakeAi,
      );

      final tuesday = await planDao.getEntryForDate('2026-11-03');
      expect(tuesday, isNotNull);
      expect(tuesday!.entry.locked, isTrue);
      expect(tuesday.entry.recipeId, lockedRecipe.recipe.id);
    });

    test(
      'subsequent weeks receive previous planned dishes in history30d',
      () async {
        final mondayW1 = DateTime(
          2026,
          11,
          2,
        ); // Week 1: Nov 2 - Nov 8 (Sunday)
        final sundayW2 = DateTime(2026, 11, 15); // Week 2: Nov 9 - Nov 15

        final fakeAi = FakePlanAiService(
          router: AiRouter(),
          validator: validator,
          db: db,
          planGenerator: (from, to, history) async {
            if (from.contains('11-02')) {
              return [
                const AiPlanDay(
                  date: '2026-11-02',
                  title: 'Фирменная солянка',
                  dishType: 'soup',
                  difficulty: 'medium',
                  mainIngredients: ['говядина'],
                  raw: {},
                ),
              ];
            } else {
              return [
                const AiPlanDay(
                  date: '2026-11-09',
                  title: 'Плов узбекский',
                  dishType: 'main',
                  difficulty: 'medium',
                  mainIngredients: ['рис', 'баранина'],
                  raw: {},
                ),
              ];
            }
          },
        );

        await mealPlanner.generateMonthPlan(
          fromDate: mondayW1,
          toDate: sundayW2,
          aiService: fakeAi,
        );

        // Verify that week 2 received week 1's planned dishes
        expect(fakeAi.recordedHistories.length, greaterThanOrEqualTo(2));
        final week2History = fakeAi.recordedHistories[1];
        expect(week2History, contains('Фирменная солянка'));
      },
    );
  });
}
