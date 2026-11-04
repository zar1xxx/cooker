import 'dart:convert';
import 'dart:io';

import 'package:chto_prigotovit/core/ai/recipe_validator.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

RecipeValidator _validator() =>
    RecipeValidator(safetyMinimums: _loadJson('spec/ai/safety_minimums.json'));

Map<String, dynamic> _chickenRecipe({
  required int totalMinutes,
  required String stepText,
  int? timerSeconds,
  String ingredientName = 'курица',
}) => {
  'title': 'Курица на сковороде',
  'dish_type': 'main',
  'total_minutes': totalMinutes,
  'servings': 2,
  'description': 'Простое второе блюдо.',
  'ingredients': [
    {'name': ingredientName, 'amount': 500, 'unit': 'g'},
  ],
  'steps': [
    {'text': 'Нарежьте курицу крупными кусками.', 'timer_seconds': null},
    {'text': stepText, 'timer_seconds': timerSeconds},
  ],
};

String? _fakeResolver(String name) => switch (name.toLowerCase().trim()) {
  'курица' => 'chicken',
  'куриное филе' => 'chicken_fillet',
  'фарш' => 'minced_meat',
  'соль' => 'salt',
  'свёкла' => 'beet',
  'грецкие орехи' => 'walnut',
  'ядра' => 'walnut',
  _ => null,
};

void main() {
  group('Heat treatment (R0-01)', () {
    test('60-minute recipe with a 3-minute chicken fry step is Retryable', () {
      final result = _validator().validate(
        _chickenRecipe(
          totalMinutes: 60,
          stepText: 'Обжарьте курицу 3 минуты.',
          timerSeconds: 180,
        ),
        resolveIngredientId: _fakeResolver,
      );

      expect(result, isA<Retryable>());
    });

    test('full_recipe_undercooked.json is Retryable', () {
      final recipe = _loadJson('test/fixtures/ai/full_recipe_undercooked.json');

      final result = _validator().validate(
        recipe,
        resolveIngredientId: _fakeResolver,
      );

      expect(result, isA<Retryable>());
    });

    test('boiling chicken for 25 minutes is Valid', () {
      final result = _validator().validate(
        _chickenRecipe(
          totalMinutes: 30,
          stepText: 'Отварите курицу до готовности.',
          timerSeconds: 1500,
        ),
        resolveIngredientId: _fakeResolver,
      );

      expect(result, isA<Valid>());
    });

    test('frying minced meat for 20 minutes without timer is Valid', () {
      final recipe = {
        'title': 'Котлеты',
        'dish_type': 'main',
        'total_minutes': 30,
        'servings': 2,
        'description': 'Домашние котлеты.',
        'ingredients': [
          {'name': 'фарш', 'amount': 400, 'unit': 'g'},
        ],
        'steps': [
          {'text': 'Слепите котлеты.', 'timer_seconds': null},
          {
            'text': 'Обжаривайте фарш 20 минут на среднем огне.',
            'timer_seconds': null,
          },
        ],
      };

      final result = _validator().validate(
        recipe,
        resolveIngredientId: _fakeResolver,
      );

      expect(result, isA<Valid>());
    });

    test('chicken_fillet with hierarchy to chicken is Retryable', () {
      final recipe = _chickenRecipe(
        totalMinutes: 30,
        stepText: 'Обжарьте филе 3 минуты.',
        timerSeconds: 180,
        ingredientName: 'куриное филе',
      );

      final result = _validator().validate(
        recipe,
        ingredientHierarchy: {
          'chicken_fillet': ['chicken'],
        },
        resolveIngredientId: _fakeResolver,
      );

      expect(result, isA<Retryable>());
    });

    test('unknown child of chicken is Retryable through the hierarchy', () {
      final recipe = _chickenRecipe(
        totalMinutes: 30,
        stepText: 'Обжарьте куриную ножку 3 минуты.',
        timerSeconds: 180,
        ingredientName: 'куриная ножка',
      );

      final result = _validator().validate(
        recipe,
        ingredientHierarchy: {
          'chicken_leg': ['chicken'],
        },
        resolveIngredientId: (name) =>
            name == 'куриная ножка' ? 'chicken_leg' : null,
      );

      expect(result, isA<Retryable>());
    });
  });

  group('Allergens by ingredient name (R0-02)', () {
    test('full_recipe_allergen.json is Rejected for a nuts allergy', () {
      final recipe = _loadJson('test/fixtures/ai/full_recipe_allergen.json');

      final result = _validator().validate(
        recipe,
        profile: {
          'allergies': ['nuts'],
        },
        ingredientHierarchy: {
          'walnut': ['nuts'],
        },
        resolveIngredientId: _fakeResolver,
        forbiddenTerms: {
          'nuts': ['орехи', 'грецкие орехи', 'фундук'],
        },
      );

      expect(result, isA<Rejected>());
    });

    test('allergen is Rejected even when the steps do not mention it', () {
      final recipe = _loadJson('test/fixtures/ai/full_recipe_allergen.json');
      recipe['title'] = 'Салат с ядрами';
      final ingredients = recipe['ingredients'] as List;
      (ingredients[1] as Map<String, dynamic>)['name'] = 'ядра';
      final steps = recipe['steps'] as List;
      (steps[1] as Map<String, dynamic>)['text'] =
          'Добавьте измельчённые ядра и перемешайте.';

      final result = _validator().validate(
        recipe,
        profile: {
          'allergies': ['nuts'],
        },
        ingredientHierarchy: {
          'walnut': ['nuts'],
        },
        resolveIngredientId: _fakeResolver,
        forbiddenTerms: {
          'nuts': ['орехи', 'грецкие орехи', 'фундук'],
        },
      );

      expect(result, isA<Rejected>());
      expect((result as Rejected).reason, contains('исключённой категории'));
    });

    test('direct forbidden ingredient id is Rejected', () {
      final recipe = {
        'title': 'Салат',
        'dish_type': 'salad',
        'total_minutes': 10,
        'servings': 2,
        'description': 'Свежий салат.',
        'ingredients': [
          {'name': 'ядра', 'amount': 50, 'unit': 'g'},
        ],
        'steps': [
          {'text': 'Нарежьте овощи.', 'timer_seconds': null},
          {'text': 'Перемешайте.', 'timer_seconds': null},
        ],
      };

      final result = _validator().validate(
        recipe,
        profile: {
          'allergies': ['nuts'],
        },
        resolveIngredientId: (name) => name == 'ядра' ? 'nuts' : null,
        forbiddenTerms: {
          'nuts': ['орехи'],
        },
      );

      expect(result, isA<Rejected>());
    });
  });

  group('Per-serving limits (R0-02)', () {
    Map<String, dynamic> saltRecipe(num amount, String unit) => {
      'title': 'Простой суп',
      'dish_type': 'soup',
      'total_minutes': 10,
      'servings': 1,
      'description': 'Суп.',
      'ingredients': [
        {'name': 'соль', 'amount': amount, 'unit': unit},
      ],
      'steps': [
        {'text': 'Вскипятите воду.', 'timer_seconds': null},
        {'text': 'Добавьте соль.', 'timer_seconds': null},
      ],
    };

    test('1 tbsp of salt per serving produces a warning (18 g)', () {
      final result = _validator().validate(
        saltRecipe(1, 'tbsp'),
        resolveIngredientId: _fakeResolver,
      );

      expect(result, isA<Valid>());
      expect((result as Valid).warnings, isNotEmpty);
      expect(result.warnings.first, contains('соли'));
    });

    test('1 tsp of salt per serving does not warn (6 g)', () {
      final result = _validator().validate(
        saltRecipe(1, 'tsp'),
        resolveIngredientId: _fakeResolver,
      );

      expect(result, isA<Valid>());
      expect((result as Valid).warnings, isEmpty);
    });

    test('grams are compared without conversion', () {
      final result = _validator().validate(
        saltRecipe(30, 'g'),
        resolveIngredientId: _fakeResolver,
      );

      expect(result, isA<Valid>());
      expect((result as Valid).warnings, isNotEmpty);
    });
  });
}
