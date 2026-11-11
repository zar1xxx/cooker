import 'dart:convert';
import 'dart:io';

import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/pantry_dao.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ingredients =
      (_json('assets/seed/ingredients.json')['ingredients'] as List)
          .cast<Map<String, dynamic>>();
  final ids = [for (final i in ingredients) i['id'] as String];
  final parentOf = {
    for (final i in ingredients) i['id'] as String: i['parent_id'] as String?,
  };

  Set<String> selfAndAncestors(String id) {
    final result = <String>{};
    String? current = id;
    while (current != null && result.add(current)) {
      current = parentOf[current];
    }
    return result;
  }

  test('R10: at least 700 products, each with a category and synonyms', () {
    const categories = {
      'vegetables',
      'fruits',
      'meat',
      'poultry',
      'fish',
      'dairy',
      'grains',
      'bakery',
      'legumes',
      'mushrooms',
      'canned',
      'spices',
      'nuts',
      'sweets',
      'greens',
    };
    expect(ingredients.length, greaterThanOrEqualTo(700));
    for (final item in ingredients) {
      expect(categories, contains(item['category']), reason: '${item['id']}');
      expect(item['synonyms'] as List, isNotEmpty, reason: '${item['id']}');
    }
  });

  test('R10: ids and names are unique, every parent exists', () {
    expect(ids.toSet().length, ids.length);
    final names = [
      for (final i in ingredients)
        (i['name'] as String).toLowerCase().replaceAll('ё', 'е'),
    ];
    expect(names.toSet().length, names.length);
    for (final item in ingredients) {
      final parent = item['parent_id'] as String?;
      if (parent == null) continue;
      expect(ids, contains(parent), reason: '${item['id']}');
    }
  });

  test('R10: every product has storage info', () {
    final items = _json('assets/seed/ingredient_info.json')['items'] as Map;
    expect(items.keys.toSet(), ids.toSet());
  });

  test('R10: new raw meat, fish and seafood require heat treatment', () {
    final safety = _json('spec/ai/safety_minimums.json');
    final ready = (safety['ready_to_eat_ids'] as List).cast<String>().toSet();
    final ruleIds = <String>{
      for (final rule in safety['heat_treatment'] as List)
        ...((rule as Map)['ingredient_ids'] as List).cast<String>(),
    };
    const raw = [
      'pork_neck',
      'beef_tenderloin',
      'lamb_leg',
      'venison',
      'minced_turkey',
      'chicken_drumstick',
      'quail',
      'duck_breast',
      'pink_salmon',
      'zander',
      'tuna_fresh',
      'octopus',
      'scallops',
      'king_prawns',
      'quail_egg',
      'beans_black',
      'boletus',
      'dried_porcini',
    ];
    for (final id in raw) {
      expect(
        selfAndAncestors(id).any(ruleIds.contains),
        isTrue,
        reason: '$id needs a heat rule',
      );
      expect(ready, isNot(contains(id)));
    }
    const readyToEat = [
      'herring_salted',
      'salted_salmon',
      'smoked_mackerel',
      'prosciutto',
      'smoked_chicken',
      'stewed_pork',
      'sprats_canned',
    ];
    for (final id in readyToEat) {
      expect(ready, contains(id));
    }
  });

  test(
    'R10-07: upgrade from v4 adds new products and keeps the pantry',
    () async {
      final file = File(
        '${Directory.systemTemp.path}/r10_upgrade_'
        '${DateTime.now().microsecondsSinceEpoch}.db',
      );
      try {
        final first = AppDatabase(NativeDatabase(file), seed: true);
        await PantryDao(first).setAvailable('potato', true);
        // Pretend this install predates R10: no quail eggs, schema v4.
        await first.customStatement(
          "DELETE FROM ingredients WHERE id = 'quail_egg'",
        );
        await first.customStatement('PRAGMA user_version = 4');
        await first.close();

        final second = AppDatabase(NativeDatabase(file), seed: true);
        final quail = await second
            .customSelect("SELECT id FROM ingredients WHERE id = 'quail_egg'")
            .get();
        expect(quail, hasLength(1));
        expect(await PantryDao(second).availableIds(), contains('potato'));
        final count = await second
            .customSelect('SELECT COUNT(*) AS c FROM ingredients')
            .getSingle();
        expect(count.read<int>('c'), ingredients.length);
        await second.close();
      } finally {
        if (file.existsSync()) file.deleteSync();
      }
    },
  );
}
