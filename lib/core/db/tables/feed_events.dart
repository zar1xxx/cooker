import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import 'common.dart';
import 'recipes.dart';

/// Feed user interactions: shown, opened, cooked, skipped, rated (1..5).
@DataClassName('FeedEventEntry')
class FeedEvents extends Table with CommonFields {
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();

  /// Event type: 'shown', 'opened', 'cooked', 'skipped', 'rated'
  TextColumn get event => text()();

  /// Rating 1..5 when event is 'rated', or null for other interactions.
  IntColumn get rating => integer().nullable()();

  /// JSON payload recording the recommendation context (occasion, mood, etc.)
  TextColumn get contextJson => text().nullable()();

  /// Timestamp in milliseconds since epoch
  IntColumn get at => integer().clientDefault(
    () => clock.now().toUtc().millisecondsSinceEpoch,
  )();
}
