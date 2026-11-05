import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../enums.dart';
import '../../preferences/preference_service.dart';

class MealPlanEntryWithRecipe {
  const MealPlanEntryWithRecipe({required this.entry, required this.recipe});

  final MealPlanEntry entry;
  final Recipe? recipe;
}

class PlanDao {
  PlanDao(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  static String formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Returns all active (non-deleted) plan entries joined with recipes.
  Future<List<MealPlanEntryWithRecipe>> allWithRecipes() async {
    final entries =
        await (_db.select(_db.mealPlanEntries)
              ..where((tbl) => tbl.deletedAt.isNull())
              ..orderBy([
                (tbl) => OrderingTerm.asc(tbl.date),
                (tbl) => OrderingTerm.asc(tbl.mealSlot),
              ]))
            .get();

    final recipeIds = entries.map((e) => e.recipeId).toSet();
    final recipes = await (_db.select(
      _db.recipes,
    )..where((tbl) => tbl.id.isIn(recipeIds))).get();
    final recipeById = {for (final r in recipes) r.id: r};

    return [
      for (final entry in entries)
        MealPlanEntryWithRecipe(
          entry: entry,
          recipe: recipeById[entry.recipeId],
        ),
    ];
  }

  /// Watches all active entries joined with recipes.
  Stream<List<MealPlanEntryWithRecipe>> watchAllWithRecipes() {
    final query = _db.select(_db.mealPlanEntries)
      ..where((tbl) => tbl.deletedAt.isNull())
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.date),
        (tbl) => OrderingTerm.asc(tbl.mealSlot),
      ]);

    return query.watch().asyncMap((entries) async {
      final recipeIds = entries.map((e) => e.recipeId).toSet();
      final recipes = await (_db.select(
        _db.recipes,
      )..where((tbl) => tbl.id.isIn(recipeIds))).get();
      final recipeById = {for (final r in recipes) r.id: r};

      return [
        for (final entry in entries)
          MealPlanEntryWithRecipe(
            entry: entry,
            recipe: recipeById[entry.recipeId],
          ),
      ];
    });
  }

  /// Gets entries for a date range [startDate, endDate] (inclusive, YYYY-MM-DD).
  Future<List<MealPlanEntryWithRecipe>> getEntriesForRange(
    String startDate,
    String endDate,
  ) async {
    final entries =
        await (_db.select(_db.mealPlanEntries)
              ..where(
                (tbl) =>
                    tbl.deletedAt.isNull() &
                    tbl.date.isBiggerOrEqualValue(startDate) &
                    tbl.date.isSmallerOrEqualValue(endDate),
              )
              ..orderBy([
                (tbl) => OrderingTerm.asc(tbl.date),
                (tbl) => OrderingTerm.asc(tbl.mealSlot),
              ]))
            .get();

    final recipeIds = entries.map((e) => e.recipeId).toSet();
    final recipes = await (_db.select(
      _db.recipes,
    )..where((tbl) => tbl.id.isIn(recipeIds))).get();
    final recipeById = {for (final r in recipes) r.id: r};

    return [
      for (final entry in entries)
        MealPlanEntryWithRecipe(
          entry: entry,
          recipe: recipeById[entry.recipeId],
        ),
    ];
  }

  /// Gets entry for a specific date and mealSlot.
  Future<MealPlanEntryWithRecipe?> getEntryForDate(
    String date, {
    String mealSlot = 'main',
  }) async {
    final entry =
        await (_db.select(_db.mealPlanEntries)
              ..where(
                (tbl) =>
                    tbl.deletedAt.isNull() &
                    tbl.date.equals(date) &
                    tbl.mealSlot.equals(mealSlot),
              )
              ..limit(1))
            .getSingleOrNull();

    if (entry == null) return null;

    final recipe = await (_db.select(
      _db.recipes,
    )..where((tbl) => tbl.id.equals(entry.recipeId))).getSingleOrNull();

    return MealPlanEntryWithRecipe(entry: entry, recipe: recipe);
  }

  /// Inserts or updates a meal plan entry for (date, mealSlot).
  Future<MealPlanEntry> upsertEntry({
    required String date,
    required String recipeId,
    String mealSlot = 'main',
    MealPlanStatus status = MealPlanStatus.planned,
    bool locked = false,
  }) async {
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;

    final existing =
        await (_db.select(_db.mealPlanEntries)
              ..where(
                (tbl) =>
                    tbl.deletedAt.isNull() &
                    tbl.date.equals(date) &
                    tbl.mealSlot.equals(mealSlot),
              )
              ..limit(1))
            .getSingleOrNull();

    if (existing != null) {
      await (_db.update(
        _db.mealPlanEntries,
      )..where((tbl) => tbl.id.equals(existing.id))).write(
        MealPlanEntriesCompanion(
          recipeId: Value(recipeId),
          status: Value(status),
          locked: Value(locked),
          updatedAt: Value(nowMs),
        ),
      );
      return (await (_db.select(
        _db.mealPlanEntries,
      )..where((tbl) => tbl.id.equals(existing.id))).getSingle());
    } else {
      final newId = _uuid.v4();
      final companion = MealPlanEntriesCompanion.insert(
        id: Value(newId),
        date: date,
        recipeId: recipeId,
        mealSlot: Value(mealSlot),
        status: Value(status),
        locked: Value(locked),
        createdAt: Value(nowMs),
        updatedAt: Value(nowMs),
      );
      await _db.into(_db.mealPlanEntries).insert(companion);
      return (await (_db.select(
        _db.mealPlanEntries,
      )..where((tbl) => tbl.id.equals(newId))).getSingle());
    }
  }

  /// Toggles or sets the locked status of an entry.
  Future<void> setLocked(String id, bool locked) async {
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(
      _db.mealPlanEntries,
    )..where((tbl) => tbl.id.equals(id))).write(
      MealPlanEntriesCompanion(locked: Value(locked), updatedAt: Value(nowMs)),
    );
  }

  /// Sets status of an entry (planned / cooked / skipped).
  Future<void> setStatus(String id, MealPlanStatus status) async {
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(
      _db.mealPlanEntries,
    )..where((tbl) => tbl.id.equals(id))).write(
      MealPlanEntriesCompanion(status: Value(status), updatedAt: Value(nowMs)),
    );
  }

  /// Replaces the recipe in an entry.
  Future<void> replaceRecipe(String id, String newRecipeId) async {
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(
      _db.mealPlanEntries,
    )..where((tbl) => tbl.id.equals(id))).write(
      MealPlanEntriesCompanion(
        recipeId: Value(newRecipeId),
        updatedAt: Value(nowMs),
      ),
    );
  }

  /// Soft deletes an entry.
  Future<void> deleteEntry(String id) async {
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(
      _db.mealPlanEntries,
    )..where((tbl) => tbl.id.equals(id))).write(
      MealPlanEntriesCompanion(
        deletedAt: Value(nowMs),
        updatedAt: Value(nowMs),
      ),
    );
  }

  /// Clears all non-locked entries in the range [fromDate, toDate].
  Future<int> clearUnlockedRange(String fromDate, String toDate) async {
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;
    return (_db.update(_db.mealPlanEntries)..where(
          (tbl) =>
              tbl.deletedAt.isNull() &
              tbl.locked.equals(false) &
              tbl.date.isBiggerOrEqualValue(fromDate) &
              tbl.date.isSmallerOrEqualValue(toDate),
        ))
        .write(
          MealPlanEntriesCompanion(
            deletedAt: Value(nowMs),
            updatedAt: Value(nowMs),
          ),
        );
  }

  /// Returns the dates that are currently locked in the range [startDate, endDate].
  Future<Set<String>> getLockedDates(String startDate, String endDate) async {
    final entries =
        await (_db.select(_db.mealPlanEntries)..where(
              (tbl) =>
                  tbl.deletedAt.isNull() &
                  tbl.locked.equals(true) &
                  tbl.date.isBiggerOrEqualValue(startDate) &
                  tbl.date.isSmallerOrEqualValue(endDate),
            ))
            .get();
    return entries.map((e) => e.date).toSet();
  }

  /// Transitions all active entries before [currentDateKey] (or today) with
  /// status [MealPlanStatus.planned] to [MealPlanStatus.skipped].
  ///
  /// For each skipped entry, records a [FeedbackKind.skipped] event in feedback_events
  /// with signal -0.2 (per ТЗ 8.1, 6.4) and recalculates the taste profile.
  /// Returns the list of skipped entries.
  Future<List<MealPlanEntry>> autoSkipPastPlannedEntries({
    String? todayKey,
    DateTime? now,
  }) async {
    final currentNow = now ?? clock.now();
    final today = todayKey ?? formatDate(currentNow);
    final nowMs = currentNow.toUtc().millisecondsSinceEpoch;

    final pastPlannedEntries =
        await (_db.select(_db.mealPlanEntries)..where(
              (tbl) =>
                  tbl.deletedAt.isNull() &
                  tbl.date.isSmallerThanValue(today) &
                  tbl.status.equalsValue(MealPlanStatus.planned),
            ))
            .get();

    if (pastPlannedEntries.isEmpty) return const [];

    for (final entry in pastPlannedEntries) {
      await (_db.update(
        _db.mealPlanEntries,
      )..where((tbl) => tbl.id.equals(entry.id))).write(
        MealPlanEntriesCompanion(
          status: const Value(MealPlanStatus.skipped),
          updatedAt: Value(nowMs),
        ),
      );

      final eventId = _uuid.v4();
      await _db
          .into(_db.feedbackEvents)
          .insert(
            FeedbackEventsCompanion.insert(
              id: Value(eventId),
              recipeId: Value(entry.recipeId),
              kind: FeedbackKind.skipped,
              reason: const Value('auto_skip_past_date'),
              at: Value(nowMs),
              createdAt: Value(nowMs),
              updatedAt: Value(nowMs),
            ),
          );
    }

    try {
      final prefService = PreferenceService(_db);
      await prefService.recalculateProfile();
    } catch (_) {}

    return pastPlannedEntries;
  }
}
