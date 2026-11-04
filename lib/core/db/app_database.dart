import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
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
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      try {
        await const SeedLoader().loadSeedData(this);
      } catch (_) {
        // In unit tests without asset rootBundle, seed data is loaded via explicit test calls
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'chto_prigotovit');
  }
}
