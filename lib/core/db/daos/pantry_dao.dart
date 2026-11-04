import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../app_database.dart';

/// What is currently at home. Quantity is intentionally not stored.
class PantryDao {
  PantryDao(this._db);

  final AppDatabase _db;

  Future<Set<String>> availableIds() async {
    final rows =
        await (_db.select(_db.pantryItems)..where(
              (tbl) => tbl.isAvailable.equals(true) & tbl.deletedAt.isNull(),
            ))
            .get();
    return rows.map((row) => row.ingredientId).toSet();
  }

  Future<List<PantryItem>> availableRows() {
    return (_db.select(_db.pantryItems)..where(
          (tbl) => tbl.isAvailable.equals(true) & tbl.deletedAt.isNull(),
        ))
        .get();
  }

  Stream<Set<String>> watchAvailableIds() {
    return (_db.select(_db.pantryItems)..where(
          (tbl) => tbl.isAvailable.equals(true) & tbl.deletedAt.isNull(),
        ))
        .watch()
        .map((rows) => rows.map((row) => row.ingredientId).toSet());
  }

  Future<void> setAvailable(String ingredientId, bool isAvailable) async {
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;
    final existing = await (_db.select(
      _db.pantryItems,
    )..where((tbl) => tbl.ingredientId.equals(ingredientId))).getSingleOrNull();

    if (existing == null) {
      await _db
          .into(_db.pantryItems)
          .insert(
            PantryItemsCompanion(
              ingredientId: Value(ingredientId),
              isAvailable: Value(isAvailable),
              createdAt: Value(nowMs),
              updatedAt: Value(nowMs),
            ),
          );
    } else {
      await (_db.update(
        _db.pantryItems,
      )..where((tbl) => tbl.id.equals(existing.id))).write(
        PantryItemsCompanion(
          isAvailable: Value(isAvailable),
          deletedAt: const Value(null),
          updatedAt: Value(nowMs),
        ),
      );
    }
  }
}
