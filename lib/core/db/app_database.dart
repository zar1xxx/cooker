import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

import 'converters/json_converters.dart';
import 'enums.dart';
import 'seed_loader.dart';
import 'tables/ai_requests.dart';
import 'tables/cooked_entries.dart';
import 'tables/feedback_events.dart';
import 'tables/ingredients.dart';
import 'tables/meal_plan_entries.dart';
import 'tables/pantry_items.dart';
import 'tables/preference_profile.dart';
import 'tables/recipe_ingredients.dart';
import 'tables/recipe_steps.dart';
import 'tables/recipes.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Ingredients,
    PantryItems,
    Recipes,
    RecipeIngredients,
    RecipeSteps,
    CookedEntries,
    MealPlanEntries,
    FeedbackEvents,
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // Self-healing seed: if the first launch failed halfway, the next launch
      // fills the empty table. Errors are reported, never swallowed.
      if (seed && await _isIngredientsEmpty()) {
        try {
          await const SeedLoader().loadSeedData(this);
        } catch (error, stackTrace) {
          debugPrint('Seed loading failed: $error\n$stackTrace');
          rethrow;
        }
      }
    },
  );

  Future<bool> _isIngredientsEmpty() async {
    final row = await customSelect('SELECT COUNT(*) AS c FROM ingredients')
        .getSingle();
    return row.read<int>('c') == 0;
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'chto_prigotovit');
  }
}
