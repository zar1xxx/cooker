import 'dart:convert';

import 'package:drift/drift.dart';

import '../../feed/taste_profile.dart';
import '../app_database.dart';

/// Read and write access to `feed_events` (R7-02, R7-07, R7-08, R7-10).
///
/// Events stay on the phone; nothing from this table is sent to the PC or
/// GigaChat.
class FeedEventDao {
  FeedEventDao(this._db);

  final AppDatabase _db;

  /// Stores one interaction. Unknown recipe ids are ignored, because the
  /// table references `recipes` and the feed must never fail on a stale card.
  Future<bool> record(
    String recipeId,
    FeedEventKind kind, {
    int? rating,
    Map<String, Object?>? context,
  }) async {
    final recipe = await (_db.select(
      _db.recipes,
    )..where((tbl) => tbl.id.equals(recipeId))).getSingleOrNull();
    if (recipe == null) return false;
    await _db
        .into(_db.feedEvents)
        .insert(
          FeedEventsCompanion.insert(
            recipeId: recipeId,
            event: kind.name,
            rating: Value(rating),
            contextJson: Value(context == null ? null : jsonEncode(context)),
          ),
        );
    return true;
  }

  /// All events, oldest first.
  Future<List<FeedEventEntry>> all() {
    return (_db.select(_db.feedEvents)
          ..where((tbl) => tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.at)]))
        .get();
  }

  Future<int> count() async {
    final rows = await all();
    return rows.length;
  }

  /// «Сбросить мои вкусы»: removes every feed event.
  Future<int> clear() {
    return _db.delete(_db.feedEvents).go();
  }

  /// Parses the stored event name; unknown names give null.
  static FeedEventKind? kindOf(FeedEventEntry entry) {
    for (final kind in FeedEventKind.values) {
      if (kind.name == entry.event) return kind;
    }
    return null;
  }
}
