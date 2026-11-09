import 'package:chto_prigotovit/core/catalog/catalog_taxonomy.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/matching/recipe_matcher.dart';
import 'package:chto_prigotovit/core/matching/recipe_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

Recipe _recipe(
  String id, {
  DishType dishType = DishType.main,
  Difficulty difficulty = Difficulty.easy,
  int totalMinutes = 30,
}) {
  return Recipe(
    id: id,
    createdAt: 0,
    updatedAt: 0,
    title: id,
    normalizedTitle: id,
    dishType: dishType,
    dishGroup: DishGroup.fromDishType(dishType),
    difficulty: difficulty,
    cuisine: 'русская',
    totalMinutes: totalMinutes,
    activeMinutes: 15,
    servings: 2,
    description: '',
    source: RecipeSource.seed,
    fingerprint: id,
    isFavorite: false,
  );
}

RecipeMatch _match(String id, {double coverage = 1.0, int missing = 0}) {
  final recipe = _recipe(id);
  return RecipeMatch(
    entry: RecipeWithIngredients(recipe: recipe, ingredients: const []),
    coverage: coverage,
    missingIds: List.filled(missing, 'missing'),
    missingNames: List.filled(missing, 'missing'),
  );
}

void main() {
  group('RecipeScorer (S1-05 / TZ 5.3)', () {
    test('default weights match the formula and sum to 1.0', () {
      const weights = ScoringWeights();
      expect(weights.coverage, 0.35);
      expect(weights.taste, 0.30);
      expect(weights.novelty, 0.20);
      expect(weights.fit, 0.10);
      expect(weights.explore, 0.05);
      expect(weights.total, closeTo(1.0, 1e-9));
    });

    test('uses the configured weights and taste lookup', () {
      const scorer = RecipeScorer(
        weights: ScoringWeights(
          coverage: 1,
          taste: 0,
          novelty: 0,
          fit: 0,
          explore: 0,
        ),
        tasteLookup: _alwaysOne,
      );
      final scored = scorer.score(
        _match('soup', coverage: 0.5),
        date: DateTime(2026, 11, 4),
      );

      expect(scored.scores.taste, 1.0);
      expect(scored.scores.total, 0.5);
    });

    test('stage 1 taste is 0.5 by default', () {
      const scorer = RecipeScorer();
      final scored = scorer.score(_match('soup'), date: DateTime(2026, 11, 4));

      expect(scored.scores.taste, 0.5);
    });

    test('explore is deterministic for a recipe and day, and varies', () {
      const scorer = RecipeScorer();
      final date = DateTime(2026, 11, 4);
      final first = scorer.score(_match('soup'), date: date);
      final second = scorer.score(_match('soup'), date: date);
      final nextDay = scorer.score(_match('soup'), date: DateTime(2026, 11, 5));
      final otherRecipe = scorer.score(_match('stew'), date: date);

      expect(first.scores.explore, second.scores.explore);
      expect(first.scores.explore, inInclusiveRange(0.0, 1.0));
      expect({
        first.scores.explore,
        nextDay.scores.explore,
        otherRecipe.scores.explore,
      }, hasLength(3));
    });

    test('novelty grows from 0 to 1 between 7 and 30 days', () {
      const scorer = RecipeScorer(
        weights: ScoringWeights(
          coverage: 0,
          taste: 0,
          novelty: 1,
          fit: 0,
          explore: 0,
        ),
      );
      final now = DateTime(2026, 11, 4);

      double noveltyFor(int daysAgo) {
        return scorer
            .score(
              _match('soup'),
              date: now,
              lastCooked: {'soup': now.subtract(Duration(days: daysAgo))},
            )
            .scores
            .novelty;
      }

      expect(noveltyFor(3), 0);
      expect(noveltyFor(7), 0);
      expect(noveltyFor(30), 1);
      expect(noveltyFor(18), closeTo(11 / 23, 1e-9));
    });

    test('never cooked and similar-recent dishes get the expected novelty', () {
      const scorer = RecipeScorer(
        weights: ScoringWeights(
          coverage: 0,
          taste: 0,
          novelty: 1,
          fit: 0,
          explore: 0,
        ),
      );
      final date = DateTime(2026, 11, 4);

      expect(scorer.score(_match('new_dish'), date: date).scores.novelty, 1);
      expect(
        scorer
            .score(
              _match('similar_dish'),
              date: date,
              similarRecentlyCooked: {'similar_dish'},
            )
            .scores
            .novelty,
        0.5,
      );
    });

    test('fit decreases for time and difficulty over the profile', () {
      const scorer = RecipeScorer(
        weights: ScoringWeights(
          coverage: 0,
          taste: 0,
          novelty: 0,
          fit: 1,
          explore: 0,
        ),
      );
      final date = DateTime(2026, 11, 4);

      double fitFor(Recipe recipe, ScoringProfile profile) {
        return scorer
            .score(
              RecipeMatch(
                entry: RecipeWithIngredients(
                  recipe: recipe,
                  ingredients: const [],
                ),
                coverage: 1,
                missingIds: const [],
                missingNames: const [],
              ),
              date: date,
              profile: profile,
            )
            .scores
            .fit;
      }

      expect(
        fitFor(
          _recipe('quick'),
          const ScoringProfile(
            maxTotalMinutes: 30,
            maxDifficulty: Difficulty.easy,
          ),
        ),
        1,
      );
      expect(
        fitFor(
          _recipe('long', totalMinutes: 60),
          const ScoringProfile(maxTotalMinutes: 30),
        ),
        0.5,
      );
      expect(
        fitFor(
          _recipe('medium', difficulty: Difficulty.medium),
          const ScoringProfile(maxDifficulty: Difficulty.easy),
        ),
        0.5,
      );
      expect(
        fitFor(
          _recipe('long_hard', difficulty: Difficulty.hard, totalMinutes: 60),
          const ScoringProfile(
            maxTotalMinutes: 30,
            maxDifficulty: Difficulty.easy,
          ),
        ),
        closeTo(1 / 6, 1e-9),
      );
    });

    test('rank sorts by score descending and breaks ties by title', () {
      const scorer = RecipeScorer(
        weights: ScoringWeights(
          coverage: 1,
          taste: 0,
          novelty: 0,
          fit: 0,
          explore: 0,
        ),
      );
      final ranked = scorer.rank([
        _match('almost', coverage: 0.5, missing: 1),
        _match('ready_b', coverage: 1),
        _match('ready_a', coverage: 1),
      ], date: DateTime(2026, 11, 4));

      expect(ranked.map((r) => r.entry.recipe.id), [
        'ready_a',
        'ready_b',
        'almost',
      ]);
    });
  });
}

double _alwaysOne(Recipe recipe) => 1;
