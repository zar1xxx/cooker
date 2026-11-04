import '../db/daos/recipe_dao.dart';

/// One recipe compared with the current pantry.
class RecipeMatch {
  const RecipeMatch({
    required this.entry,
    required this.coverage,
    required this.missingIds,
    required this.missingNames,
  });

  final RecipeWithIngredients entry;

  /// Share of required ingredients that are available (0..1).
  final double coverage;

  /// Ids of required ingredients that are not available.
  final List<String> missingIds;

  /// Human-readable names for [missingIds], in the same order.
  final List<String> missingNames;

  int get missingCount => missingIds.length;

  bool get canCookNow => missingCount == 0;

  bool get isAlmostReady =>
      missingCount > 0 && missingCount <= RecipeMatcher.maxAlmostMissing;
}

/// Recipes split into the two groups from TZ 5.2.
class RecipeMatchResult {
  const RecipeMatchResult({required this.ready, required this.almostReady});

  /// «Можно приготовить сейчас»: `missing = 0`.
  final List<RecipeMatch> ready;

  /// «Не хватает 1–2 продуктов».
  final List<RecipeMatch> almostReady;

  bool get isEmpty => ready.isEmpty && almostReady.isEmpty;

  List<RecipeMatch> get all => [...ready, ...almostReady];
}

/// Compares recipes with the pantry by required ingredients (TZ 5.2).
class RecipeMatcher {
  const RecipeMatcher();

  /// Recipes with more missing products are not shown at all.
  static const maxAlmostMissing = 2;

  RecipeMatchResult match({
    required Iterable<RecipeWithIngredients> recipes,
    required Set<String> availableIds,
    Map<String, List<String>> hierarchy = const {},
  }) {
    final effectiveAvailable = _expandWithAncestors(availableIds, hierarchy);
    final ready = <RecipeMatch>[];
    final almostReady = <RecipeMatch>[];

    for (final entry in recipes) {
      final match = _matchOne(entry, effectiveAvailable);
      if (match.canCookNow) {
        ready.add(match);
      } else if (match.isAlmostReady) {
        almostReady.add(match);
      }
    }

    return RecipeMatchResult(ready: ready, almostReady: almostReady);
  }

  /// Exposed for callers that need one recipe (recipe screen, tests).
  RecipeMatch matchOne({
    required RecipeWithIngredients recipe,
    required Set<String> availableIds,
    Map<String, List<String>> hierarchy = const {},
  }) {
    return _matchOne(recipe, _expandWithAncestors(availableIds, hierarchy));
  }

  RecipeMatch _matchOne(
    RecipeWithIngredients entry,
    Set<String> effectiveAvailable,
  ) {
    var totalRequired = 0;
    var availableRequired = 0;
    final missingIds = <String>[];
    final missingNames = <String>[];

    for (final line in entry.ingredients) {
      final ingredient = line.ingredient;
      // Staples and optional products never block a recipe.
      if (ingredient?.isStaple == true || line.recipeIngredient.isOptional) {
        continue;
      }

      totalRequired++;
      final id = line.recipeIngredient.ingredientId;
      if (effectiveAvailable.contains(id)) {
        availableRequired++;
      } else {
        missingIds.add(id);
        missingNames.add(ingredient?.name ?? id);
      }
    }

    // ASSUMPTION (D-017): a recipe with no required ingredients is always
    // available; coverage is 1.0 instead of 0/0.
    final coverage = totalRequired == 0
        ? 1.0
        : availableRequired / totalRequired;

    return RecipeMatch(
      entry: entry,
      coverage: coverage,
      missingIds: List.unmodifiable(missingIds),
      missingNames: List.unmodifiable(missingNames),
    );
  }

  /// Having a child product means having its ancestors («куриное филе» →
  /// «курица»), but not the other way round.
  Set<String> _expandWithAncestors(
    Set<String> availableIds,
    Map<String, List<String>> hierarchy,
  ) {
    final expanded = <String>{...availableIds};
    for (final id in availableIds) {
      expanded.addAll(hierarchy[id] ?? const []);
    }
    return expanded;
  }
}
