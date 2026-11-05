import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/plan_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PlanDao planDao;
  late PreferenceService prefService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();
    planDao = PlanDao(db);
    prefService = PreferenceService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Auto-skip past planned entries (S5-05 / TZ 8.1, 6.4)', () {
    test('transitions past planned meals to skipped with -0.2 signal and keeps today/future untouched', () async {
      const todayKey = '2026-11-05';
      const pastDate1 = '2026-11-03';
      const pastDate2 = '2026-11-04';
      const futureDate = '2026-11-07';

      // 1. Setup entries:
      // - pastDate1: planned (should become skipped)
      // - pastDate2: cooked (should remain cooked)
      // - today: planned (should remain planned)
      // - futureDate: planned (should remain planned)
      await planDao.upsertEntry(
        date: pastDate1,
        recipeId: 'borscht',
        status: MealPlanStatus.planned,
      );
      await planDao.upsertEntry(
        date: pastDate2,
        recipeId: 'borscht',
        status: MealPlanStatus.cooked,
      );
      await planDao.upsertEntry(
        date: todayKey,
        recipeId: 'borscht',
        status: MealPlanStatus.planned,
      );
      await planDao.upsertEntry(
        date: futureDate,
        recipeId: 'borscht',
        status: MealPlanStatus.planned,
      );

      // 2. Run auto-skip
      final skipped = await planDao.autoSkipPastPlannedEntries(
        todayKey: todayKey,
      );

      // Expect 1 entry transitioned
      expect(skipped.length, 1);
      expect(skipped.first.date, pastDate1);

      // 3. Verify statuses in DB
      final entry1 = await planDao.getEntryForDate(pastDate1);
      expect(entry1!.entry.status, MealPlanStatus.skipped);

      final entry2 = await planDao.getEntryForDate(pastDate2);
      expect(entry2!.entry.status, MealPlanStatus.cooked);

      final entryToday = await planDao.getEntryForDate(todayKey);
      expect(entryToday!.entry.status, MealPlanStatus.planned);

      final entryFuture = await planDao.getEntryForDate(futureDate);
      expect(entryFuture!.entry.status, MealPlanStatus.planned);

      // 4. Verify feedback_event inserted with FeedbackKind.skipped
      final feedbackEvents = await (db.select(
        db.feedbackEvents,
      )..where((tbl) => tbl.kind.equalsValue(FeedbackKind.skipped))).get();
      expect(feedbackEvents.length, 1);
      expect(feedbackEvents.first.recipeId, 'borscht');
      expect(feedbackEvents.first.reason, 'auto_skip_past_date');

      // 5. Verify signal in taste profile is negative
      final profile = await prefService.getProfile();
      final soupWeight = profile.dishTypeWeights['soup'] ?? 0.0;
      expect(soupWeight, lessThan(0.0));
    });

    test(
      'returns empty list and does not fail when no past planned meals exist',
      () async {
        const todayKey = '2026-11-05';
        await planDao.upsertEntry(
          date: todayKey,
          recipeId: 'borscht',
          status: MealPlanStatus.planned,
        );

        final skipped = await planDao.autoSkipPastPlannedEntries(
          todayKey: todayKey,
        );
        expect(skipped, isEmpty);

        final feedbackCount = await (db.select(db.feedbackEvents)).get();
        expect(feedbackCount, isEmpty);
      },
    );
  });
}
