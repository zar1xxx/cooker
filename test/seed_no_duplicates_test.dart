import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll('ё', 'е')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

void main() {
  final ingredients =
      (_loadJson('assets/seed/ingredients.json')['ingredients'] as List)
          .cast<Map<String, dynamic>>();
  final recipes = (_loadJson('assets/seed/recipes.json')['recipes'] as List)
      .cast<Map<String, dynamic>>();
  final stapleIds = ingredients
      .where((ingredient) => ingredient['is_staple'] == true)
      .map((ingredient) => ingredient['id'] as String)
      .toSet();

  group('Seed duplicates (S1-01)', () {
    test('normalized recipe titles are unique', () {
      final seen = <String, String>{};
      for (final recipe in recipes) {
        final key = _normalize(recipe['title'] as String);
        expect(
          seen.containsKey(key),
          isFalse,
          reason: '${recipe['id']} duplicates title of ${seen[key]}',
        );
        seen[key] = recipe['id'] as String;
      }
    });

    // D-058: threshold 0.85 as in R8-09 (2000-recipe catalog); was 0.8 for the 125-recipe seed.
    test('pairwise ingredient Jaccard stays below 0.85', () {
      final sets = <String, Set<String>>{};
      for (final recipe in recipes) {
        final ids = (recipe['ingredients'] as List)
            .cast<Map<String, dynamic>>()
            .map((ingredient) => ingredient['ingredient_id'] as String)
            .where((id) => !stapleIds.contains(id))
            .toSet();
        sets[recipe['id'] as String] = ids;
      }

      final ids = sets.keys.toList();
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          final left = sets[ids[i]]!;
          final right = sets[ids[j]]!;
          final intersection = left.intersection(right).length;
          final union = left.union(right).length;
          final jaccard = union == 0 ? 1.0 : intersection / union;
          expect(
            jaccard,
            lessThan(0.85),
            reason:
                '${ids[i]} and ${ids[j]} are too similar '
                '(${jaccard.toStringAsFixed(3)})',
          );
        }
      }
    });
  });
}
