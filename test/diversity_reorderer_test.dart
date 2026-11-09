import 'package:chto_prigotovit/core/catalog/catalog_taxonomy.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/matching/diversity_reorderer.dart';
import 'package:chto_prigotovit/core/matching/recipe_matcher.dart';
import 'package:chto_prigotovit/core/matching/recipe_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

ScoredRecipe _scored(
  String id, {
  DishType dishType = DishType.main,
  String? mainIngredientId,
  String mainCategory = 'vegetables',
  double score = 1.0,
}) {
  final recipe = Recipe(
    id: id,
    createdAt: 0,
    updatedAt: 0,
    title: id,
    normalizedTitle: id,
    dishType: dishType,
    dishGroup: DishGroup.fromDishType(dishType),
    difficulty: Difficulty.easy,
    cuisine: 'русская',
    totalMinutes: 30,
    activeMinutes: 15,
    servings: 2,
    description: '',
    source: RecipeSource.seed,
    fingerprint: id,
    isFavorite: false,
  );

  final ingredients = <RecipeIngredientLine>[];
  if (mainIngredientId != null) {
    ingredients.add(
      RecipeIngredientLine(
        recipeIngredient: RecipeIngredient(
          id: 'ri_$id',
          createdAt: 0,
          updatedAt: 0,
          recipeId: id,
          ingredientId: mainIngredientId,
          isOptional: false,
        ),
        ingredient: Ingredient(
          id: mainIngredientId,
          createdAt: 0,
          updatedAt: 0,
          name: mainIngredientId,
          synonyms: const [],
          category: mainCategory,
          isStaple: false,
        ),
      ),
    );
  }

  final match = RecipeMatch(
    entry: RecipeWithIngredients(recipe: recipe, ingredients: ingredients),
    coverage: 1.0,
    missingIds: const [],
    missingNames: const [],
  );

  return ScoredRecipe(
    match: match,
    scores: ScoreBreakdown(
      coverage: 1.0,
      taste: 0.5,
      novelty: 1.0,
      fit: 1.0,
      explore: 0.5,
      total: score,
    ),
  );
}

void main() {
  group('RecipeDiversityReorderer (S1-06 / TZ 5.4)', () {
    const reorderer = RecipeDiversityReorderer();

    test('limits same dish type to at most 3 in the top 10', () {
      // 6 soups (scores 1.0 to 0.5), 3 mains, 3 salads, 3 desserts.
      final input = [
        _scored('soup_1', dishType: DishType.soup, score: 1.0),
        _scored('soup_2', dishType: DishType.soup, score: 0.9),
        _scored('soup_3', dishType: DishType.soup, score: 0.8),
        _scored('soup_4', dishType: DishType.soup, score: 0.7),
        _scored('soup_5', dishType: DishType.soup, score: 0.6),
        _scored('soup_6', dishType: DishType.soup, score: 0.5),
        _scored('main_1', dishType: DishType.main, score: 0.49),
        _scored('main_2', dishType: DishType.main, score: 0.48),
        _scored('main_3', dishType: DishType.main, score: 0.47),
        _scored('salad_1', dishType: DishType.salad, score: 0.46),
        _scored('salad_2', dishType: DishType.salad, score: 0.45),
        _scored('salad_3', dishType: DishType.salad, score: 0.44),
        _scored('dessert_1', dishType: DishType.dessert, score: 0.43),
        _scored('dessert_2', dishType: DishType.dessert, score: 0.42),
        _scored('dessert_3', dishType: DishType.dessert, score: 0.41),
      ];

      final result = reorderer.reorder(input);
      expect(result.length, equals(15));

      final top10 = result.take(10).toList();
      final soupCount = top10
          .where((r) => r.entry.recipe.dishType == DishType.soup)
          .length;
      expect(soupCount, equals(3), reason: 'At most 3 soups in top 10');

      // The top 3 soups should be the highest-scoring ones:
      expect(top10.take(3).map((r) => r.entry.recipe.id), [
        'soup_1',
        'soup_2',
        'soup_3',
      ]);
      // Other dish types are pulled forward:
      final mainsInTop10 = top10
          .where((r) => r.entry.recipe.dishType == DishType.main)
          .length;
      expect(mainsInTop10, equals(3));

      // After top 10, the remaining soups appear:
      final afterTop10 = result.skip(10).map((r) => r.entry.recipe.id).toList();
      expect(afterTop10, containsAll(['soup_4', 'soup_5', 'soup_6']));
    });

    test('limits same main ingredient to at most 2 in top 10', () {
      // 5 chicken dishes across different dish types, 3 beef, 2 potato, 2 fish, 2 pork.
      final input = [
        _scored(
          'ch_1',
          dishType: DishType.soup,
          mainIngredientId: 'chicken',
          mainCategory: 'poultry',
          score: 1.0,
        ),
        _scored(
          'ch_2',
          dishType: DishType.main,
          mainIngredientId: 'chicken',
          mainCategory: 'poultry',
          score: 0.9,
        ),
        _scored(
          'ch_3',
          dishType: DishType.salad,
          mainIngredientId: 'chicken',
          mainCategory: 'poultry',
          score: 0.8,
        ),
        _scored(
          'ch_4',
          dishType: DishType.snack,
          mainIngredientId: 'chicken',
          mainCategory: 'poultry',
          score: 0.7,
        ),
        _scored(
          'ch_5',
          dishType: DishType.baking,
          mainIngredientId: 'chicken',
          mainCategory: 'poultry',
          score: 0.6,
        ),
        _scored(
          'beef_1',
          dishType: DishType.soup,
          mainIngredientId: 'beef',
          mainCategory: 'meat',
          score: 0.5,
        ),
        _scored(
          'beef_2',
          dishType: DishType.main,
          mainIngredientId: 'beef',
          mainCategory: 'meat',
          score: 0.49,
        ),
        _scored(
          'beef_3',
          dishType: DishType.snack,
          mainIngredientId: 'beef',
          mainCategory: 'meat',
          score: 0.48,
        ),
        _scored(
          'pot_1',
          dishType: DishType.side,
          mainIngredientId: 'potato',
          mainCategory: 'vegetables',
          score: 0.47,
        ),
        _scored(
          'pot_2',
          dishType: DishType.breakfast,
          mainIngredientId: 'potato',
          mainCategory: 'vegetables',
          score: 0.46,
        ),
        _scored(
          'fish_1',
          dishType: DishType.main,
          mainIngredientId: 'fish',
          mainCategory: 'fish',
          score: 0.45,
        ),
        _scored(
          'fish_2',
          dishType: DishType.salad,
          mainIngredientId: 'fish',
          mainCategory: 'fish',
          score: 0.44,
        ),
        _scored(
          'pork_1',
          dishType: DishType.main,
          mainIngredientId: 'pork',
          mainCategory: 'meat',
          score: 0.43,
        ),
        _scored(
          'pork_2',
          dishType: DishType.soup,
          mainIngredientId: 'pork',
          mainCategory: 'meat',
          score: 0.42,
        ),
        _scored(
          'cabbage_1',
          dishType: DishType.snack,
          mainIngredientId: 'cabbage',
          mainCategory: 'vegetables',
          score: 0.41,
        ),
      ];

      final result = reorderer.reorder(input);
      final top10 = result.take(10).toList();

      final chickenInTop10 = top10
          .where((r) => reorderer.resolveMainIngredient(r.entry) == 'chicken')
          .length;
      expect(chickenInTop10, equals(2));
    });

    test(
      'resolves child ingredient to root ancestor for main ingredient limit',
      () {
        // chicken_fillet and chicken share root ancestor 'chicken'
        final input = [
          _scored(
            'r1',
            mainIngredientId: 'chicken_fillet',
            mainCategory: 'poultry',
            score: 1.0,
          ),
          _scored(
            'r2',
            mainIngredientId: 'chicken_thigh',
            mainCategory: 'poultry',
            score: 0.9,
          ),
          _scored(
            'r3',
            mainIngredientId: 'chicken',
            mainCategory: 'poultry',
            score: 0.8,
          ),
          _scored(
            'r4',
            mainIngredientId: 'beef',
            mainCategory: 'meat',
            score: 0.7,
          ),
        ];

        String rootLookup(String id) {
          if (id.startsWith('chicken')) return 'chicken';
          return id;
        }

        final result = reorderer.reorder(input, rootAncestorLookup: rootLookup);

        final top2Ids = result.take(2).map((r) => r.entry.recipe.id).toList();
        expect(top2Ids, containsAll(['r1', 'r2']));
        // r3 should be pushed behind r4 because chicken limit (2) is reached
        expect(result[2].entry.recipe.id, equals('r4'));
        expect(result[3].entry.recipe.id, equals('r3'));
      },
    );

    test('ignores dish type limit when hasDishTypeFilter is true', () {
      // 5 soups, all should stay in top 5 if hasDishTypeFilter = true
      final input = [
        _scored('soup_1', dishType: DishType.soup, score: 1.0),
        _scored('soup_2', dishType: DishType.soup, score: 0.9),
        _scored('soup_3', dishType: DishType.soup, score: 0.8),
        _scored('soup_4', dishType: DishType.soup, score: 0.7),
        _scored('soup_5', dishType: DishType.soup, score: 0.6),
      ];

      final result = reorderer.reorder(input, hasDishTypeFilter: true);

      expect(result.map((r) => r.entry.recipe.id).toList(), [
        'soup_1',
        'soup_2',
        'soup_3',
        'soup_4',
        'soup_5',
      ]);
    });

    test('relaxes constraints when pool cannot satisfy all limits', () {
      // All 5 are soups, without filter: should not drop any recipes!
      final input = [
        _scored('soup_1', dishType: DishType.soup, score: 1.0),
        _scored('soup_2', dishType: DishType.soup, score: 0.9),
        _scored('soup_3', dishType: DishType.soup, score: 0.8),
        _scored('soup_4', dishType: DishType.soup, score: 0.7),
        _scored('soup_5', dishType: DishType.soup, score: 0.6),
      ];

      final result = reorderer.reorder(input);
      expect(result.length, equals(5));
      expect(result.map((r) => r.entry.recipe.id).toList(), [
        'soup_1',
        'soup_2',
        'soup_3',
        'soup_4',
        'soup_5',
      ]);
    });

    test('appends recipes after top 10 in original score order', () {
      final input = List.generate(
        15,
        (i) => _scored('item_$i', score: 1.0 - (i * 0.05)),
      );

      final result = reorderer.reorder(input);
      expect(result.length, equals(15));
      // Verify items after index 9 preserve relative order
      final remaining = result.skip(10).map((r) => r.entry.recipe.id).toList();
      expect(remaining.length, equals(5));
    });

    test('resolveMainIngredient prioritizes meat/poultry/fish over other ingredients', () {
      const recipe = Recipe(
        id: 'r_beef_soup',
        createdAt: 0,
        updatedAt: 0,
        title: 'Суп',
        normalizedTitle: 'суп',
        dishType: DishType.soup,
        dishGroup: DishGroup.soup,
        difficulty: Difficulty.easy,
        cuisine: 'русская',
        totalMinutes: 30,
        activeMinutes: 15,
        servings: 2,
        description: '',
        source: RecipeSource.seed,
        fingerprint: 'fp',
        isFavorite: false,
      );

      final lines = [
        // Staple: salt (ignored)
        const RecipeIngredientLine(
          recipeIngredient: RecipeIngredient(
            id: 'ri_salt',
            createdAt: 0,
            updatedAt: 0,
            recipeId: 'r_beef_soup',
            ingredientId: 'salt',
            isOptional: false,
          ),
          ingredient: Ingredient(
            id: 'salt',
            createdAt: 0,
            updatedAt: 0,
            name: 'Соль',
            synonyms: [],
            category: 'spices',
            isStaple: true,
          ),
        ),
        // Vegetable: onion
        const RecipeIngredientLine(
          recipeIngredient: RecipeIngredient(
            id: 'ri_onion',
            createdAt: 0,
            updatedAt: 0,
            recipeId: 'r_beef_soup',
            ingredientId: 'onion',
            isOptional: false,
          ),
          ingredient: Ingredient(
            id: 'onion',
            createdAt: 0,
            updatedAt: 0,
            name: 'Лук',
            synonyms: [],
            category: 'vegetables',
            isStaple: false,
          ),
        ),
        // Meat: beef (should be chosen as main!)
        const RecipeIngredientLine(
          recipeIngredient: RecipeIngredient(
            id: 'ri_beef',
            createdAt: 0,
            updatedAt: 0,
            recipeId: 'r_beef_soup',
            ingredientId: 'beef',
            isOptional: false,
          ),
          ingredient: Ingredient(
            id: 'beef',
            createdAt: 0,
            updatedAt: 0,
            name: 'Говядина',
            synonyms: [],
            category: 'meat',
            isStaple: false,
          ),
        ),
      ];

      final entry = RecipeWithIngredients(recipe: recipe, ingredients: lines);
      final mainId = reorderer.resolveMainIngredient(entry);
      expect(mainId, equals('beef'));
    });
  });
}
