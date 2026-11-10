import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/enums.dart';
import 'ai_service.dart';

/// Anti-repeat and similarity utilities per ТЗ 6.3.
class AntiRepeat {
  const AntiRepeat();

  /// Calculates the dish fingerprint: `dish_type` + up to 4 sorted normalized ingredient IDs.
  static String calculateFingerprint({
    required String dishType,
    required Iterable<String> ingredientIds,
  }) {
    final cleanType = dishType.toLowerCase().trim();
    final sorted =
        ingredientIds
            .map((s) => s.toLowerCase().trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return '$cleanType:${sorted.take(4).join(',')}';
  }

  /// Calculates Jaccard similarity coefficient between two ingredient sets:
  /// J(A, B) = |A ∩ B| / |A ∪ B|
  static double jaccardSimilarity(Iterable<String> a, Iterable<String> b) {
    final setA = a
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    final setB = b
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    if (setA.isEmpty && setB.isEmpty) return 1.0;
    if (setA.isEmpty || setB.isEmpty) return 0.0;

    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    if (union == 0) return 0.0;
    return intersection / union;
  }

  /// Checks if a suggested dish is a duplicate of an existing recipe in the database (ТЗ 6.3):
  /// - Exact match on `normalized_title`
  /// - OR same `dish_type` and Jaccard similarity of ingredients >= 0.8.
  static Future<Recipe?> findDuplicate(
    AppDatabase db, {
    required String title,
    required String dishType,
    required List<String> ingredientIds,
  }) async {
    final normTitle = title.toLowerCase().trim();

    // 1. Exact match on normalized_title
    final titleMatch =
        await (db.select(db.recipes)..where(
              (tbl) =>
                  tbl.normalizedTitle.equals(normTitle) &
                  tbl.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    if (titleMatch != null) return titleMatch;

    // 2. Jaccard similarity >= 0.8 with recipes of the same dish_type
    final typeEnum = DishType.values
        .where((e) => e.name == dishType.toLowerCase().trim())
        .firstOrNull;
    if (typeEnum == null) return null;

    final sameTypeRecipes =
        await (db.select(db.recipes)..where(
              (tbl) =>
                  tbl.dishType.equalsValue(typeEnum) & tbl.deletedAt.isNull(),
            ))
            .get();

    for (final recipe in sameTypeRecipes) {
      final recipeIngs = await (db.select(
        db.recipeIngredients,
      )..where((tbl) => tbl.recipeId.equals(recipe.id))).get();
      final recipeIngIds = recipeIngs.map((e) => e.ingredientId).toList();

      final similarity = jaccardSimilarity(ingredientIds, recipeIngIds);
      if (similarity >= 0.8) {
        return recipe;
      }
    }

    return null;
  }

  /// Builds the "do not suggest" list for the AI prompt per ТЗ 6.3:
  /// - Dishes cooked in the last 14 days
  /// - Dishes rated <= 2 stars
  /// - Suggestions rejected in the last 7 days (FeedbackKind.rejected_suggestion, disliked)
  ///
  /// Capped at 40 titles.
  static Future<List<String>> getDoNotSuggestList(
    AppDatabase db, {
    DateTime? now,
  }) async {
    final currentTime = now ?? clock.now();
    final cutoff14d = currentTime
        .subtract(const Duration(days: 14))
        .millisecondsSinceEpoch;
    final cutoff7d = currentTime
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;

    final titles = <String>[];
    final seen = <String>{};

    void addTitle(String? t) {
      if (t == null) return;
      final clean = t.trim();
      if (clean.isNotEmpty && seen.add(clean.toLowerCase())) {
        titles.add(clean);
      }
    }

    // 1. Cooked entries from last 14 days
    final recentCooked =
        await (db.select(db.cookedEntries)
              ..where((tbl) => tbl.createdAt.isBiggerOrEqualValue(cutoff14d))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();

    for (final entry in recentCooked) {
      final r = await (db.select(
        db.recipes,
      )..where((tbl) => tbl.id.equals(entry.recipeId))).getSingleOrNull();
      addTitle(r?.title);
    }

    // 2. Low-rated cooked entries (rating <= 2)
    final lowRated =
        await (db.select(db.cookedEntries)
              ..where((tbl) => tbl.rating.isSmallerOrEqualValue(2))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();

    for (final entry in lowRated) {
      final r = await (db.select(
        db.recipes,
      )..where((tbl) => tbl.id.equals(entry.recipeId))).getSingleOrNull();
      addTitle(r?.title);
    }

    // 3. Rejected suggestions / disliked from last 7 days
    final rejectedEvents =
        await (db.select(db.feedbackEvents)
              ..where(
                (tbl) =>
                    tbl.createdAt.isBiggerOrEqualValue(cutoff7d) &
                    (tbl.kind.equalsValue(FeedbackKind.rejected_suggestion) |
                        tbl.kind.equalsValue(FeedbackKind.disliked)),
              )
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();

    for (final event in rejectedEvents) {
      final recipeId = event.recipeId;
      if (recipeId != null) {
        final r = await (db.select(
          db.recipes,
        )..where((tbl) => tbl.id.equals(recipeId))).getSingleOrNull();
        addTitle(r?.title);
      }
    }

    return titles.take(40).toList();
  }

  /// Builds a deterministic cache key for `suggest_dishes` on the same calendar day.
  /// Combines available ingredients, filters, optional context tag, and date.
  static String buildCacheKey({
    required Iterable<String> availableIngredientIds,
    String? dishTypeFilter,
    String? difficultyFilter,
    String? contextTag,
    DateTime? now,
  }) {
    final currentTime = now ?? clock.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(currentTime);
    final sorted =
        availableIngredientIds
            .map((s) => s.toLowerCase().trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final cleanContext = (contextTag == null || contextTag.trim().isEmpty)
        ? '*'
        : contextTag.trim();
    final key =
        'suggest:${sorted.join(',')}:${dishTypeFilter ?? '*'}:${difficultyFilter ?? '*'}:$cleanContext:$dateStr';
    return key.hashCode.toRadixString(16);
  }

  /// Retrieves cached suggestions from `ai_requests` if requested on the same calendar day.
  static Future<List<AiDishSuggestion>?> getCachedSuggestions(
    AppDatabase db, {
    required Iterable<String> availableIngredientIds,
    String? dishTypeFilter,
    String? difficultyFilter,
    String? contextTag,
    DateTime? now,
  }) async {
    final currentTime = now ?? clock.now();
    final startOfDayMs = DateTime.utc(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    ).millisecondsSinceEpoch;
    final promptHash = buildCacheKey(
      availableIngredientIds: availableIngredientIds,
      dishTypeFilter: dishTypeFilter,
      difficultyFilter: difficultyFilter,
      contextTag: contextTag,
      now: currentTime,
    );

    final row =
        await (db.select(db.aiRequests)
              ..where(
                (tbl) =>
                    tbl.kind.equals('suggest_dishes') &
                    tbl.promptHash.equals(promptHash) &
                    tbl.status.equals('ok') &
                    tbl.at.isBiggerOrEqualValue(startOfDayMs),
              )
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.at)])
              ..limit(1))
            .getSingleOrNull();

    if (row == null || row.responseJson.isEmpty) return null;

    try {
      final decoded = jsonDecode(row.responseJson) as Map<String, dynamic>;
      final dishesRaw = (decoded['dishes'] as List?) ?? const [];
      return dishesRaw
          .whereType<Map<String, dynamic>>()
          .map(AiDishSuggestion.fromJson)
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Saves successful suggestions response into `ai_requests` cache.
  static Future<void> cacheSuggestions(
    AppDatabase db, {
    required Iterable<String> availableIngredientIds,
    String? dishTypeFilter,
    String? difficultyFilter,
    String? contextTag,
    required String responseJson,
    required String model,
    int? tokensIn,
    int? tokensOut,
    DateTime? now,
  }) async {
    final currentTime = now ?? clock.now();
    final promptHash = buildCacheKey(
      availableIngredientIds: availableIngredientIds,
      dishTypeFilter: dishTypeFilter,
      difficultyFilter: difficultyFilter,
      contextTag: contextTag,
      now: currentTime,
    );

    await db
        .into(db.aiRequests)
        .insert(
          AiRequestsCompanion(
            id: Value(const Uuid().v4()),
            kind: const Value('suggest_dishes'),
            promptHash: Value(promptHash),
            responseJson: Value(responseJson),
            model: Value(model),
            tokensIn: Value(tokensIn),
            tokensOut: Value(tokensOut),
            status: const Value('ok'),
            at: Value(currentTime.toUtc().millisecondsSinceEpoch),
            createdAt: Value(currentTime.toUtc().millisecondsSinceEpoch),
            updatedAt: Value(currentTime.toUtc().millisecondsSinceEpoch),
          ),
        );
  }
}
