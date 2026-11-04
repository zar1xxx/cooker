import 'package:drift/drift.dart';

import '../converters/json_converters.dart';
import 'common.dart';

class PreferenceProfile extends Table with CommonFields {
  TextColumn get dishTypeWeights => text()
      .map(const StringMapConverter())
      .withDefault(const Constant('{}'))();
  TextColumn get ingredientWeights => text()
      .map(const StringMapConverter())
      .withDefault(const Constant('{}'))();
  TextColumn get cuisineWeights => text()
      .map(const StringMapConverter())
      .withDefault(const Constant('{}'))();
  TextColumn get difficultyWeights => text()
      .map(const StringMapConverter())
      .withDefault(const Constant('{}'))();
  TextColumn get excludedIngredients => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get allergies => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  IntColumn get maxTotalMinutes => integer().nullable()();
  IntColumn get servingsDefault => integer().withDefault(const Constant(2))();
}
