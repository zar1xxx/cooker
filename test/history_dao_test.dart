import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late HistoryDao dao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();
    dao = HistoryDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('HistoryDao (S2-04)', () {
    test('recordCooked creates cooked_entry and feedback_event', () async {
      final entry = await dao.recordCooked(
        recipeId: 'chicken_soup_potato',
        rating: 5,
        wouldRepeat: true,
        note: 'Очень вкусно получилось',
      );

      expect(entry.id, isNotEmpty);
      expect(entry.recipeId, 'chicken_soup_potato');
      expect(entry.rating, 5);
      expect(entry.wouldRepeat, isTrue);
      expect(entry.note, 'Очень вкусно получилось');

      // Check feedback_events table
      final feedbackList = await db.select(db.feedbackEvents).get();
      final feedback = feedbackList.firstWhere(
        (f) => f.recipeId == 'chicken_soup_potato',
      );
      expect(feedback.kind, FeedbackKind.cooked);
      expect(feedback.reason, 'rating: 5');

      // Check allWithRecipes
      final history = await dao.allWithRecipes();
      expect(history.length, 1);
      expect(history.first.entry.id, entry.id);
      expect(history.first.recipe?.title, 'Куриный суп с картошкой');
    });

    test('updateRating updates the rating in database', () async {
      final entry = await dao.recordCooked(
        recipeId: 'chicken_soup_potato',
        rating: 3,
      );

      await dao.updateRating(entry.id, 5);

      final history = await dao.allWithRecipes();
      expect(history.first.entry.rating, 5);
    });

    test('softDelete and restore', () async {
      final entry = await dao.recordCooked(
        recipeId: 'chicken_soup_potato',
        rating: 4,
      );

      expect((await dao.allWithRecipes()).length, 1);

      // Soft delete hides it from allWithRecipes
      await dao.softDelete(entry.id);
      expect((await dao.allWithRecipes()).length, 0);

      // Restore makes it visible again
      await dao.restore(entry.id);
      final restored = await dao.allWithRecipes();
      expect(restored.length, 1);
      expect(restored.first.entry.id, entry.id);
    });

    test(
      'addManualEntry creates recipe with source=user when not found',
      () async {
        final entry = await dao.addManualEntry(
          title: 'Бабушкины оладьи',
          dishType: DishType.baking,
          difficulty: Difficulty.easy,
          totalMinutes: 25,
          rating: 5,
          wouldRepeat: true,
          note: 'С пылу с жару',
        );

        expect(entry.id, isNotEmpty);
        expect(entry.rating, 5);
        expect(entry.wouldRepeat, isTrue);
        expect(entry.note, 'С пылу с жару');

        // Verify recipe in database has source=user
        final recipe = await (db.select(
          db.recipes,
        )..where((tbl) => tbl.id.equals(entry.recipeId))).getSingle();
        expect(recipe.title, 'Бабушкины оладьи');
        expect(recipe.source, RecipeSource.user);
        expect(recipe.dishType, DishType.baking);
        expect(recipe.totalMinutes, 25);

        // Check allWithRecipes
        final history = await dao.allWithRecipes();
        expect(history.first.recipe?.title, 'Бабушкины оладьи');
      },
    );

    test(
      'addManualEntry reuses existing recipe by title without duplicate',
      () async {
        // 'chicken_soup_potato' has title 'Куриный суп с картошкой'
        final entry = await dao.addManualEntry(
          title: 'Куриный суп с картошкой',
          rating: 5,
        );

        expect(entry.recipeId, 'chicken_soup_potato');

        // Check no new recipe was created
        final matchingRecipes =
            await (db.select(db.recipes)..where(
                  (tbl) =>
                      tbl.normalizedTitle.equals('куриный суп с картошкой'),
                ))
                .get();
        expect(matchingRecipes.length, 1);
      },
    );

    test('getMonthSummary calculates monthly metrics accurately', () async {
      final now = DateTime(2026, 11, 15);

      // Dish 1: seed recipe cooked in November (new dish for November)
      await dao.recordCooked(
        recipeId: 'chicken_soup_potato',
        rating: 5,
        date: DateTime(2026, 11, 2),
      );

      // Dish 2: user recipe cooked in November (rating 4)
      await dao.addManualEntry(
        title: 'Оладьи',
        dishType: DishType.baking,
        rating: 4,
        date: DateTime(2026, 11, 5),
      );

      // Dish 1 again in November (not a new dish, should not count twice in newDishes)
      await dao.recordCooked(
        recipeId: 'chicken_soup_potato',
        rating: 5,
        date: DateTime(2026, 11, 10),
      );

      // Dish 3 cooked in previous month (October)
      await dao.recordCooked(
        recipeId: 'mashed_potato',
        rating: 5,
        date: DateTime(2026, 10, 20),
      );

      // Dish 3 cooked again in November (was cooked in October, so not new in November)
      await dao.recordCooked(
        recipeId: 'mashed_potato',
        rating: 3,
        date: DateTime(2026, 11, 12),
      );

      final summary = await dao.getMonthSummary(month: now);
      expect(summary.totalCooked, 4); // 4 cooked entries in November
      expect(summary.newDishesCount, 2); // chicken_soup_potato and Оладьи
      expect(summary.topRatedRecipeTitle, 'Куриный суп с картошкой');
      expect(summary.topRating, 5.0);
    });
  });
}
