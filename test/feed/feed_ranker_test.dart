import 'dart:io';

import 'package:chto_prigotovit/core/calendar/holiday_calculator.dart';
import 'package:chto_prigotovit/core/catalog/recipe_tags.dart';
import 'package:chto_prigotovit/core/feed/day_context.dart';
import 'package:chto_prigotovit/core/feed/feed_ranker.dart';
import 'package:chto_prigotovit/core/feed/taste_profile.dart';
import 'package:flutter_test/flutter_test.dart';

final _calculator = HolidayCalculator.fromJsonString(
  File('assets/seed/holidays_ru.json').readAsStringSync(),
);

// An ordinary summer weekday without any occasion.
final _now = DateTime(2026, 7, 15, 12);

DayContext _context({
  DateTime? now,
  MoodTag? mood,
  String? cuisine,
  Set<String> pantry = const {},
}) {
  return DayContext.build(
    now: now ?? _now,
    calculator: _calculator,
    mood: mood,
    cuisine: cuisine,
    pantryIds: pantry,
  );
}

FeedCandidate _candidate(
  String id, {
  String title = 'Блюдо',
  String group = 'meat',
  String cuisine = 'ru',
  int minutes = 30,
  Set<String> tags = const {},
  Set<String> ingredients = const {},
  double popularity = 0.5,
  int? cookedDaysAgo,
  int? skippedDaysAgo,
}) {
  return FeedCandidate(
    id: id,
    title: title,
    groupId: group,
    cuisine: cuisine,
    totalMinutes: minutes,
    tags: tags,
    ingredientIds: ingredients,
    popularity: popularity,
    lastCookedAt: cookedDaysAgo == null
        ? null
        : _now.subtract(Duration(days: cookedDaysAgo)),
    lastSkippedAt: skippedDaysAgo == null
        ? null
        : _now.subtract(Duration(days: skippedDaysAgo)),
  );
}

TasteProfile _lovesGroup(String group, {int events = 12}) {
  return TasteProfile.fromEvents([
    for (var i = 0; i < events; i++)
      TasteEvent(
        kind: FeedEventKind.cooked,
        at: _now.subtract(Duration(days: i)),
        groupId: group,
        cuisine: 'ru',
      ),
  ], now: _now);
}

List<String> _ids(List<FeedItem> items) => [
  for (final item in items) item.candidate.id,
];

void main() {
  const ranker = FeedRanker();

  test('default weights sum to one', () {
    expect(const FeedWeights().sum, closeTo(1, 1e-9));
  });

  group('hard filter', () {
    test('an allergen never gets into the feed', () {
      final candidates = [
        for (var i = 0; i < 30; i++)
          _candidate(
            'r$i',
            ingredients: i.isEven ? {'peanut', 'flour'} : {'flour'},
            popularity: i.isEven ? 1 : 0.1,
          ),
      ];
      final feed = ranker.rank(
        candidates: candidates,
        context: _context(),
        profile: TasteProfile.empty,
        filter: const FeedFilter(allergenIds: {'peanut'}),
        limit: 30,
      );
      expect(feed, isNotEmpty);
      for (final item in feed) {
        expect(item.candidate.ingredientIds, isNot(contains('peanut')));
      }
      expect(feed.length, 15);
    });

    test('disliked ingredients are removed too', () {
      final feed = ranker.rank(
        candidates: [
          _candidate('a', ingredients: {'liver'}),
          _candidate('b', ingredients: {'rice'}),
        ],
        context: _context(),
        profile: TasteProfile.empty,
        filter: const FeedFilter(dislikedIds: {'liver'}),
      );
      expect(_ids(feed), ['b']);
    });

    test('cooked and skipped dishes stay out of the repeat window', () {
      final feed = ranker.rank(
        candidates: [
          _candidate('cooked_recently', cookedDaysAgo: 3),
          _candidate('cooked_long_ago', cookedDaysAgo: 20),
          _candidate('skipped_recently', skippedDaysAgo: 3),
          _candidate('skipped_long_ago', skippedDaysAgo: 10),
          _candidate('new'),
        ],
        context: _context(),
        profile: TasteProfile.empty,
      );
      expect(_ids(feed).toSet(), {
        'cooked_long_ago',
        'skipped_long_ago',
        'new',
      });
    });

    test('lenten only keeps lenten dishes', () {
      final feed = ranker.rank(
        candidates: [
          _candidate('lean', tags: {'dietary:lenten'}),
          _candidate('meat'),
        ],
        context: _context(),
        profile: TasteProfile.empty,
        filter: const FeedFilter(lentenOnly: true),
      );
      expect(_ids(feed), ['lean']);
    });

    test('required tags work as a section filter', () {
      final candidates = [
        for (var i = 0; i < 20; i++)
          _candidate('r$i', tags: i < 5 ? {'dietary:vegetarian'} : <String>{}),
      ];
      final feed = ranker.rank(
        candidates: candidates,
        context: _context(),
        profile: TasteProfile.empty,
        filter: const FeedFilter(requiredTags: {'dietary:vegetarian'}),
        limit: 20,
      );
      expect(feed.length, 5);
    });
  });

  group('determinism and shape', () {
    final candidates = [
      for (var i = 0; i < 60; i++)
        _candidate(
          'r${i.toString().padLeft(2, '0')}',
          group: ['meat', 'soup', 'dessert', 'salad_snack'][i % 4],
          cuisine: ['ru', 'it', 'ge'][i % 3],
          popularity: (i % 10) / 10,
        ),
    ];

    test('same input and seed give the same feed', () {
      final profile = _lovesGroup('soup');
      final a = ranker.rank(
        candidates: candidates,
        context: _context(),
        profile: profile,
        limit: 20,
        seed: 7,
      );
      final b = ranker.rank(
        candidates: candidates.reversed.toList(),
        context: _context(),
        profile: profile,
        limit: 20,
        seed: 7,
      );
      expect(_ids(a), _ids(b));
    });

    test('items are unique and limited', () {
      final feed = ranker.rank(
        candidates: candidates,
        context: _context(),
        profile: _lovesGroup('soup'),
        limit: 20,
      );
      expect(feed.length, 20);
      expect(_ids(feed).toSet().length, 20);
    });

    test('fewer candidates than the limit give a shorter feed', () {
      final feed = ranker.rank(
        candidates: candidates.take(3).toList(),
        context: _context(),
        profile: TasteProfile.empty,
        limit: 20,
      );
      expect(feed.length, 3);
    });

    test('no candidates give an empty feed', () {
      final feed = ranker.rank(
        candidates: const [],
        context: _context(),
        profile: TasteProfile.empty,
      );
      expect(feed, isEmpty);
    });
  });

  group('diversity', () {
    test('no more than two dishes of one group in a row', () {
      final candidates = [
        for (var i = 0; i < 12; i++)
          _candidate('soup$i', group: 'soup', cuisine: 'ru', popularity: 0.95),
        for (var i = 0; i < 4; i++) ...[
          _candidate('meat$i', group: 'meat', cuisine: 'it'),
          _candidate('dessert$i', group: 'dessert', cuisine: 'fr'),
          _candidate('salad$i', group: 'salad_snack', cuisine: 'ge'),
        ],
      ];
      final feed = ranker.rank(
        candidates: candidates,
        context: _context(),
        profile: TasteProfile.empty,
        limit: 10,
      );
      final groups = [for (final item in feed) item.candidate.groupId];
      expect(groups.length, 10);
      for (var i = 2; i < groups.length; i++) {
        final run = groups[i] == groups[i - 1] && groups[i] == groups[i - 2];
        expect(run, isFalse, reason: 'run at $i in $groups');
      }
    });
  });

  group('cold start', () {
    test('popularity decides while the profile is empty', () {
      final feed = ranker.rank(
        candidates: [
          _candidate('rare', popularity: 0.1, group: 'soup'),
          _candidate('popular', popularity: 0.9, group: 'dessert'),
        ],
        context: _context(),
        profile: TasteProfile.empty,
      );
      expect(feed.first.candidate.id, 'popular');
    });

    test('a cold start feed is not empty and has no exploration', () {
      final feed = ranker.rank(
        candidates: [
          for (var i = 0; i < 30; i++) _candidate('r$i', popularity: i / 30),
        ],
        context: _context(),
        profile: TasteProfile.empty,
        limit: 20,
      );
      expect(feed.length, 20);
      expect(feed.any((item) => item.isExploration), isFalse);
    });
  });

  group('context signals', () {
    test('the chosen mood lifts matching dishes', () {
      final feed = ranker.rank(
        candidates: [
          _candidate('plain', group: 'soup'),
          _candidate('cozy', group: 'meat', tags: {'mood:cozy'}),
        ],
        context: _context(mood: MoodTag.cozy),
        profile: TasteProfile.empty,
      );
      expect(feed.first.candidate.id, 'cozy');
      expect(feed.first.reason, startsWith('Под настроение'));
    });

    test('the chosen cuisine lifts matching dishes', () {
      final feed = ranker.rank(
        candidates: [
          _candidate('ru', cuisine: 'ru', group: 'soup'),
          _candidate('it', cuisine: 'it', group: 'meat'),
        ],
        context: _context(cuisine: 'it'),
        profile: TasteProfile.empty,
      );
      expect(feed.first.candidate.id, 'it');
      expect(feed.first.reason, 'Итальянская кухня');
    });

    test('products at home lift dishes that need nothing more', () {
      final feed = ranker.rank(
        candidates: [
          _candidate('missing', group: 'soup', ingredients: {'c', 'd'}),
          _candidate('ready', group: 'meat', ingredients: {'a', 'b'}),
        ],
        context: _context(pantry: {'a', 'b'}),
        profile: TasteProfile.empty,
      );
      expect(feed.first.candidate.id, 'ready');
      expect(feed.first.reason, 'Всё есть дома');
    });

    test('a pancake dish is first on Maslenitsa and says why', () {
      final feed = ranker.rank(
        candidates: [
          _candidate('borscht', title: 'Борщ', group: 'soup'),
          _candidate('pancakes', title: 'Блины с творогом', group: 'baking'),
        ],
        context: _context(now: DateTime(2026, 2, 18, 12)),
        profile: TasteProfile.empty,
      );
      expect(feed.first.candidate.id, 'pancakes');
      expect(feed.first.reason, startsWith('Сегодня:'));
      expect(feed.first.reason, contains('Масленица'));
    });

    test('before a holiday the reason says it is coming', () {
      final feed = ranker.rank(
        candidates: [
          _candidate('salad', title: 'Оливье', group: 'salad_snack'),
          _candidate('soup', title: 'Борщ', group: 'soup'),
        ],
        context: _context(now: DateTime(2026, 12, 29, 12)),
        profile: TasteProfile.empty,
      );
      expect(feed.first.candidate.id, 'salad');
      expect(feed.first.reason, startsWith('Скоро:'));
    });

    test('a dish not cooked for a long time is lifted by freshness', () {
      final feed = ranker.rank(
        candidates: [
          _candidate('recent', group: 'soup', cookedDaysAgo: 15),
          _candidate('never', group: 'meat'),
        ],
        context: _context(),
        profile: TasteProfile.empty,
      );
      expect(feed.first.candidate.id, 'never');
    });
  });

  group('exploration', () {
    test('about 15 percent of places go to unfamiliar dishes', () {
      final candidates = [
        for (var i = 0; i < 30; i++)
          _candidate('soup$i', group: 'soup', cuisine: 'ru'),
        for (var i = 0; i < 10; i++)
          _candidate('dessert$i', group: 'dessert', cuisine: 'fr'),
      ];
      final feed = ranker.rank(
        candidates: candidates,
        context: _context(),
        profile: _lovesGroup('soup'),
        limit: 20,
      );
      final explored = feed.where((item) => item.isExploration).toList();
      expect(feed.length, 20);
      expect(explored.length, 3);
      for (final item in explored) {
        expect(item.candidate.groupId, 'dessert');
        expect(item.reason, 'Попробуйте новое');
      }
    });

    test('exploration stays the same for the same seed', () {
      final candidates = [
        for (var i = 0; i < 30; i++)
          _candidate('soup$i', group: 'soup', cuisine: 'ru'),
        for (var i = 0; i < 10; i++)
          _candidate('dessert$i', group: 'dessert', cuisine: 'fr'),
      ];
      List<String> run(int seed) => _ids(
        ranker.rank(
          candidates: candidates,
          context: _context(),
          profile: _lovesGroup('soup'),
          limit: 20,
          seed: seed,
        ),
      );
      expect(run(1), run(1));
    });
  });

  group('synthetic users', () {
    List<FeedCandidate> catalog() => [
      for (var i = 0; i < 10; i++) ...[
        _candidate('meat$i', group: 'meat'),
        _candidate('dessert$i', group: 'dessert'),
        _candidate('salad$i', group: 'salad_snack'),
        _candidate('soup$i', group: 'soup'),
      ],
    ];

    int count(List<FeedItem> feed, String group, int first) => feed
        .take(first)
        .where((item) => item.candidate.groupId == group)
        .length;

    test('a meat eater sees meat first and most often', () {
      final feed = ranker.rank(
        candidates: catalog(),
        context: _context(),
        profile: _lovesGroup('meat'),
        limit: 10,
      );
      expect(feed.first.candidate.groupId, 'meat');
      expect(count(feed, 'meat', 6), greaterThanOrEqualTo(2));
      expect(count(feed, 'meat', 6), greaterThan(count(feed, 'soup', 6)));
    });

    test('a sweet tooth sees desserts first and most often', () {
      final feed = ranker.rank(
        candidates: catalog(),
        context: _context(),
        profile: _lovesGroup('dessert'),
        limit: 10,
      );
      expect(feed.first.candidate.groupId, 'dessert');
      expect(count(feed, 'dessert', 6), greaterThanOrEqualTo(2));
    });

    test('a vegetarian with a tag filter only sees vegetarian dishes', () {
      final candidates = [
        for (var i = 0; i < 20; i++)
          _candidate(
            'r$i',
            group: i.isEven ? 'soup' : 'meat',
            tags: i.isEven ? {'dietary:vegetarian'} : <String>{},
          ),
      ];
      final feed = ranker.rank(
        candidates: candidates,
        context: _context(),
        profile: _lovesGroup('meat'),
        filter: const FeedFilter(requiredTags: {'dietary:vegetarian'}),
        limit: 20,
      );
      expect(feed, isNotEmpty);
      expect(
        feed.every(
          (item) => item.candidate.tags.contains('dietary:vegetarian'),
        ),
        isTrue,
      );
    });

    test('rejected dishes lose to liked ones', () {
      final profile = TasteProfile.fromEvents([
        for (var i = 0; i < 12; i++)
          TasteEvent(
            kind: FeedEventKind.skipped,
            at: _now.subtract(Duration(days: i)),
            groupId: 'dessert',
            cuisine: 'ru',
          ),
        for (var i = 0; i < 12; i++)
          TasteEvent(
            kind: FeedEventKind.cooked,
            at: _now.subtract(Duration(days: i)),
            groupId: 'soup',
            cuisine: 'ru',
          ),
      ], now: _now);
      final feed = ranker.rank(
        candidates: catalog(),
        context: _context(),
        profile: profile,
        limit: 10,
      );
      expect(feed.first.candidate.groupId, 'soup');
      final desserts = count(feed, 'dessert', 10);
      expect(desserts, lessThanOrEqualTo(count(feed, 'meat', 10)));
      expect(desserts, lessThanOrEqualTo(count(feed, 'salad_snack', 10)));
      expect(desserts, lessThan(count(feed, 'soup', 10)));
    });
  });
}
