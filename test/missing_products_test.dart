import 'package:chto_prigotovit/core/shopping/missing_products.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R7-09 missingProducts', () {
    const lines = [
      MissingProductInput(
        ingredientId: 'beef',
        name: 'говядина',
        amount: 400,
        unit: 'g',
      ),
      MissingProductInput(
        ingredientId: 'potato',
        name: 'картофель',
        amount: 3,
        unit: 'pcs',
      ),
      MissingProductInput(
        ingredientId: 'salt',
        name: 'соль',
        unit: 'to_taste',
        isStaple: true,
      ),
      MissingProductInput(
        ingredientId: 'dill',
        name: 'укроп',
        amount: 10,
        unit: 'g',
        isOptional: true,
      ),
      MissingProductInput(
        ingredientId: 'chicken',
        name: 'курица',
        amount: 300,
        unit: 'g',
      ),
    ];

    test('recipe minus pantry, without staples and optional items', () {
      final result = missingProducts(lines: lines, pantryIds: {'potato'});
      expect(result.map((p) => p.ingredientId), ['beef', 'chicken']);
    });

    test('a child product at home covers its parent', () {
      final result = missingProducts(
        lines: lines,
        pantryIds: {'chicken_fillet'},
        hierarchy: const {
          'chicken_fillet': ['chicken'],
        },
      );
      expect(result.map((p) => p.ingredientId), ['beef', 'potato']);
    });

    test('amounts follow the chosen servings', () {
      final result = missingProducts(
        lines: lines,
        pantryIds: const {},
        scale: 0.5,
      );
      final beef = result.firstWhere((p) => p.ingredientId == 'beef');
      expect(beef.amount, 200);
      expect(formatAmount(1.5), '1,5');
      expect(formatAmount(2), '2');
    });

    test('share text has a title and one line per product', () {
      final text = shoppingListText(
        title: 'Купить для «Борщ»:',
        products: missingProducts(lines: lines, pantryIds: const {}),
        unitLabel: (unit) => unit == 'g' ? 'г' : 'шт',
      );
      expect(
        text,
        'Купить для «Борщ»:\n- говядина: 400 г\n- картофель: 3 шт\n- курица: 300 г',
      );
    });

    test('Kuper link is a web search with only the product name', () {
      final uri = kuperSearchUri('сметана 20%');
      expect(uri.scheme, 'https');
      expect(uri.host, 'kuper.ru');
      expect(uri.path, '/search');
      expect(uri.queryParameters['query'], 'сметана 20%');
    });

    test('«Что докупить» counts how often a product is missing', () {
      final result = mostMissing(
        recipeIngredients: const {
          'a': {'beef', 'onion'},
          'b': {'beef', 'carrot'},
          'c': {'onion', 'beef'},
        },
        pantryIds: const {'carrot'},
      );
      expect(result.first.key, 'beef');
      expect(result.first.value, 3);
      expect(result.map((e) => e.key), ['beef', 'onion']);
    });
  });
}
