import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/plan_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PlanDao planDao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    // Trigger seed loading
    await db.customSelect('SELECT 1').get();
    planDao = PlanDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PlanDao (S5-01 / TZ 8.1)', () {
    test('upserts, retrieves, and updates plan entries', () async {
      final now = DateTime(2026, 11, 14, 12, 0);

      await withClock(Clock.fixed(now), () async {
        // Initially empty
        expect(await planDao.allWithRecipes(), isEmpty);

        // Insert new planned meal
        final entry = await planDao.upsertEntry(
          date: '2026-11-14',
          recipeId: 'borscht',
          status: MealPlanStatus.planned,
          locked: false,
        );

        expect(entry.date, '2026-11-14');
        expect(entry.recipeId, 'borscht');
        expect(entry.status, MealPlanStatus.planned);
        expect(entry.locked, isFalse);

        // Retrieve with recipe
        final withRecipe = await planDao.getEntryForDate('2026-11-14');
        expect(withRecipe, isNotNull);
        expect(withRecipe!.recipe?.id, 'borscht');
        expect(withRecipe.recipe?.title, contains('Борщ'));

        // Upsert updates existing entry without creating duplicate
        await planDao.upsertEntry(
          date: '2026-11-14',
          recipeId: 'chicken_soup_potato',
          status: MealPlanStatus.planned,
          locked: true,
        );

        final all = await planDao.allWithRecipes();
        expect(all.length, 1);
        expect(all.first.entry.recipeId, 'chicken_soup_potato');
        expect(all.first.entry.locked, isTrue);

        // Toggle locked
        await planDao.setLocked(entry.id, false);
        final unlocked = await planDao.getEntryForDate('2026-11-14');
        expect(unlocked!.entry.locked, isFalse);

        // Update status to cooked
        await planDao.setStatus(entry.id, MealPlanStatus.cooked);
        final cooked = await planDao.getEntryForDate('2026-11-14');
        expect(cooked!.entry.status, MealPlanStatus.cooked);

        // Replace recipe
        await planDao.replaceRecipe(entry.id, 'pea_soup');
        final replaced = await planDao.getEntryForDate('2026-11-14');
        expect(replaced!.entry.recipeId, 'pea_soup');

        // Soft delete
        await planDao.deleteEntry(entry.id);
        expect(await planDao.getEntryForDate('2026-11-14'), isNull);
        expect(await planDao.allWithRecipes(), isEmpty);
      });
    });

    test('range queries and lock filters work correctly', () async {
      await planDao.upsertEntry(
        date: '2026-11-10',
        recipeId: 'borscht',
        locked: false,
      );
      await planDao.upsertEntry(
        date: '2026-11-12',
        recipeId: 'chicken_soup_potato',
        locked: true,
      );
      await planDao.upsertEntry(
        date: '2026-11-15',
        recipeId: 'pea_soup',
        locked: false,
      );

      // Range [11-11, 11-16]
      final range = await planDao.getEntriesForRange(
        '2026-11-11',
        '2026-11-16',
      );
      expect(range.length, 2);
      expect(range.map((e) => e.entry.date).toList(), [
        '2026-11-12',
        '2026-11-15',
      ]);

      // Locked dates
      final lockedDates = await planDao.getLockedDates(
        '2026-11-01',
        '2026-11-30',
      );
      expect(lockedDates, {'2026-11-12'});

      // Clear unlocked range preserves locked entries
      final cleared = await planDao.clearUnlockedRange(
        '2026-11-10',
        '2026-11-20',
      );
      expect(cleared, 2); // 10th and 15th deleted

      final remaining = await planDao.allWithRecipes();
      expect(remaining.length, 1);
      expect(remaining.first.entry.date, '2026-11-12');
      expect(remaining.first.entry.locked, isTrue);
    });
  });
}
