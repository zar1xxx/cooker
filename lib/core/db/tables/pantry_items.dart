import 'package:drift/drift.dart';

import 'common.dart';

@TableIndex(
  name: 'idx_pantry_items_ingredient_id',
  columns: {#ingredientId},
  unique: true,
)
class PantryItems extends Table with CommonFields {
  TextColumn get ingredientId => text()();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
}
