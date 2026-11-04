import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/matching/recipe_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

Ingredient _ingredient(
  String id, {
  String? name,
  bool isStaple = false,
  String? parentId,
}) {
  return Ingredient(
    id: id,
    createdAt: 0,
    updatedAt: 0,
    name: name ?? id,
    synonyms: const [],
    category: 'test',
    isStaple: isStaple,
    parentId: parentId,
  );
}

Recipe _recipe(String id, {DishType dishType = DishType.main}) {
  return Recipe(
    id: id,
    createdAt: 0,
    updatedAt: 0,
    title: id,
    normalizedTitle: id,
    dishType: dishType,
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
}

RecipeWithIngredients _entry(
  Recipe recipe,
  List<Ingredient> ingredients, {
  Set<String> optional = const {},
}) {
  return RecipeWithIngredients(
    recipe: recipe,
    ingredients: [
      for (final ingredient in ingredients)
        RecipeIngredientLine(
          recipeIngredient: RecipeIngredient(
            id: '${recipe.id}_${ingredient.id}',
            createdAt: 0,
            updatedAt: 0,
            recipeId: recipe.id,
            ingredientId: ingredient.id,
            isOptional: optional.contains(ingredient.id),
          ),
          ingredient: ingredient,
        ),
    ],
  );
}

void main() {
  const matcher = RecipeMatcher();

  group('RecipeMatcher (S1-04 / TZ 5.2)', () {
    test('a child in the pantry covers its parent in a recipe', () {
      final chicken = _ingredient('chicken', name: 'курица');
      final fillet = _ingredient(
        'chicken_fillet',
        name: 'куриное филе',
        parentId: 'chicken',
      );
      final recipe = _recipe('soup');
      final entry = _entry(recipe, [chicken]);

      final result = matcher.match(
        recipes: [entry],
        availableIds: {fillet.id},
        hierarchy: {
          'chicken_fillet': ['chicken'],
        },
      );

      expect(result.ready, hasLength(1));
      expect(result.ready.single.coverage, 1.0);
      expect(result.almostReady, isEmpty);
    });

    test('a parent in the pantry does not cover a child in a recipe', () {
      final chicken = _ingredient('chicken', name: 'курица');
      final fillet = _ingredient(
        'chicken_fillet',
        name: 'куриное филе',
        parentId: 'chicken',
      );
      final entry = _entry(_recipe('fillet'), [fillet]);

      final result = matcher.match(
        recipes: [entry],
        availableIds: {chicken.id},
        hierarchy: {
          'chicken_fillet': ['chicken'],
        },
      );

      expect(result.ready, isEmpty);
      expect(result.almostReady.single.missingIds, ['chicken_fillet']);
    });

    test('staples and optional products are ignored', () {
      final potato = _ingredient('potato', name: 'картошка');
      final salt = _ingredient('salt', name: 'соль', isStaple: true);
      final sourCream = _ingredient('sour_cream', name: 'сметана');
      final entry = _entry(
        _recipe('with_staples'),
        [potato, salt, sourCream],
        optional: {'sour_cream'},
      );

      final result = matcher.match(recipes: [entry], availableIds: {potato.id});

      expect(result.ready.single.coverage, 1.0);
      expect(result.ready.single.missingCount, 0);
    });

    test('splits recipes into ready and almost-ready groups', () {
      final potato = _ingredient('potato', name: 'картошка');
      final onion = _ingredient('onion', name: 'лук');
      final carrot = _ingredient('carrot', name: 'морковь');
      final meat = _ingredient('meat', name: 'мясо');

      final ready = _entry(_recipe('ready'), [potato]);
      final oneMissing = _entry(_recipe('one'), [potato, onion]);
      final twoMissing = _entry(_recipe('two'), [potato, onion, carrot]);
      final threeMissing = _entry(_recipe('three'), [
        potato,
        onion,
        carrot,
        meat,
      ]);

      final result = matcher.match(
        recipes: [ready, oneMissing, twoMissing, threeMissing],
        availableIds: {potato.id},
      );

      expect(result.ready.map((m) => m.entry.recipe.id), ['ready']);
      expect(result.almostReady.map((m) => m.entry.recipe.id), ['one', 'two']);
      expect(result.almostReady.map((m) => m.missingCount), [1, 2]);
      expect(result.all, hasLength(3));
    });

    test('coverage is the share of available required products', () {
      final potato = _ingredient('potato', name: 'картошка');
      final onion = _ingredient('onion', name: 'лук');
      final carrot = _ingredient('carrot', name: 'морковь');
      final meat = _ingredient('meat', name: 'мясо');
      final entry = _entry(_recipe('stew'), [potato, onion, carrot, meat]);

      final match = matcher.matchOne(
        recipe: entry,
        availableIds: {potato.id, onion.id},
      );

      expect(match.coverage, 0.5);
      expect(match.missingCount, 2);
      expect(match.missingNames, ['морковь', 'мясо']);
    });

    test('a recipe without required products is ready with coverage 1.0', () {
      final salt = _ingredient('salt', name: 'соль', isStaple: true);
      final entry = _entry(_recipe('seasoning'), [salt]);

      final match = matcher.matchOne(recipe: entry, availableIds: {});

      expect(match.coverage, 1.0);
      expect(match.canCookNow, isTrue);
    });

    test('missing names fall back to the ingredient id', () {
      final entry = RecipeWithIngredients(
        recipe: _recipe('mystery_recipe'),
        ingredients: [
          const RecipeIngredientLine(
            recipeIngredient: RecipeIngredient(
              id: 'line',
              createdAt: 0,
              updatedAt: 0,
              recipeId: 'mystery_recipe',
              ingredientId: 'mystery',
              isOptional: false,
            ),
            ingredient: null,
          ),
        ],
      );

      final match = matcher.matchOne(recipe: entry, availableIds: {});

      expect(match.missingNames, ['mystery']);
    });
  });
}
