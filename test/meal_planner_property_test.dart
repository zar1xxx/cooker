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
import 'package:chto_prigotovit/core/matching/diversity_reorderer.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

class _FakePlanAiService extends AiService {
  _FakePlanAiService({
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
    if (planGenerator != null) {
      return planGenerator!(dateFrom, dateTo, history30d);
    }

    final fromDt = DateTime.parse(dateFrom);
    final toDt = DateTime.parse(dateTo);
    final daysCount = toDt.difference(fromDt).inDays + 1;

    final templates = [
      const AiPlanDay(
        date: '',
        title: 'Борщ с говядиной',
        dishType: 'soup',
        difficulty: 'medium',
        mainIngredients: ['свекла', 'капуста'],
        raw: {},
      ),
      const AiPlanDay(
        date: '',
        title: 'Гречневая каша',
        dishType: 'main',
        difficulty: 'easy',
        mainIngredients: ['гречка', 'сливочное_масло'],
        raw: {},
      ),
      const AiPlanDay(
        date: '',
        title: 'Куриное филе на пару',
        dishType: 'main',
        difficulty: 'easy',
        mainIngredients: ['курица', 'морковь'],
        raw: {},
      ),
      const AiPlanDay(
        date: '',
        title: 'Щи со свежей капустой',
        dishType: 'soup',
        difficulty: 'medium',
        mainIngredients: ['капуста', 'картофель'],
        raw: {},
      ),
      const AiPlanDay(
        date: '',
        title: 'Овощной салат',
        dishType: 'salad',
        difficulty: 'easy',
        mainIngredients: ['огурец', 'помидор'],
        raw: {},
      ),
      const AiPlanDay(
        date: '',
        title: 'Сырники из творога',
        dishType: 'breakfast',
        difficulty: 'easy',
        mainIngredients: ['творог', 'яйца'],
        raw: {},
      ),
      const AiPlanDay(
        date: '',
        title: 'Рыба запеченная',
        dishType: 'main',
        difficulty: 'medium',
        mainIngredients: ['рыба', 'лимон'],
        raw: {},
      ),
    ];

    final result = <AiPlanDay>[];
    for (var i = 0; i < daysCount; i++) {
      final curDate = fromDt.add(Duration(days: i));
      final tmpl = templates[i % templates.length];
      result.add(
        AiPlanDay(
          date: PlanDao.formatDate(curDate),
          title: tmpl.title,
          dishType: tmpl.dishType,
          difficulty: tmpl.difficulty,
          mainIngredients: tmpl.mainIngredients,
          raw: const {},
        ),
      );
    }
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MealPlanner Property Verification (S5-06 / TZ 8.1, 11)', () {
    const diversity = RecipeDiversityReorderer();

    final testScenarios = <_PropertyTestSpec>[
      _PropertyTestSpec(
        id: 1,
        title: 'November 2026 (30 days, starts Sunday) - default profile, pure local',
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 30),
      ),
      _PropertyTestSpec(
        id: 2,
        title: 'December 2026 (31 days, starts Tuesday) - default profile, pure local',
        start: DateTime(2026, 12, 1),
        end: DateTime(2026, 12, 31),
      ),
      _PropertyTestSpec(
        id: 3,
        title: 'January 2027 (31 days, starts Friday) - 1 pre-locked Saturday dish',
        start: DateTime(2027, 1, 1),
        end: DateTime(2027, 1, 31),
        prepare: (ctx) async {
          await ctx.planDao.upsertEntry(
            date: '2027-01-09',
            recipeId: 'borscht',
            status: MealPlanStatus.planned,
            locked: true,
          );
        },
      ),
      _PropertyTestSpec(
        id: 4,
        title: 'February 2027 (28 days non-leap, starts Monday) - 4 full 7-day weeks',
        start: DateTime(2027, 2, 1),
        end: DateTime(2027, 2, 28),
      ),
      _PropertyTestSpec(
        id: 5,
        title: 'February 2028 (29 days leap year, starts Tuesday) - leap year February',
        start: DateTime(2028, 2, 1),
        end: DateTime(2028, 2, 29),
      ),
      _PropertyTestSpec(
        id: 6,
        title: 'March 2027 (31 days) - soup disliked in profile (Rule 3 exception)',
        start: DateTime(2027, 3, 1),
        end: DateTime(2027, 3, 31),
        prepare: (ctx) async {
          // Negative feedback for soup to bring weight < -0.3
          for (var i = 0; i < 4; i++) {
            await ctx.prefService.recordEvent(
              recipeId: 'borscht',
              kind: FeedbackKind.cooked,
              reason: 'rating:1',
            );
          }
        },
      ),
      _PropertyTestSpec(
        id: 7,
        title: 'April 2027 (30 days) - soup loved in profile (weight > 0.5)',
        start: DateTime(2027, 4, 1),
        end: DateTime(2027, 4, 30),
        prepare: (ctx) async {
          for (var i = 0; i < 3; i++) {
            await ctx.prefService.recordEvent(
              recipeId: 'borscht',
              kind: FeedbackKind.cooked,
              reason: 'rating:5',
            );
          }
        },
      ),
      _PropertyTestSpec(
        id: 8,
        title:
            'May 2027 (31 days) - dishes rated 5 in history allow 10-day gap',
        start: DateTime(2027, 5, 1),
        end: DateTime(2027, 5, 31),
        prepare: (ctx) async {
          await ctx.historyDao.recordCooked(
            recipeId: 'borscht',
            rating: 5,
            date: DateTime(2027, 4, 20),
          );
          await ctx.historyDao.recordCooked(
            recipeId: 'syrniki',
            rating: 5,
            date: DateTime(2027, 4, 21),
          );
        },
      ),
      _PropertyTestSpec(
        id: 9,
        title: 'June 2027 (30 days) - 3 dishes rated 1 in history are strictly never scheduled',
        start: DateTime(2027, 6, 1),
        end: DateTime(2027, 6, 30),
        prepare: (ctx) async {
          await ctx.historyDao.recordCooked(
            recipeId: 'borscht',
            rating: 1,
            date: DateTime(2027, 5, 15),
          );
          await ctx.historyDao.recordCooked(
            recipeId: 'syrniki',
            rating: 1,
            date: DateTime(2027, 5, 16),
          );
          await ctx.historyDao.recordCooked(
            recipeId: 'olivier',
            rating: 1,
            date: DateTime(2027, 5, 17),
          );
        },
      ),
      _PropertyTestSpec(
        id: 10,
        title: 'July 2027 (31 days) - allergies: nuts, peanuts excluded from entire plan',
        start: DateTime(2027, 7, 1),
        end: DateTime(2027, 7, 31),
        prepare: (ctx) async {
          await ctx.prefService.setAllergies(['nuts', 'peanuts']);
        },
      ),
      _PropertyTestSpec(
        id: 11,
        title: 'August 2027 (31 days) - excluded: mushrooms, pork excluded from entire plan',
        start: DateTime(2027, 8, 1),
        end: DateTime(2027, 8, 31),
        prepare: (ctx) async {
          await ctx.prefService.setExcludedIngredients(['mushrooms', 'pork']);
        },
      ),
      _PropertyTestSpec(
        id: 12,
        title: 'September 2027 (30 days) - cooked history in previous 14 days avoids early repeats',
        start: DateTime(2027, 9, 1),
        end: DateTime(2027, 9, 30),
        prepare: (ctx) async {
          // Cooked Aug 26..Aug 31
          await ctx.historyDao.recordCooked(
            recipeId: 'borscht',
            rating: 4,
            date: DateTime(2027, 8, 26),
          );
          await ctx.historyDao.recordCooked(
            recipeId: 'syrniki',
            rating: 4,
            date: DateTime(2027, 8, 28),
          );
          await ctx.historyDao.recordCooked(
            recipeId: 'olivier',
            rating: 4,
            date: DateTime(2027, 8, 30),
          );
        },
      ),
      _PropertyTestSpec(
        id: 13,
        title: 'October 2027 (31 days) - 3 locked days (hard, soup, salad) all preserved',
        start: DateTime(2027, 10, 1),
        end: DateTime(2027, 10, 31),
        prepare: (ctx) async {
          await ctx.planDao.upsertEntry(
            date: '2027-10-06',
            recipeId: 'beef_stroganoff', // Hard
            status: MealPlanStatus.planned,
            locked: true,
          );
          await ctx.planDao.upsertEntry(
            date: '2027-10-15',
            recipeId: 'borscht', // Soup
            status: MealPlanStatus.planned,
            locked: true,
          );
          await ctx.planDao.upsertEntry(
            date: '2027-10-24',
            recipeId: 'olivier', // Salad
            status: MealPlanStatus.planned,
            locked: true,
          );
        },
      ),
      _PropertyTestSpec(
        id: 14,
        title: 'November 2027 (30 days) - mid-month partial plan (Nov 15 to Nov 30)',
        start: DateTime(2027, 11, 15),
        end: DateTime(2027, 11, 30),
      ),
      _PropertyTestSpec(
        id: 15,
        title: 'December 2027 (31 days) - end-of-month partial plan (Dec 25 to Dec 31)',
        start: DateTime(2027, 12, 25),
        end: DateTime(2027, 12, 31),
      ),
      _PropertyTestSpec(
        id: 16,
        title: 'January 2028 (31 days) - AI-assisted month plan with FakePlanAiService',
        start: DateTime(2028, 1, 1),
        end: DateTime(2028, 1, 31),
        useAi: true,
      ),
      _PropertyTestSpec(
        id: 17,
        title: 'February 2028 (29 days) - AI proposes consecutive hard dishes -> repaired locally',
        start: DateTime(2028, 2, 1),
        end: DateTime(2028, 2, 29),
        useAi: true,
        aiPlanGenerator: (from, to, history) async {
          return [
            AiPlanDay(
              date: from,
              title: 'Бефстроганов с картофелем',
              dishType: 'main',
              difficulty: 'hard',
              mainIngredients: const ['говядина', 'сметана'],
              raw: const {},
            ),
            AiPlanDay(
              date: PlanDao.formatDate(
                DateTime.parse(from).add(const Duration(days: 1)),
              ),
              title: 'Утка по-пекински',
              dishType: 'main',
              difficulty: 'hard',
              mainIngredients: const ['утка', 'мед'],
              raw: const {},
            ),
          ];
        },
      ),
      _PropertyTestSpec(
        id: 18,
        title: 'March 2028 (31 days) - AI-assisted plan with pre-locked Saturday dish',
        start: DateTime(2028, 3, 1),
        end: DateTime(2028, 3, 31),
        useAi: true,
        prepare: (ctx) async {
          await ctx.planDao.upsertEntry(
            date: '2028-03-11',
            recipeId: 'borscht',
            status: MealPlanStatus.planned,
            locked: true,
          );
        },
      ),
      _PropertyTestSpec(
        id: 19,
        title: 'April 2028 (30 days) - multi-constraint: allergies + 5★ ratings + locked days',
        start: DateTime(2028, 4, 1),
        end: DateTime(2028, 4, 30),
        prepare: (ctx) async {
          await ctx.prefService.setAllergies(['nuts']);
          await ctx.prefService.setExcludedIngredients(['mushrooms']);
          await ctx.historyDao.recordCooked(
            recipeId: 'borscht',
            rating: 5,
            date: DateTime(2028, 3, 20),
          );
          await ctx.planDao.upsertEntry(
            date: '2028-04-18',
            recipeId: 'syrniki',
            status: MealPlanStatus.planned,
            locked: true,
          );
        },
      ),
      _PropertyTestSpec(
        id: 20,
        title: 'May 2028 (31 days) - full regeneration over existing plan preserves locked days',
        start: DateTime(2028, 5, 1),
        end: DateTime(2028, 5, 31),
        prepare: (ctx) async {
          await ctx.planDao.upsertEntry(
            date: '2028-05-05',
            recipeId: 'borscht',
            status: MealPlanStatus.planned,
            locked: true,
          );
          await ctx.planDao.upsertEntry(
            date: '2028-05-15',
            recipeId: 'olivier',
            status: MealPlanStatus.planned,
            locked: false,
          );
        },
      ),
    ];

    test('contains exactly 20 diverse property test scenarios', () {
      expect(testScenarios.length, 20);
    });

    for (final scenario in testScenarios) {
      test('Plan #${scenario.id}: ${scenario.title}', () async {
        final db = AppDatabase(NativeDatabase.memory(), seed: true);
        await db.customSelect('SELECT 1').get();

        final recipeDao = RecipeDao(db);
        final planDao = PlanDao(db);
        final ingredientDao = IngredientDao(db);
        final prefService = PreferenceService(db);
        final historyDao = HistoryDao(db, preferenceService: prefService);

        AiService? aiService;
        if (scenario.useAi) {
          final validator = RecipeValidator(
            safetyMinimums: _loadJson('spec/ai/safety_minimums.json'),
          );
          aiService = _FakePlanAiService(
            router: AiRouter(),
            validator: validator,
            db: db,
            planGenerator: scenario.aiPlanGenerator,
          );
        }

        final mealPlanner = MealPlanner(
          recipeDao: recipeDao,
          planDao: planDao,
          ingredientDao: ingredientDao,
          preferenceService: prefService,
          historyDao: historyDao,
          db: db,
          aiService: aiService,
        );

        final ctx = _TestContext(
          db: db,
          recipeDao: recipeDao,
          planDao: planDao,
          ingredientDao: ingredientDao,
          prefService: prefService,
          historyDao: historyDao,
        );

        if (scenario.prepare != null) {
          await scenario.prepare!(ctx);
        }

        // Remember pre-locked entries before generation
        final preLockedEntries = await planDao.getEntriesForRange(
          PlanDao.formatDate(scenario.start),
          PlanDao.formatDate(scenario.end),
        );
        final preLockedMap = {
          for (final item in preLockedEntries)
            if (item.entry.locked) item.entry.date: item.entry.recipeId,
        };

        final profileBefore = await prefService.getProfile();
        final hierarchy = await ingredientDao.hierarchy();
        final dislikedRecipeIds = await historyDao.getDislikedRecipeIds();

        // 1. Generate plan
        final entries = await withClock(Clock.fixed(scenario.start), () async {
          return await mealPlanner.generateMonthPlan(
            fromDate: scenario.start,
            toDate: scenario.end,
            aiService: aiService,
          );
        });

        // Expected number of days
        final expectedDaysCount =
            scenario.end.difference(scenario.start).inDays + 1;
        expect(
          entries.length,
          expectedDaysCount,
          reason: 'All days in requested range must be planned',
        );

        // Fetch complete schedule with recipes from DB
        final scheduledEntries = await planDao.getEntriesForRange(
          PlanDao.formatDate(scenario.start),
          PlanDao.formatDate(scenario.end),
        );
        expect(scheduledEntries.length, expectedDaysCount);

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

        // 2. Validate plan with MealPlanner.validatePlan
        final historyCooked = await historyDao.allWithRecipes();
        final ratings = <String, int>{
          for (final item in historyCooked)
            if (item.entry.rating != null)
              item.entry.recipeId: item.entry.rating!,
        };

        final validation = mealPlanner.validatePlan(
          schedule,
          profile: profileBefore,
          hierarchy: hierarchy,
          ratings: ratings,
        );

        expect(
          validation.isValid,
          isTrue,
          reason:
              'Plan #${scenario.id} has rule violations: ${validation.violations}',
        );
        expect(validation.violations, isEmpty);

        // 3. Property invariant assertions

        // Invariant: Rule 1 (No repeat within 14 days, or 10 days if rated 5)
        for (var i = 0; i < schedule.length; i++) {
          final cur = schedule[i];
          final rId = cur.recipe.recipe.id;
          final isFiveStar =
              (ratings[rId] ?? 0) >= 5 || cur.recipe.recipe.isFavorite;
          final minGap = isFiveStar ? 10 : 14;

          for (var j = i + 1; j < schedule.length; j++) {
            final other = schedule[j];
            if (other.recipe.recipe.id == rId) {
              final gap = other.date.difference(cur.date).inDays.abs();
              expect(
                gap >= minGap,
                isTrue,
                reason:
                    'Dish "${cur.recipe.recipe.title}" repeated at day $gap < $minGap in Plan #${scenario.id}',
              );
            }
          }
        }

        // Invariant: Rule 2 (Same main ingredient at most 2 days in a row)
        String rootAncestorLookup(String id) {
          final ancestors = hierarchy[id];
          return (ancestors != null && ancestors.isNotEmpty)
              ? ancestors.last
              : id;
        }

        for (var i = 2; i < schedule.length; i++) {
          final d0 = schedule[i - 2];
          final d1 = schedule[i - 1];
          final d2 = schedule[i];
          if (d1.date.difference(d0.date).inDays == 1 &&
              d2.date.difference(d1.date).inDays == 1) {
            final m0 = diversity.resolveMainIngredient(
              d0.recipe,
              rootAncestorLookup: rootAncestorLookup,
            );
            final m1 = diversity.resolveMainIngredient(
              d1.recipe,
              rootAncestorLookup: rootAncestorLookup,
            );
            final m2 = diversity.resolveMainIngredient(
              d2.recipe,
              rootAncestorLookup: rootAncestorLookup,
            );
            final allSame = m0 != null && m0.isNotEmpty && m0 == m1 && m1 == m2;
            expect(
              allSame,
              isFalse,
              reason:
                  '3 consecutive days with main ingredient $m2 in Plan #${scenario.id}',
            );
          }
        }

        // Invariant: Rule 4 (Hard dishes at most 2 per week and never 2 consecutive days)
        for (var i = 1; i < schedule.length; i++) {
          final prev = schedule[i - 1];
          final cur = schedule[i];
          if (cur.date.difference(prev.date).inDays == 1) {
            final bothHard =
                prev.recipe.recipe.difficulty == Difficulty.hard &&
                cur.recipe.recipe.difficulty == Difficulty.hard;
            expect(
              bothHard,
              isFalse,
              reason:
                  'Two consecutive hard dishes on ${cur.date} in Plan #${scenario.id}',
            );
          }
        }

        // Invariant: Rule 5 (Pre-locked days must remain 100% intact)
        for (final entry in preLockedMap.entries) {
          final scheduledDay = schedule.firstWhere(
            (s) => PlanDao.formatDate(s.date) == entry.key,
          );
          expect(
            scheduledDay.recipe.recipe.id,
            entry.value,
            reason: 'Locked day ${entry.key} was changed',
          );
          expect(
            scheduledDay.locked,
            isTrue,
            reason: 'Locked day ${entry.key} lost locked status',
          );
        }

        // Invariant: Disliked dishes (rating 1) must never be suggested
        for (final day in schedule) {
          expect(
            dislikedRecipeIds.contains(day.recipe.recipe.id),
            isFalse,
            reason:
                'Recipe ${day.recipe.recipe.title} has rating 1 but was scheduled in Plan #${scenario.id}',
          );
        }

        // Invariant: Forbidden ingredients (allergies + excluded) must never appear
        final forbidden = <String>{
          ...profileBefore.allergies,
          ...profileBefore.excludedIngredients,
        };
        for (final id in [
          ...profileBefore.allergies,
          ...profileBefore.excludedIngredients,
        ]) {
          for (final hEntry in hierarchy.entries) {
            if (hEntry.value.contains(id)) {
              forbidden.add(hEntry.key);
            }
          }
        }

        for (final day in schedule) {
          for (final line in day.recipe.ingredients) {
            final ingId = line.recipeIngredient.ingredientId;
            expect(
              forbidden.contains(ingId),
              isFalse,
              reason:
                  'Day ${day.date} has forbidden ingredient $ingId in Plan #${scenario.id}',
            );
          }
        }

        await db.close();
      });
    }
  });
}

class _TestContext {
  _TestContext({
    required this.db,
    required this.recipeDao,
    required this.planDao,
    required this.ingredientDao,
    required this.prefService,
    required this.historyDao,
  });

  final AppDatabase db;
  final RecipeDao recipeDao;
  final PlanDao planDao;
  final IngredientDao ingredientDao;
  final PreferenceService prefService;
  final HistoryDao historyDao;
}

class _PropertyTestSpec {
  _PropertyTestSpec({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.prepare,
    this.useAi = false,
    this.aiPlanGenerator,
  });

  final int id;
  final String title;
  final DateTime start;
  final DateTime end;
  final Future<void> Function(_TestContext ctx)? prepare;
  final bool useAi;
  final Future<List<AiPlanDay>?> Function(
    String from,
    String to,
    List<String> history,
  )?
  aiPlanGenerator;
}
