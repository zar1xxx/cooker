import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final ingredients =
      (_loadJson('assets/seed/ingredients.json')['ingredients'] as List)
          .cast<Map<String, dynamic>>();
  final recipes = (_loadJson('assets/seed/recipes.json')['recipes'] as List)
      .cast<Map<String, dynamic>>();
  final byId = {
    for (final ingredient in ingredients)
      ingredient['id'] as String: ingredient,
  };

  group('Seed references (S1-01)', () {
    test('ingredient ids are unique and parents exist', () {
      final ids = <String>{};
      for (final ingredient in ingredients) {
        final id = ingredient['id'] as String;
        expect(ids.add(id), isTrue, reason: 'duplicate ingredient id $id');
      }
      for (final ingredient in ingredients) {
        final parentId = ingredient['parent_id'] as String?;
        if (parentId == null) continue;
        expect(
          byId.containsKey(parentId),
          isTrue,
          reason: '${ingredient['id']} refers to missing parent $parentId',
        );
      }
    });

    test('ingredient hierarchy has no cycles', () {
      for (final ingredient in ingredients) {
        final seen = <String>{ingredient['id'] as String};
        var parent = ingredient['parent_id'] as String?;
        while (parent != null) {
          expect(
            seen.add(parent),
            isTrue,
            reason: 'cycle around ${ingredient['id']}',
          );
          parent = byId[parent]?['parent_id'] as String?;
        }
      }
    });

    test('categories are known and staples are exactly the five basics', () {
      const categories = {
        'vegetables',
        'fruits',
        'meat',
        'poultry',
        'fish',
        'dairy',
        'grains',
        'bakery',
        'legumes',
        'mushrooms',
        'canned',
        'spices',
        'nuts',
        'sweets',
        'greens',
      };
      for (final ingredient in ingredients) {
        expect(
          categories,
          contains(ingredient['category']),
          reason: '${ingredient['id']} has unknown category',
        );
      }
      final staples = ingredients
          .where((ingredient) => ingredient['is_staple'] == true)
          .map((ingredient) => ingredient['id'])
          .toSet();
      expect(staples, {
        'salt',
        'water',
        'sugar',
        'black_pepper',
        'sunflower_oil',
      });
    });

    test('every recipe ingredient exists and units are consistent', () {
      for (final recipe in recipes) {
        final recipeIngredients = (recipe['ingredients'] as List)
            .cast<Map<String, dynamic>>();
        expect(
          recipeIngredients,
          isNotEmpty,
          reason: '${recipe['id']} has no ingredients',
        );
        for (final ingredient in recipeIngredients) {
          final id = ingredient['ingredient_id'] as String;
          expect(
            byId.containsKey(id),
            isTrue,
            reason: '${recipe['id']} refers to missing ingredient $id',
          );
          final amount = ingredient['amount'];
          final unit = ingredient['unit'] as String?;
          if (amount == null) {
            expect(
              unit,
              'to_taste',
              reason: '${recipe['id']}: null amount requires to_taste',
            );
          } else {
            expect(
              unit,
              isNot('to_taste'),
              reason: '${recipe['id']}: to_taste requires a null amount',
            );
            expect(
              (amount as num).toDouble(),
              greaterThan(0),
              reason: '${recipe['id']}: amount must be positive',
            );
          }
        }
      }
    });

    test('recipe metadata uses known enums and sane ranges', () {
      const dishTypes = {
        'soup',
        'main',
        'side',
        'salad',
        'breakfast',
        'snack',
        'baking',
        'dessert',
        'drink',
        'preserve',
      };
      const difficulties = {'easy', 'medium', 'hard'};
      for (final recipe in recipes) {
        expect(dishTypes, contains(recipe['dish_type']));
        expect(difficulties, contains(recipe['difficulty']));
        final servings = (recipe['servings'] as num).toInt();
        expect(servings, inInclusiveRange(1, 12));
        final active = (recipe['active_minutes'] as num).toInt();
        final total = (recipe['total_minutes'] as num).toInt();
        expect(active, greaterThan(0));
        expect(total, greaterThanOrEqualTo(active));
      }
    });
  });
}
