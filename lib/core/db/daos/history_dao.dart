import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../enums.dart';

class CookedEntryWithRecipe {
  const CookedEntryWithRecipe({required this.entry, required this.recipe});

  final CookedEntry entry;
  final Recipe? recipe;
}

class HistoryDao {
  HistoryDao(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  String _formatIsoDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Records that a recipe was cooked, with optional rating and notes.
  /// Also emits a corresponding `FeedbackKind.cooked` event into `feedback_events`.
  Future<CookedEntry> recordCooked({
    required String recipeId,
    int? rating,
    bool? wouldRepeat,
    String? note,
    DateTime? date,
  }) async {
    final now = clock.now();
    final nowMs = now.toUtc().millisecondsSinceEpoch;
    final entryId = _uuid.v4();
    final cookedOn = _formatIsoDate(date ?? now);

    final entry = CookedEntry(
      id: entryId,
      createdAt: nowMs,
      updatedAt: nowMs,
      recipeId: recipeId,
      cookedOn: cookedOn,
      rating: rating,
      wouldRepeat: wouldRepeat,
      note: note,
    );

    await _db.into(_db.cookedEntries).insert(entry);

    // Also record feedback event for taste profile calculation
    final feedbackId = _uuid.v4();
    final feedback = FeedbackEvent(
      id: feedbackId,
      createdAt: nowMs,
      updatedAt: nowMs,
      recipeId: recipeId,
      kind: FeedbackKind.cooked,
      reason: rating != null ? 'rating: $rating' : 'cooked without rating',
      at: nowMs,
    );

    await _db.into(_db.feedbackEvents).insert(feedback);

    return entry;
  }

  Future<List<CookedEntryWithRecipe>> allWithRecipes() async {
    final entries =
        await (_db.select(_db.cookedEntries)
              ..where((tbl) => tbl.deletedAt.isNull())
              ..orderBy([
                (tbl) => OrderingTerm.desc(tbl.cookedOn),
                (tbl) => OrderingTerm.desc(tbl.createdAt),
              ]))
            .get();

    final recipeIds = entries.map((e) => e.recipeId).toSet();
    final recipes = await (_db.select(
      _db.recipes,
    )..where((tbl) => tbl.id.isIn(recipeIds))).get();
    final recipeById = {for (final r in recipes) r.id: r};

    return [
      for (final entry in entries)
        CookedEntryWithRecipe(entry: entry, recipe: recipeById[entry.recipeId]),
    ];
  }

  Future<void> updateRating(String entryId, int rating) async {
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(
      _db.cookedEntries,
    )..where((tbl) => tbl.id.equals(entryId))).write(
      CookedEntriesCompanion(rating: Value(rating), updatedAt: Value(nowMs)),
    );
  }
}
