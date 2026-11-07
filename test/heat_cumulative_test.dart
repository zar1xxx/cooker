import 'dart:convert';
import 'dart:io';

import 'package:chto_prigotovit/core/ai/recipe_validator.dart';
import 'package:flutter_test/flutter_test.dart';

// D-R2: heat treatment is checked by cumulative time, counted from the first
// step that mentions the product to the end of the recipe.

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

RecipeValidator _validator() =>
    RecipeValidator(safetyMinimums: _loadJson('spec/ai/safety_minimums.json'));

String? _resolver(String name) => switch (name.toLowerCase().trim()) {
  'куриное филе' => 'chicken_fillet',
  'курица' => 'chicken',
  'картофель' => 'potato',
  'морковь' => 'carrot',
  'панировочные сухари' => 'breadcrumbs',
  _ => null,
};

Map<String, dynamic> _recipe(
  List<Map<String, dynamic>> steps, {
  String dishType = 'main',
  int totalMinutes = 60,
  List<String> ingredients = const ['куриное филе'],
}) => {
  'title': 'Тестовое блюдо',
  'dish_type': dishType,
  'total_minutes': totalMinutes,
  'servings': 2,
  'description': 'Проверка правила нагрева.',
  'ingredients': [
    for (final name in ingredients) {'name': name, 'amount': 300, 'unit': 'g'},
  ],
  'steps': steps,
};

Map<String, dynamic> _step(String text, [int? seconds]) => {
  'text': text,
  'timer_seconds': seconds,
};

void main() {
  group('Cumulative heat time (D-R2)', () {
    test('fry 10 + bake 15 for chicken is Valid', () {
      final result = _validator().validate(
        _recipe([
          _step('Куриное филе отбейте и обваляйте в сухарях.'),
          _step('Обжарьте котлеты в масле 10 минут.', 600),
          _step('Запекайте котлеты в духовке 15 минут.', 900),
        ]),
        resolveIngredientId: _resolver,
      );
      expect(result, isA<Valid>());
    });

    test('a single 5-minute fry of chicken is Retryable', () {
      final result = _validator().validate(
        _recipe([
          _step('Куриное филе нарежьте полосками.'),
          _step('Обжарьте курицу 5 минут.', 300),
        ]),
        resolveIngredientId: _resolver,
      );
      expect(result, isA<Retryable>());
    });

    test('heating before the chicken is added does not count', () {
      final result = _validator().validate(
        _recipe(
          [
            _step('Варите картофель и морковь 20 минут.', 1200),
            _step('Добавьте нарезанное куриное филе и варите 3 минуты.', 180),
          ],
          dishType: 'soup',
          ingredients: const ['картофель', 'морковь', 'куриное филе'],
        ),
        resolveIngredientId: _resolver,
      );
      expect(result, isA<Retryable>());
    });

    test('oven step without the word "запекайте" still counts', () {
      final result = _validator().validate(
        _recipe(
          [
            _step('Курицу натрите солью и выложите в форму.'),
            _step(
              'Отправьте форму в духовку при 180 градусах на 40 минут.',
              2400,
            ),
          ],
          ingredients: const ['курица'],
        ),
        resolveIngredientId: _resolver,
      );
      expect(result, isA<Valid>());
    });

    test('ingredientTerms mark where the product enters the recipe', () {
      final result = _validator().validate(
        _recipe(
          [
            _step('Жарьте лук 15 минут.', 900),
            _step('Положите грудку и прогрейте 2 минуты.', 120),
          ],
          ingredients: const ['куриное филе'],
        ),
        resolveIngredientId: _resolver,
        ingredientTerms: const {
          'chicken_fillet': ['грудк'],
        },
      );
      // "Положите … прогрейте" has no heating keyword, and the 15 minutes
      // of onion frying happened before the chicken was added.
      expect(result, isA<Retryable>());
    });
  });

  group('Seed recipes are not padded with generated heat steps (R2-02)', () {
    final recipes = (_loadJson('assets/seed/recipes.json')['recipes'] as List)
        .cast<Map<String, dynamic>>();

    test('no step looks like "<глагол> N минут: <продукт>."', () {
      final padded = <String>[];
      final pattern = RegExp(r'\d+ минут: ');
      for (final recipe in recipes) {
        for (final step
            in (recipe['steps'] as List).cast<Map<String, dynamic>>()) {
          if (pattern.hasMatch(step['text'] as String)) {
            padded.add('${recipe['id']}: ${step['text']}');
          }
        }
      }
      expect(padded, isEmpty, reason: padded.join('\n'));
    });

    test('the 8 previously padded recipes keep their own technology', () {
      const ids = [
        'chicken_fry_onion',
        'chicken_cream_sauce',
        'chicken_curry',
        'beef_stroganoff',
        'pork_bake_potato',
        'pilaf',
        'chicken_kiev',
        'caesar_chicken',
      ];
      final byId = {for (final r in recipes) r['id'] as String: r};
      for (final id in ids) {
        expect(byId.containsKey(id), isTrue, reason: id);
        final steps = (byId[id]!['steps'] as List).cast<Map<String, dynamic>>();
        final timers = steps
            .map((s) => (s['timer_seconds'] as num?)?.toInt() ?? 0)
            .fold<int>(0, (a, b) => a + b);
        // Before R2 the padding added 15–30 extra minutes of heating.
        expect(timers, lessThanOrEqualTo(60 * 60), reason: id);
      }
    });
  });

  group('Ready-to-eat products (D-R2)', () {
    test('ham added at the end needs no heat treatment', () {
      final result = _validator().validate(
        _recipe(
          [
            _step('Огурцы нарежьте ломтиками.'),
            _step('Добавьте нарезанную ветчину и перемешайте.'),
          ],
          dishType: 'salad',
          totalMinutes: 15,
          ingredients: const ['ветчина'],
        ),
        resolveIngredientId: (n) => n == 'ветчина' ? 'ham' : null,
        ingredientHierarchy: const {
          'ham': ['pork'],
        },
      );
      expect(result, isA<Valid>());
    });
  });
}
