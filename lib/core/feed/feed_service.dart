import 'package:clock/clock.dart';

import '../calendar/holiday_calculator.dart';
import '../catalog/recipe_tags.dart';
import '../db/app_database.dart';
import '../db/daos/feed_event_dao.dart';
import '../db/daos/history_dao.dart';
import '../db/daos/ingredient_dao.dart';
import '../db/daos/pantry_dao.dart';
import '../db/daos/recipe_dao.dart';
import '../db/enums.dart';
import '../preferences/preference_service.dart' as prefs;
import '../shopping/missing_products.dart';
import 'day_context.dart';
import 'feed_ranker.dart';
import 'feed_settings.dart';
import 'taste_profile.dart';

/// What the user picked on the feed screen: mood, cuisine, section, diet.
class FeedQuery {
  const FeedQuery({
    this.mood,
    this.cuisine,
    this.groupId,
    this.requiredTags = const <String>{},
  });

  final MoodTag? mood;
  final String? cuisine;

  /// Dish group id (`soup`, `baking` ...) for the section screen.
  final String? groupId;

  /// Tags as `kind:tag`, for example `dietary:vegetarian`.
  final Set<String> requiredTags;

  String get _key {
    final tags = requiredTags.toList()..sort();
    return '${mood?.id}|$cuisine|$groupId|${tags.join(',')}';
  }

  @override
  bool operator ==(Object other) => other is FeedQuery && other._key == _key;

  @override
  int get hashCode => _key.hashCode;
}

/// Asks the assistant for dishes when the catalog has too few (R7-06).
///
/// Implementations save validated recipes with `source = ai` and return how
/// many were added. They must never throw: the feed works without them.
abstract class FeedAiFiller {
  Future<int> fill({
    required DayContext context,
    required int count,
    required Set<String> forbiddenIds,
  });
}

/// Everything the feed screen shows.
class FeedSnapshot {
  const FeedSnapshot({
    required this.context,
    required this.main,
    required this.occasion,
    required this.fromPantry,
    required this.toBuy,
    required this.recipes,
    required this.groupCounts,
    required this.cuisines,
    this.aiAdded = 0,
  });

  final DayContext context;

  /// «Может понравиться»: up to [FeedService.mainLimit] cards.
  final List<FeedItem> main;

  /// «К празднику»: empty when there is no occasion soon.
  final List<FeedItem> occasion;

  /// «Из того, что есть дома».
  final List<FeedItem> fromPantry;

  /// «Что докупить»: product name and in how many dishes it is missing.
  final List<MapEntry<String, int>> toBuy;

  final Map<String, Recipe> recipes;

  /// Number of dishes in each dish group id (for «Разделы»).
  final Map<String, int> groupCounts;

  /// Cuisine codes of the catalog, the most common first, without `home`.
  final List<String> cuisines;

  /// Dishes the assistant added during this load.
  final int aiAdded;
}

/// Builds the feed from the local catalog (R7-05, R7-06).
///
/// Works fully offline. The assistant is asked only when the catalog gives
/// fewer than [mainLimit] dishes, and its failure is silent.
class FeedService {
  FeedService({
    required this.db,
    required this.recipeDao,
    required this.ingredientDao,
    required this.pantryDao,
    required this.historyDao,
    required this.feedEventDao,
    required this.preferenceService,
    required this.holidays,
    this.settings = const FeedSettings(),
    this.aiFiller,
  });

  final AppDatabase db;
  final RecipeDao recipeDao;
  final IngredientDao ingredientDao;
  final PantryDao pantryDao;
  final HistoryDao historyDao;
  final FeedEventDao feedEventDao;
  final prefs.PreferenceService preferenceService;
  final HolidayCalculator holidays;
  final FeedSettings settings;
  final FeedAiFiller? aiFiller;

  static const int mainLimit = 5;
  static const int rowLimit = 5;
  static const int sectionLimit = 40;

  Future<FeedSnapshot> load([FeedQuery query = const FeedQuery()]) {
    return _load(query, allowAi: true);
  }

  Future<FeedSnapshot> _load(FeedQuery query, {required bool allowAi}) async {
    final now = clock.now();
    final data = await _CatalogData.read(this);

    final context = DayContext.build(
      now: now,
      calculator: settings.considerHolidays
          ? holidays
          : HolidayCalculator(const []),
      mood: query.mood,
      cuisine: query.cuisine,
      pantryIds: data.effectivePantry,
    );
    final filter = FeedFilter(
      allergenIds: data.forbiddenIds,
      lentenOnly: settings.considerFasts && context.isFastingDay,
      requiredTags: query.requiredTags,
    );
    final ranker = FeedRanker(explorationShare: settings.showNew ? 0.15 : 0.0);
    final profile = TasteProfile.fromEvents(data.tasteEvents, now: now);
    final seed =
        context.date.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

    final candidates = [
      for (final candidate in data.candidates)
        if (query.groupId == null || candidate.groupId == query.groupId)
          candidate,
    ];

    final main = ranker.rank(
      candidates: candidates,
      context: context,
      profile: profile,
      filter: filter,
      limit: query.groupId == null ? mainLimit : sectionLimit,
      seed: seed,
    );

    final filler = aiFiller;
    // The assistant only tops up the main feed, not sections or diet filters.
    final isMainFeed = query.groupId == null && query.requiredTags.isEmpty;
    if (allowAi && isMainFeed && filler != null && main.length < mainLimit) {
      var added = 0;
      try {
        added = await filler.fill(
          context: context,
          count: mainLimit - main.length,
          forbiddenIds: data.forbiddenIds,
        );
      } catch (_) {
        added = 0;
      }
      if (added > 0) {
        final reloaded = await _load(query, allowAi: false);
        return FeedSnapshot(
          context: reloaded.context,
          main: reloaded.main,
          occasion: reloaded.occasion,
          fromPantry: reloaded.fromPantry,
          toBuy: reloaded.toBuy,
          recipes: reloaded.recipes,
          groupCounts: reloaded.groupCounts,
          cuisines: reloaded.cuisines,
          aiAdded: added,
        );
      }
    }

    final wide = ranker.rank(
      candidates: candidates,
      context: context,
      profile: profile,
      filter: filter,
      limit: sectionLimit,
      seed: seed,
    );

    final occasion = context.featuredOccasion == null
        ? const <FeedItem>[]
        : [
            for (final item in wide)
              if ((item.components['occasion'] ?? 0) >= 0.99) item,
          ].take(rowLimit).toList();

    final fromPantry =
        [
          for (final item in wide)
            if ((item.components['pantry'] ?? 0) > 0.5) item,
        ]..sort((a, b) {
          final byPantry = (b.components['pantry'] ?? 0).compareTo(
            a.components['pantry'] ?? 0,
          );
          return byPantry != 0
              ? byPantry
              : a.candidate.id.compareTo(b.candidate.id);
        });

    final toBuyIds = mostMissing(
      recipeIngredients: {
        for (final item in wide.take(20))
          item.candidate.id: data.buyableIngredients[item.candidate.id] ?? {},
      },
      pantryIds: data.effectivePantry,
    );

    return FeedSnapshot(
      context: context,
      main: main,
      occasion: occasion,
      fromPantry: fromPantry.take(rowLimit).toList(),
      toBuy: [
        for (final entry in toBuyIds)
          MapEntry(data.ingredientNames[entry.key] ?? entry.key, entry.value),
      ],
      recipes: data.recipes,
      groupCounts: data.groupCounts,
      cuisines: data.cuisines,
    );
  }
}

/// Catalog, pantry, history and events read once per load.
class _CatalogData {
  _CatalogData({
    required this.candidates,
    required this.recipes,
    required this.tasteEvents,
    required this.effectivePantry,
    required this.forbiddenIds,
    required this.buyableIngredients,
    required this.ingredientNames,
    required this.groupCounts,
    required this.cuisines,
  });

  final List<FeedCandidate> candidates;
  final Map<String, Recipe> recipes;
  final List<TasteEvent> tasteEvents;
  final Set<String> effectivePantry;
  final Set<String> forbiddenIds;

  /// Recipe id → non-optional, non-staple ingredient ids.
  final Map<String, Set<String>> buyableIngredients;
  final Map<String, String> ingredientNames;
  final Map<String, int> groupCounts;
  final List<String> cuisines;

  static Future<_CatalogData> read(FeedService service) async {
    final pantry = await service.pantryDao.availableIds();
    final hierarchy = await service.ingredientDao.hierarchy();
    final ingredients = await service.ingredientDao.all();
    final normalizer = await service.ingredientDao.createNormalizer();
    final taste = await service.preferenceService.getProfile();
    final recipes = await service.recipeDao.allWithIngredients();
    final tagRows = await service.db.select(service.db.recipeTags).get();
    final events = await service.feedEventDao.all();
    final cooked = await service.historyDao.allWithRecipes();
    final disliked = await service.historyDao.getDislikedRecipeIds();

    final staples = {
      for (final ingredient in ingredients)
        if (ingredient.isStaple) ingredient.id,
    };
    final names = {
      for (final ingredient in ingredients) ingredient.id: ingredient.name,
    };

    // A product at home covers its parents too (chicken fillet → chicken).
    final effectivePantry = <String>{...pantry, ...staples};
    for (final id in pantry) {
      effectivePantry.addAll(hierarchy[id] ?? const <String>[]);
    }

    // Allergies and «не ем», expanded to child products.
    final forbidden = <String>{};
    for (final term in [...taste.allergies, ...taste.excludedIngredients]) {
      final text = term.toLowerCase().trim();
      if (text.isEmpty) continue;
      final id = normalizer.resolve(text);
      if (id == null) continue;
      forbidden
        ..add(id)
        ..addAll(normalizer.descendantsOf(id));
    }

    final tagsByRecipe = <String, Set<String>>{};
    for (final row in tagRows) {
      tagsByRecipe
          .putIfAbsent(row.recipeId, () => <String>{})
          .add('${row.tagKind.id}:${row.tag}');
    }

    final lastCooked = <String, DateTime>{};
    void markCooked(String recipeId, DateTime at) {
      final previous = lastCooked[recipeId];
      if (previous == null || at.isAfter(previous)) lastCooked[recipeId] = at;
    }

    for (final row in cooked) {
      final day = DateTime.tryParse(row.entry.cookedOn);
      if (day != null) markCooked(row.entry.recipeId, day);
    }
    final lastSkipped = <String, DateTime>{};
    for (final event in events) {
      final at = DateTime.fromMillisecondsSinceEpoch(
        event.at,
        isUtc: true,
      ).toLocal();
      final kind = FeedEventDao.kindOf(event);
      if (kind == FeedEventKind.cooked) markCooked(event.recipeId, at);
      if (kind == FeedEventKind.skipped) {
        final previous = lastSkipped[event.recipeId];
        if (previous == null || at.isAfter(previous)) {
          lastSkipped[event.recipeId] = at;
        }
      }
    }

    final candidates = <FeedCandidate>[];
    final recipeById = <String, Recipe>{};
    final buyable = <String, Set<String>>{};
    final groupCounts = <String, int>{};
    final cuisineCounts = <String, int>{};
    final attributes = <String, _Attributes>{};

    for (final entry in recipes) {
      final recipe = entry.recipe;
      recipeById[recipe.id] = recipe;
      final allIds = {
        for (final line in entry.ingredients)
          line.recipeIngredient.ingredientId,
      };
      buyable[recipe.id] = {
        for (final line in entry.ingredients)
          if (!line.recipeIngredient.isOptional &&
              !staples.contains(line.recipeIngredient.ingredientId))
            line.recipeIngredient.ingredientId,
      };
      final groupId = recipe.dishGroup.id;
      final tags = tagsByRecipe[recipe.id] ?? const <String>{};
      attributes[recipe.id] = _Attributes(
        groupId: groupId,
        cuisine: recipe.cuisine,
        tags: tags,
        ingredientIds: allIds,
      );
      groupCounts.update(groupId, (value) => value + 1, ifAbsent: () => 1);
      if (recipe.cuisine != 'home') {
        cuisineCounts.update(
          recipe.cuisine,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
      if (disliked.contains(recipe.id)) continue;
      candidates.add(
        FeedCandidate(
          id: recipe.id,
          title: recipe.title,
          groupId: groupId,
          cuisine: recipe.cuisine,
          totalMinutes: recipe.totalMinutes,
          tags: tags,
          ingredientIds: allIds,
          popularity: recipe.isFavorite
              ? 0.9
              : (recipe.quality == 'template' ? 0.35 : 0.6),
          lastCookedAt: lastCooked[recipe.id],
          lastSkippedAt: lastSkipped[recipe.id],
        ),
      );
    }

    final tasteEvents = <TasteEvent>[];
    for (final event in events) {
      final kind = FeedEventDao.kindOf(event);
      final attrs = attributes[event.recipeId];
      if (kind == null || attrs == null) continue;
      tasteEvents.add(
        TasteEvent(
          kind: kind,
          rating: event.rating,
          at: DateTime.fromMillisecondsSinceEpoch(
            event.at,
            isUtc: true,
          ).toLocal(),
          groupId: attrs.groupId,
          cuisine: attrs.cuisine,
          tags: attrs.tags,
          ingredientIds: attrs.ingredientIds,
        ),
      );
    }

    final cuisines = cuisineCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });

    return _CatalogData(
      candidates: candidates,
      recipes: recipeById,
      tasteEvents: tasteEvents,
      effectivePantry: effectivePantry,
      forbiddenIds: forbidden,
      buyableIngredients: buyable,
      ingredientNames: names,
      groupCounts: groupCounts,
      cuisines: [for (final entry in cuisines.take(8)) entry.key],
    );
  }
}

class _Attributes {
  const _Attributes({
    required this.groupId,
    required this.cuisine,
    required this.tags,
    required this.ingredientIds,
  });

  final String groupId;
  final String cuisine;
  final Set<String> tags;
  final Set<String> ingredientIds;
}

/// Kept for callers that want to know whether a recipe came from the
/// assistant without importing the enum file.
bool isAiRecipe(Recipe recipe) => recipe.source == RecipeSource.ai;
