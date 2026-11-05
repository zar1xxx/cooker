import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final ingredientsData =
      (_loadJson('assets/seed/ingredients.json')['ingredients'] as List)
          .cast<Map<String, dynamic>>();
  final recipes = (_loadJson('assets/seed/recipes.json')['recipes'] as List)
      .cast<Map<String, dynamic>>();

  final ingredientById = {
    for (final ing in ingredientsData) ing['id'] as String: ing,
  };

  final nonCuttableCategories = {'grains', 'bakery', 'spices'};
  final nonCuttableIds = {
    'water',
    'milk',
    'kefir',
    'cream',
    'sour_cream',
    'oil_vegetable',
    'oil_sunflower',
    'oil_olive',
    'butter',
  };

  bool isNonCuttable(String id, Map<String, dynamic>? ing) {
    if (ing == null) return false;
    if (id.startsWith('minced_')) return true;
    if (nonCuttableIds.contains(id)) return true;
    final cat = ing['category'] as String?;
    return nonCuttableCategories.contains(cat);
  }

  final meatCategories = {'meat', 'poultry', 'fish'};

  bool hasMeat(Map<String, dynamic> recipe) {
    final ings = (recipe['ingredients'] as List).cast<Map<String, dynamic>>();
    for (final item in ings) {
      final id = item['ingredient_id'] as String;
      if (id.startsWith('minced_')) return true;
      final info = ingredientById[id];
      if (info != null && meatCategories.contains(info['category'])) {
        return true;
      }
    }
    return false;
  }

  int countSentences(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return 0;
    // Split by sentence terminators (. ! ?) followed by whitespace or end of string
    final parts = cleaned.split(RegExp(r'[.!?]+(?:\s+|$)'));
    return parts.where((p) => p.trim().isNotEmpty).length;
  }

  group('Seed recipes quality checks (R1-03)', () {
    test('no template phrases: "остальные продукты", standalone "до готовности", inappropriate under-lid steeping', () {
      final failures = <String>[];

      for (final recipe in recipes) {
        final id = recipe['id'] as String;
        final steps = (recipe['steps'] as List).cast<Map<String, dynamic>>();

        for (int i = 0; i < steps.length; i++) {
          final text = steps[i]['text'] as String;
          final lower = text.toLowerCase();

          if (lower.contains('остальные продукты') ||
              lower.contains('остальных продуктов') ||
              lower.contains('остальными продуктами')) {
            failures.add(
              '$id: step ${i + 1} contains "остальные продукты": "$text"',
            );
          }

          if (lower.contains('до готовности')) {
            // Must have a physical readiness indicator nearby
            final hasReadinessSign =
                lower.contains('мягкост') ||
                lower.contains('прозрачн') ||
                lower.contains('золотист') ||
                lower.contains('пока ') ||
                lower.contains('румян') ||
                lower.contains('выпари') ||
                lower.contains('загуст') ||
                lower.contains('свернет') ||
                lower.contains('готовности мяса') ||
                lower.contains('готовности риса') ||
                lower.contains('готовности овощей');
            if (!hasReadinessSign) {
              failures.add(
                '$id: step ${i + 1} has "до готовности" without readiness cue: "$text"',
              );
            }
          }
        }
      }

      expect(
        failures,
        isEmpty,
        reason:
            'Found ${failures.length} template phrase violations:\n${failures.join('\n')}',
      );
    });

    test('no "Нарежьте..." steps containing grains, flour, minced meat, liquids or spices', () {
      final failures = <String>[];

      for (final recipe in recipes) {
        final id = recipe['id'] as String;
        final steps = (recipe['steps'] as List).cast<Map<String, dynamic>>();
        final ings = (recipe['ingredients'] as List)
            .cast<Map<String, dynamic>>();

        for (int i = 0; i < steps.length; i++) {
          final text = steps[i]['text'] as String;
          final lower = text.toLowerCase();

          if (lower.contains('нарежьте') || lower.contains('порежьте')) {
            for (final ingRef in ings) {
              final ingId = ingRef['ingredient_id'] as String;
              final ingInfo = ingredientById[ingId];
              if (isNonCuttable(ingId, ingInfo)) {
                final ingName = (ingInfo?['name'] as String? ?? ingId)
                    .toLowerCase();
                // Check if this non-cuttable ingredient appears in the chopping step
                if (lower.contains(ingName)) {
                  failures.add(
                    '$id: step ${i + 1} tells to chop non-cuttable "$ingName" ($ingId): "$text"',
                  );
                }
              }
            }
          }
        }
      }

      expect(
        failures,
        isEmpty,
        reason:
            'Found ${failures.length} non-cuttable slicing violations:\n${failures.join('\n')}',
      );
    });

    test('ingredient names in steps are not catalog nominative lists joined by "и" or comma', () {
      final failures = <String>[];
      final nonStapleNames = ingredientsData
          .where(
            (i) => i['is_staple'] != true && (i['name'] as String).length >= 4,
          )
          .map((i) => (i['name'] as String).toLowerCase())
          .toList();

      for (final recipe in recipes) {
        final id = recipe['id'] as String;
        final steps = (recipe['steps'] as List).cast<Map<String, dynamic>>();

        for (int i = 0; i < steps.length; i++) {
          final text = (steps[i]['text'] as String).toLowerCase();

          for (final name1 in nonStapleNames) {
            final idx1 = text.indexOf(name1);
            if (idx1 == -1) continue;

            for (final name2 in nonStapleNames) {
              if (name1 == name2) continue;

              if (text.contains('$name1, $name2') ||
                  text.contains('$name1 и $name2')) {
                failures.add(
                  '$id: step ${i + 1} contains comma/и-separated nominative catalog names "$name1" and "$name2": "${steps[i]['text']}"',
                );
              }
            }
          }
        }
      }

      expect(
        failures,
        isEmpty,
        reason:
            'Found ${failures.length} raw catalog nominative listing violations:\n${failures.join('\n')}',
      );
    });

    test('step counts: soups >= 5, meat mains >= 4; each step has <= 2 sentences', () {
      final failures = <String>[];

      for (final recipe in recipes) {
        final id = recipe['id'] as String;
        final type = recipe['dish_type'] as String;
        final steps = (recipe['steps'] as List).cast<Map<String, dynamic>>();

        if (type == 'soup' && steps.length < 5) {
          failures.add(
            '$id: soup has only ${steps.length} steps (expected >= 5)',
          );
        }

        if (type == 'main' && hasMeat(recipe) && steps.length < 4) {
          failures.add(
            '$id: meat main has only ${steps.length} steps (expected >= 4)',
          );
        }

        for (int i = 0; i < steps.length; i++) {
          final text = steps[i]['text'] as String;
          final sentences = countSentences(text);
          if (sentences > 2) {
            failures.add(
              '$id: step ${i + 1} has $sentences sentences (expected <= 2): "$text"',
            );
          }
        }
      }

      expect(
        failures,
        isEmpty,
        reason:
            'Found ${failures.length} structure/length violations:\n${failures.join('\n')}',
      );
    });

    test('no step phrasing is repeated across more than 3 recipes', () {
      final stepMap = <String, Set<String>>{};

      for (final recipe in recipes) {
        final id = recipe['id'] as String;
        final steps = (recipe['steps'] as List).cast<Map<String, dynamic>>();

        for (final step in steps) {
          final text = (step['text'] as String).trim().toLowerCase();
          stepMap.putIfAbsent(text, () => <String>{}).add(id);
        }
      }

      final overRepeated = <String>[];
      for (final entry in stepMap.entries) {
        if (entry.value.length > 3) {
          overRepeated.add(
            '"${entry.key}" appears in ${entry.value.length} recipes: ${entry.value.take(5).join(', ')}...',
          );
        }
      }

      expect(
        overRepeated,
        isEmpty,
        reason:
            'Found ${overRepeated.length} over-repeated steps (> 3 recipes):\n${overRepeated.join('\n')}',
      );
    });
  });
}
