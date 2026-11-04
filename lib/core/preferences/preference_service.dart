import 'dart:math';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/enums.dart';

class TasteProfile {
  const TasteProfile({
    required this.dishTypeWeights,
    required this.difficultyWeights,
    required this.cuisineWeights,
    required this.ingredientWeights,
    required this.excludedIngredients,
    required this.allergies,
    this.maxTotalMinutes,
    this.servingsDefault = 2,
  });

  final Map<String, double> dishTypeWeights;
  final Map<String, double> difficultyWeights;
  final Map<String, double> cuisineWeights;
  final Map<String, double> ingredientWeights;
  final List<String> excludedIngredients;
  final List<String> allergies;
  final int? maxTotalMinutes;
  final int servingsDefault;

  /// Returns the taste weight for a recipe based on its attributes.
  double scoreRecipe(Recipe recipe, List<String> recipeIngredientIds) {
    var sum = 0.0;
    var count = 0;

    final dishWeight = dishTypeWeights[recipe.dishType.name];
    if (dishWeight != null) {
      sum += dishWeight;
      count++;
    }

    final diffWeight = difficultyWeights[recipe.difficulty.name];
    if (diffWeight != null) {
      sum += diffWeight;
      count++;
    }

    final cuisWeight = cuisineWeights[recipe.cuisine];
    if (cuisWeight != null) {
      sum += cuisWeight;
      count++;
    }

    for (final ingId in recipeIngredientIds) {
      final ingWeight = ingredientWeights[ingId];
      if (ingWeight != null) {
        sum += ingWeight;
        count++;
      }
    }

    if (count == 0) return 0.0;
    final avg = sum / count;
    return avg.clamp(-1.0, 1.0);
  }
}

class CompressedProfile {
  const CompressedProfile({
    required this.topLikedFeatures,
    required this.topDislikedFeatures,
    required this.topRatedRecipeTitles,
  });

  final List<MapEntry<String, double>> topLikedFeatures;
  final List<MapEntry<String, double>> topDislikedFeatures;
  final List<String> topRatedRecipeTitles;
}

class PreferenceService {
  PreferenceService(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  /// Calculates signal s_i for a feedback event per Table 6.4:
  /// - cooked with rating 5: +1.0
  /// - cooked with rating 4: +0.5
  /// - cooked without rating: +0.3
  /// - cooked with rating 3: 0.0
  /// - cooked with rating 1-2 or disliked: -1.0
  /// - skipped: -0.2
  /// - rejected suggestion: -0.3
  static double calculateSignal(FeedbackKind kind, {String? reason}) {
    switch (kind) {
      case FeedbackKind.cooked:
        if (reason != null && reason.startsWith('rating:')) {
          final parts = reason.split(':');
          if (parts.length > 1) {
            final r = int.tryParse(parts[1].trim());
            if (r == 5) return 1.0;
            if (r == 4) return 0.5;
            if (r == 3) return 0.0;
            if (r != null && r <= 2) return -1.0;
          }
        }
        return 0.3; // Cooked without rating
      case FeedbackKind.liked:
        return 1.0;
      case FeedbackKind.disliked:
        return -1.0;
      case FeedbackKind.skipped:
        return -0.2;
      case FeedbackKind.rejected_suggestion:
        return -0.3;
      case FeedbackKind.opened:
        return 0.0;
    }
  }

  /// Calculates exponential decay weight with 60-day half-life: 2^(-delta_t / 60).
  static double decayWeight(DateTime eventTime, DateTime now) {
    final diffMs = now.difference(eventTime).inMilliseconds;
    final deltaDays = max(0.0, diffMs / (86400000.0));
    return pow(2.0, -deltaDays / 60.0).toDouble();
  }

  Map<String, double> _convertMap(Map<String, dynamic> raw) {
    final result = <String, double>{};
    for (final entry in raw.entries) {
      if (entry.value is num) {
        result[entry.key] = (entry.value as num).toDouble();
      }
    }
    return result;
  }

  /// Retrieves the current preference profile from SQLite (creates default if missing).
  Future<TasteProfile> getProfile() async {
    var row = await (_db.select(
      _db.preferenceProfile,
    )..limit(1)).getSingleOrNull();

    if (row == null) {
      final nowMs = clock.now().toUtc().millisecondsSinceEpoch;
      final newRow = PreferenceProfileCompanion(
        id: Value(_uuid.v4()),
        createdAt: Value(nowMs),
        updatedAt: Value(nowMs),
        dishTypeWeights: const Value({}),
        ingredientWeights: const Value({}),
        cuisineWeights: const Value({}),
        difficultyWeights: const Value({}),
        excludedIngredients: const Value([]),
        allergies: const Value([]),
        servingsDefault: const Value(2),
      );
      await _db.into(_db.preferenceProfile).insert(newRow);
      row = await (_db.select(_db.preferenceProfile)..limit(1)).getSingle();
    }

    return TasteProfile(
      dishTypeWeights: _convertMap(row.dishTypeWeights),
      difficultyWeights: _convertMap(row.difficultyWeights),
      cuisineWeights: _convertMap(row.cuisineWeights),
      ingredientWeights: _convertMap(row.ingredientWeights),
      excludedIngredients: List<String>.from(row.excludedIngredients),
      allergies: List<String>.from(row.allergies),
      maxTotalMinutes: row.maxTotalMinutes,
      servingsDefault: row.servingsDefault,
    );
  }

  /// Records a feedback event and immediately recalculates the preference profile.
  Future<TasteProfile> recordEvent({
    required String? recipeId,
    required FeedbackKind kind,
    String? reason,
    int? at,
  }) async {
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;
    final event = FeedbackEvent(
      id: _uuid.v4(),
      createdAt: nowMs,
      updatedAt: nowMs,
      recipeId: recipeId,
      kind: kind,
      reason: reason,
      at: at ?? nowMs,
    );

    await _db.into(_db.feedbackEvents).insert(event);
    return recalculateProfile();
  }

  /// Recalculates all feature weights from feedback events using ТЗ 6.4 formula:
  /// w_f = (sum_i s_i * 2^(-delta_t / 60)) / (sum_i 2^(-delta_t / 60) + 3)
  Future<TasteProfile> recalculateProfile() async {
    final now = clock.now();
    final nowMs = now.toUtc().millisecondsSinceEpoch;

    // Fetch all active feedback events
    final events = await (_db.select(
      _db.feedbackEvents,
    )..where((tbl) => tbl.deletedAt.isNull())).get();

    final recipeIds = events
        .map((e) => e.recipeId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    final recipes = await (_db.select(
      _db.recipes,
    )..where((tbl) => tbl.id.isIn(recipeIds))).get();
    final recipeById = {for (final r in recipes) r.id: r};

    final ingRows = await (_db.select(
      _db.recipeIngredients,
    )..where((tbl) => tbl.recipeId.isIn(recipeIds))).get();
    final ingredientsByRecipe = <String, List<String>>{};
    for (final ing in ingRows) {
      ingredientsByRecipe
          .putIfAbsent(ing.recipeId, () => [])
          .add(ing.ingredientId);
    }

    // Accumulators: Map<feature, (numerator, denominator)>
    final dishTypeAccum = <String, (double, double)>{};
    final difficultyAccum = <String, (double, double)>{};
    final cuisineAccum = <String, (double, double)>{};
    final ingredientAccum = <String, (double, double)>{};

    void accumulate(
      Map<String, (double, double)> map,
      String key,
      double s,
      double decay,
    ) {
      final current = map[key] ?? (0.0, 0.0);
      map[key] = (current.$1 + s * decay, current.$2 + decay);
    }

    for (final ev in events) {
      if (ev.recipeId == null) continue;
      final recipe = recipeById[ev.recipeId];
      if (recipe == null) continue;

      final s = calculateSignal(ev.kind, reason: ev.reason);
      final evTime = DateTime.fromMillisecondsSinceEpoch(ev.at, isUtc: true);
      final decay = decayWeight(evTime, now);

      // Feature 1: DishType
      accumulate(dishTypeAccum, recipe.dishType.name, s, decay);

      // Feature 2: Difficulty
      accumulate(difficultyAccum, recipe.difficulty.name, s, decay);

      // Feature 3: Cuisine
      if (recipe.cuisine.isNotEmpty) {
        accumulate(cuisineAccum, recipe.cuisine, s, decay);
      }

      // Feature 4: Ingredients
      final ingIds = ingredientsByRecipe[recipe.id] ?? const [];
      for (final ingId in ingIds) {
        accumulate(ingredientAccum, ingId, s, decay);
      }
    }

    Map<String, double> computeWeights(Map<String, (double, double)> accum) {
      final res = <String, double>{};
      for (final entry in accum.entries) {
        final num = entry.value.$1;
        final den = entry.value.$2 + 3.0; // The +3 prior damping term
        final w = (num / den).clamp(-1.0, 1.0);
        res[entry.key] = double.parse(w.toStringAsFixed(4));
      }
      return res;
    }

    final newDishWeights = computeWeights(dishTypeAccum);
    final newDiffWeights = computeWeights(difficultyAccum);
    final newCuisWeights = computeWeights(cuisineAccum);
    final newIngWeights = computeWeights(ingredientAccum);

    // Save updated weights into preference_profile row
    final currentProfile = await getProfile();
    await (_db.update(_db.preferenceProfile)).write(
      PreferenceProfileCompanion(
        dishTypeWeights: Value(newDishWeights),
        difficultyWeights: Value(newDiffWeights),
        cuisineWeights: Value(newCuisWeights),
        ingredientWeights: Value(newIngWeights),
        updatedAt: Value(nowMs),
      ),
    );

    return TasteProfile(
      dishTypeWeights: newDishWeights,
      difficultyWeights: newDiffWeights,
      cuisineWeights: newCuisWeights,
      ingredientWeights: newIngWeights,
      excludedIngredients: currentProfile.excludedIngredients,
      allergies: currentProfile.allergies,
      maxTotalMinutes: currentProfile.maxTotalMinutes,
      servingsDefault: currentProfile.servingsDefault,
    );
  }

  Future<void> _ensureProfileRow() async {
    final existing = await (_db.select(_db.preferenceProfile)..limit(1)).get();
    if (existing.isEmpty) {
      await getProfile();
    }
  }

  /// Resets learned taste weights while preserving user-selected allergies and excluded items.
  Future<TasteProfile> resetProfile() async {
    await _ensureProfileRow();
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.preferenceProfile)).write(
      PreferenceProfileCompanion(
        dishTypeWeights: const Value({}),
        difficultyWeights: const Value({}),
        cuisineWeights: const Value({}),
        ingredientWeights: const Value({}),
        updatedAt: Value(nowMs),
      ),
    );
    return getProfile();
  }

  Future<void> setAllergies(List<String> allergies) async {
    await _ensureProfileRow();
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.preferenceProfile)).write(
      PreferenceProfileCompanion(
        allergies: Value(allergies),
        updatedAt: Value(nowMs),
      ),
    );
  }

  Future<void> setExcludedIngredients(List<String> excluded) async {
    await _ensureProfileRow();
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.preferenceProfile)).write(
      PreferenceProfileCompanion(
        excludedIngredients: Value(excluded),
        updatedAt: Value(nowMs),
      ),
    );
  }

  /// Produces a compact profile description for prompts and the settings screen:
  /// - Top 5 liked features (w > 0)
  /// - Top 5 disliked features (w < 0)
  /// - 5 best rated recipe titles
  Future<CompressedProfile> getCompressedProfile() async {
    var profile = await getProfile();
    if (profile.dishTypeWeights.isEmpty &&
        profile.difficultyWeights.isEmpty &&
        profile.cuisineWeights.isEmpty &&
        profile.ingredientWeights.isEmpty) {
      profile = await recalculateProfile();
    }

    final allFeatures = <MapEntry<String, double>>[
      ...profile.dishTypeWeights.entries,
      ...profile.difficultyWeights.entries,
      ...profile.cuisineWeights.entries,
      ...profile.ingredientWeights.entries,
    ];

    final liked = allFeatures.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final disliked = allFeatures.where((e) => e.value < 0).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // 5 best rated recipes from history
    final cooked =
        await (_db.select(_db.cookedEntries)
              ..where((tbl) => tbl.deletedAt.isNull() & tbl.rating.isNotNull())
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.rating)]))
            .get();

    final topRecipeIds = <String>{};
    for (final c in cooked) {
      topRecipeIds.add(c.recipeId);
      if (topRecipeIds.length >= 5) break;
    }

    final topRecipes = await (_db.select(
      _db.recipes,
    )..where((tbl) => tbl.id.isIn(topRecipeIds))).get();

    return CompressedProfile(
      topLikedFeatures: liked.take(5).toList(),
      topDislikedFeatures: disliked.take(5).toList(),
      topRatedRecipeTitles: topRecipes.map((r) => r.title).toList(),
    );
  }
}
