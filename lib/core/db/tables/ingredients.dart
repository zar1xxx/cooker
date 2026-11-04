import 'package:drift/drift.dart';

import '../converters/json_converters.dart';
import 'common.dart';

class Ingredients extends Table with CommonFields {
  TextColumn get name => text()();
  TextColumn get synonyms => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get category => text()();
  BoolColumn get isStaple => boolean().withDefault(const Constant(false))();
  TextColumn get icon => text().nullable()();
}
