import 'dart:convert';
import 'dart:io';

import 'package:chto_prigotovit/core/ai/recipe_validator.dart';
import 'package:chto_prigotovit/core/matching/ingredient_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

List<IngredientTerm> _loadTerms() {
  final decoded = jsonDecode(
    File('assets/seed/ingredients.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final list = decoded['ingredients'] as List;
  return [
    for (final raw in list.cast<Map<String, dynamic>>())
      IngredientTerm(
        id: raw['id'] as String,
        name: raw['name'] as String,
        synonyms:
            (raw['synonyms'] as List?)?.cast<String>() ?? const <String>[],
        parentId: raw['parent_id'] as String?,
      ),
  ];
}

void main() {
  late IngredientNormalizer normalizer;

  setUpAll(() {
    normalizer = IngredientNormalizer(_loadTerms());
  });

  group('IngredientNormalizer (S1-02 / TZ 5.1)', () {
    test('lower-cases and replaces ё with е', () {
      expect(normalizer.normalize('  Свёкла, '), 'свекла');
    });

    test('stems common Russian endings but keeps at least 3 letters', () {
      expect(normalizer.stem('картошка'), 'картошк');
      expect(normalizer.stem('морковь'), 'морков');
      expect(normalizer.stem('яйца'), 'яйц');
      expect(normalizer.stem('соль'), 'сол');
      expect(normalizer.stem('лук'), 'лук');
    });

    test('resolves exact names and colloquial synonyms', () {
      expect(normalizer.resolve('картошка'), 'potato');
      expect(normalizer.resolve('Картошку'), 'potato');
      expect(normalizer.resolve('морковка'), 'carrot');
      expect(normalizer.resolve('морковь'), 'carrot');
      expect(normalizer.resolve('курица'), 'chicken');
      expect(normalizer.resolve('филе'), 'chicken_fillet');
      expect(normalizer.resolve('грецкие орехи'), 'walnut');
    });

    test('resolves a typo with Levenshtein distance <= 2', () {
      expect(normalizer.resolve('марковь'), 'carrot');
      expect(normalizer.resolve('картофель'), 'potato');
    });

    test('resolves free text split by commas and «и»', () {
      final ids = normalizer.resolveMany('картошка, лук и морковь');

      expect(ids, ['potato', 'onion', 'carrot']);
    });

    test('reports unknown products separately', () {
      expect(normalizer.resolve('папайя'), isNull);
      expect(normalizer.unresolved('картошка, папайя'), ['папайя']);
    });

    test('walks the hierarchy in both directions', () {
      expect(normalizer.descendantsOf('nuts'), contains('walnut'));
      expect(normalizer.descendantsOf('chicken'), contains('chicken_fillet'));
      expect(normalizer.ancestorsOf('walnut'), contains('nuts'));
      expect(normalizer.isDescendantOf('chicken_fillet', 'chicken'), isTrue);
      expect(normalizer.hierarchy()['walnut'], contains('nuts'));
    });
  });

  group('RecipeValidator integration (S1-02)', () {
    test('normalizer resolves AI ingredient names for the validator', () {
      final safety = jsonDecode(
        File('spec/ai/safety_minimums.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final recipe = jsonDecode(
        File('test/fixtures/ai/full_recipe_undercooked.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final validator = RecipeValidator(safetyMinimums: safety);

      final result = validator.validate(
        recipe,
        resolveIngredientId: normalizer.resolve,
        ingredientHierarchy: normalizer.hierarchy(),
      );

      expect(result, isA<Retryable>());
    });
  });
}
