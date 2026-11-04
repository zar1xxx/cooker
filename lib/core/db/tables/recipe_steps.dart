import 'package:drift/drift.dart';

import 'common.dart';

@TableIndex(name: 'idx_recipe_steps_recipe_id', columns: {#recipeId})
class RecipeSteps extends Table with CommonFields {
  TextColumn get recipeId => text()();
  IntColumn get position => integer()();
  TextColumn get textContent => text().named('text')();
  IntColumn get timerSeconds => integer().nullable()();
  TextColumn get tip => text().nullable()();
}
