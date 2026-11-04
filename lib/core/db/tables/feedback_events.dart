import 'package:drift/drift.dart';

import '../enums.dart';
import 'common.dart';

class FeedbackEvents extends Table with CommonFields {
  TextColumn get recipeId => text().nullable()();
  TextColumn get kind => textEnum<FeedbackKind>()();
  TextColumn get reason => text().nullable()();
  IntColumn get at => integer().clientDefault(
    () => DateTime.now().toUtc().millisecondsSinceEpoch,
  )();
}
