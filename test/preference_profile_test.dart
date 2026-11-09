import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PreferenceService service;
  late HistoryDao historyDao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();
    service = PreferenceService(db);
    historyDao = HistoryDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PreferenceService (S4-02 / TZ 6.4)', () {
    test('signal values match Table 6.4', () {
      expect(
        PreferenceService.calculateSignal(
          FeedbackKind.cooked,
          reason: 'rating: 5',
        ),
        1.0,
      );
      expect(
        PreferenceService.calculateSignal(
          FeedbackKind.cooked,
          reason: 'rating: 4',
        ),
        0.5,
      );
      expect(
        PreferenceService.calculateSignal(
          FeedbackKind.cooked,
          reason: 'rating: 3',
        ),
        0.0,
      );
      expect(
        PreferenceService.calculateSignal(
          FeedbackKind.cooked,
          reason: 'rating: 2',
        ),
        -1.0,
      );
      expect(
        PreferenceService.calculateSignal(
          FeedbackKind.cooked,
          reason: 'rating: 1',
        ),
        -1.0,
      );
      expect(
        PreferenceService.calculateSignal(
          FeedbackKind.cooked,
          reason: 'cooked without rating',
        ),
        0.3,
      );
      expect(
        PreferenceService.calculateSignal(FeedbackKind.cooked, reason: null),
        0.3,
      );
      expect(PreferenceService.calculateSignal(FeedbackKind.liked), 1.0);
      expect(PreferenceService.calculateSignal(FeedbackKind.disliked), -1.0);
      expect(PreferenceService.calculateSignal(FeedbackKind.skipped), -0.2);
      expect(
        PreferenceService.calculateSignal(FeedbackKind.rejected_suggestion),
        -0.3,
      );
    });

    test('decay weight with 60-day half-life: 2^(-delta_t / 60)', () {
      final now = DateTime(2026, 11, 4, 12, 0);

      // Event right now -> delta_t = 0 -> weight = 1.0
      expect(PreferenceService.decayWeight(now, now), 1.0);

      // Event 60 days ago -> delta_t = 60 -> weight = 0.5
      final sixtyDaysAgo = now.subtract(const Duration(days: 60));
      expect(
        PreferenceService.decayWeight(sixtyDaysAgo, now),
        closeTo(0.5, 0.001),
      );

      // Event 120 days ago -> delta_t = 120 -> weight = 0.25
      final oneTwentyDaysAgo = now.subtract(const Duration(days: 120));
      expect(
        PreferenceService.decayWeight(oneTwentyDaysAgo, now),
        closeTo(0.25, 0.001),
      );
    });

    test('three soups on 5, two desserts on 2 -> w(soup) > 0 > w(dessert)', () async {
      final now = DateTime(2026, 11, 4, 12, 0);

      await withClock(Clock.fixed(now), () async {
        // Record 3 soup cooked events with rating 5
        // chicken_soup_potato has dishType: soup
        await historyDao.recordCooked(
          recipeId: 'chicken_soup_potato',
          rating: 5,
          date: now,
        );
        await historyDao.recordCooked(
          recipeId: 'chicken_soup_potato',
          rating: 5,
          date: now,
        );
        await historyDao.recordCooked(
          recipeId: 'chicken_soup_potato',
          rating: 5,
          date: now,
        );

        // Create a dessert recipe and record 2 cooked events with rating 2
        final dessert = await historyDao.addManualEntry(
          title: 'Шоколадный торт',
          dishType: DishType.dessert,
          rating: 2,
          date: now,
        );
        await historyDao.recordCooked(
          recipeId: dessert.recipeId,
          rating: 2,
          date: now,
        );

        // Recalculate profile
        final profile = await service.recalculateProfile();

        final soupWeight =
            (profile.dishTypeWeights['soup'] as num?)?.toDouble() ?? 0.0;
        final dessertWeight =
            (profile.dishTypeWeights['dessert'] as num?)?.toDouble() ?? 0.0;

        // Three ratings of 5 at t=0:
        // num = 3 * 1.0 = 3.0, den = 3 * 1.0 + 3 = 6.0 => w(soup) = 0.5
        expect(soupWeight, closeTo(0.5, 0.01));
        expect(soupWeight, greaterThan(0));

        // Two ratings of 2 at t=0:
        // num = 2 * (-1.0) = -2.0, den = 2 * 1.0 + 3 = 5.0 => w(dessert) = -0.4
        expect(dessertWeight, closeTo(-0.4, 0.01));
        expect(dessertWeight, lessThan(0));

        expect(soupWeight, greaterThan(dessertWeight));
      });
    });

    test('signal distributes across dishType, difficulty, cuisine, and ingredients', () async {
      final now = DateTime(2026, 11, 4, 12, 0);

      await withClock(Clock.fixed(now), () async {
        // chicken_soup_potato:
        // dishType: soup, difficulty: easy, cuisine: русская
        // ingredients include chicken, potato, onion, carrot
        await historyDao.recordCooked(
          recipeId: 'chicken_soup_potato',
          rating: 5,
          date: now,
        );

        final profile = await service.recalculateProfile();

        // 1 signal of 1.0 at t=0: num = 1.0, den = 1.0 + 3 = 4.0 => 0.25
        expect(profile.dishTypeWeights['soup'], closeTo(0.25, 0.01));
        expect(profile.difficultyWeights['easy'], closeTo(0.25, 0.01));
        expect(profile.cuisineWeights['ru'], closeTo(0.25, 0.01));

        // Ingredients also received weights
        expect(profile.ingredientWeights.containsKey('chicken'), isTrue);
        expect(profile.ingredientWeights['chicken'], closeTo(0.25, 0.01));
        expect(profile.ingredientWeights['potato'], closeTo(0.25, 0.01));
      });
    });

    test(
      'resetProfile clears weights but preserves allergies and excluded',
      () async {
        final now = DateTime(2026, 11, 4, 12, 0);

        await withClock(Clock.fixed(now), () async {
          await historyDao.recordCooked(
            recipeId: 'chicken_soup_potato',
            rating: 5,
            date: now,
          );

          await service.setAllergies(['peanuts']);
          await service.setExcludedIngredients(['cilantro']);
          await service.recalculateProfile();

          var profile = await service.getProfile();
          expect(profile.dishTypeWeights.isNotEmpty, isTrue);
          expect(profile.allergies, ['peanuts']);
          expect(profile.excludedIngredients, ['cilantro']);

          // Reset
          await service.resetProfile();

          profile = await service.getProfile();
          expect(profile.dishTypeWeights.isEmpty, isTrue);
          expect(profile.ingredientWeights.isEmpty, isTrue);
          expect(profile.allergies, ['peanuts']); // Preserved
          expect(profile.excludedIngredients, ['cilantro']); // Preserved
        });
      },
    );

    test(
      'getCompressedProfile returns top 5 liked and top 5 disliked features',
      () async {
        final now = DateTime(2026, 11, 4, 12, 0);

        await withClock(Clock.fixed(now), () async {
          await historyDao.recordCooked(
            recipeId: 'chicken_soup_potato',
            rating: 5,
            date: now,
          );

          final compressed = await service.getCompressedProfile();
          expect(compressed.topLikedFeatures.isNotEmpty, isTrue);
          expect(compressed.topLikedFeatures.length, lessThanOrEqualTo(5));
          expect(compressed.topDislikedFeatures.length, lessThanOrEqualTo(5));
        });
      },
    );
  });
}
