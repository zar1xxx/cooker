import 'package:clock/clock.dart';

import '../db/app_database.dart';
import '../db/daos/recipe_dao.dart';
import '../db/enums.dart';
import '../preferences/preference_service.dart';
import 'recipe_matcher.dart';

/// Formula weights from TZ 5.3. The defaults sum to 1.0.
class ScoringWeights {
  const ScoringWeights({
    this.coverage = 0.35,
    this.taste = 0.30,
    this.novelty = 0.20,
    this.fit = 0.10,
    this.explore = 0.05,
  });

  final double coverage;
  final double taste;
  final double novelty;
  final double fit;
  final double explore;

  double get total => coverage + taste + novelty + fit + explore;
}

/// Optional limits from the taste profile. Stage 1 passes `null`, so fit is 1.
class ScoringProfile {
  const ScoringProfile({this.maxTotalMinutes, this.maxDifficulty});

  final int? maxTotalMinutes;
  final Difficulty? maxDifficulty;
}

/// Resolves the `taste` component. Stage 1 always returns 0.5 (TZ 11);
/// Stage 4 replaces this with the preference profile.
typedef TasteLookup = double Function(Recipe recipe);

double defaultTasteLookup(Recipe recipe) => 0.5;

class ScoreBreakdown {
  const ScoreBreakdown({
    required this.coverage,
    required this.taste,
    required this.novelty,
    required this.fit,
    required this.explore,
    required this.total,
  });

  final double coverage;
  final double taste;
  final double novelty;
  final double fit;
  final double explore;
  final double total;
}

class ScoredRecipe {
  const ScoredRecipe({required this.match, required this.scores});

  final RecipeMatch match;
  final ScoreBreakdown scores;

  RecipeWithIngredients get entry => match.entry;

  double get total => scores.total;
}

/// Ranks matches by the TZ 5.3 formula.
class RecipeScorer {
  const RecipeScorer({
    this.weights = const ScoringWeights(),
    this.tasteLookup = defaultTasteLookup,
    this.matchTasteLookup,
  });

  /// Factory creating a RecipeScorer configured with a learned TasteProfile
  /// and personal dish ratings from history per ТЗ 5.3 and 6.4.
  factory RecipeScorer.withProfile(
    TasteProfile profile, {
    Map<String, double> recipeRatings = const {},
    ScoringWeights weights = const ScoringWeights(),
  }) {
    return RecipeScorer(
      weights: weights,
      matchTasteLookup: (match) {
        final recipeId = match.entry.recipe.id;
        final personalRating = recipeRatings[recipeId];
        if (personalRating != null) {
          // Normalize 1..5 star rating to 0..1: (r - 1) / 4
          return ((personalRating - 1.0) / 4.0).clamp(0.0, 1.0);
        }
        // Normalize profile score (-1..1) to 0..1: (w + 1) / 2
        final ingIds = match.entry.ingredients
            .map((i) => i.recipeIngredient.ingredientId)
            .toList();
        final w = profile.scoreRecipe(match.entry.recipe, ingIds);
        return ((w + 1.0) / 2.0).clamp(0.0, 1.0);
      },
    );
  }

  final ScoringWeights weights;
  final TasteLookup tasteLookup;
  final double Function(RecipeMatch match)? matchTasteLookup;

  /// Sorts descending by total score. Ties are broken by title so the order
  /// stays deterministic.
  List<ScoredRecipe> rank(
    Iterable<RecipeMatch> matches, {
    DateTime? date,
    Map<String, DateTime> lastCooked = const {},
    Set<String> similarRecentlyCooked = const {},
    ScoringProfile? profile,
  }) {
    final now = date ?? clock.now();
    final scored = [
      for (final match in matches)
        score(
          match,
          date: now,
          lastCooked: lastCooked,
          similarRecentlyCooked: similarRecentlyCooked,
          profile: profile,
        ),
    ];
    scored.sort((a, b) {
      final byScore = b.total.compareTo(a.total);
      if (byScore != 0) return byScore;
      return a.entry.recipe.title.compareTo(b.entry.recipe.title);
    });
    return scored;
  }

  ScoredRecipe score(
    RecipeMatch match, {
    DateTime? date,
    Map<String, DateTime> lastCooked = const {},
    Set<String> similarRecentlyCooked = const {},
    ScoringProfile? profile,
  }) {
    final now = date ?? clock.now();
    final recipe = match.entry.recipe;
    final coverage = match.coverage.clamp(0.0, 1.0);
    final taste =
        (matchTasteLookup != null
                ? matchTasteLookup!(match)
                : tasteLookup(recipe))
            .clamp(0.0, 1.0);
    final novelty = _novelty(recipe, now, lastCooked, similarRecentlyCooked);
    final fit = _fit(recipe, profile);
    final explore = _explore(recipe.id, now);

    final total =
        weights.coverage * coverage +
        weights.taste * taste +
        weights.novelty * novelty +
        weights.fit * fit +
        weights.explore * explore;

    return ScoredRecipe(
      match: match,
      scores: ScoreBreakdown(
        coverage: coverage,
        taste: taste,
        novelty: novelty,
        fit: fit,
        explore: explore,
        total: total,
      ),
    );
  }

  double _novelty(
    Recipe recipe,
    DateTime now,
    Map<String, DateTime> lastCooked,
    Set<String> similarRecentlyCooked,
  ) {
    final cooked = lastCooked[recipe.id];
    if (cooked != null) {
      final days = now.difference(cooked).inMinutes / (60 * 24);
      if (days <= 7) return 0;
      if (days >= 30) return 1;
      return (days - 7) / 23;
    }

    // ASSUMPTION (D-018): a similar dish cooked within the last 7 days gives
    // half of the usual novelty penalty, so novelty starts at 0.5.
    if (similarRecentlyCooked.contains(recipe.id)) return 0.5;

    return 1;
  }

  double _fit(Recipe recipe, ScoringProfile? profile) {
    if (profile == null) return 1;

    var fit = 1.0;
    final maxMinutes = profile.maxTotalMinutes;
    if (maxMinutes != null &&
        maxMinutes > 0 &&
        recipe.totalMinutes > maxMinutes) {
      fit *= maxMinutes / recipe.totalMinutes;
    }

    final maxDifficulty = profile.maxDifficulty;
    if (maxDifficulty != null &&
        recipe.difficulty.index > maxDifficulty.index) {
      fit *= 1 / (1 + recipe.difficulty.index - maxDifficulty.index);
    }

    return fit.clamp(0.0, 1.0);
  }

  /// Random-looking but stable value for a recipe on a given day (TZ 5.3).
  double _explore(String recipeId, DateTime date) {
    final day =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    var hash = _fnv1a('$day|$recipeId');
    // Final avalanche so neighbouring ids do not produce neighbouring values.
    hash ^= hash >> 16;
    hash = (hash * 0x7feb352d) & 0xffffffff;
    hash ^= hash >> 15;
    hash = (hash * 0x846ca68b) & 0xffffffff;
    hash ^= hash >> 16;
    return hash / 0xffffffff;
  }

  int _fnv1a(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
