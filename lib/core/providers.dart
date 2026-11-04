import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_database.dart';
import 'db/daos/ingredient_dao.dart';
import 'db/daos/pantry_dao.dart';
import 'db/daos/recipe_dao.dart';

/// One database instance per application.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(null);
  ref.onDispose(db.close);
  return db;
});

final ingredientDaoProvider = Provider<IngredientDao>((ref) {
  return IngredientDao(ref.watch(databaseProvider));
});

final pantryDaoProvider = Provider<PantryDao>((ref) {
  return PantryDao(ref.watch(databaseProvider));
});

final recipeDaoProvider = Provider<RecipeDao>((ref) {
  return RecipeDao(ref.watch(databaseProvider));
});

/// Ingredient ids currently marked as available at home.
final pantryProvider = AsyncNotifierProvider<PantryNotifier, Set<String>>(
  PantryNotifier.new,
);

class PantryNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    return ref.watch(pantryDaoProvider).availableIds();
  }

  Future<void> toggle(String ingredientId) async {
    final current = state.value ?? const <String>{};
    final next = {...current};
    final isAvailable = !next.contains(ingredientId);
    if (isAvailable) {
      next.add(ingredientId);
    } else {
      next.remove(ingredientId);
    }
    state = AsyncData(next);
    await ref.read(pantryDaoProvider).setAvailable(ingredientId, isAvailable);
  }

  Future<void> setAvailable(String ingredientId, bool isAvailable) async {
    final current = state.value ?? const <String>{};
    final next = {...current};
    if (isAvailable) {
      next.add(ingredientId);
    } else {
      next.remove(ingredientId);
    }
    state = AsyncData(next);
    await ref.read(pantryDaoProvider).setAvailable(ingredientId, isAvailable);
  }
}

/// Minimal local suggestions: recipes fully covered by the pantry.
/// S1-04…S1-06 replace this with the matcher, scorer and diversity rules.
final suggestionsProvider = FutureProvider<List<RecipeWithIngredients>>((
  ref,
) async {
  final available = await ref.watch(pantryProvider.future);
  if (available.isEmpty) return const [];

  final recipes = await ref.watch(recipeDaoProvider).allWithIngredients();
  return recipes.where((entry) {
    final required = entry.ingredients.where(
      (line) =>
          line.ingredient?.isStaple != true &&
          !line.recipeIngredient.isOptional,
    );
    return required.every(
      (line) => available.contains(line.recipeIngredient.ingredientId),
    );
  }).toList();
});
