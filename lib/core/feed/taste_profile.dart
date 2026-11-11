import 'dart:math' as math;

/// Kind of a user interaction with a dish in the feed.
enum FeedEventKind { shown, opened, cooked, skipped, rated }

/// One feed interaction joined with the attributes of its recipe.
///
/// The profile is built from these plain values, so it has no dependency on
/// the database and can be tested with literals.
class TasteEvent {
  const TasteEvent({
    required this.kind,
    required this.at,
    required this.groupId,
    required this.cuisine,
    this.rating,
    this.tags = const <String>{},
    this.ingredientIds = const <String>{},
  });

  final FeedEventKind kind;

  /// Rating 1..5 for [FeedEventKind.rated], otherwise null.
  final int? rating;

  final DateTime at;

  /// Dish group id, for example `soup`.
  final String groupId;

  /// Cuisine code, for example `ru`.
  final String cuisine;

  /// Tags as `kind:tag`, for example `dietary:vegan`.
  final Set<String> tags;

  final Set<String> ingredientIds;

  /// Signed strength of the event before time decay.
  ///
  /// cooked +1, rating 4 +1, rating 5 +1.5, rating 1-2 -1, skipped -1,
  /// opened +0.2; shown and rating 3 carry no signal.
  double get baseWeight {
    switch (kind) {
      case FeedEventKind.cooked:
        return 1;
      case FeedEventKind.skipped:
        return -1;
      case FeedEventKind.opened:
        return 0.2;
      case FeedEventKind.shown:
        return 0;
      case FeedEventKind.rated:
        final value = rating ?? 3;
        if (value >= 5) return 1.5;
        if (value == 4) return 1;
        if (value <= 2) return -1;
        return 0;
    }
  }
}

/// Learned taste of the user: weights by dish group, cuisine, tag and key
/// ingredient, with exponential decay so that taste can change.
class TasteProfile {
  const TasteProfile._({
    required this.groupWeights,
    required this.cuisineWeights,
    required this.tagWeights,
    required this.ingredientWeights,
    required this.signalCount,
  });

  /// A profile without any history.
  static const TasteProfile empty = TasteProfile._(
    groupWeights: <String, double>{},
    cuisineWeights: <String, double>{},
    tagWeights: <String, double>{},
    ingredientWeights: <String, double>{},
    signalCount: 0,
  );

  /// Fewer meaningful events than this means a cold start.
  static const int coldStartThreshold = 10;

  /// Ingredients count less than groups and cuisines: a recipe has many.
  static const double ingredientFactor = 0.5;

  /// Builds the profile from [events] as of [now].
  ///
  /// Events from the future are ignored. [halfLifeDays] is the age at which
  /// an event counts half as much.
  factory TasteProfile.fromEvents(
    Iterable<TasteEvent> events, {
    required DateTime now,
    double halfLifeDays = 60,
  }) {
    final groups = <String, double>{};
    final cuisines = <String, double>{};
    final tags = <String, double>{};
    final ingredients = <String, double>{};
    var signals = 0;

    for (final event in events) {
      final base = event.baseWeight;
      if (base == 0) continue;
      final ageDays = now.difference(event.at).inMinutes / (60 * 24);
      if (ageDays < 0) continue;
      final decay = math.pow(0.5, ageDays / halfLifeDays).toDouble();
      final weight = base * decay;
      signals++;

      groups.update(
        event.groupId,
        (value) => value + weight,
        ifAbsent: () => weight,
      );
      cuisines.update(
        event.cuisine,
        (value) => value + weight,
        ifAbsent: () => weight,
      );
      for (final tag in event.tags) {
        tags.update(tag, (value) => value + weight, ifAbsent: () => weight);
      }
      for (final id in event.ingredientIds) {
        final part = weight * ingredientFactor;
        ingredients.update(id, (value) => value + part, ifAbsent: () => part);
      }
    }

    return TasteProfile._(
      groupWeights: Map.unmodifiable(groups),
      cuisineWeights: Map.unmodifiable(cuisines),
      tagWeights: Map.unmodifiable(tags),
      ingredientWeights: Map.unmodifiable(ingredients),
      signalCount: signals,
    );
  }

  final Map<String, double> groupWeights;
  final Map<String, double> cuisineWeights;
  final Map<String, double> tagWeights;
  final Map<String, double> ingredientWeights;

  /// Number of events that carried a signal.
  final int signalCount;

  bool get isColdStart => signalCount < coldStartThreshold;

  /// Whether the profile has any opinion about the group or the cuisine.
  bool knows({required String groupId, required String cuisine}) {
    return (groupWeights[groupId] ?? 0) != 0 ||
        (cuisineWeights[cuisine] ?? 0) != 0;
  }

  /// Affinity in [-1, 1]: negative means the user tends to reject such dishes.
  ///
  /// Group 35%, cuisine 25%, ingredients 25%, tags 15%. Every part is squashed
  /// with x / (1 + |x|), so one strong event cannot dominate.
  double affinity({
    required String groupId,
    required String cuisine,
    Set<String> tags = const <String>{},
    Set<String> ingredientIds = const <String>{},
  }) {
    final group = _squash(groupWeights[groupId] ?? 0);
    final cuisineScore = _squash(cuisineWeights[cuisine] ?? 0);
    final tagScore = _meanSquashed(tagWeights, tags);
    final ingredientScore = _meanSquashed(ingredientWeights, ingredientIds);
    return 0.35 * group +
        0.25 * cuisineScore +
        0.25 * ingredientScore +
        0.15 * tagScore;
  }

  static double _squash(double x) => x / (1 + x.abs());

  static double _meanSquashed(Map<String, double> weights, Set<String> keys) {
    var sum = 0.0;
    var count = 0;
    for (final key in keys) {
      final weight = weights[key];
      if (weight == null) continue;
      sum += _squash(weight);
      count++;
    }
    return count == 0 ? 0 : sum / count;
  }
}
