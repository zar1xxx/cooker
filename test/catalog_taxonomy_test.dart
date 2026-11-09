import 'package:flutter_test/flutter_test.dart';
import 'package:chto_prigotovit/core/catalog/catalog_taxonomy.dart';
import 'package:chto_prigotovit/core/db/enums.dart';

void main() {
  group('R7-01: Catalog Taxonomy (DishGroup, Cuisine, Tags)', () {
    test('DishGroup has exactly 11 canonical groups with Russian titles', () {
      expect(DishGroup.values.length, 11);
      final ids = DishGroup.values.map((g) => g.id).toSet();
      expect(ids, {
        'baking',
        'meat',
        'fish_seafood',
        'vegetable',
        'soup',
        'porridge_side',
        'salad_snack',
        'egg_dairy',
        'dessert',
        'beverage',
        'preserves',
      });

      for (final g in DishGroup.values) {
        expect(g.titleRu.isNotEmpty, isTrue);
        expect(DishGroup.fromId(g.id), equals(g));
        expect(DishGroup.tryFromId(g.id), equals(g));
      }
      expect(DishGroup.tryFromId('non_existent'), isNull);
    });

    test('DishGroup maps from legacy DishType correctly', () {
      expect(DishGroup.fromDishType(DishType.soup), DishGroup.soup);
      expect(DishGroup.fromDishType(DishType.baking), DishGroup.baking);
      expect(DishGroup.fromDishType(DishType.dessert), DishGroup.dessert);
      expect(DishGroup.fromDishType(DishType.drink), DishGroup.beverage);
      expect(DishGroup.fromDishType(DishType.preserve), DishGroup.preserves);
      expect(DishGroup.fromDishType(DishType.salad), DishGroup.saladSnack);
      expect(DishGroup.fromDishType(DishType.snack), DishGroup.saladSnack);
      expect(DishGroup.fromDishType(DishType.side), DishGroup.porridgeSide);
      expect(DishGroup.fromDishType(DishType.breakfast), DishGroup.eggDairy);
      expect(DishGroup.fromDishType(DishType.main), DishGroup.meat);
    });

    test('Cuisine defines canonical cuisines and normalizes codes', () {
      expect(Cuisine.canonical.length, 9);
      expect(Cuisine.normalize(null), 'home');
      expect(Cuisine.normalize(''), 'home');
      expect(Cuisine.normalize('RU'), 'ru');
      expect(Cuisine.normalize('  it  '), 'it');

      expect(Cuisine.titleForCode('ru'), 'Русская');
      expect(Cuisine.titleForCode('it'), 'Итальянская');
      expect(Cuisine.titleForCode('ge'), 'Грузинская');
      expect(Cuisine.titleForCode('uz'), 'Узбекская');
      expect(Cuisine.titleForCode('home'), 'Домашняя');
      expect(Cuisine.titleForCode('xyz'), 'XYZ');
    });

    test(
      'TagKind, DietaryTag, OccasionTag, MoodTag enums and RecipeTag structure',
      () {
        expect(TagKind.values.length, 3);
        expect(DietaryTag.values.length, 7);
        expect(OccasionTag.values.length, 6);
        expect(MoodTag.values.length, 6);

        final tag1 = RecipeTag.dietary(DietaryTag.vegetarian);
        final tag2 = const RecipeTag(kind: TagKind.dietary, tag: 'vegetarian');
        expect(tag1, equals(tag2));
        expect(tag1.localizedTitle, 'Вегетарианское');
        expect(tag1.toString(), 'dietary:vegetarian');

        final tagOccasion = RecipeTag.occasion(OccasionTag.quick);
        expect(tagOccasion.localizedTitle, contains('Быстрое'));

        final tagMood = RecipeTag.mood(MoodTag.cozy);
        expect(tagMood.localizedTitle, 'Уютное');
      },
    );
  });

  group('R7-01: Taxonomy Inference Rules', () {
    test('Rule: meat or poultry ingredients -> NOT vegetarian, NOT vegan, NOT lenten', () {
      final ingredients = [
        const TaxonomyIngredient(
          id: 'chicken_breast',
          amount: 300,
          unit: 'g',
          category: 'poultry',
        ),
        const TaxonomyIngredient(
          id: 'carrot',
          amount: 100,
          unit: 'g',
          category: 'vegetables',
        ),
        const TaxonomyIngredient(id: 'water', amount: 500, unit: 'ml'),
      ];

      final tags = RecipeTaxonomyRules.inferDietaryTags(
        ingredients: ingredients,
      );
      expect(tags.contains(DietaryTag.vegetarian), isFalse);
      expect(tags.contains(DietaryTag.vegan), isFalse);
      expect(tags.contains(DietaryTag.lenten), isFalse);
      // Chicken breast has no gluten and no dairy
      expect(tags.contains(DietaryTag.glutenFree), isTrue);
      expect(tags.contains(DietaryTag.lactoseFree), isTrue);
    });

    test('Rule: fish ingredients -> NOT vegetarian, NOT vegan, NOT lenten', () {
      final ingredients = [
        const TaxonomyIngredient(
          id: 'salmon',
          amount: 200,
          unit: 'g',
          category: 'fish',
        ),
        const TaxonomyIngredient(
          id: 'potato',
          amount: 200,
          unit: 'g',
          category: 'vegetables',
        ),
      ];

      final tags = RecipeTaxonomyRules.inferDietaryTags(
        ingredients: ingredients,
      );
      expect(tags.contains(DietaryTag.vegetarian), isFalse);
      expect(tags.contains(DietaryTag.vegan), isFalse);
      expect(tags.contains(DietaryTag.lenten), isFalse);
      expect(tags.contains(DietaryTag.glutenFree), isTrue);
    });

    test('Rule: dairy and eggs -> vegetarian, but NOT vegan, NOT lenten, NOT lactose_free for dairy', () {
      final ingredients = [
        const TaxonomyIngredient(id: 'egg', amount: 2, unit: 'pcs'),
        const TaxonomyIngredient(
          id: 'milk',
          amount: 100,
          unit: 'ml',
          category: 'dairy',
        ),
        const TaxonomyIngredient(
          id: 'dill',
          amount: 10,
          unit: 'g',
          category: 'greens',
        ),
      ];

      final tags = RecipeTaxonomyRules.inferDietaryTags(
        ingredients: ingredients,
      );
      expect(tags.contains(DietaryTag.vegetarian), isTrue);
      expect(tags.contains(DietaryTag.vegan), isFalse);
      expect(tags.contains(DietaryTag.lenten), isFalse);
      expect(tags.contains(DietaryTag.lactoseFree), isFalse); // Has milk
    });

    test('Rule: eggs alone without dairy -> lactoseFree is true', () {
      final ingredients = [
        const TaxonomyIngredient(id: 'egg', amount: 2, unit: 'pcs'),
        const TaxonomyIngredient(
          id: 'tomato',
          amount: 100,
          unit: 'g',
          category: 'vegetables',
        ),
      ];

      final tags = RecipeTaxonomyRules.inferDietaryTags(
        ingredients: ingredients,
      );
      expect(tags.contains(DietaryTag.vegetarian), isTrue);
      expect(tags.contains(DietaryTag.vegan), isFalse);
      expect(
        tags.contains(DietaryTag.lactoseFree),
        isTrue,
      ); // Eggs have no lactose
    });

    test('Rule: pure plant ingredients -> vegan, lenten, vegetarian', () {
      final ingredients = [
        const TaxonomyIngredient(
          id: 'potato',
          amount: 200,
          unit: 'g',
          category: 'vegetables',
        ),
        const TaxonomyIngredient(
          id: 'mushrooms',
          amount: 150,
          unit: 'g',
          category: 'mushrooms',
        ),
        const TaxonomyIngredient(
          id: 'onion',
          amount: 50,
          unit: 'g',
          category: 'vegetables',
        ),
        const TaxonomyIngredient(id: 'vegetable_oil', amount: 15, unit: 'ml'),
      ];

      final tags = RecipeTaxonomyRules.inferDietaryTags(
        ingredients: ingredients,
      );
      expect(tags.contains(DietaryTag.vegetarian), isTrue);
      expect(tags.contains(DietaryTag.vegan), isTrue);
      expect(tags.contains(DietaryTag.lenten), isTrue);
      expect(tags.contains(DietaryTag.glutenFree), isTrue);
      expect(tags.contains(DietaryTag.lactoseFree), isTrue);
    });

    test('Rule: flour or bread -> NOT glutenFree', () {
      final ingredients = [
        const TaxonomyIngredient(
          id: 'wheat_flour',
          amount: 200,
          unit: 'g',
          category: 'bakery',
        ),
        const TaxonomyIngredient(id: 'water', amount: 100, unit: 'ml'),
        const TaxonomyIngredient(id: 'salt', amount: 2, unit: 'g'),
      ];

      final tags = RecipeTaxonomyRules.inferDietaryTags(
        ingredients: ingredients,
      );
      expect(tags.contains(DietaryTag.glutenFree), isFalse);
      expect(tags.contains(DietaryTag.vegan), isTrue);
    });

    test('Rule: low_calorie threshold <= 350 kcal per serving', () {
      final lowCalIngredients = [
        const TaxonomyIngredient(
          id: 'cucumber',
          amount: 200,
          unit: 'g',
          category: 'vegetables',
        ),
        const TaxonomyIngredient(
          id: 'tomato',
          amount: 200,
          unit: 'g',
          category: 'vegetables',
        ),
        const TaxonomyIngredient(
          id: 'dill',
          amount: 10,
          unit: 'g',
          category: 'greens',
        ),
        const TaxonomyIngredient(id: 'olive_oil', amount: 5, unit: 'ml'),
      ];

      final tagsLow = RecipeTaxonomyRules.inferDietaryTags(
        ingredients: lowCalIngredients,
        servings: 2,
      );
      expect(tagsLow.contains(DietaryTag.lowCalorie), isTrue);

      final highCalTags = RecipeTaxonomyRules.inferDietaryTags(
        ingredients: lowCalIngredients,
        kcalPerServing: 550, // Explicitly above 350
        servings: 2,
      );
      expect(highCalTags.contains(DietaryTag.lowCalorie), isFalse);
    });

    test('Rule: high_protein threshold >= 20g protein per serving', () {
      final tagsHighProtein = RecipeTaxonomyRules.inferDietaryTags(
        ingredients: [
          const TaxonomyIngredient(
            id: 'chicken_breast',
            amount: 200,
            unit: 'g',
            category: 'poultry',
          ),
        ],
        servings: 1,
      );
      expect(tagsHighProtein.contains(DietaryTag.highProtein), isTrue);

      final tagsLowProtein = RecipeTaxonomyRules.inferDietaryTags(
        ingredients: [
          const TaxonomyIngredient(
            id: 'apple',
            amount: 100,
            unit: 'g',
            category: 'fruits',
          ),
        ],
        servings: 2,
      );
      expect(tagsLowProtein.contains(DietaryTag.highProtein), isFalse);
    });

    test('Rule: occasion and mood inference based on time and attributes', () {
      final occasionsQuick = RecipeTaxonomyRules.inferOccasionTags(
        totalMinutes: 20,
        servings: 2,
      );
      expect(occasionsQuick.contains(OccasionTag.quick), isTrue);
      expect(occasionsQuick.contains(OccasionTag.everyday), isTrue);

      final occasionsGuests = RecipeTaxonomyRules.inferOccasionTags(
        totalMinutes: 90,
        servings: 8,
        title: 'Праздничный торт',
      );
      expect(occasionsGuests.contains(OccasionTag.forGuests), isTrue);
      expect(occasionsGuests.contains(OccasionTag.festive), isTrue);

      final moods = RecipeTaxonomyRules.inferMoodTags(
        totalMinutes: 15,
        dishGroup: DishGroup.soup,
        cuisine: 'it',
      );
      expect(moods.contains(MoodTag.onTheRun), isTrue); // <= 20 min
      expect(moods.contains(MoodTag.cozy), isTrue); // soup
      expect(moods.contains(MoodTag.somethingNew), isTrue); // Italian cuisine
    });

    test('Rule: inferDishGroup identifies group from title, ingredients, and dishType', () {
      expect(
        RecipeTaxonomyRules.inferDishGroup(
          ingredients: [],
          title: 'Борщ домашний',
        ),
        DishGroup.soup,
      );

      expect(
        RecipeTaxonomyRules.inferDishGroup(
          ingredients: [],
          title: 'Шоколадный торт',
        ),
        DishGroup.dessert,
      );

      expect(
        RecipeTaxonomyRules.inferDishGroup(
          dishType: DishType.main,
          ingredients: [const TaxonomyIngredient(id: 'beef', category: 'meat')],
        ),
        DishGroup.meat,
      );

      expect(
        RecipeTaxonomyRules.inferDishGroup(
          dishType: DishType.main,
          ingredients: [const TaxonomyIngredient(id: 'cod', category: 'fish')],
        ),
        DishGroup.fishSeafood,
      );
    });

    test('NutritionReference estimates calories and protein accurately', () {
      final (kcal, protein) = NutritionReference.estimatePerServing(
        ingredients: [
          (
            ingredientId: 'potato',
            amount: 200,
            unit: 'g',
            category: 'vegetables',
          ),
          (
            ingredientId: 'chicken_breast',
            amount: 200,
            unit: 'g',
            category: 'poultry',
          ),
        ],
        servings: 2,
      );
      // Potato: 200g * 77/100 = 154 kcal, 4g protein
      // Chicken: 200g * 165/100 = 330 kcal, 62g protein
      // Total: 484 kcal, 66g protein -> per 2 servings: ~242 kcal, 33g protein
      expect(kcal, inInclusiveRange(230, 260));
      expect(protein, inInclusiveRange(30.0, 36.0));
    });
  });
}
