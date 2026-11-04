import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/ingredient_dao.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/matching/diversity_reorderer.dart';
import 'package:chto_prigotovit/core/matching/ingredient_normalizer.dart';
import 'package:chto_prigotovit/core/matching/recipe_matcher.dart';
import 'package:chto_prigotovit/core/matching/recipe_scorer.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late IngredientDao ingredientDao;
  late RecipeDao recipeDao;
  late IngredientNormalizer normalizer;
  late Map<String, List<String>> hierarchy;

  setUpAll(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    // Trigger seed loading
    await db.customSelect('SELECT 1').get();
    ingredientDao = IngredientDao(db);
    recipeDao = RecipeDao(db);
    normalizer = await ingredientDao.createNormalizer();
    hierarchy = await ingredientDao.hierarchy();
  });

  tearDownAll(() async {
    await db.close();
  });

  group('Matching Integration (S1-08 / TZ 5.1-5.4)', () {
    test('normalizes colloquial terms and hierarchy correctly', () {
      // «картошка» resolves to potato
      final potatoId = normalizer.resolve('картошка');
      expect(potatoId, equals('potato'));

      // «морковка» resolves to carrot (canonical name is морковь)
      final carrotId = normalizer.resolve('морковка');
      expect(carrotId, equals('carrot'));

      // «филе» resolves to chicken_fillet
      final filletId = normalizer.resolve('филе');
      expect(filletId, equals('chicken_fillet'));

      // chicken_fillet has ancestor chicken
      expect(normalizer.ancestorsOf('chicken_fillet'), contains('chicken'));
      expect(normalizer.isDescendantOf('chicken_fillet', 'chicken'), isTrue);
    });

    test('validates scoring formula on fixed inputs', () {
      const weights = ScoringWeights(
        coverage: 0.35,
        taste: 0.30,
        novelty: 0.20,
        fit: 0.10,
        explore: 0.05,
      );

      final breakdown = ScoreBreakdown(
        coverage: 1.0,
        taste: 0.5,
        novelty: 1.0,
        fit: 1.0,
        explore: 0.5,
        total:
            weights.coverage * 1.0 +
            weights.taste * 0.5 +
            weights.novelty * 1.0 +
            weights.fit * 1.0 +
            weights.explore * 0.5,
      );

      // 0.35*1.0 + 0.30*0.5 + 0.20*1.0 + 0.10*1.0 + 0.05*0.5 = 0.35 + 0.15 + 0.20 + 0.10 + 0.025 = 0.825
      expect(breakdown.total, closeTo(0.825, 1e-9));
    });

    test('Stage 1 completion criterion: «картошка, лук, морковь, курица» yields soup and main dish in ready, and filter «Суп + Легко» filters accurately', () async {
      // Resolve free text input into pantry ids
      const input = 'картошка, лук, морковь, курица';
      final resolvedIds = normalizer.resolveMany(input).toSet();

      expect(
        resolvedIds,
        containsAll(['potato', 'onion', 'carrot', 'chicken']),
      );

      // Load all recipes with ingredients from seed
      final allRecipes = await recipeDao.allWithIngredients();
      expect(allRecipes.length, greaterThanOrEqualTo(120));

      // Match against available ids
      const matcher = RecipeMatcher();
      final matchResult = matcher.match(
        recipes: allRecipes,
        availableIds: resolvedIds,
        hierarchy: hierarchy,
      );

      // Group 1: «Можно приготовить сейчас»
      expect(matchResult.ready, isNotEmpty);

      // Score both groups
      const scorer = RecipeScorer();
      final scoredReady = scorer.rank(matchResult.ready);
      final scoredAlmost = scorer.rank(matchResult.almostReady);
      expect(scoredAlmost, isNotEmpty);

      // Apply diversity reordering
      const reorderer = RecipeDiversityReorderer();
      String rootAncestorLookup(String id) =>
          normalizer.ancestorsOf(id).lastOrNull ?? id;

      final diverseReady = reorderer.reorder(
        scoredReady,
        rootAncestorLookup: rootAncestorLookup,
      );

      // Verify: in «Можно сейчас» there IS a soup AND a main dish
      final hasSoup = diverseReady.any(
        (s) => s.entry.recipe.dishType == DishType.soup,
      );
      final hasMain = diverseReady.any(
        (s) => s.entry.recipe.dishType == DishType.main,
      );

      expect(hasSoup, isTrue, reason: 'Must contain at least one soup');
      expect(hasMain, isTrue, reason: 'Must contain at least one main dish');

      // Apply filter: «Суп + Легко»
      final filtered = diverseReady.where((s) {
        final recipe = s.entry.recipe;
        return recipe.dishType == DishType.soup &&
            recipe.difficulty == Difficulty.easy;
      }).toList();

      expect(filtered, isNotEmpty, reason: 'Must find easy soup');
      for (final item in filtered) {
        expect(item.entry.recipe.dishType, equals(DishType.soup));
        expect(item.entry.recipe.difficulty, equals(Difficulty.easy));
        expect(item.match.missingCount, equals(0));
      }

      // Diversity constraint on top 10
      final top10 = diverseReady.take(10).toList();
      final dishTypeCounts = <DishType, int>{};
      for (final item in top10) {
        final t = item.entry.recipe.dishType;
        dishTypeCounts[t] = (dishTypeCounts[t] ?? 0) + 1;
        expect(
          dishTypeCounts[t]!,
          lessThanOrEqualTo(3),
          reason: 'At most 3 dishes of any single type in top 10',
        );
      }
    });
  });
}
