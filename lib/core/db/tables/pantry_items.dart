import 'package:drift/drift.dart';

import 'common.dart';

class PantryItems extends Table with CommonFields {
  TextColumn get ingredientId => text()();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
}
