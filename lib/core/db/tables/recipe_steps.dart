import 'package:drift/drift.dart';

import 'common.dart';

class RecipeSteps extends Table with CommonFields {
  TextColumn get recipeId => text()();
  IntColumn get position => integer()();
  TextColumn get textContent => text().named('text')();
  IntColumn get timerSeconds => integer().nullable()();
  TextColumn get tip => text().nullable()();
}
