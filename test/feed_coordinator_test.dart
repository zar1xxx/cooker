import 'dart:async';

import 'package:chto_prigotovit/core/ai/ai_service.dart';
import 'package:chto_prigotovit/core/catalog/dish_group.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/matching/recipe_matcher.dart';
import 'package:chto_prigotovit/core/matching/recipe_scorer.dart';
import 'package:chto_prigotovit/features/suggestions/feed_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

ScoredRecipe _dummyScored(
  String id,
  String title, {
  RecipeSource source = RecipeSource.seed,
}) {
  final recipe = Recipe(
    id: id,
    title: title,
    normalizedTitle: title.toLowerCase().trim(),
    dishType: DishType.main,
    dishGroup: DishGroup.meat,
    difficulty: Difficulty.easy,
    cuisine: 'русская',
    totalMinutes: 30,
    activeMinutes: 15,
    servings: 2,
    description: '',
    source: source,
    fingerprint: 'main:$id',
    aiModel: null,
    isFavorite: false,
    createdAt: 0,
    updatedAt: 0,
  );
  final entry = RecipeWithIngredients(recipe: recipe, ingredients: const []);
  final match = RecipeMatch(
    entry: entry,
    coverage: 1.0,
    missingIds: const [],
    missingNames: const [],
  );
  return ScoredRecipe(
    match: match,
    scores: const ScoreBreakdown(
      coverage: 1.0,
      taste: 0.0,
      novelty: 0.0,
      fit: 0.0,
      explore: 0.0,
      total: 1.0,
    ),
  );
}

void main() {
  group('FeedCoordinator (R8-08)', () {
    test('1. First 3 cards are from catalog; AI slots appear at positions 4, 8, 12...', () async {
      final catalog = List.generate(
        20,
        (i) => _dummyScored('rec_$i', 'Блюдо $i'),
      );
      final coordinator = FeedCoordinator(
        allCatalogRecipes: catalog,
        isAiAvailable: true,
        fetchAiDishes: ({required alreadyShownTitles}) async => [
          const AiDishSuggestion(
            title: 'ИИ Блюдо',
            dishType: 'main',
            difficulty: 'easy',
            totalMinutes: 25,
            mainIngredients: ['картошка'],
            missing: [],
            why: 'Быстро',
            raw: {},
          ),
        ],
      );

      coordinator.initialize();

      // First 3 items must be from catalog
      expect(coordinator.items[0], isA<CatalogCardItem>());
      expect(coordinator.items[1], isA<CatalogCardItem>());
      expect(coordinator.items[2], isA<CatalogCardItem>());

      // Position 4 (0-based index 3) must be an AI card or placeholder
      expect(
        coordinator.items[3] is AiCardItem ||
            coordinator.items[3] is AiPlaceholderCardItem,
        isTrue,
      );

      // Positions 5, 6, 7 are catalog items
      expect(coordinator.items[4], isA<CatalogCardItem>());
      expect(coordinator.items[5], isA<CatalogCardItem>());
      expect(coordinator.items[6], isA<CatalogCardItem>());

      // Position 8 (0-based index 7) must be an AI card or placeholder
      expect(
        coordinator.items[7] is AiCardItem ||
            coordinator.items[7] is AiPlaceholderCardItem,
        isTrue,
      );
    });

    test('2. Trigger pagination loads next page when remaining <= 6', () async {
      final catalog = List.generate(
        25,
        (i) => _dummyScored('rec_$i', 'Блюдо $i'),
      );
      final coordinator = FeedCoordinator(
        allCatalogRecipes: catalog,
        isAiAvailable: true,
        fetchAiDishes: ({required alreadyShownTitles}) async => [],
      );

      coordinator.initialize();
      final initialCount = coordinator.items.length;

      // When remaining items > 6, no new page
      coordinator.onScrollNearEnd(10);
      expect(coordinator.items.length, equals(initialCount));

      // When remaining items <= 6, next page is loaded
      coordinator.onScrollNearEnd(5);
      expect(coordinator.items.length, greaterThan(initialCount));
    });

    test(
      '3. Concurrency limit: at most 1 active AI request at a time',
      () async {
        final completer = Completer<List<AiDishSuggestion>>();
        int callCount = 0;

        final catalog = List.generate(
          15,
          (i) => _dummyScored('rec_$i', 'Блюдо $i'),
        );
        final coordinator = FeedCoordinator(
          allCatalogRecipes: catalog,
          isAiAvailable: true,
          fetchAiDishes: ({required alreadyShownTitles}) async {
            callCount++;
            return completer.future;
          },
        );

        coordinator.initialize();

        // 1 AI slot requested, request is in flight
        expect(coordinator.isAiRequestInProgress, isTrue);
        expect(callCount, equals(1));

        // Trigger another page while request is pending
        coordinator.onScrollNearEnd(2);

        // Call count should still be 1 (never parallel)
        expect(callCount, equals(1));

        // Resolve the request
        completer.complete([]);
        await Future<void>.delayed(Duration.zero);
        expect(coordinator.isAiRequestInProgress, isFalse);
      },
    );

    test('4. On AI failure, placeholder card collapses smoothly without appearing as error', () async {
      final catalog = List.generate(
        10,
        (i) => _dummyScored('rec_$i', 'Блюдо $i'),
      );
      final coordinator = FeedCoordinator(
        allCatalogRecipes: catalog,
        isAiAvailable: true,
        fetchAiDishes: ({required alreadyShownTitles}) async {
          throw Exception('Network error');
        },
      );

      coordinator.initialize();
      await Future<void>.delayed(Duration.zero);

      // The placeholder should be removed, leaving only valid catalog cards
      expect(coordinator.items.whereType<AiPlaceholderCardItem>(), isEmpty);
      expect(coordinator.items.whereType<CatalogCardItem>().length, equals(9));
    });

    test('5. Duplicate with catalog is discarded', () async {
      final catalog = [
        _dummyScored('rec_1', 'Борщ домашний'),
        _dummyScored('rec_2', 'Щи кислые'),
        _dummyScored('rec_3', 'Гречневая каша'),
        _dummyScored('rec_4', 'Макароны по-флотски'),
      ];

      final coordinator = FeedCoordinator(
        allCatalogRecipes: catalog,
        isAiAvailable: true,
        existingCatalogTitles: {'борщ домашний'},
        fetchAiDishes: ({required alreadyShownTitles}) async => [
          const AiDishSuggestion(
            title: 'Борщ домашний', // Exact duplicate of catalog!
            dishType: 'soup',
            difficulty: 'medium',
            totalMinutes: 60,
            mainIngredients: ['свёкла', 'капуста'],
            missing: [],
            why: 'Любимый суп',
            raw: {},
          ),
        ],
      );

      coordinator.initialize();
      await Future<void>.delayed(Duration.zero);

      // Duplicate dish was rejected, placeholder collapsed
      expect(coordinator.items.whereType<AiCardItem>(), isEmpty);
      expect(coordinator.items.whereType<AiPlaceholderCardItem>(), isEmpty);
    });

    test('6. Offline mode: feed runs purely on catalog with 0 placeholders and 0 AI slots', () async {
      final catalog = List.generate(
        15,
        (i) => _dummyScored('rec_$i', 'Блюдо $i'),
      );
      bool aiCalled = false;

      final coordinator = FeedCoordinator(
        allCatalogRecipes: catalog,
        isAiAvailable: false,
        fetchAiDishes: ({required alreadyShownTitles}) async {
          aiCalled = true;
          return [];
        },
      );

      coordinator.initialize();

      // No placeholders, only catalog cards
      expect(coordinator.items.whereType<AiPlaceholderCardItem>(), isEmpty);
      expect(coordinator.items.whereType<AiCardItem>(), isEmpty);
      expect(coordinator.items.every((it) => it is CatalogCardItem), isTrue);
      expect(aiCalled, isFalse);
    });
  });
}
