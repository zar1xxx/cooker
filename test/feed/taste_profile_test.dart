import 'package:chto_prigotovit/core/feed/taste_profile.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 11, 10, 12);

TasteEvent _event(
  FeedEventKind kind, {
  String group = 'soup',
  String cuisine = 'ru',
  int? rating,
  int daysAgo = 0,
  Set<String> tags = const {},
  Set<String> ingredients = const {},
}) {
  return TasteEvent(
    kind: kind,
    rating: rating,
    at: _now.subtract(Duration(days: daysAgo)),
    groupId: group,
    cuisine: cuisine,
    tags: tags,
    ingredientIds: ingredients,
  );
}

void main() {
  group('event weights', () {
    test('cooked, ratings, skipped, opened and shown', () {
      expect(_event(FeedEventKind.cooked).baseWeight, 1);
      expect(_event(FeedEventKind.skipped).baseWeight, -1);
      expect(_event(FeedEventKind.opened).baseWeight, 0.2);
      expect(_event(FeedEventKind.shown).baseWeight, 0);
      expect(_event(FeedEventKind.rated, rating: 5).baseWeight, 1.5);
      expect(_event(FeedEventKind.rated, rating: 4).baseWeight, 1);
      expect(_event(FeedEventKind.rated, rating: 3).baseWeight, 0);
      expect(_event(FeedEventKind.rated, rating: 2).baseWeight, -1);
      expect(_event(FeedEventKind.rated, rating: 1).baseWeight, -1);
    });
  });

  group('profile from events', () {
    test('an empty profile is neutral and cold', () {
      const profile = TasteProfile.empty;
      expect(profile.isColdStart, isTrue);
      expect(profile.affinity(groupId: 'soup', cuisine: 'ru'), 0);
    });

    test('cooked dishes raise and skipped dishes lower the affinity', () {
      final profile = TasteProfile.fromEvents([
        _event(FeedEventKind.cooked, group: 'soup'),
        _event(FeedEventKind.cooked, group: 'soup'),
        _event(FeedEventKind.skipped, group: 'dessert', cuisine: 'fr'),
      ], now: _now);

      expect(profile.affinity(groupId: 'soup', cuisine: 'ru'), greaterThan(0));
      expect(profile.affinity(groupId: 'dessert', cuisine: 'fr'), lessThan(0));
      expect(profile.affinity(groupId: 'meat', cuisine: 'it'), 0);
    });

    test('shown events and rating 3 carry no signal', () {
      final profile = TasteProfile.fromEvents([
        _event(FeedEventKind.shown),
        _event(FeedEventKind.rated, rating: 3),
      ], now: _now);
      expect(profile.signalCount, 0);
      expect(profile.groupWeights, isEmpty);
    });

    test('half of the weight is left after the half-life', () {
      final fresh = TasteProfile.fromEvents([
        _event(FeedEventKind.cooked),
      ], now: _now);
      final old = TasteProfile.fromEvents([
        _event(FeedEventKind.cooked, daysAgo: 60),
      ], now: _now);
      expect(fresh.groupWeights['soup'], closeTo(1, 1e-9));
      expect(old.groupWeights['soup'], closeTo(0.5, 1e-3));
    });

    test('a recent dislike outweighs an old like', () {
      final profile = TasteProfile.fromEvents([
        _event(FeedEventKind.cooked, daysAgo: 240),
        _event(FeedEventKind.skipped),
      ], now: _now);
      expect(profile.groupWeights['soup'], lessThan(0));
    });

    test('events from the future are ignored', () {
      final profile = TasteProfile.fromEvents([
        _event(FeedEventKind.cooked, daysAgo: -3),
      ], now: _now);
      expect(profile.signalCount, 0);
    });

    test('tags and ingredients take part in the affinity', () {
      final profile = TasteProfile.fromEvents([
        _event(
          FeedEventKind.cooked,
          group: 'meat',
          tags: {'dietary:high_protein'},
          ingredients: {'beef'},
        ),
      ], now: _now);

      final liked = profile.affinity(
        groupId: 'fish_seafood',
        cuisine: 'it',
        tags: {'dietary:high_protein'},
        ingredientIds: {'beef'},
      );
      final unrelated = profile.affinity(
        groupId: 'fish_seafood',
        cuisine: 'it',
        tags: {'dietary:vegan'},
        ingredientIds: {'carrot'},
      );
      expect(liked, greaterThan(unrelated));
      expect(unrelated, 0);
    });

    test('affinity stays within -1 and 1 for extreme histories', () {
      final profile = TasteProfile.fromEvents([
        for (var i = 0; i < 200; i++)
          _event(
            FeedEventKind.cooked,
            tags: {'dietary:vegan'},
            ingredients: {'carrot'},
          ),
      ], now: _now);
      final value = profile.affinity(
        groupId: 'soup',
        cuisine: 'ru',
        tags: {'dietary:vegan'},
        ingredientIds: {'carrot'},
      );
      expect(value, lessThanOrEqualTo(1));
      expect(value, greaterThan(0.8));
    });
  });

  group('cold start', () {
    test('ten meaningful events end the cold start', () {
      final nine = TasteProfile.fromEvents([
        for (var i = 0; i < 9; i++) _event(FeedEventKind.cooked),
      ], now: _now);
      final ten = TasteProfile.fromEvents([
        for (var i = 0; i < 10; i++) _event(FeedEventKind.cooked),
      ], now: _now);
      expect(nine.isColdStart, isTrue);
      expect(ten.isColdStart, isFalse);
    });

    test('knows reports whether the profile has an opinion', () {
      final profile = TasteProfile.fromEvents([
        _event(FeedEventKind.cooked),
      ], now: _now);
      expect(profile.knows(groupId: 'soup', cuisine: 'it'), isTrue);
      expect(profile.knows(groupId: 'meat', cuisine: 'ru'), isTrue);
      expect(profile.knows(groupId: 'meat', cuisine: 'it'), isFalse);
    });
  });
}
