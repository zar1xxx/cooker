import 'dart:convert';
import 'dart:io';

import 'package:chto_prigotovit/core/catalog/catalog_taxonomy.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/db/seed_loader.dart';
import 'package:chto_prigotovit/core/matching/recipe_matcher.dart';
import 'package:chto_prigotovit/core/matching/recipe_scorer.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeMatch _match(String id, {String? quality}) {
  final recipe = Recipe(
    id: id,
    createdAt: 0,
    updatedAt: 0,
    title: id,
    normalizedTitle: id,
    dishType: DishType.main,
    dishGroup: DishGroup.fromDishType(DishType.main),
    difficulty: Difficulty.easy,
    cuisine: 'ru',
    totalMinutes: 30,
    activeMinutes: 15,
    servings: 2,
    description: '',
    quality: quality,
    source: RecipeSource.seed,
    fingerprint: id,
    isFavorite: false,
  );
  return RecipeMatch(
    entry: RecipeWithIngredients(recipe: recipe, ingredients: const []),
    coverage: 1,
    missingIds: const [],
    missingNames: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R9-04 quality in scoring', () {
    final date = DateTime(2026, 11, 4);

    test('a template recipe scores lower than a curated one', () {
      const scorer = RecipeScorer();
      final curated = scorer.score(
        _match('same', quality: 'curated'),
        date: date,
      );
      final template = scorer.score(
        _match('same', quality: 'template'),
        date: date,
      );
      expect(
        curated.total - template.total,
        closeTo(const ScoringWeights().templatePenalty, 1e-9),
      );
    });

    test('a recipe without a marker counts as curated', () {
      const scorer = RecipeScorer();
      final plain = scorer.score(_match('same'), date: date);
      final curated = scorer.score(
        _match('same', quality: 'curated'),
        date: date,
      );
      expect(plain.total, curated.total);
    });

    test('template recipes stay in the ranking, only lower', () {
      const scorer = RecipeScorer();
      final ranked = scorer.rank([
        _match('a_template', quality: 'template'),
        _match('b_curated', quality: 'curated'),
      ], date: date);
      expect(ranked.length, 2);
      expect(ranked.first.entry.recipe.id, 'b_curated');
      expect(ranked.last.total, greaterThanOrEqualTo(0));
    });
  });

  group('R9-02 quality field in the seed', () {
    late List<Map<String, dynamic>> recipes;

    setUpAll(() {
      final data = jsonDecode(
        File('assets/seed/recipes.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      recipes = (data['recipes'] as List).cast<Map<String, dynamic>>();
    });

    test('every recipe has quality template or curated', () {
      for (final recipe in recipes) {
        expect(
          recipe['quality'],
          anyOf('template', 'curated'),
          reason: recipe['id'] as String,
        );
      }
    });

    test('the seed loader stores the marker', () async {
      final db = AppDatabase(NativeDatabase.memory(), seed: false);
      addTearDown(db.close);
      await const SeedLoader().loadSeedData(
        db,
        ingredientsJson: File('assets/seed/ingredients.json')
            .readAsStringSync(),
        recipesJson: File('assets/seed/recipes.json').readAsStringSync(),
      );
      final rows = await db.select(db.recipes).get();
      final byId = {for (final row in rows) row.id: row.quality};
      for (final recipe in recipes) {
        expect(
          byId[recipe['id']],
          recipe['quality'],
          reason: '${recipe['id']}',
        );
      }
    });
  });
}
