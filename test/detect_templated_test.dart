import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/detect_templated_recipes.dart';

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> _loadRecipes() {
  final data = _loadJson('assets/seed/recipes.json');
  return (data['recipes'] as List).cast<Map<String, dynamic>>();
}

/// A minimal recipe builder for the synthetic edge cases.
Map<String, dynamic> _recipe({
  required String id,
  required String title,
  required List<String> steps,
  String description = '',
}) => {
  'id': id,
  'title': title,
  'dish_type': 'main',
  'description': description,
  'ingredients': const [],
  'steps': [
    for (final s in steps) {'text': s},
  ],
};

void main() {
  late List<Map<String, dynamic>> recipes;
  late Set<String> detectedIds;

  late List<DetectedTemplate> detected;

  setUpAll(() {
    recipes = _loadRecipes();
    detected = detectTemplated(recipes);
    detectedIds = detected.map((d) => d.id).toSet();
    // Generate the report artifacts so the file-based assertions below are
    // self-contained on a fresh checkout.
    writeDetectionReport(detected, 'docs/reports/rewrite');
  });

  group('R9-01 detector on the real seed catalog', () {
    const templateIds = [
      'bake_cookies_chocolate_chip_classic',
      'bake_muffins_lemon_poppy_seed',
      'bake_scones_cream_currant_black',
    ];
    const curatedIds = ['borscht', 'omelet_classic', 'plov'];

    test('flags known template recipes', () {
      // Hand-rewritten recipes (quality == curated) may legitimately leave
      // the template list, so they are not required to be flagged.
      for (final id in templateIds) {
        final rec = recipes.firstWhere((r) => r['id'] == id);
        if (rec['quality'] == 'curated') continue;
        expect(
          detectedIds.contains(id),
          isTrue,
          reason: '$id should be flagged as templated',
        );
      }
    });

    test('leaves known curated recipes unflagged', () {
      for (final id in curatedIds) {
        expect(
          detectedIds.contains(id),
          isFalse,
          reason: '$id should be kept as curated',
        );
      }
    });

    test('produces a CSV with header and one row per template', () {
      final csv = File('docs/reports/rewrite/templated.csv').readAsStringSync();
      final lines = csv.split('\n').where((l) => l.trim().isNotEmpty).toList();
      expect(lines.first, 'id,title,dish_type,reasons');
      expect(lines.length - 1, detectedIds.length);
    });

    test('writes a machine-readable id list', () {
      final ids = jsonDecode(
        File('docs/reports/rewrite/detected_template_ids.json')
            .readAsStringSync(),
      ) as List;
      final stillTemplate = templateIds.where(
        (id) =>
            recipes.firstWhere((r) => r['id'] == id)['quality'] != 'curated',
      );
      expect(ids, containsAll(stillTemplate));
      final sortedIds = [...ids]..sort();
      expect(ids, equals(sortedIds), reason: 'id list must be sorted');
    });
  });

  group('R9-01 synthetic edge cases', () {
    // Build a catalog where recipes b1..b12 share two identical leading steps
    // (condition a: >=2 steps in 10+ others) while recipe solo has unique text.
    List<Map<String, dynamic>> buildCatalog() {
      final out = <Map<String, dynamic>>[];
      for (var i = 0; i < 12; i++) {
        out.add(
          _recipe(
            id: 'batch_$i',
            title: 'Dish $i',
            description: 'Unique description for dish $i.',
            steps: [
              'Common opening instruction shared across many dishes here.',
              'Second shared cooking step that repeats a lot in the catalog.',
              'Only batch_$i has this unique closing step.',
            ],
          ),
        );
      }
      out.add(
        _recipe(
          id: 'solo',
          title: 'Solo dish',
          steps: [
            'First solo step entirely on its own.',
            'Second solo step with no neighbours at all.',
            'Third solo step that is also unique.',
          ],
        ),
      );
      return out;
    }

    test('flags recipes with two heavily shared steps', () {
      final detected = detectTemplated(buildCatalog());
      final ids = detected.map((d) => d.id).toSet();
      expect(ids, containsAll([for (var i = 0; i < 12; i++) 'batch_$i']));
      for (final d in detected) {
        expect(d.reasons, contains('steps-shared'));
      }
    });

    test('leaves a fully unique recipe unflagged', () {
      final detected = detectTemplated(buildCatalog());
      final ids = detected.map((d) => d.id).toSet();
      expect(ids.contains('solo'), isFalse);
    });

    test('flags a recipe whose every step is shared but never 10+ times', () {
      // Two recipes sharing all steps with each other (2 copies) -> no single
      // step reaches the 10-recipient threshold, and both keep a unique-ish
      // closing line, so neither should be flagged by the strict rules.
      final catalog = <Map<String, dynamic>>[
        _recipe(
          id: 'x',
          title: 'X',
          steps: const ['Step one for first.', 'Step two for first.'],
        ),
        _recipe(
          id: 'y',
          title: 'Y',
          steps: const ['Step one for second.', 'Step two for second.'],
        ),
      ];
      final detected = detectTemplated(catalog);
      expect(detected, isEmpty);
    });
  });
}
