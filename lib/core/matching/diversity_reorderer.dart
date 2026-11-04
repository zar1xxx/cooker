import '../db/daos/recipe_dao.dart';
import '../db/enums.dart';
import 'recipe_scorer.dart';

/// Applies diversity constraints to recommendation lists per TZ 5.4.
///
/// Within the first [topLimit] items (default 10):
/// - At most [maxPerDishType] dishes of any single [DishType] (default 3),
///   unless [hasDishTypeFilter] is active.
/// - At most [maxPerMainIngredient] dishes sharing the same main ingredient
///   (default 2), resolved to the root ancestor.
class RecipeDiversityReorderer {
  const RecipeDiversityReorderer();

  static const defaultTopLimit = 10;
  static const defaultMaxPerDishType = 3;
  static const defaultMaxPerMainIngredient = 2;

  static const _proteinCategories = {'meat', 'poultry', 'fish'};
  static const _secondaryCategories = {'legumes', 'mushrooms'};
  static const _tertiaryCategories = {'dairy', 'grains'};

  /// Reorders [scored] recipes using greedy MMR-like selection to ensure
  /// diversity across dish types and main ingredients in the top results.
  List<ScoredRecipe> reorder(
    List<ScoredRecipe> scored, {
    bool hasDishTypeFilter = false,
    int topLimit = defaultTopLimit,
    int maxPerDishType = defaultMaxPerDishType,
    int maxPerMainIngredient = defaultMaxPerMainIngredient,
    String Function(String id)? rootAncestorLookup,
  }) {
    if (scored.length <= 1) return List<ScoredRecipe>.from(scored);

    final remaining = List<ScoredRecipe>.from(scored);
    final result = <ScoredRecipe>[];
    final dishTypeCounts = <DishType, int>{};
    final mainIngredientCounts = <String, int>{};

    while (result.length < topLimit && remaining.isNotEmpty) {
      ScoredRecipe? bestCandidate;
      int bestViolations = 999;
      int bestTypeCount = 999;
      int bestIngCount = 999;

      for (final candidate in remaining) {
        final dishType = candidate.entry.recipe.dishType;
        final mainIng = resolveMainIngredient(
          candidate.entry,
          rootAncestorLookup: rootAncestorLookup,
        );

        final curTypeCount = dishTypeCounts[dishType] ?? 0;
        final curIngCount = (mainIng != null && mainIng.isNotEmpty)
            ? (mainIngredientCounts[mainIng] ?? 0)
            : 0;

        final dishTypeViolated =
            !hasDishTypeFilter && curTypeCount >= maxPerDishType;
        final mainIngViolated =
            mainIng != null &&
            mainIng.isNotEmpty &&
            curIngCount >= maxPerMainIngredient;

        var violations = 0;
        if (dishTypeViolated) violations++;
        if (mainIngViolated) violations++;

        // Ideal match found with highest score (since remaining is in score order)
        if (violations == 0) {
          bestCandidate = candidate;
          break;
        }

        // Compare violation severity
        if (violations < bestViolations) {
          bestViolations = violations;
          bestTypeCount = curTypeCount;
          bestIngCount = curIngCount;
          bestCandidate = candidate;
        } else if (violations == bestViolations) {
          // Break ties by minimizing the over-represented counts
          final candidateSum = curTypeCount + curIngCount;
          final bestSum = bestTypeCount + bestIngCount;
          if (candidateSum < bestSum) {
            bestTypeCount = curTypeCount;
            bestIngCount = curIngCount;
            bestCandidate = candidate;
          }
        }
      }

      final picked = bestCandidate ?? remaining.first;
      remaining.remove(picked);
      result.add(picked);

      final dishType = picked.entry.recipe.dishType;
      dishTypeCounts[dishType] = (dishTypeCounts[dishType] ?? 0) + 1;

      final mainIng = resolveMainIngredient(
        picked.entry,
        rootAncestorLookup: rootAncestorLookup,
      );
      if (mainIng != null && mainIng.isNotEmpty) {
        mainIngredientCounts[mainIng] =
            (mainIngredientCounts[mainIng] ?? 0) + 1;
      }
    }

    // Remaining items keep their original score order after topLimit slots.
    result.addAll(remaining);
    return result;
  }

  /// Identifies the central/main ingredient of a recipe.
  ///
  /// Priority:
  /// 1. Meat, poultry or fish (non-staple, non-optional).
  /// 2. Legumes or mushrooms (non-staple, non-optional).
  /// 3. Dairy or grains (non-staple, non-optional).
  /// 4. First non-staple, non-optional ingredient.
  /// 5. First non-optional ingredient, or null if none exist.
  ///
  /// If [rootAncestorLookup] is given, the ingredient id is resolved to its
  /// root ancestor (e.g. 'chicken_fillet' -> 'chicken').
  String? resolveMainIngredient(
    RecipeWithIngredients entry, {
    String Function(String id)? rootAncestorLookup,
  }) {
    final required = entry.ingredients.where((line) {
      return !line.recipeIngredient.isOptional &&
          line.ingredient?.isStaple != true;
    }).toList();

    String? chosenId;

    if (required.isNotEmpty) {
      // 1. Proteins
      for (final line in required) {
        final cat = line.ingredient?.category;
        if (cat != null && _proteinCategories.contains(cat)) {
          chosenId = line.recipeIngredient.ingredientId;
          break;
        }
      }

      // 2. Legumes / mushrooms
      if (chosenId == null) {
        for (final line in required) {
          final cat = line.ingredient?.category;
          if (cat != null && _secondaryCategories.contains(cat)) {
            chosenId = line.recipeIngredient.ingredientId;
            break;
          }
        }
      }

      // 3. Dairy / grains
      if (chosenId == null) {
        for (final line in required) {
          final cat = line.ingredient?.category;
          if (cat != null && _tertiaryCategories.contains(cat)) {
            chosenId = line.recipeIngredient.ingredientId;
            break;
          }
        }
      }

      // 4. First non-staple required
      chosenId ??= required.first.recipeIngredient.ingredientId;
    } else {
      // Fallback: any non-optional or first ingredient
      final nonOptional = entry.ingredients
          .where((line) => !line.recipeIngredient.isOptional)
          .toList();
      if (nonOptional.isNotEmpty) {
        chosenId = nonOptional.first.recipeIngredient.ingredientId;
      } else if (entry.ingredients.isNotEmpty) {
        chosenId = entry.ingredients.first.recipeIngredient.ingredientId;
      }
    }

    if (chosenId == null) return null;
    return rootAncestorLookup != null ? rootAncestorLookup(chosenId) : chosenId;
  }
}
