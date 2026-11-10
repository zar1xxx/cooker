import 'dart:convert';
import 'dart:io';

import 'package:chto_prigotovit/core/ai/recipe_validator.dart';
import 'package:chto_prigotovit/core/catalog/difficulty_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final ingredients =
      (_loadJson('assets/seed/ingredients.json')['ingredients'] as List)
          .cast<Map<String, dynamic>>();
  final recipes = (_loadJson('assets/seed/recipes.json')['recipes'] as List)
      .cast<Map<String, dynamic>>();
  final validator = RecipeValidator(
    safetyMinimums: _loadJson('spec/ai/safety_minimums.json'),
  );

  final byId = {
    for (final ingredient in ingredients)
      ingredient['id'] as String: ingredient,
  };
  final hierarchy = <String, List<String>>{};
  for (final ingredient in ingredients) {
    final parents = <String>[];
    var parent = ingredient['parent_id'] as String?;
    while (parent != null && !parents.contains(parent)) {
      parents.add(parent);
      parent = byId[parent]?['parent_id'] as String?;
    }
    hierarchy[ingredient['id'] as String] = parents;
  }

  group('Seed recipes pass RecipeValidator (S1-01)', () {
    test('every seed recipe is Valid', () {
      final failures = <String>[];
      for (final recipe in recipes) {
        final result = validator.validate(
          recipe,
          ingredientHierarchy: hierarchy,
        );
        if (result is! Valid) {
          failures.add('${recipe['id']}: $result');
        }
      }

      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('every recipe has a difficulty matching the rules', () {
      final failures = <String>[];
      for (final recipe in recipes) {
        final expected = DifficultyCalculator.calculateFromJson(recipe)
            .difficulty
            .name;
        if (recipe['difficulty'] != expected) {
          failures.add(
            '${recipe['id']}: difficulty=${recipe['difficulty']}, '
            'expected=$expected',
          );
        }
      }

      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('seed covers every dish type and every difficulty', () {
      expect(
        recipes.map((recipe) => recipe['dish_type']).toSet(),
        containsAll({
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
        }),
      );
      expect(
        recipes.map((recipe) => recipe['difficulty']).toSet(),
        containsAll({'easy', 'medium', 'hard'}),
      );
    });

    test('every recipe has at least two steps and positive time', () {
      for (final recipe in recipes) {
        expect(
          (recipe['steps'] as List).length,
          greaterThanOrEqualTo(2),
          reason: '${recipe['id']} has too few steps',
        );
        expect(
          (recipe['total_minutes'] as num).toInt(),
          greaterThan(0),
          reason: '${recipe['id']} has non-positive total time',
        );
        for (final step
            in (recipe['steps'] as List).cast<Map<String, dynamic>>()) {
          expect(
            (step['text'] as String).trim(),
            isNotEmpty,
            reason: '${recipe['id']} has an empty step',
          );
        }
      }
    });
  });
}
