import 'dart:io';

import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/seed_loader.dart';
import 'package:drift/drift.dart' show Value;
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
    db = AppDatabase(NativeDatabase.memory(), seed: false);
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

    test('seed loads parent_id so chicken_fillet belongs to chicken', () async {
      const loader = SeedLoader();

      await loader.loadSeedData(
        db,
        ingredientsJson: ingredientsJson,
        recipesJson: recipesJson,
      );

      final fillet = await (db.select(
        db.ingredients,
      )..where((t) => t.id.equals('chicken_fillet'))).getSingle();
      expect(fillet.parentId, 'chicken');
    });

    test('two products sharing a synonym are both found in FTS', () async {
      const loader = SeedLoader();
      const customIngredients = '''
{
  "ingredients": [
    {
      "id": "potato",
      "name": "картофель",
      "synonyms": ["картошка"],
      "category": "vegetables",
      "parent_id": null,
      "is_staple": false
    },
    {
      "id": "young_potato",
      "name": "молодой картофель",
      "synonyms": ["картошка"],
      "category": "vegetables",
      "parent_id": "potato",
      "is_staple": false
    }
  ]
}
''';

      await loader.loadSeedData(
        db,
        ingredientsJson: customIngredients,
        recipesJson: '{"recipes": []}',
      );

      final results = await db.searchIngredientsFts('картошка').get();
      expect(
        results.map((row) => row.ingredientId),
        containsAll(['potato', 'young_potato']),
      );
    });

    test('database with seed: false stays empty until explicit load', () async {
      expect(await db.select(db.ingredients).get(), isEmpty);
      expect(await db.select(db.recipes).get(), isEmpty);
    });

    test('broken seed JSON throws instead of being swallowed', () async {
      const loader = SeedLoader();

      await expectLater(
        loader.loadSeedData(
          db,
          ingredientsJson: '{broken',
          recipesJson: '{"recipes": []}',
        ),
        throwsA(isA<FormatException>()),
      );

      expect(await db.select(db.ingredients).get(), isEmpty);
    });

    test('repeated seed keeps favorite flag and createdAt', () async {
      const loader = SeedLoader();

      await loader.loadSeedData(
        db,
        ingredientsJson: ingredientsJson,
        recipesJson: recipesJson,
      );

      final recipeBefore = await (db.select(
        db.recipes,
      )..where((t) => t.id.equals('omelet_classic'))).getSingle();
      final ingredientBefore = await (db.select(
        db.ingredients,
      )..where((t) => t.id.equals('potato'))).getSingle();

      await (db.update(db.recipes)..where((t) => t.id.equals('omelet_classic')))
          .write(const RecipesCompanion(isFavorite: Value(true)));

      await loader.loadSeedData(
        db,
        ingredientsJson: ingredientsJson,
        recipesJson: recipesJson,
      );

      final recipeAfter = await (db.select(
        db.recipes,
      )..where((t) => t.id.equals('omelet_classic'))).getSingle();
      final ingredientAfter = await (db.select(
        db.ingredients,
      )..where((t) => t.id.equals('potato'))).getSingle();

      expect(recipeAfter.isFavorite, isTrue);
      expect(recipeAfter.createdAt, recipeBefore.createdAt);
      expect(ingredientAfter.createdAt, ingredientBefore.createdAt);
    });
  });
}
