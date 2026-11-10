import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:chto_prigotovit/core/catalog/catalog_taxonomy.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/seed_loader.dart';

void main() {
  group('R7-02: Database Drift Migration (schemaVersion 1 -> 2)', () {
    test('Migration adds new columns to recipes and creates recipe_tags and feed_events tables', () async {
      final dbFile = File(
        '${Directory.systemTemp.path}/migration_test_${DateTime.now().microsecondsSinceEpoch}.db',
      );

      // 1. Manually set up schema version 1 and seed with sample recipes
      final setupDb = NativeDatabase(dbFile);
      await setupDb.ensureOpen(_DbV1User());

      await setupDb.runCustom('''
        CREATE TABLE recipes (
          id TEXT NOT NULL PRIMARY KEY,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER,
          title TEXT NOT NULL,
          normalized_title TEXT NOT NULL,
          dish_type TEXT NOT NULL,
          difficulty TEXT NOT NULL,
          cuisine TEXT NOT NULL,
          total_minutes INTEGER NOT NULL,
          active_minutes INTEGER NOT NULL,
          servings INTEGER NOT NULL DEFAULT 2,
          description TEXT NOT NULL,
          source TEXT NOT NULL,
          fingerprint TEXT NOT NULL,
          ai_model TEXT,
          is_favorite INTEGER NOT NULL DEFAULT 0
        );
      ''');
      await setupDb.runCustom('PRAGMA user_version = 1;');

      await setupDb.runCustom('''
        INSERT INTO recipes (
          id, created_at, updated_at, title, normalized_title, dish_type,
          difficulty, cuisine, total_minutes, active_minutes, servings,
          description, source, fingerprint, is_favorite
        ) VALUES 
          ('r_soup', 1000, 1000, 'Борщ', 'борщ', 'soup', 'easy', 'русская', 60, 20, 4, 'Суп', 'seed', 'soup:1', 0),
          ('r_baking', 1000, 1000, 'Пирог', 'пирог', 'baking', 'medium', 'русская', 50, 25, 6, 'Пирог', 'seed', 'baking:1', 0),
          ('r_main', 1000, 1000, 'Котлеты', 'котлеты', 'main', 'easy', 'домашняя', 30, 15, 2, 'Котлеты', 'seed', 'main:1', 0);
      ''');
      await setupDb.close();

      // 2. Open AppDatabase with schemaVersion 2 to trigger migration
      final db = AppDatabase(NativeDatabase(dbFile), seed: false);

      // Verify schema version is now 3
      final versionResult = await db
          .customSelect('PRAGMA user_version;')
          .getSingle();
      expect(versionResult.read<int>('user_version'), equals(3));

      // 3. Verify recipes table has new columns and backfilled dish_group
      final rows = await db.select(db.recipes).get();
      expect(rows.length, equals(3));

      final soup = rows.firstWhere((r) => r.id == 'r_soup');
      expect(soup.dishGroup, equals(DishGroup.soup));

      final baking = rows.firstWhere((r) => r.id == 'r_baking');
      expect(baking.dishGroup, equals(DishGroup.baking));

      final main = rows.firstWhere((r) => r.id == 'r_main');
      expect(main.dishGroup, equals(DishGroup.meat));

      // 4. Verify recipe_tags table exists and works
      await db
          .into(db.recipeTags)
          .insert(
            const RecipeTagsCompanion(
              recipeId: Value('r_soup'),
              tagKind: Value(TagKind.dietary),
              tag: Value('high_protein'),
            ),
          );

      await db
          .into(db.recipeTags)
          .insert(
            const RecipeTagsCompanion(
              recipeId: Value('r_soup'),
              tagKind: Value(TagKind.occasion),
              tag: Value('everyday'),
            ),
          );

      final tags = await (db.select(
        db.recipeTags,
      )..where((tbl) => tbl.recipeId.equals('r_soup'))).get();
      expect(tags.length, equals(2));
      expect(tags.map((t) => t.tag).toSet(), {'high_protein', 'everyday'});

      // 5. Verify feed_events table exists and accepts interactions
      await db
          .into(db.feedEvents)
          .insert(
            const FeedEventsCompanion(
              recipeId: Value('r_soup'),
              event: Value('shown'),
              contextJson: Value('{"occasion":"lunch"}'),
            ),
          );

      await db
          .into(db.feedEvents)
          .insert(
            const FeedEventsCompanion(
              recipeId: Value('r_soup'),
              event: Value('rated'),
              rating: Value(5),
              contextJson: Value('{"mood":"cozy"}'),
            ),
          );

      final feedEntries = await (db.select(
        db.feedEvents,
      )..where((tbl) => tbl.recipeId.equals('r_soup'))).get();
      expect(feedEntries.length, equals(2));
      expect(feedEntries.any((e) => e.event == 'shown'), isTrue);
      final ratingEvent = feedEntries.firstWhere((e) => e.event == 'rated');
      expect(ratingEvent.rating, equals(5));

      await db.close();
      if (dbFile.existsSync()) {
        dbFile.deleteSync();
      }
    });

    test(
      'SeedLoader seeds recipes with dish_group, cuisine, and recipe_tags',
      () async {
        final db = AppDatabase(NativeDatabase.memory(), seed: false);

        const minimalIngredients = '''
      {
        "version": 1,
        "ingredients": [
          {"id": "chicken", "name": "курица", "category": "poultry", "is_staple": false},
          {"id": "potato", "name": "картофель", "category": "vegetables", "is_staple": false}
        ]
      }
      ''';

        const minimalRecipes = '''
      {
        "version": 1,
        "recipes": [
          {
            "id": "test_recipe_1",
            "title": "Куриное жаркое",
            "dish_type": "main",
            "dish_group": "meat",
            "cuisine": "ru",
            "difficulty": "easy",
            "total_minutes": 35,
            "active_minutes": 15,
            "servings": 2,
            "description": "Ароматное жаркое",
            "ingredients": [
              {"ingredient_id": "chicken", "amount": 300, "unit": "g"},
              {"ingredient_id": "potato", "amount": 2, "unit": "pcs"}
            ],
            "steps": [
              {"text": "Нарезать курицу и картофель.", "timer_seconds": null},
              {"text": "Тушить 20 минут до готовности.", "timer_seconds": 1200}
            ],
            "tags": [
              {"kind": "dietary", "tag": "high_protein"},
              {"kind": "occasion", "tag": "everyday"},
              {"kind": "mood", "tag": "hearty"}
            ]
          }
        ]
      }
      ''';

        await const SeedLoader().loadSeedData(
          db,
          ingredientsJson: minimalIngredients,
          recipesJson: minimalRecipes,
        );

        final recipes = await db.select(db.recipes).get();
        expect(recipes.length, equals(1));
        final rec = recipes.first;
        expect(rec.id, equals('test_recipe_1'));
        expect(rec.dishGroup, equals(DishGroup.meat));
        expect(rec.cuisine, equals('ru'));

        final tags = await (db.select(
          db.recipeTags,
        )..where((tbl) => tbl.recipeId.equals('test_recipe_1'))).get();
        expect(tags.length, equals(3));
        expect(tags.map((t) => t.tag).toSet(), {
          'high_protein',
          'everyday',
          'hearty',
        });

        await db.close();
      },
    );
  });
}

class _DbV1User extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}

  @override
  int get schemaVersion => 1;
}
