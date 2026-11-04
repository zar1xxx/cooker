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
  'сахар' => 'sugar',
  'масло подсолнечное' => 'sunflower_oil',
  'сливочное масло' => 'butter',
  'уксус' => 'vinegar',
  'острый перец' => 'chili_pepper',
  'перец чили' => 'chili_pepper',
  'говядина' => 'beef',
  'свёкла' => 'beet',
  'грецкие орехи' => 'walnut',
  'ядра' => 'walnut',
  'яйца' || 'яйцо' => 'egg',
  'картофель' => 'potato',
  'лук' => 'onion',
  'мука' => 'flour',
  'сметана' => 'sour_cream',
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

    test('braising beef for 1 hour from text is Valid', () {
      final recipe = {
        'title': 'Тушёная говядина',
        'dish_type': 'main',
        'total_minutes': 75,
        'servings': 4,
        'ingredients': [
          {'name': 'говядина', 'amount': 600, 'unit': 'g'},
        ],
        'steps': [
          {'text': 'Нарежьте мясо кубиками.', 'timer_seconds': null},
          {
            'text': 'Тушите мясо 1 час на медленном огне.',
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
  });

  group('Attempt counter (TZ 9.1)', () {
    test('undercooked recipe on attempt 1 returns Retryable', () {
      final result = _validator().validate(
        _chickenRecipe(
          totalMinutes: 30,
          stepText: 'Обжарьте 3 минуты.',
          timerSeconds: 180,
        ),
        resolveIngredientId: _fakeResolver,
        attempt: 1,
      );

      expect(result, isA<Retryable>());
    });

    test('undercooked recipe on attempt 2 returns Rejected', () {
      final result = _validator().validate(
        _chickenRecipe(
          totalMinutes: 30,
          stepText: 'Обжарьте 3 минуты.',
          timerSeconds: 180,
        ),
        resolveIngredientId: _fakeResolver,
        attempt: 2,
      );

      expect(result, isA<Rejected>());
      expect((result as Rejected).reason, contains('тепловая обработка'));
    });

    test('schema violation on attempt 2 returns Rejected', () {
      final result = _validator().validate({
        'title': 'A', // too short (< 2 chars)
        'dish_type': 'main',
        'total_minutes': 20,
        'servings': 2,
        'ingredients': [
          {'name': 'картофель', 'amount': 300, 'unit': 'g'},
        ],
        'steps': [
          {'text': 'Очистите картофель.', 'timer_seconds': null},
          {'text': 'Отварите до готовности.', 'timer_seconds': null},
        ],
      }, attempt: 2);

      expect(result, isA<Rejected>());
    });
  });

  group('Schema adherence (TZ 9.1 & full_recipe.schema.json)', () {
    Map<String, dynamic> validBaseRecipe() => {
      'title': 'Картофельное пюре',
      'dish_type': 'side',
      'difficulty': 'easy',
      'cuisine': 'домашняя',
      'total_minutes': 25,
      'active_minutes': 15,
      'servings': 3,
      'description': 'Нежное картофельное пюре.',
      'ingredients': [
        {'name': 'картофель', 'amount': 600, 'unit': 'g', 'is_optional': false},
        {'name': 'молоко', 'amount': 100, 'unit': 'ml', 'is_optional': false},
      ],
      'steps': [
        {'text': 'Очистите и отварите картофель.', 'timer_seconds': null},
        {'text': 'Разомните с тёплым молоком.', 'timer_seconds': null},
      ],
    };

    test('title too short or missing produces Retryable', () {
      final r = validBaseRecipe()..['title'] = 'X';
      expect(_validator().validate(r), isA<Retryable>());

      final rEmpty = validBaseRecipe()..['title'] = ' ';
      expect(_validator().validate(rEmpty), isA<Retryable>());
    });

    test('unknown dish_type produces Retryable', () {
      final r = validBaseRecipe()..['dish_type'] = 'fastfood';
      expect(_validator().validate(r), isA<Retryable>());
    });

    test('unknown difficulty produces Retryable', () {
      final r = validBaseRecipe()..['difficulty'] = 'expert';
      expect(_validator().validate(r), isA<Retryable>());
    });

    test('total_minutes out of bounds (< 5 or > 600) produces Retryable', () {
      final r1 = validBaseRecipe()..['total_minutes'] = 2;
      expect(_validator().validate(r1), isA<Retryable>());

      final r2 = validBaseRecipe()..['total_minutes'] = 700;
      expect(_validator().validate(r2), isA<Retryable>());
    });

    test('active_minutes > total_minutes produces Retryable', () {
      final r = validBaseRecipe()
        ..['total_minutes'] = 20
        ..['active_minutes'] = 25;
      expect(_validator().validate(r), isA<Retryable>());
    });

    test('servings out of bounds (< 1 or > 12) produces Retryable', () {
      final r0 = validBaseRecipe()..['servings'] = 0;
      expect(_validator().validate(r0), isA<Retryable>());

      final r15 = validBaseRecipe()..['servings'] = 15;
      expect(_validator().validate(r15), isA<Retryable>());
    });

    test('empty ingredients list produces Retryable', () {
      final r = validBaseRecipe()..['ingredients'] = [];
      expect(_validator().validate(r), isA<Retryable>());
    });

    test('invalid ingredient unit produces Retryable', () {
      final r = validBaseRecipe()
        ..['ingredients'] = [
          {'name': 'картофель', 'amount': 5, 'unit': 'meter'},
        ];
      expect(_validator().validate(r), isA<Retryable>());
    });

    test('negative ingredient amount produces Retryable', () {
      final r = validBaseRecipe()
        ..['ingredients'] = [
          {'name': 'картофель', 'amount': -100, 'unit': 'g'},
        ];
      expect(_validator().validate(r), isA<Retryable>());
    });

    test('less than 2 steps produces Retryable', () {
      final r = validBaseRecipe()
        ..['steps'] = [
          {'text': 'Очистите картофель.', 'timer_seconds': null},
        ];
      expect(_validator().validate(r), isA<Retryable>());
    });

    test('step timer exceeding total_minutes + 10% produces Retryable', () {
      final r = validBaseRecipe()
        ..['total_minutes'] = 10
        ..['steps'] = [
          {'text': 'Шаг 1.', 'timer_seconds': 400},
          {
            'text': 'Шаг 2.',
            'timer_seconds': 400,
          }, // sum 800s > 10 * 60 * 1.1 = 660s
        ];
      expect(_validator().validate(r), isA<Retryable>());
    });

    test('strictSchema enforces difficulty, cuisine, active_minutes', () {
      final r = validBaseRecipe()..remove('difficulty');
      expect(_validator().validate(r, strictSchema: true), isA<Retryable>());
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

  group('Stop-list checks (TZ 9.1)', () {
    test('recipe mentioning pale deathcap is Rejected', () {
      final recipe = {
        'title': 'Грибной суп',
        'dish_type': 'soup',
        'total_minutes': 30,
        'servings': 2,
        'ingredients': [
          {'name': 'картофель', 'amount': 200, 'unit': 'g'},
          {'name': 'бледная поганка', 'amount': 50, 'unit': 'g'},
        ],
        'steps': [
          {'text': 'Нарежьте грибы.', 'timer_seconds': null},
          {'text': 'Отварите в супе.', 'timer_seconds': 600},
        ],
      };

      final result = _validator().validate(recipe);
      expect(result, isA<Rejected>());
      expect((result as Rejected).reason, contains('бледная поганка'));
    });

    test('recipe mentioning household chemicals in step text is Rejected', () {
      final recipe = {
        'title': 'Пирог',
        'dish_type': 'baking',
        'total_minutes': 40,
        'servings': 4,
        'ingredients': [
          {'name': 'мука', 'amount': 300, 'unit': 'g'},
        ],
        'steps': [
          {'text': 'Замесите тесто.', 'timer_seconds': null},
          {
            'text': 'Протрите стол, где была бытовая химия.',
            'timer_seconds': null,
          },
        ],
      };

      final result = _validator().validate(recipe);
      expect(result, isA<Rejected>());
      expect((result as Rejected).reason, contains('бытовая химия'));
    });
  });

  group('Per-serving limits (R0-02 & TZ 9.1)', () {
    Map<String, dynamic> singleIngRecipe(
      String name,
      num amount,
      String unit, {
      int servings = 1,
    }) => {
      'title': 'Блюдо с приправой',
      'dish_type': 'soup',
      'total_minutes': 15,
      'servings': servings,
      'description': 'Тестовое блюдо.',
      'ingredients': [
        {'name': name, 'amount': amount, 'unit': unit},
      ],
      'steps': [
        {'text': 'Шаг 1.', 'timer_seconds': null},
        {'text': 'Шаг 2.', 'timer_seconds': null},
      ],
    };

    test('1 tbsp of salt per serving produces a warning (18 g > 10 g)', () {
      final result = _validator().validate(
        singleIngRecipe('соль', 1, 'tbsp'),
        resolveIngredientId: _fakeResolver,
      );

      expect(result, isA<Valid>());
      expect((result as Valid).warnings, isNotEmpty);
      expect(result.warnings.first, contains('соли'));
    });

    test('1 tsp of salt per serving does not warn (6 g <= 10 g)', () {
      final result = _validator().validate(
        singleIngRecipe('соль', 1, 'tsp'),
        resolveIngredientId: _fakeResolver,
      );

      expect(result, isA<Valid>());
      expect((result as Valid).warnings, isEmpty);
    });

    test('sugar exceeding 80 g per serving produces a warning', () {
      final result = _validator().validate(
        singleIngRecipe('сахар', 100, 'g', servings: 1),
        resolveIngredientId: _fakeResolver,
      );

      expect(result, isA<Valid>());
      expect((result as Valid).warnings.first, contains('сахара'));
    });

    test('oil exceeding 50 ml per serving produces a warning', () {
      final result = _validator().validate(
        singleIngRecipe(
          'масло подсолнечное',
          4,
          'tbsp',
          servings: 1,
        ), // 4 * 15 = 60 ml > 50 ml
        resolveIngredientId: _fakeResolver,
      );

      expect(result, isA<Valid>());
      expect((result as Valid).warnings.first, contains('масла'));
    });

    test('butter exceeding 60 g per serving produces a warning', () {
      final result = _validator().validate(
        singleIngRecipe('сливочное масло', 70, 'g', servings: 1),
        resolveIngredientId: _fakeResolver,
      );

      expect(result, isA<Valid>());
      expect((result as Valid).warnings.first, contains('сливочного масла'));
    });

    test('vinegar exceeding 30 ml per serving produces a warning', () {
      final result = _validator().validate(
        singleIngRecipe(
          'уксус',
          3,
          'tbsp',
          servings: 1,
        ), // 3 * 15 = 45 ml > 30 ml
        resolveIngredientId: _fakeResolver,
      );

      expect(result, isA<Valid>());
      expect((result as Valid).warnings.first, contains('уксуса'));
    });

    test('chili exceeding 1 pcs per serving produces a warning', () {
      final result = _validator().validate(
        singleIngRecipe('острый перец', 2, 'pcs', servings: 1),
        resolveIngredientId: _fakeResolver,
      );

      expect(result, isA<Valid>());
      expect((result as Valid).warnings.first, contains('острого перца'));
    });
  });

  group('validateDishes (suggest_dishes)', () {
    test('suggest_dishes_ok.json passes validation', () {
      final data = _loadJson('test/fixtures/ai/suggest_dishes_ok.json');
      final result = _validator().validateDishes(
        data,
        resolveIngredientId: _fakeResolver,
      );
      expect(result, isA<Valid>());
    });

    test('dish with allergen in main_ingredients is Rejected', () {
      final data = {
        'dishes': [
          {
            'title': 'Ореховый салат',
            'dish_type': 'salad',
            'difficulty': 'easy',
            'total_minutes': 15,
            'main_ingredients': ['грецкие орехи', 'свёкла'],
            'missing': [],
            'why': 'Полезно',
          },
        ],
      };

      final result = _validator().validateDishes(
        data,
        profile: {
          'allergies': ['nuts'],
        },
        ingredientHierarchy: {
          'walnut': ['nuts'],
        },
        resolveIngredientId: _fakeResolver,
        forbiddenTerms: {
          'nuts': ['орехи', 'грецкие орехи'],
        },
      );

      expect(result, isA<Rejected>());
    });

    test('dish with stop-list component is Rejected', () {
      final data = {
        'dishes': [
          {
            'title': 'Суп с поганкой',
            'dish_type': 'soup',
            'difficulty': 'easy',
            'total_minutes': 20,
            'main_ingredients': ['картофель'],
            'missing': [],
            'why': 'Содержит бледная поганка для вкуса',
          },
        ],
      };

      final result = _validator().validateDishes(data);
      expect(result, isA<Rejected>());
    });

    test('dishes with invalid dish_type returns Retryable', () {
      final data = {
        'dishes': [
          {
            'title': 'Пицца',
            'dish_type': 'fast_food', // invalid
            'difficulty': 'easy',
            'total_minutes': 20,
            'main_ingredients': ['мука', 'сыр'],
            'missing': [],
            'why': 'Быстро',
          },
        ],
      };

      final result = _validator().validateDishes(data);
      expect(result, isA<Retryable>());
    });
  });

  group('Raw JSON validation', () {
    test('full_recipe_ok.json is Valid', () {
      final jsonStr = File('test/fixtures/ai/full_recipe_ok.json')
          .readAsStringSync();
      final result = _validator().validateRawRecipeJson(
        jsonStr,
        resolveIngredientId: _fakeResolver,
      );
      expect(result, isA<Valid>());
      expect((result as Valid).warnings, isEmpty);
    });

    test(
      'broken json in full_recipe_broken.txt returns Retryable on attempt 1',
      () {
        final rawText = File('test/fixtures/ai/full_recipe_broken.txt')
            .readAsStringSync();
        final result = _validator().validateRawRecipeJson(rawText, attempt: 1);
        expect(result, isA<Retryable>());
        expect(
          (result as Retryable).reasonForModel,
          contains('Некорректный JSON'),
        );
      },
    );

    test(
      'broken json in full_recipe_broken.txt returns Rejected on attempt 2',
      () {
        final rawText = File('test/fixtures/ai/full_recipe_broken.txt')
            .readAsStringSync();
        final result = _validator().validateRawRecipeJson(rawText, attempt: 2);
        expect(result, isA<Rejected>());
      },
    );

    test('markdown code fences around json are handled cleanly', () {
      final validJson = File('test/fixtures/ai/full_recipe_ok.json')
          .readAsStringSync();
      final wrapped =
          'Вот рецепт блюда:\n```json\n$validJson\n```\nПриятного аппетита!';
      final result = _validator().validateRawRecipeJson(
        wrapped,
        resolveIngredientId: _fakeResolver,
      );
      expect(result, isA<Valid>());
    });
  });
}
