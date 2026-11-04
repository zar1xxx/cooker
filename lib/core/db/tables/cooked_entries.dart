import 'package:drift/drift.dart';

import 'common.dart';

class CookedEntries extends Table with CommonFields {
  TextColumn get recipeId => text()();
  TextColumn get cookedOn => text()();
  IntColumn get rating => integer().nullable()();
  BoolColumn get wouldRepeat => boolean().nullable()();
  TextColumn get note => text().nullable()();
}
