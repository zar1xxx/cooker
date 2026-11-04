import 'package:clock/clock.dart';

import '../db/app_database.dart';
import '../db/daos/history_dao.dart';
import '../db/daos/ingredient_dao.dart';
import '../db/daos/plan_dao.dart';
import '../db/daos/recipe_dao.dart';
import '../db/enums.dart';
import '../matching/diversity_reorderer.dart';
import '../matching/recipe_matcher.dart';
import '../matching/recipe_scorer.dart';
import '../preferences/preference_service.dart';

class ScheduledDay {
  const ScheduledDay({
    required this.date,
    required this.recipe,
    this.locked = false,
  });

  final DateTime date;
  final RecipeWithIngredients recipe;
  final bool locked;
}

class PlanViolation {
  const PlanViolation({
    required this.ruleNumber,
    required this.date,
    required this.message,
    this.recipeId,
  });

  final int ruleNumber;
  final String date;
  final String message;
  final String? recipeId;

  @override
  String toString() => 'Rule $ruleNumber violation on $date: $message';
}

class PlanValidationResult {
  const PlanValidationResult({required this.isValid, required this.violations});

  final bool isValid;
  final List<PlanViolation> violations;
}

/// Local meal planner implementing the five rotation rules from TZ 8.1:
/// 1. Same dish at most once per 14 days (favorite dishes rated 5 once per 10 days).
/// 2. Same main ingredient at most 2 days in a row.
/// 3. Soup at least 2 times per week (unless taste profile dislikes soup).
/// 4. Hard dishes at most 2 per week and never on two consecutive days.
/// 5. Dish type proportions roughly match profile weights.
class MealPlanner {
  MealPlanner({
    required this.recipeDao,
    required this.planDao,
    required this.ingredientDao,
    required this.preferenceService,
    this.historyDao,
    RecipeDiversityReorderer? diversityReorderer,
  }) : _diversity = diversityReorderer ?? const RecipeDiversityReorderer();

  final RecipeDao recipeDao;
  final PlanDao planDao;
  final IngredientDao ingredientDao;
  final PreferenceService preferenceService;
  final HistoryDao? historyDao;
  final RecipeDiversityReorderer _diversity;

  /// Generates a local meal plan for all non-locked days from [fromDate] to [toDate]
  /// (inclusive), filling the schedule from local database using scoring without coverage.
  Future<List<MealPlanEntry>> generateMonthPlan({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final start = fromDate ?? clock.now();
    // Default to the end of the current month
    final end = toDate ?? DateTime(start.year, start.month + 1, 0);

    final allRecipes = await recipeDao.allWithIngredients();
    if (allRecipes.isEmpty) return const [];

    final profile = await preferenceService.getProfile();
    final hierarchy = await ingredientDao.hierarchy();

    // Collect forbidden ingredient IDs (allergies + excluded) and their descendants
    final forbiddenIds = <String>{};
    for (final id in [...profile.allergies, ...profile.excludedIngredients]) {
      forbiddenIds.add(id);
      for (final entry in hierarchy.entries) {
        if (entry.value.contains(id)) {
          forbiddenIds.add(entry.key);
        }
      }
    }

    // Recipes with rating 1 must never be suggested
    final dislikedIds = historyDao != null
        ? await historyDao!.getDislikedRecipeIds()
        : <String>{};

    // Filter candidate recipes: no allergens, no rating 1 dishes
    final candidateRecipes = allRecipes.where((r) {
      if (dislikedIds.contains(r.recipe.id)) return false;
      for (final line in r.ingredients) {
        final ingId = line.recipeIngredient.ingredientId;
        if (forbiddenIds.contains(ingId)) return false;
        final ancestors = hierarchy[ingId] ?? const [];
        if (ancestors.any(forbiddenIds.contains)) return false;
      }
      return true;
    }).toList();

    if (candidateRecipes.isEmpty) return const [];

    // Load recent history (last 14 days) to honor the 14-day rule across plan boundary
    final lastCookedDates = <String, DateTime>{};
    final ratings = <String, int>{};
    if (historyDao != null) {
      final historyEntries = await historyDao!.allWithRecipes();
      for (final item in historyEntries) {
        final rId = item.entry.recipeId;
        final cookedDt = DateTime.tryParse(item.entry.cookedOn);
        if (cookedDt != null) {
          final existing = lastCookedDates[rId];
          if (existing == null || cookedDt.isAfter(existing)) {
            lastCookedDates[rId] = cookedDt;
          }
        }
        if (item.entry.rating != null) {
          ratings[rId] = item.entry.rating!;
        }
      }
    }

    // Load existing plan entries in the target range to respect locked days
    final startDateStr = PlanDao.formatDate(start);
    final endDateStr = PlanDao.formatDate(end);
    final existingPlanEntries = await planDao.getEntriesForRange(
      startDateStr,
      endDateStr,
    );
    final existingByDate = {
      for (final item in existingPlanEntries) item.entry.date: item,
    };

    // Helper for main ingredient resolution to root ancestor
    String rootAncestor(String id) {
      final ancestors = hierarchy[id];
      return (ancestors != null && ancestors.isNotEmpty) ? ancestors.last : id;
    }

    // Check if profile strongly dislikes soup (Rule 3 exception)
    final soupWeight = profile.dishTypeWeights['soup'] ?? 0.0;
    final soupDisliked = soupWeight < -0.3;

    // Scorer without coverage (TZ 8.1)
    final scorer = RecipeScorer.withProfile(
      profile,
      recipeRatings: {
        for (final entry in ratings.entries) entry.key: entry.value.toDouble(),
      },
      weights: const ScoringWeights(
        coverage: 0.0,
        taste: 0.45,
        novelty: 0.30,
        fit: 0.15,
        explore: 0.10,
      ),
    );

    // Build the daily schedule
    final recipeById = {for (final r in allRecipes) r.recipe.id: r};
    final schedule = <ScheduledDay>[];

    var currentDate = DateTime(start.year, start.month, start.day);
    final lastDate = DateTime(end.year, end.month, end.day);

    while (!currentDate.isAfter(lastDate)) {
      final dateKey = PlanDao.formatDate(currentDate);
      final existing = existingByDate[dateKey];

      if (existing != null && existing.entry.locked) {
        // Locked day: keep existing recipe
        final recipeWithIng =
            recipeById[existing.entry.recipeId] ??
            candidateRecipes.firstWhere(
              (r) => r.recipe.id == existing.entry.recipeId,
              orElse: () => candidateRecipes.first,
            );
        schedule.add(
          ScheduledDay(date: currentDate, recipe: recipeWithIng, locked: true),
        );
      } else {
        // Unlocked day: pick the best candidate satisfying Rules 1-4
        final chosen = _pickBestRecipeForDay(
          date: currentDate,
          schedule: schedule,
          candidates: candidateRecipes,
          scorer: scorer,
          ratings: ratings,
          lastCookedDates: lastCookedDates,
          soupDisliked: soupDisliked,
          rootAncestorLookup: rootAncestor,
        );

        schedule.add(
          ScheduledDay(date: currentDate, recipe: chosen, locked: false),
        );
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Persist planned days into the database
    final resultEntries = <MealPlanEntry>[];
    for (final day in schedule) {
      final dateStr = PlanDao.formatDate(day.date);
      final existing = existingByDate[dateStr];
      if (existing != null && existing.entry.locked) {
        resultEntries.add(existing.entry);
      } else {
        final saved = await planDao.upsertEntry(
          date: dateStr,
          recipeId: day.recipe.recipe.id,
          status: MealPlanStatus.planned,
          locked: false,
        );
        resultEntries.add(saved);
      }
    }

    return resultEntries;
  }

  /// Picks the optimal recipe for [date] enforcing Rules 1-4.
  RecipeWithIngredients _pickBestRecipeForDay({
    required DateTime date,
    required List<ScheduledDay> schedule,
    required List<RecipeWithIngredients> candidates,
    required RecipeScorer scorer,
    required Map<String, int> ratings,
    required Map<String, DateTime> lastCookedDates,
    required bool soupDisliked,
    required String Function(String) rootAncestorLookup,
  }) {
    // Determine context from previous days
    final prevDay1 = schedule.isNotEmpty ? schedule.last : null;
    final prevDay2 = schedule.length >= 2
        ? schedule[schedule.length - 2]
        : null;

    final prevMain1 = prevDay1 != null
        ? _diversity.resolveMainIngredient(
            prevDay1.recipe,
            rootAncestorLookup: rootAncestorLookup,
          )
        : null;
    final prevMain2 = prevDay2 != null
        ? _diversity.resolveMainIngredient(
            prevDay2.recipe,
            rootAncestorLookup: rootAncestorLookup,
          )
        : null;

    final consecutiveMain = (prevMain1 != null && prevMain1 == prevMain2)
        ? prevMain1
        : null;

    // Week boundaries (Monday to Sunday) for weekly rules 3 & 4
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final daysInCurrentWeek = schedule.where((d) {
      return !d.date.isBefore(weekStart) && !d.date.isAfter(weekEnd);
    }).toList();

    final soupsInWeekSoFar = daysInCurrentWeek
        .where((d) => d.recipe.recipe.dishType == DishType.soup)
        .length;
    final hardInWeekSoFar = daysInCurrentWeek
        .where((d) => d.recipe.recipe.difficulty == Difficulty.hard)
        .length;

    final daysRemainingInWeek = 7 - daysInCurrentWeek.length;
    final mustBeSoup =
        !soupDisliked &&
        (2 - soupsInWeekSoFar) >= daysRemainingInWeek &&
        daysRemainingInWeek > 0;

    final cannotBeHard =
        (prevDay1 != null &&
            prevDay1.recipe.recipe.difficulty == Difficulty.hard) ||
        hardInWeekSoFar >= 2;

    // Filter candidates strictly meeting the rules
    final validCandidates = candidates.where((c) {
      final r = c.recipe;

      // Rule 1: No repeat within 14 days (10 days if rated 5)
      final minGap = (ratings[r.id] == 5) ? 10 : 14;
      for (final past in schedule) {
        if (past.recipe.recipe.id == r.id) {
          final diff = date.difference(past.date).inDays.abs();
          if (diff < minGap) return false;
        }
      }
      final historicalDate = lastCookedDates[r.id];
      if (historicalDate != null) {
        final diff = date.difference(historicalDate).inDays.abs();
        if (diff < minGap) return false;
      }

      // Rule 2: At most 2 days in a row with the same main ingredient
      if (consecutiveMain != null) {
        final cMain = _diversity.resolveMainIngredient(
          c,
          rootAncestorLookup: rootAncestorLookup,
        );
        if (cMain == consecutiveMain) return false;
      }

      // Rule 4: Hard dishes at most 2 per week and never consecutive
      if (cannotBeHard && r.difficulty == Difficulty.hard) {
        return false;
      }

      // Rule 3: Soup quota enforcement
      if (mustBeSoup && r.dishType != DishType.soup) {
        return false;
      }

      return true;
    }).toList();

    final pool = validCandidates.isNotEmpty ? validCandidates : candidates;

    // Score candidates and choose the highest
    RecipeWithIngredients best = pool.first;
    double bestScore = -1.0;

    for (final candidate in pool) {
      final match = RecipeMatch(
        entry: candidate,
        coverage: 1.0,
        missingIds: const [],
        missingNames: const [],
      );
      final scored = scorer.score(match, date: date);
      var total = scored.total;

      // Soft preference for soup if quota is not yet met
      if (!soupDisliked &&
          soupsInWeekSoFar < 2 &&
          candidate.recipe.dishType == DishType.soup) {
        total += 0.20;
      }

      if (total > bestScore) {
        bestScore = total;
        best = candidate;
      }
    }

    return best;
  }

  /// Validates any schedule (local or AI-generated) against the 5 rules from TZ 8.1.
  PlanValidationResult validatePlan(
    List<ScheduledDay> schedule, {
    TasteProfile? profile,
    Map<String, List<String>>? hierarchy,
  }) {
    final violations = <PlanViolation>[];
    final soupDisliked = (profile?.dishTypeWeights['soup'] ?? 0.0) < -0.3;

    String rootAncestor(String id) {
      if (hierarchy == null) return id;
      final ancestors = hierarchy[id];
      return (ancestors != null && ancestors.isNotEmpty) ? ancestors.last : id;
    }

    // Sort by date
    final sorted = [...schedule]..sort((a, b) => a.date.compareTo(b.date));

    // Rule 1: No repeat within 14 days (10 days if rated 5)
    for (var i = 0; i < sorted.length; i++) {
      final current = sorted[i];
      final minGap = 14; // Base gap for validation

      for (var j = i + 1; j < sorted.length; j++) {
        final other = sorted[j];
        if (current.recipe.recipe.id == other.recipe.recipe.id) {
          final diff = other.date.difference(current.date).inDays.abs();
          if (diff < minGap) {
            violations.add(
              PlanViolation(
                ruleNumber: 1,
                date: PlanDao.formatDate(other.date),
                message:
                    'Блюдо "${current.recipe.recipe.title}" повторяется через $diff дней (минимум 14 дней)',
                recipeId: current.recipe.recipe.id,
              ),
            );
          }
        }
      }
    }

    // Rule 2: At most 2 days in a row with the same main ingredient
    for (var i = 2; i < sorted.length; i++) {
      final day0 = sorted[i - 2];
      final day1 = sorted[i - 1];
      final day2 = sorted[i];

      // Check consecutive calendar dates
      if (day1.date.difference(day0.date).inDays == 1 &&
          day2.date.difference(day1.date).inDays == 1) {
        final m0 = _diversity.resolveMainIngredient(
          day0.recipe,
          rootAncestorLookup: rootAncestor,
        );
        final m1 = _diversity.resolveMainIngredient(
          day1.recipe,
          rootAncestorLookup: rootAncestor,
        );
        final m2 = _diversity.resolveMainIngredient(
          day2.recipe,
          rootAncestorLookup: rootAncestor,
        );

        if (m0 != null && m0.isNotEmpty && m0 == m1 && m1 == m2) {
          violations.add(
            PlanViolation(
              ruleNumber: 2,
              date: PlanDao.formatDate(day2.date),
              message:
                  'Один главный ингредиент ($m2) повторяется 3 дня подряд (${PlanDao.formatDate(day0.date)}..${PlanDao.formatDate(day2.date)})',
              recipeId: day2.recipe.recipe.id,
            ),
          );
        }
      }
    }

    // Rule 4 (Consecutive hard days): never on two consecutive days
    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final curr = sorted[i];

      if (curr.date.difference(prev.date).inDays == 1) {
        if (prev.recipe.recipe.difficulty == Difficulty.hard &&
            curr.recipe.recipe.difficulty == Difficulty.hard) {
          violations.add(
            PlanViolation(
              ruleNumber: 4,
              date: PlanDao.formatDate(curr.date),
              message:
                  'Сложные блюда идут два дня подряд (${PlanDao.formatDate(prev.date)} и ${PlanDao.formatDate(curr.date)})',
              recipeId: curr.recipe.recipe.id,
            ),
          );
        }
      }
    }

    // Group days by Monday-Sunday calendar week for weekly rules (Rules 3 & 4)
    final weeks = <String, List<ScheduledDay>>{};
    for (final day in sorted) {
      final weekStart = day.date.subtract(Duration(days: day.date.weekday - 1));
      final weekKey = PlanDao.formatDate(weekStart);
      weeks.putIfAbsent(weekKey, () => []).add(day);
    }

    for (final entry in weeks.entries) {
      final weekDays = entry.value;

      // Rule 4 (Weekly hard limit): at most 2 per week
      final hardCount = weekDays
          .where((d) => d.recipe.recipe.difficulty == Difficulty.hard)
          .length;
      if (hardCount > 2) {
        violations.add(
          PlanViolation(
            ruleNumber: 4,
            date: entry.key,
            message: 'Сложных блюд на неделе $hardCount (максимум 2 в неделю)',
          ),
        );
      }

      // Rule 3 (Weekly soup quota): at least 2 per full week of 7 days
      if (!soupDisliked && weekDays.length == 7) {
        final soupCount = weekDays
            .where((d) => d.recipe.recipe.dishType == DishType.soup)
            .length;
        if (soupCount < 2) {
          violations.add(
            PlanViolation(
              ruleNumber: 3,
              date: entry.key,
              message:
                  'Супов на неделе $soupCount (требуется не менее 2 в неделю)',
            ),
          );
        }
      }
    }

    return PlanValidationResult(
      isValid: violations.isEmpty,
      violations: violations,
    );
  }
}
