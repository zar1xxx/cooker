import 'dart:io';

import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/seed_loader.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late String ingredientsJson;
  late String recipesJson;

  setUpAll(() {
    ingredientsJson = File('assets/seed/ingredients.json').readAsStringSync();
    recipesJson = File('assets/seed/recipes.json').readAsStringSync();
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Seed loader tests (S0-06 / seed_loads_test)', () {
    test('loads seed ingredients and recipes into database', () async {
      const loader = SeedLoader();

      await loader.loadSeedData(
        db,
        ingredientsJson: ingredientsJson,
        recipesJson: recipesJson,
      );

      final ingredients = await db.select(db.ingredients).get();
      expect(ingredients, isNotEmpty);
      expect(ingredients.any((i) => i.id == 'potato'), isTrue);

      final recipes = await db.select(db.recipes).get();
      expect(recipes, isNotEmpty);
      expect(recipes.any((r) => r.id == 'omelet_classic'), isTrue);

      final recipeIngredients = await db.select(db.recipeIngredients).get();
      expect(recipeIngredients, isNotEmpty);

      final recipeSteps = await db.select(db.recipeSteps).get();
      expect(recipeSteps, isNotEmpty);

      // Verify FTS5 indexed the ingredients
      final ftsResults = await db.searchIngredientsFts('картошка').get();
      expect(ftsResults, isNotEmpty);
      expect(ftsResults.first.name, 'картофель');
    });

    test(
      'seed loading is idempotent (multiple runs do not duplicate data)',
      () async {
        const loader = SeedLoader();

        // First run
        await loader.loadSeedData(
          db,
          ingredientsJson: ingredientsJson,
          recipesJson: recipesJson,
        );

        final count1 = (await db.select(db.ingredients).get()).length;
        final recipesCount1 = (await db.select(db.recipes).get()).length;
        final ingCount1 = (await db.select(db.recipeIngredients).get()).length;
        final stepsCount1 = (await db.select(db.recipeSteps).get()).length;

        // Second run
        await loader.loadSeedData(
          db,
          ingredientsJson: ingredientsJson,
          recipesJson: recipesJson,
        );

        final count2 = (await db.select(db.ingredients).get()).length;
        final recipesCount2 = (await db.select(db.recipes).get()).length;
        final ingCount2 = (await db.select(db.recipeIngredients).get()).length;
        final stepsCount2 = (await db.select(db.recipeSteps).get()).length;

        expect(count2, count1);
        expect(recipesCount2, recipesCount1);
        expect(ingCount2, ingCount1);
        expect(stepsCount2, stepsCount1);
      },
    );
  });
}
