import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../app_database.dart';

class RecipeIngredientLine {
  const RecipeIngredientLine({
    required this.recipeIngredient,
    required this.ingredient,
  });

  final RecipeIngredient recipeIngredient;
  final Ingredient? ingredient;
}

class RecipeWithIngredients {
  const RecipeWithIngredients({
    required this.recipe,
    required this.ingredients,
  });

  final Recipe recipe;
  final List<RecipeIngredientLine> ingredients;
}

class RecipeDetail {
  const RecipeDetail({
    required this.recipe,
    required this.ingredients,
    required this.steps,
  });

  final Recipe recipe;
  final List<RecipeIngredientLine> ingredients;
  final List<RecipeStep> steps;
}

/// Read access to recipes and their composition.
class RecipeDao {
  RecipeDao(this._db);

  final AppDatabase _db;

  Future<List<Recipe>> all() {
    return (_db.select(
      _db.recipes,
    )..where((tbl) => tbl.deletedAt.isNull())).get();
  }

  Future<Recipe?> byId(String id) {
    return (_db.select(_db.recipes)
          ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<List<RecipeStep>> stepsFor(String recipeId) {
    return (_db.select(_db.recipeSteps)
          ..where((tbl) => tbl.recipeId.equals(recipeId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.position)]))
        .get();
  }

  Future<List<RecipeWithIngredients>> allWithIngredients() async {
    final recipes = await all();
    final ingredientRows = await _db.select(_db.recipeIngredients).get();
    final ingredients = await _db.select(_db.ingredients).get();
    final ingredientById = {for (final row in ingredients) row.id: row};

    final linesByRecipe = <String, List<RecipeIngredientLine>>{};
    for (final row in ingredientRows) {
      linesByRecipe
          .putIfAbsent(row.recipeId, () => [])
          .add(
            RecipeIngredientLine(
              recipeIngredient: row,
              ingredient: ingredientById[row.ingredientId],
            ),
          );
    }

    return [
      for (final recipe in recipes)
        RecipeWithIngredients(
          recipe: recipe,
          ingredients: linesByRecipe[recipe.id] ?? const [],
        ),
    ];
  }

  Future<void> setFavorite(String recipeId, bool isFavorite) async {
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(
      _db.recipes,
    )..where((tbl) => tbl.id.equals(recipeId))).write(
      RecipesCompanion(isFavorite: Value(isFavorite), updatedAt: Value(nowMs)),
    );
  }

  Future<bool> toggleFavorite(String recipeId) async {
    final recipe = await byId(recipeId);
    if (recipe == null) return false;
    final next = !recipe.isFavorite;
    await setFavorite(recipeId, next);
    return next;
  }

  Future<RecipeDetail?> getRecipeDetail(String recipeId) async {
    final recipe = await byId(recipeId);
    if (recipe == null) return null;

    final ingredientRows = await (_db.select(
      _db.recipeIngredients,
    )..where((tbl) => tbl.recipeId.equals(recipeId))).get();
    final ingredientIds = ingredientRows.map((r) => r.ingredientId).toSet();
    final ingredients = await (_db.select(
      _db.ingredients,
    )..where((tbl) => tbl.id.isIn(ingredientIds))).get();
    final ingredientById = {for (final ing in ingredients) ing.id: ing};

    final lines = [
      for (final row in ingredientRows)
        RecipeIngredientLine(
          recipeIngredient: row,
          ingredient: ingredientById[row.ingredientId],
        ),
    ];
    final steps = await stepsFor(recipeId);

    return RecipeDetail(recipe: recipe, ingredients: lines, steps: steps);
  }
}
