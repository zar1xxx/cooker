import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_database.dart';
import 'db/daos/ingredient_dao.dart';
import 'db/daos/history_dao.dart';
import 'db/daos/pantry_dao.dart';
import 'db/daos/recipe_dao.dart';
import 'matching/diversity_reorderer.dart';
import 'matching/recipe_matcher.dart';
import 'matching/recipe_scorer.dart';

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

/// Category metadata for the pantry UI.
class IngredientCategory {
  const IngredientCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final String icon;
}

final categoriesProvider = Provider<List<IngredientCategory>>((ref) {
  return const [
    IngredientCategory(id: 'vegetables', name: 'Овощи', icon: 'carrot'),
    IngredientCategory(id: 'meat', name: 'Мясо', icon: 'meat'),
    IngredientCategory(id: 'poultry', name: 'Птица', icon: 'chicken'),
    IngredientCategory(id: 'dairy', name: 'Молочное и яйца', icon: 'milk'),
    IngredientCategory(id: 'grains', name: 'Крупы и макароны', icon: 'grain'),
    IngredientCategory(id: 'fish', name: 'Рыба и морепродукты', icon: 'fish'),
    IngredientCategory(id: 'bakery', name: 'Мука и хлеб', icon: 'bread'),
    IngredientCategory(id: 'fruits', name: 'Фрукты и ягоды', icon: 'apple'),
    IngredientCategory(id: 'greens', name: 'Зелень', icon: 'leaf'),
    IngredientCategory(id: 'mushrooms', name: 'Грибы', icon: 'mushroom'),
    IngredientCategory(id: 'legumes', name: 'Бобовые', icon: 'bean'),
    IngredientCategory(id: 'canned', name: 'Консервы', icon: 'can'),
    IngredientCategory(id: 'spices', name: 'Специи и соусы', icon: 'spice'),
    IngredientCategory(id: 'nuts', name: 'Орехи и семечки', icon: 'nut'),
    IngredientCategory(id: 'sweets', name: 'Сладкое', icon: 'candy'),
  ];
});

final ingredientsByCategoryProvider =
    FutureProvider.family<List<Ingredient>, String>((ref, categoryId) async {
      final dao = ref.watch(ingredientDaoProvider);
      return dao.byCategory(categoryId);
    });

final frequentIngredientsProvider = FutureProvider<List<Ingredient>>((
  ref,
) async {
  final dao = ref.watch(ingredientDaoProvider);
  const defaultFrequentIds = [
    'onion',
    'carrot',
    'egg',
    'potato',
    'garlic',
    'butter',
    'chicken',
    'flour',
    'milk',
    'sour_cream',
    'tomato',
    'dill',
  ];
  return dao.byIds(defaultFrequentIds);
});

final ingredientSearchProvider =
    FutureProvider.family<List<Ingredient>, String>((ref, query) async {
      final trimmed = query.trim();
      if (trimmed.isEmpty) return const [];
      final dao = ref.watch(ingredientDaoProvider);
      return dao.searchWithNormalizer(trimmed);
    });

/// Recommendation result grouped into «Можно приготовить сейчас» and
/// «Не хватает 1–2 продуктов» per TZ 5.2.
class SuggestionsState {
  const SuggestionsState({this.ready = const [], this.almostReady = const []});

  final List<ScoredRecipe> ready;
  final List<ScoredRecipe> almostReady;

  int get totalCount => ready.length + almostReady.length;
  bool get isEmpty => ready.isEmpty && almostReady.isEmpty;
}

final suggestionsProvider = FutureProvider<SuggestionsState>((ref) async {
  final available = await ref.watch(pantryProvider.future);
  if (available.isEmpty) return const SuggestionsState();

  final recipeDao = ref.watch(recipeDaoProvider);
  final ingredientDao = ref.watch(ingredientDaoProvider);

  final recipes = await recipeDao.allWithIngredients();
  final hierarchy = await ingredientDao.hierarchy();
  final normalizer = await ingredientDao.createNormalizer();

  const matcher = RecipeMatcher();
  final matchResult = matcher.match(
    recipes: recipes,
    availableIds: available,
    hierarchy: hierarchy,
  );

  const scorer = RecipeScorer();
  final scoredReady = scorer.rank(matchResult.ready);
  final scoredAlmost = scorer.rank(matchResult.almostReady);

  const reorderer = RecipeDiversityReorderer();
  String rootAncestorLookup(String id) =>
      normalizer.ancestorsOf(id).lastOrNull ?? id;

  final diverseReady = reorderer.reorder(
    scoredReady,
    rootAncestorLookup: rootAncestorLookup,
  );
  final diverseAlmost = reorderer.reorder(
    scoredAlmost,
    rootAncestorLookup: rootAncestorLookup,
  );

  return SuggestionsState(ready: diverseReady, almostReady: diverseAlmost);
});

final recipeDetailProvider = FutureProvider.family<RecipeDetail?, String>((
  ref,
  recipeId,
) async {
  final dao = ref.watch(recipeDaoProvider);
  return dao.getRecipeDetail(recipeId);
});

final ingredientHierarchyProvider = FutureProvider<Map<String, List<String>>>((
  ref,
) async {
  final dao = ref.watch(ingredientDaoProvider);
  return dao.hierarchy();
});

final historyDaoProvider = Provider<HistoryDao>((ref) {
  return HistoryDao(ref.watch(databaseProvider));
});

final historyEntriesProvider = FutureProvider<List<CookedEntryWithRecipe>>((
  ref,
) async {
  final dao = ref.watch(historyDaoProvider);
  return dao.allWithRecipes();
});
