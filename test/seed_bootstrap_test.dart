import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('database seeds itself on first open when seed is enabled', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final ingredients = await db.select(db.ingredients).get();
    final recipes = await db.select(db.recipes).get();

    expect(ingredients.length, greaterThanOrEqualTo(10));
    expect(recipes, isNotEmpty);
    expect(
      ingredients.firstWhere((row) => row.id == 'chicken_fillet').parentId,
      'chicken',
    );
  });
}
