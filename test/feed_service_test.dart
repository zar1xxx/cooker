import 'dart:io';

import 'package:chto_prigotovit/core/calendar/holiday_calculator.dart';
import 'package:chto_prigotovit/core/catalog/dish_group.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/feed_event_dao.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/db/daos/ingredient_dao.dart';
import 'package:chto_prigotovit/core/db/daos/pantry_dao.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/feed/day_context.dart';
import 'package:chto_prigotovit/core/feed/feed_ai_filler.dart';
import 'package:chto_prigotovit/core/feed/feed_service.dart';
import 'package:chto_prigotovit/core/feed/feed_settings.dart';
import 'package:chto_prigotovit/core/feed/taste_profile.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

HolidayCalculator _holidays() => HolidayCalculator.fromJsonString(
  File('assets/seed/holidays_ru.json').readAsStringSync(),
);

FeedService _service(
  AppDatabase db, {
  FeedAiFiller? filler,
  FeedSettings settings = const FeedSettings(),
}) {
  final preferences = PreferenceService(db);
  return FeedService(
    db: db,
    recipeDao: RecipeDao(db),
    ingredientDao: IngredientDao(db),
    pantryDao: PantryDao(db),
    historyDao: HistoryDao(db, preferenceService: preferences),
    feedEventDao: FeedEventDao(db),
    preferenceService: preferences,
    holidays: _holidays(),
    settings: settings,
    aiFiller: filler,
  );
}

Future<void> _insertRecipe(
  AppDatabase db,
  String id, {
  RecipeSource source = RecipeSource.seed,
}) {
  return db
      .into(db.recipes)
      .insert(
        RecipesCompanion.insert(
          id: Value(id),
          title: 'Блюдо $id',
          normalizedTitle: 'блюдо $id',
          dishType: DishType.soup,
          dishGroup: const Value(DishGroup.soup),
          difficulty: Difficulty.easy,
          cuisine: 'ru',
          totalMinutes: 30,
          activeMinutes: 10,
          description: 'Тестовое блюдо',
          source: source,
          fingerprint: id,
        ),
      );
}

class _AddingFiller implements FeedAiFiller {
  _AddingFiller(this.db);

  final AppDatabase db;
  int calls = 0;
  DayContext? lastContext;

  @override
  Future<int> fill({
    required DayContext context,
    required int count,
    required Set<String> forbiddenIds,
  }) async {
    calls++;
    lastContext = context;
    await _insertRecipe(db, 'ai_dish', source: RecipeSource.ai);
    return 1;
  }
}

class _ThrowingFiller implements FeedAiFiller {
  int calls = 0;

  @override
  Future<int> fill({
    required DayContext context,
    required int count,
    required Set<String> forbiddenIds,
  }) async {
    calls++;
    throw StateError('no network');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R7-06 FeedService on the real catalog', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory(), seed: true);
      await db.customSelect('SELECT 1').get();
    });

    tearDown(() async {
      await db.close();
    });

    test('works offline: five cards, each with a reason', () async {
      final filler = _ThrowingFiller();
      final snapshot = await _service(db, filler: filler).load();
      expect(snapshot.main, hasLength(FeedService.mainLimit));
      for (final item in snapshot.main) {
        expect(item.reason, isNotEmpty);
        expect(snapshot.recipes[item.candidate.id], isNotNull);
      }
      // The catalog is large enough: the assistant is not asked at all.
      expect(filler.calls, 0);
      expect(snapshot.groupCounts.values.fold<int>(0, (a, b) => a + b), 2039);
    });

    test('is deterministic for the same day', () async {
      final first = await _service(db).load();
      final second = await _service(db).load();
      expect(
        first.main.map((i) => i.candidate.id),
        second.main.map((i) => i.candidate.id),
      );
    });

    test('an allergen never appears, even in a full section', () async {
      await PreferenceService(db).setAllergies(['картофель']);
      final soups = await _service(db).load(const FeedQuery(groupId: 'soup'));
      expect(soups.main, isNotEmpty);
      for (final item in soups.main) {
        expect(item.candidate.ingredientIds, isNot(contains('potato')));
      }
    });

    test('«Не хочу такое» removes the dish from the feed', () async {
      final before = await _service(db).load();
      final skipped = before.main.first.candidate.id;
      await FeedEventDao(db).record(skipped, FeedEventKind.skipped);

      final after = await _service(db).load();
      expect(after.main.map((i) => i.candidate.id), isNot(contains(skipped)));
      final section = await _service(db)
          .load(FeedQuery(groupId: before.main.first.candidate.groupId));
      expect(section.main.map((i) => i.candidate.id), isNot(contains(skipped)));
    });

    test('a dish cooked recently is not repeated', () async {
      final before = await _service(db).load();
      final cooked = before.main.first.candidate.id;
      final preferences = PreferenceService(db);
      await HistoryDao(
        db,
        preferenceService: preferences,
      ).recordCooked(recipeId: cooked, rating: 5);

      final events = await FeedEventDao(db).all();
      expect(events.map((e) => e.event), containsAll(['cooked', 'rated']));

      final after = await _service(db).load();
      expect(after.main.map((i) => i.candidate.id), isNot(contains(cooked)));
    });

    test('a diet filter keeps only tagged dishes', () async {
      final section = await _service(db).load(
        const FeedQuery(groupId: 'soup', requiredTags: {'dietary:vegetarian'}),
      );
      for (final item in section.main) {
        expect(item.candidate.tags, contains('dietary:vegetarian'));
      }
    });
  });

  group('R7-06 assistant fills a short catalog', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory(), seed: false);
      await db.customSelect('SELECT 1').get();
      await _insertRecipe(db, 'one');
      await _insertRecipe(db, 'two');
    });

    tearDown(() async {
      await db.close();
    });

    test('adds assistant dishes and shows them in the feed', () async {
      final filler = _AddingFiller(db);
      final snapshot = await _service(db, filler: filler).load();
      expect(filler.calls, 1);
      expect(snapshot.aiAdded, 1);
      expect(snapshot.main.map((i) => i.candidate.id), contains('ai_dish'));
      expect(snapshot.recipes['ai_dish']!.source, RecipeSource.ai);
    });

    test('a failing assistant leaves the catalog feed on screen', () async {
      final filler = _ThrowingFiller();
      final snapshot = await _service(db, filler: filler).load();
      expect(filler.calls, 1);
      expect(snapshot.aiAdded, 0);
      expect(snapshot.main.map((i) => i.candidate.id).toSet(), {'one', 'two'});
    });

    test('sections never call the assistant', () async {
      final filler = _AddingFiller(db);
      await _service(db, filler: filler).load(const FeedQuery(groupId: 'soup'));
      expect(filler.calls, 0);
    });

    test('context hints carry only the occasion, cuisine and mood', () {
      final context = DayContext(
        now: DateTime(2026, 11, 10, 12),
        date: DateTime.utc(2026, 11, 10),
        weekday: DateTime.tuesday,
        dayPart: DayPart.day,
        season: Season.autumn,
        cuisine: 'it',
      );
      expect(AiServiceFeedFiller.contextHints(context), ['Итальянская кухня']);
    });
  });

  group('R7-02 / R7-10 FeedEventDao', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory(), seed: false);
      await db.customSelect('SELECT 1').get();
      await _insertRecipe(db, 'one');
    });

    tearDown(() async {
      await db.close();
    });

    test('records known recipes, ignores unknown ids, clears all', () async {
      final dao = FeedEventDao(db);
      expect(await dao.record('one', FeedEventKind.opened), isTrue);
      expect(await dao.record('one', FeedEventKind.rated, rating: 4), isTrue);
      expect(await dao.record('missing', FeedEventKind.skipped), isFalse);

      final events = await dao.all();
      expect(events.map(FeedEventDao.kindOf), [
        FeedEventKind.opened,
        FeedEventKind.rated,
      ]);
      expect(events.last.rating, 4);

      await dao.clear();
      expect(await dao.count(), 0);
    });
  });
}
