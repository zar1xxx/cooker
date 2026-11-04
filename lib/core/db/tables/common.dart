import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

mixin CommonFields on Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  IntColumn get createdAt => integer().clientDefault(
    () => clock.now().toUtc().millisecondsSinceEpoch,
  )();
  IntColumn get updatedAt => integer().clientDefault(
    () => clock.now().toUtc().millisecondsSinceEpoch,
  )();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
