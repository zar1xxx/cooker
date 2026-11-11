import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calendar/holiday_calculator.dart';
import '../../core/db/daos/feed_event_dao.dart';
import '../../core/feed/day_context.dart';
import '../../core/feed/feed_ai_filler.dart';
import '../../core/feed/feed_service.dart';
import '../../core/feed/feed_settings.dart';
import '../../core/providers.dart';
import '../../core/shopping/external_actions.dart';

final feedEventDaoProvider = Provider<FeedEventDao>((ref) {
  return FeedEventDao(ref.watch(databaseProvider));
});

/// Offline calendar of holidays and fasts (`assets/seed/holidays_ru.json`).
final holidayCalculatorProvider = FutureProvider<HolidayCalculator>((
  ref,
) async {
  final source = await rootBundle.loadString('assets/seed/holidays_ru.json');
  return HolidayCalculator.fromJsonString(source);
});

final feedSettingsServiceProvider = Provider<FeedSettingsService>((ref) {
  return FeedSettingsService();
});

final feedSettingsProvider = FutureProvider<FeedSettings>((ref) {
  return ref.watch(feedSettingsServiceProvider).load();
});

/// The assistant used when the catalog is short of dishes. Tests override it
/// with `null` or a fake.
final feedAiFillerProvider = Provider<FeedAiFiller?>((ref) {
  return _LazyAiFiller(ref);
});

final externalActionsProvider = Provider<ExternalActions>((ref) {
  return const PlatformExternalActions();
});

final feedServiceProvider = FutureProvider<FeedService>((ref) async {
  final holidays = await ref.watch(holidayCalculatorProvider.future);
  final settings = await ref.watch(feedSettingsProvider.future);
  return FeedService(
    db: ref.watch(databaseProvider),
    recipeDao: ref.watch(recipeDaoProvider),
    ingredientDao: ref.watch(ingredientDaoProvider),
    pantryDao: ref.watch(pantryDaoProvider),
    historyDao: ref.watch(historyDaoProvider),
    feedEventDao: ref.watch(feedEventDaoProvider),
    preferenceService: ref.watch(preferenceServiceProvider),
    holidays: holidays,
    settings: settings,
    aiFiller: ref.watch(feedAiFillerProvider),
  );
});

final feedSnapshotProvider = FutureProvider.family<FeedSnapshot, FeedQuery>((
  ref,
  query,
) async {
  // Rebuild when products at home change.
  await ref.watch(pantryProvider.future);
  final service = await ref.watch(feedServiceProvider.future);
  return service.load(query);
});

/// Resolves the AI service only when the feed really needs it, so opening
/// the feed never waits for the network.
class _LazyAiFiller implements FeedAiFiller {
  _LazyAiFiller(this._ref);

  final Ref _ref;

  @override
  Future<int> fill({
    required DayContext context,
    required int count,
    required Set<String> forbiddenIds,
  }) async {
    try {
      final aiService = await _ref.read(aiServiceProvider.future);
      final filler = AiServiceFeedFiller(
        aiService: aiService,
        ingredientDao: _ref.read(ingredientDaoProvider),
      );
      return await filler.fill(
        context: context,
        count: count,
        forbiddenIds: forbiddenIds,
      );
    } catch (_) {
      return 0;
    }
  }
}
