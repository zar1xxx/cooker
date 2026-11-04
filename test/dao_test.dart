import 'dart:io';

import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/ingredient_dao.dart';
import 'package:chto_prigotovit/core/db/daos/pantry_dao.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/seed_loader.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late IngredientDao ingredientDao;
  late PantryDao pantryDao;
  late RecipeDao recipeDao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: false);
    await const SeedLoader().loadSeedData(
      db,
      ingredientsJson: File('assets/seed/ingredients.json').readAsStringSync(),
      recipesJson: File('assets/seed/recipes.json').readAsStringSync(),
    );
    ingredientDao = IngredientDao(db);
    pantryDao = PantryDao(db);
    recipeDao = RecipeDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('IngredientDao (S1-09)', () {
    test('finds an ingredient by a colloquial synonym', () async {
      final results = await ingredientDao.search('картошка');

      expect(results, isNotEmpty);
      expect(results.first.id, 'potato');
    });

    test('prefix search finds a word form', () async {
      final results = await ingredientDao.search('морков');

      expect(results.map((row) => row.id), contains('carrot'));
    });

    test('returns ingredients by category', () async {
      final vegetables = await ingredientDao.byCategory('vegetables');

      expect(
        vegetables.map((row) => row.id),
        containsAll(['potato', 'carrot']),
      );
    });

    test('builds a transitive hierarchy map', () async {
      final hierarchy = await ingredientDao.hierarchy();

      expect(hierarchy['chicken_fillet'], contains('chicken'));
      expect(hierarchy['walnut'], contains('nuts'));
    });
  });

  group('PantryDao (S1-09)', () {
    test('stores available ids and can remove them', () async {
      expect(await pantryDao.availableIds(), isEmpty);

      await pantryDao.setAvailable('potato', true);
      await pantryDao.setAvailable('carrot', true);
      expect(await pantryDao.availableIds(), {'potato', 'carrot'});

      await pantryDao.setAvailable('potato', false);
      expect(await pantryDao.availableIds(), {'carrot'});

      // Turning it back on reuses the same row instead of duplicating it.
      await pantryDao.setAvailable('potato', true);
      expect(await pantryDao.availableIds(), {'potato', 'carrot'});
      expect((await pantryDao.availableRows()).length, 2);
    });
  });

  group('RecipeDao (S1-09)', () {
    test('loads recipes together with their ingredients', () async {
      final recipes = await recipeDao.allWithIngredients();

      expect(recipes, isNotEmpty);
      final omelet = recipes.firstWhere(
        (entry) => entry.recipe.id == 'omelet_classic',
      );
      expect(omelet.ingredients, isNotEmpty);
      expect(
        omelet.ingredients.map((line) => line.ingredient?.id),
        contains('egg'),
      );
    });

    test('loads steps in order', () async {
      final steps = await recipeDao.stepsFor('omelet_classic');

      expect(steps, isNotEmpty);
      expect(steps.first.position, 1);
    });

    test('toggles the favorite flag', () async {
      await recipeDao.setFavorite('omelet_classic', true);
      expect((await recipeDao.byId('omelet_classic'))!.isFavorite, isTrue);

      await recipeDao.setFavorite('omelet_classic', false);
      expect((await recipeDao.byId('omelet_classic'))!.isFavorite, isFalse);
    });
  });

  group('Riverpod providers (S1-09)', () {
    test('pantryProvider loads and toggles ids through PantryDao', () async {
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      expect(await container.read(pantryProvider.future), isEmpty);

      await container.read(pantryProvider.notifier).toggle('potato');
      expect(await container.read(pantryProvider.future), {'potato'});

      await container.read(pantryProvider.notifier).toggle('potato');
      expect(await container.read(pantryProvider.future), isEmpty);
      expect(await pantryDao.availableIds(), isEmpty);
    });
  });
}
