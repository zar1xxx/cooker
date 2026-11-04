import 'package:chto_prigotovit/core/calendar/meal_planner.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/db/daos/ingredient_dao.dart';
import 'package:chto_prigotovit/core/db/daos/plan_dao.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late RecipeDao recipeDao;
  late PlanDao planDao;
  late IngredientDao ingredientDao;
  late PreferenceService preferenceService;
  late HistoryDao historyDao;
  late MealPlanner mealPlanner;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();

    recipeDao = RecipeDao(db);
    planDao = PlanDao(db);
    ingredientDao = IngredientDao(db);
    preferenceService = PreferenceService(db);
    historyDao = HistoryDao(db, preferenceService: preferenceService);

    mealPlanner = MealPlanner(
      recipeDao: recipeDao,
      planDao: planDao,
      ingredientDao: ingredientDao,
      preferenceService: preferenceService,
      historyDao: historyDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('MealPlanner (S5-02 / TZ 8.1)', () {
    test('generates month plan satisfying all 5 rotation rules', () async {
      final fixedStart = DateTime(2026, 11, 2); // Monday
      final fixedEnd = DateTime(2026, 11, 29); // 4 full weeks (28 days)

      await withClock(Clock.fixed(fixedStart), () async {
        final entries = await mealPlanner.generateMonthPlan(
          fromDate: fixedStart,
          toDate: fixedEnd,
        );

        expect(entries.length, 28);

        // Fetch full schedule with recipes
        final scheduledEntries = await planDao.getEntriesForRange(
          PlanDao.formatDate(fixedStart),
          PlanDao.formatDate(fixedEnd),
        );
        expect(scheduledEntries.length, 28);

        final allWithIng = await recipeDao.allWithIngredients();
        final byId = {for (final r in allWithIng) r.recipe.id: r};

        final schedule = [
          for (final item in scheduledEntries)
            ScheduledDay(
              date: DateTime.parse(item.entry.date),
              recipe: byId[item.entry.recipeId]!,
              locked: item.entry.locked,
            ),
        ];

        final profile = await preferenceService.getProfile();
        final hierarchy = await ingredientDao.hierarchy();

        // Validate complete schedule against all rules
        final validation = mealPlanner.validatePlan(
          schedule,
          profile: profile,
          hierarchy: hierarchy,
        );

        expect(
          validation.isValid,
          isTrue,
          reason:
              'Generated plan must have 0 violations: ${validation.violations}',
        );
        expect(validation.violations, isEmpty);
      });
    });

    test('locked day survives plan regeneration intact', () async {
      final fixedStart = DateTime(2026, 11, 2);
      final fixedEnd = DateTime(2026, 11, 15); // 2 weeks

      await withClock(Clock.fixed(fixedStart), () async {
        // Lock Saturday Nov 7 to borscht
        final lockedDate = '2026-11-07';
        await planDao.upsertEntry(
          date: lockedDate,
          recipeId: 'borscht',
          status: MealPlanStatus.planned,
          locked: true,
        );

        final entries = await mealPlanner.generateMonthPlan(
          fromDate: fixedStart,
          toDate: fixedEnd,
        );

        expect(entries.length, 14);

        final saturdayEntry = await planDao.getEntryForDate(lockedDate);
        expect(saturdayEntry, isNotNull);
        expect(saturdayEntry!.entry.recipeId, 'borscht');
        expect(saturdayEntry.entry.locked, isTrue);
      });
    });

    test(
      'respects allergies and rating 1 exclusions in planned schedule',
      () async {
        final fixedStart = DateTime(2026, 11, 2);
        final fixedEnd = DateTime(2026, 11, 15);

        await withClock(Clock.fixed(fixedStart), () async {
          // Exclude mushrooms
          await preferenceService.setExcludedIngredients(['mushrooms']);

          // Rate borscht with 1 in history
          await historyDao.recordCooked(
            recipeId: 'borscht',
            rating: 1,
            date: fixedStart.subtract(const Duration(days: 5)),
          );

          final entries = await mealPlanner.generateMonthPlan(
            fromDate: fixedStart,
            toDate: fixedEnd,
          );

          final scheduledRecipeIds = entries.map((e) => e.recipeId).toSet();

          // Borscht must not be scheduled
          expect(scheduledRecipeIds.contains('borscht'), isFalse);

          // Mushroom soup must not be scheduled
          expect(scheduledRecipeIds.contains('mushroom_soup'), isFalse);
        });
      },
    );

    test('validatePlan correctly detects Rule 1, 2, 4 violations', () async {
      final allWithIng = await recipeDao.allWithIngredients();
      final borscht = allWithIng.firstWhere((r) => r.recipe.id == 'borscht');
      final chickenSoup = allWithIng.firstWhere(
        (r) => r.recipe.id == 'chicken_soup_potato',
      );
      final hierarchy = await ingredientDao.hierarchy();

      // Artificial schedule with violations
      final badSchedule = [
        // Rule 1 violation: borscht on day 1 and day 5 (< 14 days)
        ScheduledDay(date: DateTime(2026, 11, 2), recipe: borscht),
        ScheduledDay(date: DateTime(2026, 11, 3), recipe: chickenSoup),
        ScheduledDay(date: DateTime(2026, 11, 4), recipe: chickenSoup),
        // Rule 2 violation: chicken soup 3 days in a row (Nov 3, 4, 5)
        ScheduledDay(date: DateTime(2026, 11, 5), recipe: chickenSoup),
        ScheduledDay(date: DateTime(2026, 11, 6), recipe: borscht),
      ];

      final validation = mealPlanner.validatePlan(
        badSchedule,
        hierarchy: hierarchy,
      );

      expect(validation.isValid, isFalse);

      final rule1Violations = validation.violations
          .where((v) => v.ruleNumber == 1)
          .toList();
      expect(rule1Violations.isNotEmpty, isTrue);

      final rule2Violations = validation.violations
          .where((v) => v.ruleNumber == 2)
          .toList();
      expect(rule2Violations.isNotEmpty, isTrue);
    });
  });
}
