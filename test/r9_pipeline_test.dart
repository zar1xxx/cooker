import 'package:flutter_test/flutter_test.dart';

import '../tool/r9_lib.dart';
import '../tool/rank_rewrite_queue.dart';

Map<String, dynamic> _recipe(
  String id, {
  String title = 'Куриный суп',
  String dishType = 'soup',
  int total = 60,
  List<Map<String, dynamic>>? ingredients,
  List<Map<String, dynamic>>? steps,
  String description = 'Лёгкий суп на курином бульоне для семейного обеда.',
  String quality = 'template',
}) => {
  'id': id,
  'title': title,
  'dish_type': dishType,
  'description': description,
  'total_minutes': total,
  'quality': quality,
  'ingredients':
      ingredients ??
      [
        {'ingredient_id': 'chicken', 'amount': 500, 'unit': 'g'},
        {'ingredient_id': 'egg', 'amount': 2, 'unit': 'pcs'},
      ],
  'steps':
      steps ??
      [
        {'text': 'Залейте курицу холодной водой и доведите до кипения.'},
        {
          'text': 'Варите бульон на слабом огне до мягкости мяса.',
          'timer_seconds': 2400,
        },
        {'text': 'Вбейте 2 яйца и перемешайте тонкой струйкой в кастрюле.'},
      ],
};

const _categories = {'chicken': 'poultry', 'egg': 'dairy'};

void main() {
  group('R9-05 checkBatch', () {
    final known = {'a', 'b'};

    test('a good batch passes', () {
      final batch = {
        'recipes': [
          {
            'id': 'a',
            'description': 'Описание блюда для проверки.',
            'steps': [
              {'text': 'Нарежьте овощи кубиками и сложите в миску.'},
            ],
            'total_minutes': 30,
          },
        ],
      };
      expect(checkBatch(batch, known), isEmpty);
    });

    test('forbidden fields, unknown ids and short steps are refused', () {
      final batch = {
        'recipes': [
          {
            'id': 'a',
            'title': 'Новое название',
            'description': 'x',
            'steps': [
              {'text': 'коротко'},
            ],
          },
          {'id': 'zzz', 'description': 'x', 'steps': []},
        ],
      };
      final errors = checkBatch(batch, known);
      expect(errors.any((e) => e.contains('forbidden fields')), isTrue);
      expect(errors.any((e) => e.contains('shorter than')), isTrue);
      expect(errors.any((e) => e.contains('unknown id')), isTrue);
    });
  });

  group('R9-05 applyBatch', () {
    test('replaces the allowed fields and marks the recipe curated', () {
      final recipes = [_recipe('a'), _recipe('b')];
      final changed = applyBatch(recipes, {
        'recipes': [
          {
            'id': 'a',
            'description': 'Новое описание.',
            'steps': [
              {'text': 'Новый шаг приготовления блюда.'},
            ],
            'total_minutes': 45,
          },
        ],
      });
      expect(changed, ['a']);
      expect(recipes[0]['quality'], 'curated');
      expect(recipes[0]['total_minutes'], 45);
      expect(recipes[0]['title'], 'Куриный суп');
      expect(recipes[1]['quality'], 'template');
    });
  });

  group('R9-05 lintCurated', () {
    test('a good recipe has no problems', () {
      final recipes = [_recipe('a', quality: 'curated')];
      expect(lintCurated(recipes, _categories, {'a'}), isEmpty);
    });

    test('catches every rule', () {
      final bad = _recipe(
        'bad',
        total: 10,
        description: 'Одинаково.',
        steps: [
          {'text': 'Коротко'},
          {'text': 'Коротко'},
          {'text': 'Вбейте 5 яиц и варите долго.', 'timer_seconds': 6000},
        ],
      );
      final twin = _recipe('twin', description: 'Одинаково.');
      final errors = lintCurated([bad, twin], _categories, {'bad'});
      final text = errors.join('\n');
      expect(text, contains('shorter than'));
      expect(text, contains('repeated step'));
      expect(text, contains('description is not unique'));
      expect(text, contains('timers'));
      expect(text, contains('more eggs'));
    });

    test('raw poultry without a timer is flagged', () {
      final recipe = _recipe(
        'raw',
        steps: [
          {'text': 'Залейте курицу холодной водой в кастрюле.'},
          {'text': 'Подавайте суп горячим с зеленью и хлебом.'},
        ],
      );
      final errors = lintCurated([recipe], _categories, {'raw'});
      expect(
        errors.any((e) => e.contains('no step with timer_seconds')),
        isTrue,
      );
    });

    test('a step repeated in many recipes is flagged', () {
      final recipes = [
        for (var i = 0; i < 5; i++)
          _recipe(
            'r$i',
            description: 'Описание номер $i для проверки уникальности.',
            steps: [
              {'text': 'Один и тот же шаг для всех пяти рецептов подряд.'},
              {'text': 'Варите до готовности.', 'timer_seconds': 600},
              {'text': 'Подавайте блюдо $i отдельно от остальных.'},
            ],
          ),
      ];
      final errors = lintCurated(recipes, _categories, {'r0'});
      expect(errors.any((e) => e.contains('appears in 5 recipes')), isTrue);
    });
  });

  group('R9-03 buildQueue', () {
    test('famous dishes go first, round-robin, rest by type', () {
      Map<String, dynamic> r(String id, String title, String type) =>
          _recipe(id, title: title, dishType: type);
      final recipes = [
        r('z_other', 'Что-то особенное', 'main'),
        r('a_shchi_1', 'Щи с курицей', 'soup'),
        r('a_shchi_2', 'Щи с грибами', 'soup'),
        r('a_shchi_3', 'Щи с говядиной', 'soup'),
        r('b_borsch', 'Красный борщ', 'soup'),
        _recipe('done', title: 'Борщ готовый', quality: 'curated'),
      ];
      final queue = buildQueue(recipes, [(1, 'борщ'), (2, 'щи')]);
      final ids = [for (final row in queue) row[1]];
      expect(ids, [
        'b_borsch',
        'a_shchi_1',
        'a_shchi_2',
        'a_shchi_3',
        'z_other',
      ]);
      expect(queue.first.first, '1');
    });

    test('skipped recipes (needs_ingredients) stay out of the queue', () {
      final recipes = [
        _recipe('a_soup', title: 'Щи с курицей', dishType: 'soup'),
        _recipe('b_soup', title: 'Щи без капусты', dishType: 'soup'),
      ];
      final queue = buildQueue(recipes, [(1, 'щи')], skip: {'b_soup'});
      expect([for (final row in queue) row[1]], ['a_soup']);
    });
  });
}
