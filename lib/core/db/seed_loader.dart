import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../catalog/catalog_taxonomy.dart';
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
      final nowMs = clock.now().toUtc().millisecondsSinceEpoch;

      await _loadIngredients(db, ingredientsList, nowMs);
      await _loadRecipes(db, recipesList, nowMs);
    });
  }

  Future<void> _loadIngredients(
    AppDatabase db,
    List<dynamic> ingredientsList,
    int nowMs,
  ) async {
    for (final raw in ingredientsList) {
      if (raw is! Map<String, dynamic>) continue;
      final id = raw['id'] as String;
      final name = raw['name'] as String;
      final synonyms =
          (raw['synonyms'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[];
      final category = raw['category'] as String? ?? 'other';
      final isStaple = raw['is_staple'] as bool? ?? false;
      final parentId = raw['parent_id'] as String?;

      final existing = await (db.select(
        db.ingredients,
      )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

      if (existing == null) {
        await db
            .into(db.ingredients)
            .insert(
              IngredientsCompanion(
                id: Value(id),
                name: Value(name),
                synonyms: Value(synonyms),
                category: Value(category),
                isStaple: Value(isStaple),
                parentId: Value(parentId),
                createdAt: Value(nowMs),
                updatedAt: Value(nowMs),
              ),
            );
      } else {
        // Keep user-owned fields (createdAt, deletedAt) untouched.
        await (db.update(
          db.ingredients,
        )..where((tbl) => tbl.id.equals(id))).write(
          IngredientsCompanion(
            name: Value(name),
            synonyms: Value(synonyms),
            category: Value(category),
            isStaple: Value(isStaple),
            parentId: Value(parentId),
            updatedAt: Value(nowMs),
          ),
        );
      }

      // Sync FTS table by ingredient id: two products may share a name or a
      // synonym, so deleting by name would erase the other product's row.
      await (db.delete(
        db.ingredientsFts,
      )..where((tbl) => tbl.ingredientId.equals(id))).go();
      await db
          .into(db.ingredientsFts)
          .insert(
            IngredientsFtsCompanion(
              ingredientId: Value(id),
              name: Value(name),
              synonyms: Value(synonyms.join(' ')),
            ),
          );
    }
  }

  Future<void> _loadRecipes(
    AppDatabase db,
    List<dynamic> recipesList,
    int nowMs,
  ) async {
    for (final raw in recipesList) {
      if (raw is! Map<String, dynamic>) continue;
      final id = raw['id'] as String;
      final title = raw['title'] as String;
      final normalizedTitle = title.toLowerCase().trim();
      final dishType = DishType.values.byName(raw['dish_type'] as String);
      final dishGroup =
          DishGroup.tryFromId(raw['dish_group'] as String?) ??
          DishGroup.fromDishType(dishType);
      final difficulty = Difficulty.values.byName(raw['difficulty'] as String);
      final rawCuisine = raw['cuisine'] as String?;
      final cuisine = Cuisine.normalize(rawCuisine);
      final totalMinutes = raw['total_minutes'] as int? ?? 30;
      final activeMinutes = raw['active_minutes'] as int? ?? 15;
      final cookMinutes = (raw['cook_minutes'] as int?) ?? totalMinutes;
      final kcalPerServing = raw['kcal_per_serving'] as int?;
      final servings = raw['servings'] as int? ?? 2;
      final description = raw['description'] as String? ?? '';
      final quality = raw['quality'] == 'template' ? 'template' : 'curated';

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

      final existing = await (db.select(
        db.recipes,
      )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

      if (existing == null) {
        await db
            .into(db.recipes)
            .insert(
              RecipesCompanion(
                id: Value(id),
                title: Value(title),
                normalizedTitle: Value(normalizedTitle),
                dishType: Value(dishType),
                dishGroup: Value(dishGroup),
                difficulty: Value(difficulty),
                cuisine: Value(cuisine),
                totalMinutes: Value(totalMinutes),
                activeMinutes: Value(activeMinutes),
                cookMinutes: Value(cookMinutes),
                kcalPerServing: Value(kcalPerServing),
                servings: Value(servings),
                description: Value(description),
                quality: Value(quality),
                source: const Value(RecipeSource.seed),
                fingerprint: Value(fingerprint),
                createdAt: Value(nowMs),
                updatedAt: Value(nowMs),
              ),
            );
      } else {
        // Keep user-owned fields (createdAt, isFavorite, deletedAt) untouched.
        await (db.update(db.recipes)..where((tbl) => tbl.id.equals(id))).write(
          RecipesCompanion(
            title: Value(title),
            normalizedTitle: Value(normalizedTitle),
            dishType: Value(dishType),
            dishGroup: Value(dishGroup),
            difficulty: Value(difficulty),
            cuisine: Value(cuisine),
            totalMinutes: Value(totalMinutes),
            activeMinutes: Value(activeMinutes),
            cookMinutes: Value(cookMinutes),
            kcalPerServing: Value(kcalPerServing),
            servings: Value(servings),
            description: Value(description),
            quality: Value(quality),
            fingerprint: Value(fingerprint),
            updatedAt: Value(nowMs),
          ),
        );
      }

      await _syncRecipeIngredients(db, id, rawIngredients, nowMs);
      await _syncRecipeSteps(db, id, rawSteps, nowMs);
      await _syncRecipeTags(
        db,
        id,
        raw['tags'],
        rawIngredients,
        totalMinutes,
        servings,
        dishGroup,
        difficulty,
        cuisine,
        title,
      );
    }
  }

  Future<void> _syncRecipeIngredients(
    AppDatabase db,
    String recipeId,
    List<dynamic> rawIngredients,
    int nowMs,
  ) async {
    final existingRows = await (db.select(
      db.recipeIngredients,
    )..where((tbl) => tbl.recipeId.equals(recipeId))).get();
    final existingById = {for (final row in existingRows) row.id: row};
    final keptIds = <String>{};

    for (var i = 0; i < rawIngredients.length; i++) {
      final ing = rawIngredients[i];
      if (ing is! Map<String, dynamic>) continue;
      final ingId = ing['ingredient_id'] as String;
      final amount = (ing['amount'] as num?)?.toDouble();
      final unit = ing['unit'] as String?;
      final isOptional = ing['is_optional'] as bool? ?? false;
      final note = ing['note'] as String?;
      final rowId = '${recipeId}_ing_$i';
      keptIds.add(rowId);

      if (existingById.containsKey(rowId)) {
        await (db.update(
          db.recipeIngredients,
        )..where((tbl) => tbl.id.equals(rowId))).write(
          RecipeIngredientsCompanion(
            ingredientId: Value(ingId),
            amount: Value(amount),
            unit: Value(unit),
            isOptional: Value(isOptional),
            note: Value(note),
            updatedAt: Value(nowMs),
          ),
        );
      } else {
        await db
            .into(db.recipeIngredients)
            .insert(
              RecipeIngredientsCompanion(
                id: Value(rowId),
                recipeId: Value(recipeId),
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
    }

    for (final row in existingRows) {
      if (keptIds.contains(row.id)) continue;
      await (db.delete(
        db.recipeIngredients,
      )..where((tbl) => tbl.id.equals(row.id))).go();
    }
  }

  Future<void> _syncRecipeSteps(
    AppDatabase db,
    String recipeId,
    List<dynamic> rawSteps,
    int nowMs,
  ) async {
    final existingRows = await (db.select(
      db.recipeSteps,
    )..where((tbl) => tbl.recipeId.equals(recipeId))).get();
    final existingById = {for (final row in existingRows) row.id: row};
    final keptIds = <String>{};

    for (var i = 0; i < rawSteps.length; i++) {
      final step = rawSteps[i];
      if (step is! Map<String, dynamic>) continue;
      final text = step['text'] as String;
      final timerSeconds = step['timer_seconds'] as int?;
      final tip = step['tip'] as String?;
      final rowId = '${recipeId}_step_$i';
      keptIds.add(rowId);

      if (existingById.containsKey(rowId)) {
        await (db.update(
          db.recipeSteps,
        )..where((tbl) => tbl.id.equals(rowId))).write(
          RecipeStepsCompanion(
            position: Value(i + 1),
            textContent: Value(text),
            timerSeconds: Value(timerSeconds),
            tip: Value(tip),
            updatedAt: Value(nowMs),
          ),
        );
      } else {
        await db
            .into(db.recipeSteps)
            .insert(
              RecipeStepsCompanion(
                id: Value(rowId),
                recipeId: Value(recipeId),
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

    for (final row in existingRows) {
      if (keptIds.contains(row.id)) continue;
      await (db.delete(
        db.recipeSteps,
      )..where((tbl) => tbl.id.equals(row.id))).go();
    }
  }

  Future<void> _syncRecipeTags(
    AppDatabase db,
    String recipeId,
    dynamic rawTags,
    List<dynamic> rawIngredients,
    int totalMinutes,
    int servings,
    DishGroup dishGroup,
    Difficulty difficulty,
    String cuisine,
    String title,
  ) async {
    final tagsToInsert = <RecipeTag>[];

    if (rawTags is List && rawTags.isNotEmpty) {
      for (final item in rawTags) {
        if (item is Map) {
          final kindStr = item['kind']?.toString() ?? 'dietary';
          final tagStr = item['tag']?.toString() ?? '';
          final kind = TagKind.tryFromId(kindStr);
          if (kind != null && tagStr.isNotEmpty) {
            tagsToInsert.add(RecipeTag(kind: kind, tag: tagStr));
          }
        } else if (item is String && item.isNotEmpty) {
          if (item.contains(':')) {
            final parts = item.split(':');
            final kind = TagKind.tryFromId(parts[0]);
            if (kind != null && parts[1].isNotEmpty) {
              tagsToInsert.add(RecipeTag(kind: kind, tag: parts[1]));
            }
          } else {
            if (DietaryTag.tryFromId(item) != null) {
              tagsToInsert.add(RecipeTag.dietary(DietaryTag.fromId(item)));
            } else if (OccasionTag.tryFromId(item) != null) {
              tagsToInsert.add(RecipeTag.occasion(OccasionTag.fromId(item)));
            } else if (MoodTag.tryFromId(item) != null) {
              tagsToInsert.add(RecipeTag.mood(MoodTag.fromId(item)));
            }
          }
        }
      }
    }

    if (tagsToInsert.isEmpty) {
      final taxonomyIngredients = rawIngredients
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => TaxonomyIngredient(
              id: e['ingredient_id']?.toString() ?? '',
              amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
              unit: e['unit']?.toString() ?? 'g',
            ),
          )
          .toList();

      final inferred = RecipeTaxonomyRules.inferAllTags(
        ingredients: taxonomyIngredients,
        totalMinutes: totalMinutes,
        servings: servings,
        dishGroup: dishGroup,
        difficulty: difficulty,
        cuisine: cuisine,
        title: title,
      );
      tagsToInsert.addAll(inferred);
    }

    // Clear and sync tags for this recipe
    await (db.delete(
      db.recipeTags,
    )..where((tbl) => tbl.recipeId.equals(recipeId))).go();

    for (final tag in tagsToInsert) {
      await db
          .into(db.recipeTags)
          .insert(
            RecipeTagsCompanion(
              recipeId: Value(recipeId),
              tagKind: Value(tag.kind),
              tag: Value(tag.tag),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }
  }
}
