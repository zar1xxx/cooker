import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai/ai_router.dart';
import 'ai/ai_service.dart';
import 'ai/ai_settings_service.dart';
import 'ai/anti_repeat.dart';
import 'ai/gigachat_provider.dart';
import 'ai/lm_studio_provider.dart';
import 'ai/pc_discovery.dart';
import 'ai/recipe_validator.dart';
import 'db/app_database.dart';
import 'db/daos/history_dao.dart';
import 'db/daos/ingredient_dao.dart';
import 'db/daos/pantry_dao.dart';
import 'db/daos/plan_dao.dart';
import 'db/daos/recipe_dao.dart';
import 'matching/diversity_reorderer.dart';
import 'matching/recipe_matcher.dart';
import 'matching/recipe_scorer.dart';
import 'preferences/preference_service.dart';
import 'backup/backup_service.dart';
import 'calendar/meal_planner.dart';
import 'services/daily_notification_service.dart';

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

final planDaoProvider = Provider<PlanDao>((ref) {
  return PlanDao(ref.watch(databaseProvider));
});

final calendarPlanEntriesProvider =
    FutureProvider<List<MealPlanEntryWithRecipe>>((ref) async {
      return ref.watch(planDaoProvider).allWithRecipes();
    });

final todayPlanEntryProvider = FutureProvider<MealPlanEntryWithRecipe?>((
  ref,
) async {
  final planDao = ref.watch(planDaoProvider);
  await planDao.autoSkipPastPlannedEntries();
  final todayKey = PlanDao.formatDate(clock.now());
  return planDao.getEntryForDate(todayKey);
});

final dailyNotificationServiceProvider = Provider<DailyNotificationService>((
  ref,
) {
  final service = DailyNotificationService();
  service.init();
  return service;
});

final mealPlannerProvider = Provider<MealPlanner>((ref) {
  final aiService = ref.watch(aiServiceProvider).value;
  return MealPlanner(
    recipeDao: ref.watch(recipeDaoProvider),
    planDao: ref.watch(planDaoProvider),
    ingredientDao: ref.watch(ingredientDaoProvider),
    preferenceService: ref.watch(preferenceServiceProvider),
    historyDao: ref.watch(historyDaoProvider),
    db: ref.watch(databaseProvider),
    aiService: aiService,
  );
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
  final historyDao = ref.watch(historyDaoProvider);
  final tasteProfile = await ref.watch(preferenceProfileProvider.future);

  final recipes = await recipeDao.allWithIngredients();
  final hierarchy = await ingredientDao.hierarchy();
  final normalizer = await ingredientDao.createNormalizer();

  const matcher = RecipeMatcher();
  final matchResult = matcher.match(
    recipes: recipes,
    availableIds: available,
    hierarchy: hierarchy,
  );

  // Exclude recipes with rating 1 per ТЗ 5.3 & 6.4 ("блюдо с оценкой 1 не предлагается")
  final dislikedIds = await historyDao.getDislikedRecipeIds();

  // Exclude recipes with allergens or excluded ingredients per ТЗ 9.1 & Scenario 5
  final rawForbidden = {
    ...tasteProfile.allergies.map((s) => s.toLowerCase().trim()),
    ...tasteProfile.excludedIngredients.map((s) => s.toLowerCase().trim()),
  }.where((s) => s.isNotEmpty).toSet();

  final forbiddenIds = <String>{};
  for (final term in rawForbidden) {
    forbiddenIds.add(term);
    final resolvedId = normalizer.resolve(term);
    if (resolvedId != null) {
      forbiddenIds.add(resolvedId.toLowerCase());
      for (final desc in normalizer.descendantsOf(resolvedId)) {
        forbiddenIds.add(desc.toLowerCase());
      }
    }
  }

  bool containsForbidden(RecipeWithIngredients entry) {
    if (forbiddenIds.isEmpty) return false;
    for (final line in entry.ingredients) {
      final idLower = line.recipeIngredient.ingredientId.toLowerCase().trim();
      final nameLower = line.ingredient?.name.toLowerCase().trim() ?? '';
      if (forbiddenIds.contains(idLower) ||
          (nameLower.isNotEmpty && forbiddenIds.contains(nameLower))) {
        return true;
      }
      final parents = hierarchy[line.recipeIngredient.ingredientId] ?? const [];
      for (final p in parents) {
        if (forbiddenIds.contains(p.toLowerCase().trim())) {
          return true;
        }
      }
    }
    return false;
  }

  final readyMatches = matchResult.ready
      .where(
        (m) =>
            !dislikedIds.contains(m.entry.recipe.id) &&
            !containsForbidden(m.entry),
      )
      .toList();
  final almostMatches = matchResult.almostReady
      .where(
        (m) =>
            !dislikedIds.contains(m.entry.recipe.id) &&
            !containsForbidden(m.entry),
      )
      .toList();

  final recipeRatings = await historyDao.getAverageRatingsByRecipe();
  final scorer = RecipeScorer.withProfile(
    tasteProfile,
    recipeRatings: recipeRatings,
  );
  final scoredReady = scorer.rank(readyMatches);
  final scoredAlmost = scorer.rank(almostMatches);

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

final preferenceServiceProvider = Provider<PreferenceService>((ref) {
  return PreferenceService(ref.watch(databaseProvider));
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(databaseProvider));
});

final preferenceProfileProvider = FutureProvider<TasteProfile>((ref) async {
  final service = ref.watch(preferenceServiceProvider);
  return service.getProfile();
});

final compressedProfileProvider = FutureProvider<CompressedProfile>((
  ref,
) async {
  final service = ref.watch(preferenceServiceProvider);
  return service.getCompressedProfile();
});

final historyDaoProvider = Provider<HistoryDao>((ref) {
  return HistoryDao(
    ref.watch(databaseProvider),
    preferenceService: ref.watch(preferenceServiceProvider),
  );
});

final historyEntriesProvider = FutureProvider<List<CookedEntryWithRecipe>>((
  ref,
) async {
  final dao = ref.watch(historyDaoProvider);
  return dao.allWithRecipes();
});

final historyMonthSummaryProvider =
    FutureProvider.family<HistoryMonthSummary, DateTime?>((ref, month) async {
      final dao = ref.watch(historyDaoProvider);
      return dao.getMonthSummary(month: month);
    });

final aiSettingsServiceProvider = Provider<AiSettingsService>((ref) {
  return AiSettingsService();
});

final aiSettingsProvider = FutureProvider<AiSettings>((ref) async {
  final service = ref.watch(aiSettingsServiceProvider);
  return service.loadSettings();
});

final pcDiscoveryProvider = Provider<PcDiscovery>((ref) {
  return PcDiscovery();
});

final aiRouterProvider = Provider<AiRouter>((ref) {
  final router = AiRouter();
  final settingsService = ref.watch(aiSettingsServiceProvider);
  settingsService.loadSettings().then((settings) {
    settingsService.applyToRouter(router, settings);
  });
  return router;
});

final monthlyGigaChatTokensProvider = FutureProvider<int>((ref) async {
  final aiService = await ref.watch(aiServiceProvider.future);
  return aiService.getMonthlyTokensUsed(modelFilter: 'gigachat');
});

class AiConnectionChecker {
  const AiConnectionChecker();

  Future<bool> checkPc(String host, int port) async {
    if (host.trim().isEmpty) return false;
    try {
      final pc = LmStudioProvider(baseUrl: 'http://${host.trim()}:$port');
      return await pc.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkGigaChat(String authKey, String baseUrl) async {
    if (authKey.trim().isEmpty) return false;
    try {
      final giga = GigaChatProvider(
        authKey: authKey.trim(),
        baseUrl: baseUrl.trim().isNotEmpty
            ? baseUrl.trim()
            : 'https://gigachat.devices.sberbank.ru',
      );
      return await giga.isAvailable();
    } catch (_) {
      return false;
    }
  }
}

final aiConnectionCheckerProvider = Provider<AiConnectionChecker>((ref) {
  return const AiConnectionChecker();
});

final recipeValidatorProvider = FutureProvider<RecipeValidator>((ref) async {
  return RecipeValidator.fromAsset();
});

final aiServiceProvider = FutureProvider<AiService>((ref) async {
  final router = ref.watch(aiRouterProvider);
  final validator = await ref.watch(recipeValidatorProvider.future);
  final db = ref.watch(databaseProvider);
  return AiService(router: router, validator: validator, db: db);
});

final aiModeProvider = FutureProvider<AiMode>((ref) async {
  final router = ref.watch(aiRouterProvider);
  return router.getMode();
});

final aiDishesProvider =
    AsyncNotifierProvider<AiDishesNotifier, List<AiDishSuggestion>>(
      AiDishesNotifier.new,
    );

class AiDishesNotifier extends AsyncNotifier<List<AiDishSuggestion>> {
  @override
  Future<List<AiDishSuggestion>> build() async {
    final availableIds = await ref.watch(pantryProvider.future);
    if (availableIds.isEmpty) return const [];

    final aiService = await ref.watch(aiServiceProvider.future);
    final ingredientDao = ref.watch(ingredientDaoProvider);
    final prefService = ref.watch(preferenceServiceProvider);
    final db = ref.watch(databaseProvider);

    final ingredients = await ingredientDao.byIds(availableIds.toList());
    final availableNames = ingredients.map((i) => i.name).toList();

    final profile = await prefService.getProfile();
    final compressed = await prefService.getCompressedProfile();
    final doNotSuggest = await AntiRepeat.getDoNotSuggestList(db);
    final forbidden = [...profile.allergies, ...profile.excludedIngredients];
    final hierarchy = await ingredientDao.hierarchy();
    final normalizer = await ingredientDao.createNormalizer();

    return aiService.suggestDishes(
      availableIngredients: availableNames,
      forbiddenIngredients: forbidden,
      doNotSuggest: doNotSuggest,
      likes: compressed.topLikedFeatures.map((e) => e.key).toList(),
      dislikes: compressed.topDislikedFeatures.map((e) => e.key).toList(),
      topRated: compressed.topRatedRecipeTitles,
      maxTotalMinutes: profile.maxTotalMinutes,
      profile: {
        'allergies': profile.allergies,
        'excluded_ingredients': profile.excludedIngredients,
      },
      ingredientHierarchy: hierarchy,
      resolveIngredientId: (name) => normalizer.resolve(name),
    );
  }

  Future<void> fetchOtherVariants({
    List<String> alreadyShown = const [],
  }) async {
    final availableIds = await ref.read(pantryProvider.future);
    if (availableIds.isEmpty) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final aiService = await ref.read(aiServiceProvider.future);
      final ingredientDao = ref.read(ingredientDaoProvider);
      final prefService = ref.read(preferenceServiceProvider);
      final db = ref.read(databaseProvider);

      final ingredients = await ingredientDao.byIds(availableIds.toList());
      final availableNames = ingredients.map((i) => i.name).toList();

      final profile = await prefService.getProfile();
      final compressed = await prefService.getCompressedProfile();
      final baseDoNotSuggest = await AntiRepeat.getDoNotSuggestList(db);
      final mergedDoNotSuggest = {
        ...baseDoNotSuggest,
        ...alreadyShown,
      }.toList();
      final forbidden = [...profile.allergies, ...profile.excludedIngredients];
      final hierarchy = await ingredientDao.hierarchy();
      final normalizer = await ingredientDao.createNormalizer();

      return aiService.suggestDishes(
        availableIngredients: availableNames,
        forbiddenIngredients: forbidden,
        doNotSuggest: mergedDoNotSuggest,
        likes: compressed.topLikedFeatures.map((e) => e.key).toList(),
        dislikes: compressed.topDislikedFeatures.map((e) => e.key).toList(),
        topRated: compressed.topRatedRecipeTitles,
        maxTotalMinutes: profile.maxTotalMinutes,
        bypassCache: true,
        profile: {
          'allergies': profile.allergies,
          'excluded_ingredients': profile.excludedIngredients,
        },
        ingredientHierarchy: hierarchy,
        resolveIngredientId: (name) => normalizer.resolve(name),
      );
    });
  }
}
