import 'package:drift/drift.dart';

import '../enums.dart';
import 'common.dart';

class Recipes extends Table with CommonFields {
  TextColumn get title => text()();
  TextColumn get normalizedTitle => text()();
  TextColumn get dishType => textEnum<DishType>()();
  TextColumn get difficulty => textEnum<Difficulty>()();
  TextColumn get cuisine => text()();
  IntColumn get totalMinutes => integer()();
  IntColumn get activeMinutes => integer()();
  IntColumn get servings => integer().withDefault(const Constant(2))();
  TextColumn get description => text()();
  TextColumn get source => textEnum<RecipeSource>()();
  TextColumn get fingerprint => text()();
  TextColumn get aiModel => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
}
