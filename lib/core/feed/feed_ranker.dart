import 'dart:math' as math;

import '../calendar/holiday_calculator.dart';
import '../catalog/cuisine.dart';
import '../catalog/dish_group.dart';
import '../catalog/recipe_tags.dart';
import 'day_context.dart';
import 'taste_profile.dart';

/// A recipe as the ranker sees it: plain values, no database types.
class FeedCandidate {
  const FeedCandidate({
    required this.id,
    required this.title,
    required this.groupId,
    required this.cuisine,
    required this.totalMinutes,
    this.tags = const <String>{},
    this.ingredientIds = const <String>{},
    this.popularity = 0.5,
    this.lastCookedAt,
    this.lastSkippedAt,
  });

  final String id;
  final String title;

  /// Dish group id, for example `soup`.
  final String groupId;

  /// Cuisine code, for example `it`.
  final String cuisine;

  final int totalMinutes;

  /// Tags as `kind:tag`, for example `dietary:lenten`.
  final Set<String> tags;

  final Set<String> ingredientIds;

  /// General popularity 0..1, used while the user's own taste is unknown.
  final double popularity;

  final DateTime? lastCookedAt;
  final DateTime? lastSkippedAt;
}

/// Weights of the score components. The defaults sum to 1.
class FeedWeights {
  const FeedWeights({
    this.taste = 0.30,
    this.occasion = 0.15,
    this.mood = 0.10,
    this.cuisine = 0.08,
    this.pantry = 0.17,
    this.season = 0.05,
    this.freshness = 0.08,
    this.time = 0.07,
  });

  final double taste;
  final double occasion;
  final double mood;
  final double cuisine;
  final double pantry;
  final double season;
  final double freshness;
  final double time;

  double get sum =>
      taste + occasion + mood + cuisine + pantry + season + freshness + time;
}

/// Hard rules applied before any scoring.
///
/// The caller expands [allergenIds] and [dislikedIds] through the ingredient
/// hierarchy (a child product of an allergen is an allergen too).
class FeedFilter {
  const FeedFilter({
    this.allergenIds = const <String>{},
    this.dislikedIds = const <String>{},
    this.lentenOnly = false,
    this.requiredTags = const <String>{},
    this.cookedWindowDays = 14,
    this.skippedWindowDays = 7,
  });

  final Set<String> allergenIds;
  final Set<String> dislikedIds;
  final bool lentenOnly;
  final Set<String> requiredTags;
  final int cookedWindowDays;
  final int skippedWindowDays;

  bool allows(FeedCandidate candidate, {required DateTime now}) {
    for (final id in candidate.ingredientIds) {
      if (allergenIds.contains(id) || dislikedIds.contains(id)) return false;
    }
    if (lentenOnly && !candidate.tags.contains('dietary:lenten')) return false;
    if (!candidate.tags.containsAll(requiredTags)) return false;
    final cooked = candidate.lastCookedAt;
    if (cooked != null && now.difference(cooked).inDays < cookedWindowDays) {
      return false;
    }
    final skipped = candidate.lastSkippedAt;
    if (skipped != null && now.difference(skipped).inDays < skippedWindowDays) {
      return false;
    }
    return true;
  }
}

/// One card of the feed with its explanation.
class FeedItem {
  const FeedItem({
    required this.candidate,
    required this.score,
    required this.reason,
    required this.isExploration,
    required this.components,
  });

  final FeedCandidate candidate;

  /// Weighted score in 0..1.
  final double score;

  /// One short phrase for the card, built from a template.
  final String reason;

  /// A dish outside the learned profile ("Try something new").
  final bool isExploration;

  /// Component values 0..1 by name, for tests and diagnostics.
  final Map<String, double> components;
}

/// Local, deterministic feed ranking: filter, score, diversify, explore.
class FeedRanker {
  const FeedRanker({
    this.weights = const FeedWeights(),
    this.explorationShare = 0.15,
    this.maxSameGroupInRow = 2,
    this.mmrLambda = 0.7,
  });

  final FeedWeights weights;

  /// Share of places given to dishes outside the profile.
  final double explorationShare;

  /// At most this many dishes of one group in a row (while others exist).
  final int maxSameGroupInRow;

  /// 1 means pure score, lower values push harder for variety.
  final double mmrLambda;

  /// Builds a feed of up to [limit] items. The same input and [seed] always
  /// give the same result.
  List<FeedItem> rank({
    required List<FeedCandidate> candidates,
    required DayContext context,
    required TasteProfile profile,
    FeedFilter filter = const FeedFilter(),
    int limit = 10,
    int seed = 0,
  }) {
    final eligible = [
      for (final candidate in candidates)
        if (filter.allows(candidate, now: context.now)) candidate,
    ]..sort((a, b) => a.id.compareTo(b.id));

    final scored = [
      for (final candidate in eligible) _score(candidate, context, profile),
    ]..sort(_byScoreThenId);

    final random = math.Random(seed);
    final exploration = _pickExploration(scored, profile, limit, random);
    final explorationIds = {for (final item in exploration) item.candidate.id};
    final pool = [
      for (final item in scored)
        if (!explorationIds.contains(item.candidate.id)) item,
    ];

    final mainCount = math.min(limit - exploration.length, pool.length);
    final main = _diversify(pool, mainCount);
    return _interleave(main, exploration);
  }

  _Scored _score(
    FeedCandidate candidate,
    DayContext context,
    TasteProfile profile,
  ) {
    final affinity = profile.affinity(
      groupId: candidate.groupId,
      cuisine: candidate.cuisine,
      tags: candidate.tags,
      ingredientIds: candidate.ingredientIds,
    );
    final learned = (affinity + 1) / 2;
    final taste = profile.isColdStart
        ? 0.5 * learned + 0.5 * candidate.popularity.clamp(0.0, 1.0)
        : learned;

    final components = <String, double>{
      'taste': taste,
      'occasion': _occasionScore(candidate, context.featuredOccasion),
      'mood': _moodScore(candidate, context.mood),
      'cuisine': _cuisineScore(candidate, context.cuisine),
      'pantry': _pantryScore(candidate, context.pantryIds),
      'season': _seasonScore(candidate, context.season),
      'freshness': _freshnessScore(candidate, context.now),
      'time': _timeScore(candidate, context),
    };
    final weighted = <String, double>{
      'taste': weights.taste,
      'occasion': weights.occasion,
      'mood': weights.mood,
      'cuisine': weights.cuisine,
      'pantry': weights.pantry,
      'season': weights.season,
      'freshness': weights.freshness,
      'time': weights.time,
    };

    var total = 0.0;
    String? topName;
    var topGain = 0.0;
    components.forEach((name, value) {
      final weight = weighted[name] ?? 0;
      total += weight * value;
      final gain = weight * (value - 0.5);
      if (gain > topGain) {
        topGain = gain;
        topName = name;
      }
    });

    return _Scored(
      candidate: candidate,
      score: total,
      components: components,
      reason: _reason(topName, topGain, candidate, context, profile),
    );
  }

  double _occasionScore(FeedCandidate candidate, Occasion? occasion) {
    if (occasion == null) return 0.5;
    final title = candidate.title.toLowerCase();
    final keywords = _occasionKeywords[occasion.code] ?? const <String>[];
    for (final keyword in keywords) {
      if (title.contains(keyword)) return 1;
    }
    final tags = candidate.tags;
    if (occasion.type == OccasionType.holiday ||
        occasion.type == OccasionType.feast) {
      if (tags.contains('occasion:festive') ||
          tags.contains('occasion:for_guests')) {
        return 0.8;
      }
    }
    if (_picnicOccasions.contains(occasion.code) &&
        tags.contains('occasion:picnic')) {
      return 0.8;
    }
    return 0.3;
  }

  double _moodScore(FeedCandidate candidate, MoodTag? mood) {
    if (mood == null) return 0.5;
    return candidate.tags.contains('mood:${mood.id}') ? 1 : 0;
  }

  double _cuisineScore(FeedCandidate candidate, String? cuisine) {
    if (cuisine == null) return 0.5;
    return candidate.cuisine == cuisine ? 1 : 0;
  }

  double _pantryScore(FeedCandidate candidate, Set<String> pantry) {
    if (pantry.isEmpty || candidate.ingredientIds.isEmpty) return 0.5;
    final have = candidate.ingredientIds.where(pantry.contains).length;
    return have / candidate.ingredientIds.length;
  }

  double _seasonScore(FeedCandidate candidate, Season season) {
    final tags = candidate.tags;
    switch (season) {
      case Season.winter:
      case Season.autumn:
        if (candidate.groupId == 'soup' ||
            tags.contains('mood:cozy') ||
            tags.contains('mood:hearty')) {
          return 1;
        }
        return 0.5;
      case Season.summer:
      case Season.spring:
        if (candidate.groupId == 'salad_snack' ||
            candidate.groupId == 'beverage' ||
            tags.contains('mood:light')) {
          return 1;
        }
        return 0.5;
    }
  }

  double _freshnessScore(FeedCandidate candidate, DateTime now) {
    final cooked = candidate.lastCookedAt;
    if (cooked == null) return 1;
    return (now.difference(cooked).inDays / 60).clamp(0.0, 1.0).toDouble();
  }

  double _timeScore(FeedCandidate candidate, DayContext context) {
    if (context.isWeekend) return 0.7;
    final minutes = candidate.totalMinutes;
    if (minutes <= 30) return 1;
    if (minutes <= 60) return 0.7;
    if (minutes <= 90) return 0.4;
    return 0.2;
  }

  String _reason(
    String? top,
    double gain,
    FeedCandidate candidate,
    DayContext context,
    TasteProfile profile,
  ) {
    if (top == null || gain < 0.01) return 'Хороший вариант на сегодня';
    switch (top) {
      case 'occasion':
        final occasion = context.featuredOccasion;
        if (occasion == null) return 'Хороший вариант на сегодня';
        final days = context.daysToFeaturedOccasion ?? 0;
        return days == 0
            ? 'Сегодня: ${occasion.name}'
            : 'Скоро: ${occasion.name}';
      case 'mood':
        final mood = context.mood;
        return mood == null
            ? 'Под настроение'
            : 'Под настроение: ${mood.titleRu.toLowerCase()}';
      case 'cuisine':
        return '${Cuisine.titleForCode(candidate.cuisine)} кухня';
      case 'pantry':
        final have = candidate.ingredientIds
            .where(context.pantryIds.contains)
            .length;
        return have == candidate.ingredientIds.length
            ? 'Всё есть дома'
            : 'Почти всё есть дома';
      case 'season':
        return 'Подходит по сезону';
      case 'freshness':
        return 'Давно не готовили';
      case 'time':
        return 'Быстро: ${candidate.totalMinutes} мин';
      default:
        final group = DishGroup.tryFromId(candidate.groupId);
        if (group != null && (profile.groupWeights[group.id] ?? 0) > 0) {
          return 'Вы любите: ${group.titleRu.toLowerCase()}';
        }
        return 'Похоже на то, что вам нравится';
    }
  }

  List<_Scored> _pickExploration(
    List<_Scored> scored,
    TasteProfile profile,
    int limit,
    math.Random random,
  ) {
    if (profile.isColdStart) return const <_Scored>[];
    final wanted = (limit * explorationShare).floor();
    if (wanted == 0) return const <_Scored>[];

    final unknown = [
      for (final item in scored)
        if (!profile.knows(
          groupId: item.candidate.groupId,
          cuisine: item.candidate.cuisine,
        ))
          item,
    ];
    if (unknown.isEmpty) return const <_Scored>[];

    // Good dishes only: sample from the better third of unfamiliar ones.
    final pool = unknown.take(math.max(wanted * 3, 3)).toList()
      ..shuffle(random);
    return pool.take(wanted).map((item) => item.asExploration()).toList();
  }

  List<_Scored> _diversify(List<_Scored> pool, int count) {
    final remaining = pool.take(math.max(count * 10, 100)).toList();
    final selected = <_Scored>[];
    while (selected.length < count && remaining.isNotEmpty) {
      _Scored? best;
      var bestValue = double.negativeInfinity;
      for (final item in remaining) {
        if (_breaksRun(selected, item)) continue;
        var maxSimilarity = 0.0;
        for (final other in selected) {
          final similarity = _similarity(other.candidate, item.candidate);
          if (similarity > maxSimilarity) maxSimilarity = similarity;
        }
        final value = mmrLambda * item.score - (1 - mmrLambda) * maxSimilarity;
        if (value > bestValue) {
          bestValue = value;
          best = item;
        }
      }
      // Every remaining dish would extend a run: relax the rule.
      final chosen = best ?? remaining.first;
      selected.add(chosen);
      remaining.remove(chosen);
    }
    return selected;
  }

  bool _breaksRun(List<_Scored> selected, _Scored item) {
    if (selected.length < maxSameGroupInRow) return false;
    final tail = selected.sublist(selected.length - maxSameGroupInRow);
    return tail.every(
      (chosen) => chosen.candidate.groupId == item.candidate.groupId,
    );
  }

  double _similarity(FeedCandidate a, FeedCandidate b) {
    var value = 0.0;
    if (a.groupId == b.groupId) value += 0.6;
    if (a.cuisine == b.cuisine) value += 0.4;
    return value;
  }

  List<FeedItem> _interleave(List<_Scored> main, List<_Scored> exploration) {
    final result = <FeedItem>[for (final item in main) item.toItem()];
    if (exploration.isEmpty) return result;
    final step = math.max(2, (main.length + 1) ~/ (exploration.length + 1));
    var position = step;
    for (final item in exploration) {
      result.insert(math.min(position, result.length), item.toItem());
      position += step + 1;
    }
    return result;
  }

  static int _byScoreThenId(_Scored a, _Scored b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0 ? byScore : a.candidate.id.compareTo(b.candidate.id);
  }

  /// Title keywords per occasion code (lower case, partial words).
  static const Map<String, List<String>> _occasionKeywords =
      <String, List<String>>{
        'maslenitsa': ['блин', 'оладь', 'сырник'],
        'easter': ['кулич', 'пасх', 'яйц'],
        'bright_week': ['кулич', 'пасх', 'яйц'],
        'new_year': ['оливье', 'холодец', 'мандарин', 'шуб', 'заливн'],
        'christmas': ['гус', 'утк', 'кутья'],
        'defender_day': ['стейк', 'шашлык', 'отбивн'],
        'womens_day': ['торт', 'пирожн', 'десерт'],
        'victory_day': ['гречнев', 'каша', 'тушён'],
        'apple_spas': ['яблок', 'шарлотк'],
        'trinity': ['пирог', 'каравай'],
      };

  static const Set<String> _picnicOccasions = {
    'labour_day',
    'victory_day',
    'russia_day',
  };
}

class _Scored {
  const _Scored({
    required this.candidate,
    required this.score,
    required this.components,
    required this.reason,
    this.isExploration = false,
  });

  final FeedCandidate candidate;
  final double score;
  final Map<String, double> components;
  final String reason;
  final bool isExploration;

  _Scored asExploration() => _Scored(
    candidate: candidate,
    score: score,
    components: components,
    reason: 'Попробуйте новое',
    isExploration: true,
  );

  FeedItem toItem() => FeedItem(
    candidate: candidate,
    score: score,
    reason: reason,
    isExploration: isExploration,
    components: components,
  );
}
