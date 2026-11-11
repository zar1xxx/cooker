import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

import '../catalog/catalog_taxonomy.dart';
import 'converters/json_converters.dart';
import 'enums.dart';
import 'seed_loader.dart';
import 'tables/ai_requests.dart';
import 'tables/cooked_entries.dart';
import 'tables/feed_events.dart';
import 'tables/feedback_events.dart';
import 'tables/ingredients.dart';
import 'tables/meal_plan_entries.dart';
import 'tables/pantry_items.dart';
import 'tables/preference_profile.dart';
import 'tables/recipe_ingredients.dart';
import 'tables/recipe_steps.dart';
import 'tables/recipe_tags.dart';
import 'tables/recipes.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Ingredients,
    PantryItems,
    Recipes,
    RecipeIngredients,
    RecipeSteps,
    RecipeTags,
    CookedEntries,
    MealPlanEntries,
    FeedbackEvents,
    FeedEvents,
    PreferenceProfile,
    AiRequests,
  ],
  include: {'tables/ingredients_fts.drift'},
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor? executor, {this.seed = true})
    : super(executor ?? _openConnection());

  final bool seed;

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Add new columns to recipes table
        await m.addColumn(recipes, recipes.dishGroup);
        await m.addColumn(recipes, recipes.cookMinutes);
        await m.addColumn(recipes, recipes.kcalPerServing);

        // Create new tables for tags and feed interactions
        await m.createTable(recipeTags);
        await m.createTable(feedEvents);

        // Backfill dish_group based on dish_type for existing recipes
        await customStatement('''
              UPDATE recipes SET dish_group = CASE dish_type
                WHEN 'soup' THEN 'soup'
                WHEN 'baking' THEN 'baking'
                WHEN 'dessert' THEN 'dessert'
                WHEN 'drink' THEN 'beverage'
                WHEN 'preserve' THEN 'preserves'
                WHEN 'salad' THEN 'saladSnack'
                WHEN 'snack' THEN 'saladSnack'
                WHEN 'side' THEN 'porridgeSide'
                WHEN 'breakfast' THEN 'eggDairy'
                WHEN 'main' THEN 'meat'
                ELSE 'vegetable'
              END
            ''');
      }
      if (from < 3) {
        // The v2 backfill wrote snake_case ids ('salad_snack'), but drift's
        // textEnum stores the Dart enum name ('saladSnack'). Repair them.
        await repairDishGroupValues();
      }
      if (from < 4) {
        // R9: catalog text quality marker ('curated' | 'template').
        await m.addColumn(recipes, recipes.quality);
      }
      if (from < 5) {
        // R10: the product list grew to 700+ items. No table changes:
        // beforeOpen reloads the bundled seed after any upgrade, which adds
        // new products and keeps pantry, favourites and history.
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // Self-healing seed: if the first launch failed halfway, the next launch
      // fills the empty table. Errors are reported, never swallowed.
      // After an upgrade the bundled catalog is reloaded too, so old installs
      // receive new recipes (existing user data is kept by the loader).
      if (seed && (await _isIngredientsEmpty() || details.hadUpgrade)) {
        try {
          await const SeedLoader().loadSeedData(this);
        } catch (error, stackTrace) {
          debugPrint('Seed loading failed: $error\n$stackTrace');
          rethrow;
        }
      }
    },
  );

  /// Converts snake_case dish group ids written by the old v2 migration
  /// into the enum names drift reads back.
  Future<void> repairDishGroupValues() async {
    await customStatement('''
      UPDATE recipes SET dish_group = CASE dish_group
        WHEN 'salad_snack' THEN 'saladSnack'
        WHEN 'porridge_side' THEN 'porridgeSide'
        WHEN 'egg_dairy' THEN 'eggDairy'
        WHEN 'fish_seafood' THEN 'fishSeafood'
        ELSE dish_group
      END
    ''');
  }

  Future<bool> _isIngredientsEmpty() async {
    final row = await customSelect('SELECT COUNT(*) AS c FROM ingredients')
        .getSingle();
    return row.read<int>('c') == 0;
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'chto_prigotovit');
  }
}
