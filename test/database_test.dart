import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory(), seed: false);
  });

  tearDown(() async {
    await db.close();
  });

  group('Database tests (S0-05 / TZ 4.1)', () {
    test('schema version is 1', () {
      expect(db.schemaVersion, 1);
    });

    test(
      'all 10 tables exist and support insert/select with common fields',
      () async {
        // 1. ingredients
        final ingredientCompanion = IngredientsCompanion.insert(
          name: 'Курица',
          synonyms: const Value(['куриное филе', 'цыпленок']),
          category: 'мясо',
          isStaple: const Value(false),
        );
        final ingredient = await db
            .into(db.ingredients)
            .insertReturning(ingredientCompanion);
        expect(ingredient.id, isNotEmpty);
        expect(ingredient.createdAt, isPositive);
        expect(ingredient.updatedAt, isPositive);
        expect(ingredient.deletedAt, isNull);
        expect(ingredient.name, 'Курица');
        expect(ingredient.synonyms, ['куриное филе', 'цыпленок']);

        // 2. pantry_items
        final pantryCompanion = PantryItemsCompanion.insert(
          ingredientId: ingredient.id,
          isAvailable: const Value(true),
        );
        final pantryItem = await db
            .into(db.pantryItems)
            .insertReturning(pantryCompanion);
        expect(pantryItem.id, isNotEmpty);
        expect(pantryItem.ingredientId, ingredient.id);
        expect(pantryItem.isAvailable, isTrue);

        // 3. recipes
        final recipeCompanion = RecipesCompanion.insert(
          title: 'Куриный суп',
          normalizedTitle: 'куриный суп',
          dishType: DishType.soup,
          difficulty: Difficulty.easy,
          cuisine: 'русская',
          totalMinutes: 40,
          activeMinutes: 15,
          description: 'Вкусный домашний суп',
          source: RecipeSource.seed,
          fingerprint: 'soup:chicken',
        );
        final recipe = await db
            .into(db.recipes)
            .insertReturning(recipeCompanion);
        expect(recipe.id, isNotEmpty);
        expect(recipe.title, 'Куриный суп');
        expect(recipe.dishType, DishType.soup);
        expect(recipe.difficulty, Difficulty.easy);

        // 4. recipe_ingredients
        final recipeIngCompanion = RecipeIngredientsCompanion.insert(
          recipeId: recipe.id,
          ingredientId: ingredient.id,
          amount: const Value(300),
          unit: const Value('g'),
        );
        final recipeIng = await db
            .into(db.recipeIngredients)
            .insertReturning(recipeIngCompanion);
        expect(recipeIng.id, isNotEmpty);
        expect(recipeIng.recipeId, recipe.id);
        expect(recipeIng.amount, 300);

        // 5. recipe_steps
        final stepCompanion = RecipeStepsCompanion.insert(
          recipeId: recipe.id,
          position: 1,
          textContent: 'Сварить бульон.',
          timerSeconds: const Value(1200),
        );
        final step = await db
            .into(db.recipeSteps)
            .insertReturning(stepCompanion);
        expect(step.id, isNotEmpty);
        expect(step.timerSeconds, 1200);

        // 6. cooked_entries
        final cookedCompanion = CookedEntriesCompanion.insert(
          recipeId: recipe.id,
          cookedOn: '2026-11-04',
          rating: const Value(5),
          wouldRepeat: const Value(true),
        );
        final cooked = await db
            .into(db.cookedEntries)
            .insertReturning(cookedCompanion);
        expect(cooked.id, isNotEmpty);
        expect(cooked.rating, 5);

        // 7. meal_plan_entries
        final planCompanion = MealPlanEntriesCompanion.insert(
          date: '2026-11-05',
          recipeId: recipe.id,
        );
        final plan = await db
            .into(db.mealPlanEntries)
            .insertReturning(planCompanion);
        expect(plan.id, isNotEmpty);
        expect(plan.status, MealPlanStatus.planned);

        // 8. feedback_events
        final feedbackCompanion = FeedbackEventsCompanion.insert(
          recipeId: Value(recipe.id),
          kind: FeedbackKind.liked,
        );
        final feedback = await db
            .into(db.feedbackEvents)
            .insertReturning(feedbackCompanion);
        expect(feedback.id, isNotEmpty);
        expect(feedback.kind, FeedbackKind.liked);

        // 9. preference_profile
        final profileCompanion = PreferenceProfileCompanion.insert(
          dishTypeWeights: const Value({'soup': 0.8}),
          ingredientWeights: const Value({'chicken': 0.5}),
          excludedIngredients: const Value(['грибы']),
        );
        final profile = await db
            .into(db.preferenceProfile)
            .insertReturning(profileCompanion);
        expect(profile.id, isNotEmpty);
        expect(profile.dishTypeWeights, {'soup': 0.8});
        expect(profile.excludedIngredients, ['грибы']);

        // 10. ai_requests
        final aiCompanion = AiRequestsCompanion.insert(
          kind: 'suggest_dishes',
          promptHash: 'abc123hash',
          responseJson: '{}',
          model: 'lmstudio/qwen-7b',
          status: 'ok',
        );
        final aiReq = await db.into(db.aiRequests).insertReturning(aiCompanion);
        expect(aiReq.id, isNotEmpty);
        expect(aiReq.kind, 'suggest_dishes');
      },
    );

    test(
      'FTS5 virtual table operates and finds ingredients by search query',
      () async {
        await db
            .into(db.ingredientsFts)
            .insert(
              IngredientsFtsCompanion.insert(
                ingredientId: 'potato',
                name: 'картофель',
                synonyms: 'картошка, бульба',
              ),
            );

        final searchResults = await db.searchIngredientsFts('картошка').get();
        expect(searchResults, isNotEmpty);
        expect(searchResults.first.ingredientId, 'potato');
        expect(searchResults.first.name, 'картофель');
        expect(searchResults.first.synonyms, contains('картошка'));
      },
    );

    test('required indexes and unique constraints exist', () async {
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
          .get();
      final names = rows.map((row) => row.read<String>('name')).toSet();

      expect(
        names,
        containsAll([
          'idx_recipe_ingredients_recipe_id',
          'idx_recipe_ingredients_ingredient_id',
          'idx_recipe_steps_recipe_id',
          'idx_cooked_entries_cooked_on',
          'idx_pantry_items_ingredient_id',
          'idx_meal_plan_entries_date_slot',
        ]),
      );

      await db
          .into(db.pantryItems)
          .insert(PantryItemsCompanion.insert(ingredientId: 'potato'));
      await expectLater(
        db
            .into(db.pantryItems)
            .insert(PantryItemsCompanion.insert(ingredientId: 'potato')),
        throwsA(anything),
      );
    });
  });
}
