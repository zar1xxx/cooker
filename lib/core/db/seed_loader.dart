import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'app_database.dart';
import 'enums.dart';

class SeedLoader {
  const SeedLoader();

  Future<void> loadSeedData(
    AppDatabase db, {
    String? ingredientsJson,
    String? recipesJson,
  }) async {
    final ingContent =
        ingredientsJson ??
        await rootBundle.loadString('assets/seed/ingredients.json');
    final recContent =
        recipesJson ?? await rootBundle.loadString('assets/seed/recipes.json');

    final dynamic ingDecoded = jsonDecode(ingContent);
    final dynamic recDecoded = jsonDecode(recContent);

    final ingredientsList =
        (ingDecoded is Map && ingDecoded['ingredients'] is List)
        ? (ingDecoded['ingredients'] as List)
        : (ingDecoded is List ? ingDecoded : const []);

    final recipesList = (recDecoded is Map && recDecoded['recipes'] is List)
        ? (recDecoded['recipes'] as List)
        : (recDecoded is List ? recDecoded : const []);

    await db.transaction(() async {
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

      // 1. Load ingredients
      for (final raw in ingredientsList) {
        if (raw is! Map<String, dynamic>) continue;
        final id = raw['id'] as String;
        final name = raw['name'] as String;
        final synonyms =
            (raw['synonyms'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
        final category = raw['category'] as String? ?? 'other';
        final isStaple = raw['is_staple'] as bool? ?? false;

        await db
            .into(db.ingredients)
            .insertOnConflictUpdate(
              IngredientsCompanion(
                id: Value(id),
                name: Value(name),
                synonyms: Value(synonyms),
                category: Value(category),
                isStaple: Value(isStaple),
                createdAt: Value(nowMs),
                updatedAt: Value(nowMs),
              ),
            );

        // Sync FTS table
        await (db.delete(
          db.ingredientsFts,
        )..where((tbl) => tbl.name.equals(name))).go();
        await db
            .into(db.ingredientsFts)
            .insert(
              IngredientsFtsCompanion(
                name: Value(name),
                synonyms: Value(synonyms.join(' ')),
              ),
            );
      }

      // 2. Load recipes
      for (final raw in recipesList) {
        if (raw is! Map<String, dynamic>) continue;
        final id = raw['id'] as String;
        final title = raw['title'] as String;
        final normalizedTitle = title.toLowerCase().trim();
        final dishType = DishType.values.byName(raw['dish_type'] as String);
        final difficulty = Difficulty.values.byName(
          raw['difficulty'] as String,
        );
        final cuisine = raw['cuisine'] as String? ?? 'домашняя';
        final totalMinutes = raw['total_minutes'] as int? ?? 30;
        final activeMinutes = raw['active_minutes'] as int? ?? 15;
        final servings = raw['servings'] as int? ?? 2;
        final description = raw['description'] as String? ?? '';

        final rawIngredients = (raw['ingredients'] as List?) ?? const [];
        final rawSteps = (raw['steps'] as List?) ?? const [];

        final sortedIngIds =
            rawIngredients
                .whereType<Map<String, dynamic>>()
                .map((e) => e['ingredient_id']?.toString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList()
              ..sort();
        final fingerprint =
            '${raw['dish_type']}:${sortedIngIds.take(4).join(',')}';

        await db
            .into(db.recipes)
            .insertOnConflictUpdate(
              RecipesCompanion(
                id: Value(id),
                title: Value(title),
                normalizedTitle: Value(normalizedTitle),
                dishType: Value(dishType),
                difficulty: Value(difficulty),
                cuisine: Value(cuisine),
                totalMinutes: Value(totalMinutes),
                activeMinutes: Value(activeMinutes),
                servings: Value(servings),
                description: Value(description),
                source: const Value(RecipeSource.seed),
                fingerprint: Value(fingerprint),
                createdAt: Value(nowMs),
                updatedAt: Value(nowMs),
              ),
            );

        // Refresh recipe ingredients
        await (db.delete(
          db.recipeIngredients,
        )..where((tbl) => tbl.recipeId.equals(id))).go();

        for (var i = 0; i < rawIngredients.length; i++) {
          final ing = rawIngredients[i];
          if (ing is! Map<String, dynamic>) continue;
          final ingId = ing['ingredient_id'] as String;
          final amount = (ing['amount'] as num?)?.toDouble();
          final unit = ing['unit'] as String?;
          final isOptional = ing['is_optional'] as bool? ?? false;
          final note = ing['note'] as String?;

          await db
              .into(db.recipeIngredients)
              .insert(
                RecipeIngredientsCompanion(
                  id: Value('${id}_ing_$i'),
                  recipeId: Value(id),
                  ingredientId: Value(ingId),
                  amount: Value(amount),
                  unit: Value(unit),
                  isOptional: Value(isOptional),
                  note: Value(note),
                  createdAt: Value(nowMs),
                  updatedAt: Value(nowMs),
                ),
              );
        }

        // Refresh recipe steps
        await (db.delete(
          db.recipeSteps,
        )..where((tbl) => tbl.recipeId.equals(id))).go();

        for (var i = 0; i < rawSteps.length; i++) {
          final step = rawSteps[i];
          if (step is! Map<String, dynamic>) continue;
          final text = step['text'] as String;
          final timerSeconds = step['timer_seconds'] as int?;
          final tip = step['tip'] as String?;

          await db
              .into(db.recipeSteps)
              .insert(
                RecipeStepsCompanion(
                  id: Value('${id}_step_$i'),
                  recipeId: Value(id),
                  position: Value(i + 1),
                  textContent: Value(text),
                  timerSeconds: Value(timerSeconds),
                  tip: Value(tip),
                  createdAt: Value(nowMs),
                  updatedAt: Value(nowMs),
                ),
              );
        }
      }
    });
  }
}
