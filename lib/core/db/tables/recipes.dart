import 'package:drift/drift.dart';

import '../../catalog/dish_group.dart';
import '../enums.dart';
import 'common.dart';

class Recipes extends Table with CommonFields {
  TextColumn get title => text()();
  TextColumn get normalizedTitle => text()();
  TextColumn get dishType => textEnum<DishType>()();
  TextColumn get dishGroup =>
      textEnum<DishGroup>().withDefault(const Constant('vegetable'))();
  TextColumn get difficulty => textEnum<Difficulty>()();
  TextColumn get cuisine => text()();
  IntColumn get totalMinutes => integer()();
  IntColumn get activeMinutes => integer()();
  IntColumn get cookMinutes => integer().nullable()();
  IntColumn get kcalPerServing => integer().nullable()();
  IntColumn get servings => integer().withDefault(const Constant(2))();
  TextColumn get description => text()();
  TextColumn get source => textEnum<RecipeSource>()();
  TextColumn get fingerprint => text()();
  TextColumn get aiModel => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
}
