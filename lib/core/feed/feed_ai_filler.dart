import '../ai/ai_failure.dart';
import '../ai/ai_service.dart';
import '../catalog/cuisine.dart';
import '../db/daos/ingredient_dao.dart';
import 'day_context.dart';
import 'feed_service.dart';

/// R7-06: fills the feed with assistant dishes when the catalog runs short.
///
/// Only product names and context hints (occasion, cuisine, mood) leave the
/// phone; no events or names of people. Every dish goes through
/// [AiService.fullRecipe], which runs `RecipeValidator`, and is cached in the
/// database with `source = ai`. Any failure returns 0 and the feed is shown
/// from the catalog.
class AiServiceFeedFiller implements FeedAiFiller {
  AiServiceFeedFiller({required this.aiService, required this.ingredientDao});

  final AiService aiService;
  final IngredientDao ingredientDao;

  /// Context hints for the `likes` field of the suggest prompt.
  static List<String> contextHints(DayContext context) {
    final occasion = context.featuredOccasion;
    return [
      if (occasion != null) '${occasion.name}: ${occasion.hint}',
      if (context.cuisine != null)
        '${Cuisine.titleForCode(context.cuisine!)} кухня',
      if (context.mood != null) context.mood!.titleRu,
      if (context.isFastingDay) 'постное',
    ];
  }

  @override
  Future<int> fill({
    required DayContext context,
    required int count,
    required Set<String> forbiddenIds,
  }) async {
    if (count <= 0) return 0;
    try {
      final pantry = await ingredientDao.byIds(context.pantryIds);
      final forbidden = await ingredientDao.byIds(forbiddenIds);
      final available = [for (final item in pantry) item.name];
      final forbiddenNames = [for (final item in forbidden) item.name];

      final suggestions = await aiService.suggestDishes(
        availableIngredients: available,
        forbiddenIngredients: forbiddenNames,
        likes: contextHints(context),
        count: count,
      );
      final dishes = suggestions.dataOrNull;
      if (dishes == null) return 0;

      var added = 0;
      for (final dish in dishes.take(count)) {
        final full = await aiService.fullRecipe(
          title: dish.title,
          dishType: dish.dishType,
          difficulty: dish.difficulty,
          mainIngredients: dish.mainIngredients,
          availableIngredients: available,
          forbiddenIngredients: forbiddenNames,
        );
        if (full is! AiSuccess<Map<String, dynamic>>) continue;
        final saved = await aiService.saveAiRecipeToDatabase(full.data);
        if (saved != null) added++;
      }
      return added;
    } catch (_) {
      return 0;
    }
  }
}
