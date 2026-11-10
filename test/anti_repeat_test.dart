import 'package:chto_prigotovit/core/ai/anti_repeat.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
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

  group('AntiRepeat.calculateFingerprint (TZ 6.3)', () {
    test('formats dish_type with up to 4 sorted normalized ingredient IDs', () {
      final fp1 = AntiRepeat.calculateFingerprint(
        dishType: 'Soup',
        ingredientIds: ['Potato', 'Carrot', 'Onion', 'Chicken', 'Salt'],
      );
      expect(fp1, equals('soup:carrot,chicken,onion,potato'));

      final fp2 = AntiRepeat.calculateFingerprint(
        dishType: 'main',
        ingredientIds: ['pork', 'potato'],
      );
      expect(fp2, equals('main:pork,potato'));
    });
  });

  group('AntiRepeat.jaccardSimilarity (TZ 6.3)', () {
    test('identical sets have similarity 1.0', () {
      final sim = AntiRepeat.jaccardSimilarity(
        ['potato', 'onion', 'carrot'],
        ['potato', 'onion', 'carrot'],
      );
      expect(sim, equals(1.0));
    });

    test('disjoint sets have similarity 0.0', () {
      final sim = AntiRepeat.jaccardSimilarity(
        ['apple', 'banana'],
        ['potato', 'onion'],
      );
      expect(sim, equals(0.0));
    });

    test('4 out of 5 overlapping ingredients has Jaccard 0.8', () {
      final setA = ['potato', 'onion', 'carrot', 'chicken']; // 4
      final setB = ['potato', 'onion', 'carrot', 'chicken', 'dill']; // 5
      // Intersection = 4, Union = 5 -> 4/5 = 0.8
      final sim = AntiRepeat.jaccardSimilarity(setA, setB);
      expect(sim, equals(0.8));
    });
  });

  group('AntiRepeat.findDuplicate (TZ 6.3)', () {
    test('matches duplicate by exact normalized title', () async {
      await db
          .into(db.recipes)
          .insert(
            const RecipesCompanion(
              id: Value('recipe_1'),
              title: Value('Борщ домашний'),
              normalizedTitle: Value('борщ домашний'),
              dishType: Value(DishType.soup),
              difficulty: Value(Difficulty.medium),
              cuisine: Value('русская'),
              totalMinutes: Value(60),
              activeMinutes: Value(30),
              servings: Value(4),
              description: Value('Вкусный борщ.'),
              source: Value(RecipeSource.seed),
              fingerprint: Value('soup:beet,beef,cabbage,potato'),
            ),
          );

      final dup = await AntiRepeat.findDuplicate(
        db,
        title: '  БОРЩ ДОМАШНИЙ  ',
        dishType: 'soup',
        ingredientIds: ['beet', 'beef'],
      );

      expect(dup, isNotNull);
      expect(dup!.id, equals('recipe_1'));
    });

    test(
      'matches duplicate by Jaccard similarity >= 0.8 with same dish_type',
      () async {
        await db
            .into(db.recipes)
            .insert(
              const RecipesCompanion(
                id: Value('recipe_soup'),
                title: Value('Куриный суп с овощами'),
                normalizedTitle: Value('куриный суп с овощами'),
                dishType: Value(DishType.soup),
                difficulty: Value(Difficulty.easy),
                cuisine: Value('домашняя'),
                totalMinutes: Value(40),
                activeMinutes: Value(20),
                servings: Value(4),
                description: Value('Легкий суп.'),
                source: Value(RecipeSource.seed),
                fingerprint: Value('soup:carrot,chicken,onion,potato'),
              ),
            );

        // Recipe ingredients: potato, onion, carrot, chicken (4 items)
        for (final ing in ['potato', 'onion', 'carrot', 'chicken']) {
          await db
              .into(db.recipeIngredients)
              .insert(
                RecipeIngredientsCompanion(
                  id: Value('ing_$ing'),
                  recipeId: const Value('recipe_soup'),
                  ingredientId: Value(ing),
                ),
              );
        }

        // New dish with ingredients: potato, onion, carrot, chicken, dill (Jaccard = 4/5 = 0.8)
        final dup = await AntiRepeat.findDuplicate(
          db,
          title: 'Домашний супчик с курочкой', // different title
          dishType: 'soup',
          ingredientIds: ['potato', 'onion', 'carrot', 'chicken', 'dill'],
        );

        expect(dup, isNotNull);
        expect(dup!.id, equals('recipe_soup'));
      },
    );

    test('does not match duplicate if dish_type differs even with identical ingredients', () async {
      await db
          .into(db.recipes)
          .insert(
            const RecipesCompanion(
              id: Value('recipe_main'),
              title: Value('Жаркое с курицей'),
              normalizedTitle: Value('жаркое с курицей'),
              dishType: Value(DishType.main),
              difficulty: Value(Difficulty.easy),
              cuisine: Value('домашняя'),
              totalMinutes: Value(40),
              activeMinutes: Value(20),
              servings: Value(4),
              description: Value('Второе блюдо.'),
              source: Value(RecipeSource.seed),
              fingerprint: Value('main:carrot,chicken,onion,potato'),
            ),
          );

      for (final ing in ['potato', 'onion', 'carrot', 'chicken']) {
        await db
            .into(db.recipeIngredients)
            .insert(
              RecipeIngredientsCompanion(
                id: Value('ing_main_$ing'),
                recipeId: const Value('recipe_main'),
                ingredientId: Value(ing),
              ),
            );
      }

      // Different dishType: soup vs main
      final dup = await AntiRepeat.findDuplicate(
        db,
        title: 'Суп с курицей',
        dishType: 'soup',
        ingredientIds: ['potato', 'onion', 'carrot', 'chicken'],
      );

      expect(dup, isNull);
    });
  });

  group('AntiRepeat.getDoNotSuggestList (TZ 6.3)', () {
    test('aggregates cooked within 14d, low rated, and rejected suggestions within 7d', () async {
      final now = DateTime.utc(2026, 11, 4, 12, 0);

      // Recipe 1: cooked 3 days ago (within 14d)
      await db
          .into(db.recipes)
          .insert(
            const RecipesCompanion(
              id: Value('r1'),
              title: Value('Борщ'),
              normalizedTitle: Value('борщ'),
              dishType: Value(DishType.soup),
              difficulty: Value(Difficulty.medium),
              cuisine: Value('русская'),
              totalMinutes: Value(50),
              activeMinutes: Value(25),
              description: Value(''),
              source: Value(RecipeSource.seed),
              fingerprint: Value('soup:beef,beet'),
            ),
          );
      await db
          .into(db.cookedEntries)
          .insert(
            CookedEntriesCompanion(
              id: const Value('c1'),
              recipeId: const Value('r1'),
              cookedOn: const Value('2026-11-01'),
              rating: const Value(5),
              createdAt: Value(
                now.subtract(const Duration(days: 3)).millisecondsSinceEpoch,
              ),
            ),
          );

      // Recipe 2: low rating (2 stars) cooked 20 days ago
      await db
          .into(db.recipes)
          .insert(
            const RecipesCompanion(
              id: Value('r2'),
              title: Value('Манная каша'),
              normalizedTitle: Value('манная каша'),
              dishType: Value(DishType.breakfast),
              difficulty: Value(Difficulty.easy),
              cuisine: Value('русская'),
              totalMinutes: Value(15),
              activeMinutes: Value(10),
              description: Value(''),
              source: Value(RecipeSource.seed),
              fingerprint: Value('breakfast:milk,semolina'),
            ),
          );
      await db
          .into(db.cookedEntries)
          .insert(
            CookedEntriesCompanion(
              id: const Value('c2'),
              recipeId: const Value('r2'),
              cookedOn: const Value('2026-10-15'),
              rating: const Value(2), // low rated
              createdAt: Value(
                now.subtract(const Duration(days: 20)).millisecondsSinceEpoch,
              ),
            ),
          );

      // Recipe 3: rejected suggestion 2 days ago (within 7d)
      await db
          .into(db.recipes)
          .insert(
            const RecipesCompanion(
              id: Value('r3'),
              title: Value('Рыбный пирог'),
              normalizedTitle: Value('рыбный пирог'),
              dishType: Value(DishType.baking),
              difficulty: Value(Difficulty.hard),
              cuisine: Value('русская'),
              totalMinutes: Value(90),
              activeMinutes: Value(45),
              description: Value(''),
              source: Value(RecipeSource.seed),
              fingerprint: Value('baking:fish,flour'),
            ),
          );
      await db
          .into(db.feedbackEvents)
          .insert(
            FeedbackEventsCompanion(
              id: const Value('f1'),
              recipeId: const Value('r3'),
              kind: const Value(FeedbackKind.rejected_suggestion),
              createdAt: Value(
                now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
              ),
            ),
          );

      final list = await AntiRepeat.getDoNotSuggestList(db, now: now);

      expect(list, contains('Борщ'));
      expect(list, contains('Манная каша'));
      expect(list, contains('Рыбный пирог'));
    });
  });

  group('AntiRepeat caching (TZ 6.3)', () {
    test('caches suggestions and retrieves on same calendar day', () async {
      final now = DateTime.utc(2026, 11, 4, 10, 0);
      const jsonResponse =
          '{"dishes":[{"title":"Оладьи","dish_type":"breakfast","difficulty":"easy","total_minutes":20,"main_ingredients":["мука","молоко"],"missing":[],"why":"Быстро"}]}';

      await AntiRepeat.cacheSuggestions(
        db,
        availableIngredientIds: ['flour', 'milk'],
        dishTypeFilter: 'breakfast',
        responseJson: jsonResponse,
        model: 'test-model',
        now: now,
      );

      final cached = await AntiRepeat.getCachedSuggestions(
        db,
        availableIngredientIds: ['flour', 'milk'],
        dishTypeFilter: 'breakfast',
        now: now,
      );

      expect(cached, isNotNull);
      expect(cached!.length, equals(1));
      expect(cached.first.title, equals('Оладьи'));
    });

    test('returns null for different day or missing cache', () async {
      final day1 = DateTime.utc(2026, 11, 4, 10, 0);
      final day2 = DateTime.utc(2026, 11, 5, 10, 0);

      await AntiRepeat.cacheSuggestions(
        db,
        availableIngredientIds: ['flour'],
        responseJson: '{"dishes":[]}',
        model: 'test-model',
        now: day1,
      );

      final cachedDay2 = await AntiRepeat.getCachedSuggestions(
        db,
        availableIngredientIds: ['flour'],
        now: day2,
      );

      expect(cachedDay2, isNull);
    });

    test('R8-07: distinguishes cache entries by contextTag on the same day', () async {
      final now = DateTime.utc(2026, 11, 4, 10, 0);
      const jsonContextA =
          '{"dishes":[{"title":"Быстрый омлет","dish_type":"breakfast","difficulty":"easy","total_minutes":10,"main_ingredients":["яйца"],"missing":[],"why":"Быстро"}]}';

      await AntiRepeat.cacheSuggestions(
        db,
        availableIngredientIds: ['eggs'],
        contextTag: 'fast:likes_eggs',
        responseJson: jsonContextA,
        model: 'test-model',
        now: now,
      );

      final match = await AntiRepeat.getCachedSuggestions(
        db,
        availableIngredientIds: ['eggs'],
        contextTag: 'fast:likes_eggs',
        now: now,
      );
      expect(match, isNotNull);
      expect(match!.first.title, equals('Быстрый омлет'));

      final differentContext = await AntiRepeat.getCachedSuggestions(
        db,
        availableIngredientIds: ['eggs'],
        contextTag: 'slow:baking',
        now: now,
      );
      expect(differentContext, isNull);
    });
  });
}
