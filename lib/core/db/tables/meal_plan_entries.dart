import 'package:drift/drift.dart';

import '../enums.dart';
import 'common.dart';

class MealPlanEntries extends Table with CommonFields {
  TextColumn get date => text()();
  TextColumn get recipeId => text()();
  TextColumn get mealSlot => text().withDefault(const Constant('main'))();
  TextColumn get status => textEnum<MealPlanStatus>().withDefault(
    Constant(MealPlanStatus.planned.name),
  )();
  BoolColumn get locked => boolean().withDefault(const Constant(false))();
}
