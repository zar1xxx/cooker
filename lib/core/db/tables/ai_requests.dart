import 'package:drift/drift.dart';

import 'common.dart';

class AiRequests extends Table with CommonFields {
  TextColumn get kind => text()();
  TextColumn get promptHash => text()();
  TextColumn get responseJson => text()();
  TextColumn get model => text()();
  IntColumn get tokensIn => integer().nullable()();
  IntColumn get tokensOut => integer().nullable()();
  TextColumn get status => text()();
  IntColumn get at => integer().clientDefault(
    () => DateTime.now().toUtc().millisecondsSinceEpoch,
  )();
}
