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

class HistoryMonthSummary {
  const HistoryMonthSummary({
    required this.month,
    required this.totalCooked,
    required this.newDishesCount,
    this.topRatedRecipeTitle,
    this.topRating,
  });

  final DateTime month;
  final int totalCooked;
  final int newDishesCount;
  final String? topRatedRecipeTitle;
  final double? topRating;
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

  /// Soft deletes a cooked entry by marking its deletedAt timestamp.
  Future<void> softDelete(String entryId) async {
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(
      _db.cookedEntries,
    )..where((tbl) => tbl.id.equals(entryId))).write(
      CookedEntriesCompanion(deletedAt: Value(nowMs), updatedAt: Value(nowMs)),
    );
  }

  /// Restores a soft-deleted cooked entry.
  Future<void> restore(String entryId) async {
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(
      _db.cookedEntries,
    )..where((tbl) => tbl.id.equals(entryId))).write(
      CookedEntriesCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(nowMs),
      ),
    );
  }

  /// Manually records a cooked dish per ТЗ 8.2.
  /// If recipe with this title does not exist, creates one with source = RecipeSource.user.
  Future<CookedEntry> addManualEntry({
    required String title,
    DishType dishType = DishType.main,
    Difficulty difficulty = Difficulty.easy,
    int totalMinutes = 30,
    DateTime? date,
    int? rating,
    bool? wouldRepeat,
    String? note,
  }) async {
    final trimmedTitle = title.trim();
    final normTitle = trimmedTitle.toLowerCase();
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;

    // Search for existing recipe with this normalized title
    final existing =
        await (_db.select(_db.recipes)
              ..where((tbl) => tbl.normalizedTitle.equals(normTitle))
              ..limit(1))
            .getSingleOrNull();

    String recipeId;
    if (existing != null) {
      recipeId = existing.id;
    } else {
      recipeId = _uuid.v4();
      await _db
          .into(_db.recipes)
          .insert(
            RecipesCompanion(
              id: Value(recipeId),
              title: Value(trimmedTitle),
              normalizedTitle: Value(normTitle),
              dishType: Value(dishType),
              difficulty: Value(difficulty),
              cuisine: const Value('домашняя'),
              totalMinutes: Value(totalMinutes),
              activeMinutes: Value(totalMinutes ~/ 2),
              servings: const Value(2),
              description: Value(trimmedTitle),
              source: const Value(RecipeSource.user),
              fingerprint: Value('${dishType.name}:'),
              isFavorite: const Value(false),
              createdAt: Value(nowMs),
              updatedAt: Value(nowMs),
            ),
          );
    }

    return recordCooked(
      recipeId: recipeId,
      rating: rating,
      wouldRepeat: wouldRepeat,
      note: note,
      date: date,
    );
  }

  /// Computes monthly summary per ТЗ 8.2:
  /// - total cooked dishes in the month
  /// - new dishes count (first time cooked across all history)
  /// - top rated dish title and its rating
  Future<HistoryMonthSummary> getMonthSummary({DateTime? month}) async {
    final targetMonth = month ?? clock.now();
    final yearStr = targetMonth.year.toString().padLeft(4, '0');
    final monthStr = targetMonth.month.toString().padLeft(2, '0');
    final monthPrefix = '$yearStr-$monthStr';

    final allEntries =
        await (_db.select(_db.cookedEntries)
              ..where((tbl) => tbl.deletedAt.isNull())
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.cookedOn)]))
            .get();

    final thisMonthEntries = allEntries
        .where((e) => e.cookedOn.startsWith(monthPrefix))
        .toList();

    final totalCooked = thisMonthEntries.length;

    // Distinct recipe history to detect if first cooked date is in this month
    final cookedByRecipe = <String, List<CookedEntry>>{};
    for (final e in allEntries) {
      cookedByRecipe.putIfAbsent(e.recipeId, () => []).add(e);
    }

    final thisMonthRecipeIds = thisMonthEntries.map((e) => e.recipeId).toSet();
    int newDishesCount = 0;
    for (final rid in thisMonthRecipeIds) {
      final entriesForRecipe = cookedByRecipe[rid] ?? [];
      if (entriesForRecipe.isNotEmpty &&
          entriesForRecipe.first.cookedOn.startsWith(monthPrefix)) {
        newDishesCount++;
      }
    }

    // Top rated dish in this month
    final ratedEntries = thisMonthEntries
        .where((e) => e.rating != null)
        .toList();
    String? topRecipeTitle;
    double? topRating;

    if (ratedEntries.isNotEmpty) {
      final ratingsByRecipe = <String, List<int>>{};
      for (final e in ratedEntries) {
        ratingsByRecipe.putIfAbsent(e.recipeId, () => []).add(e.rating!);
      }

      String? bestRecipeId;
      double highestAvg = -1.0;
      for (final entry in ratingsByRecipe.entries) {
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        if (avg > highestAvg) {
          highestAvg = avg;
          bestRecipeId = entry.key;
        }
      }

      if (bestRecipeId != null) {
        final recipe = await (_db.select(
          _db.recipes,
        )..where((tbl) => tbl.id.equals(bestRecipeId!))).getSingleOrNull();
        topRecipeTitle = recipe?.title;
        topRating = highestAvg;
      }
    }

    return HistoryMonthSummary(
      month: DateTime(targetMonth.year, targetMonth.month),
      totalCooked: totalCooked,
      newDishesCount: newDishesCount,
      topRatedRecipeTitle: topRecipeTitle,
      topRating: topRating,
    );
  }
}
