import 'package:flutter_test/flutter_test.dart';

import '../tool/r9_lib.dart';

void main() {
  final recipes = recipesOf(readJsonFile('assets/seed/recipes.json'));
  final categories = ingredientCategories(
    readJsonFile('assets/seed/ingredients.json'),
  );
  final applied = readAppliedIds('tool/seed_data/rewrite/applied_ids.txt');

  group('R9 curated recipes', () {
    test('every rewritten recipe passes the lint', () {
      final errors = lintCurated(recipes, categories, applied);
      expect(errors, isEmpty, reason: errors.join('\n'));
    });

    test('rewritten recipes exist in the catalog and are curated', () {
      final byId = {for (final r in recipes) r['id'] as String: r};
      for (final id in applied) {
        expect(byId[id], isNotNull, reason: '$id is missing');
        expect(byId[id]!['quality'], 'curated', reason: id);
      }
    });

    test('no curated recipe shares a step with more than 3 recipes', () {
      final counts = <String, int>{};
      for (final r in recipes) {
        final title = r['title'] as String;
        for (final s in (r['steps'] as List).cast<Map<String, dynamic>>()) {
          final key = normalizeStep(s['text'] as String, title);
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
      final bad = <String>[];
      for (final r in recipes.where((r) => applied.contains(r['id']))) {
        final title = r['title'] as String;
        for (final s in (r['steps'] as List).cast<Map<String, dynamic>>()) {
          if ((counts[normalizeStep(s['text'] as String, title)] ?? 0) > 3) {
            bad.add(r['id'] as String);
          }
        }
      }
      expect(bad, isEmpty);
    });
  });
}
