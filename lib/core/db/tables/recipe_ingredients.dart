import 'package:drift/drift.dart';

import 'common.dart';

class RecipeIngredients extends Table with CommonFields {
  TextColumn get recipeId => text()();
  TextColumn get ingredientId => text()();
  RealColumn get amount => real().nullable()();
  TextColumn get unit => text().nullable()();
  BoolColumn get isOptional => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
}
