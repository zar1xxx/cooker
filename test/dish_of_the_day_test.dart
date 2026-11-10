import 'package:chto_prigotovit/core/calendar/meal_planner.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/db/daos/ingredient_dao.dart';
import 'package:chto_prigotovit/core/db/daos/pantry_dao.dart';
import 'package:chto_prigotovit/core/db/daos/plan_dao.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/core/services/daily_notification_service.dart';
import 'package:chto_prigotovit/features/calendar/today_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'daily_notification_service_test.dart';

Widget _createTodayTestWidget(
  AppDatabase db, {
  Set<String> pantry = const {},
  DailyNotificationService? notifService,
}) {
  final fakeNotifService =
      notifService ??
      DailyNotificationService(
        plugin: RecordingNotificationPlugin(),
        storage: FakeSecureStorage(),
      );

  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      pantryProvider.overrideWith(() => _StaticPantryNotifier(pantry)),
      dailyNotificationServiceProvider.overrideWithValue(fakeNotifService),
    ],
    child: const MaterialApp(
      locale: Locale('ru'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: TodayScreen(),
    ),
  );
}

class _StaticPantryNotifier extends PantryNotifier {
  _StaticPantryNotifier(this._initial);
  final Set<String> _initial;

  @override
  Future<Set<String>> build() async => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ru', null);
  });

  group('Dish of the Day (R8-04)', () {
    late AppDatabase db;
    late RecipeDao recipeDao;
    late PlanDao planDao;
    late IngredientDao ingredientDao;
    late PantryDao pantryDao;
    late PreferenceService preferenceService;
    late HistoryDao historyDao;
    late MealPlanner mealPlanner;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory(), seed: true);
      await db.customSelect('SELECT 1').get();
      recipeDao = RecipeDao(db);
      planDao = PlanDao(db);
      ingredientDao = IngredientDao(db);
      pantryDao = PantryDao(db);
      preferenceService = PreferenceService(db);
      historyDao = HistoryDao(db);
      mealPlanner = MealPlanner(
        recipeDao: recipeDao,
        planDao: planDao,
        ingredientDao: ingredientDao,
        preferenceService: preferenceService,
        historyDao: historyDao,
        db: db,
        pantryDao: pantryDao,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('when pantry contains potato, onion, carrot, chicken, dish of the day does NOT require beef or sausage', () async {
      final today = DateTime(2026, 11, 10);
      final pantry = {'potato', 'onion', 'carrot', 'chicken'};

      final picked = await mealPlanner.pickDishOfTheDay(
        date: today,
        pantry: pantry,
      );

      expect(picked, isNotNull);
      final ingredientIds = picked!.ingredients
          .map((i) => i.recipeIngredient.ingredientId)
          .toSet();

      // Must NOT require beef or sausage
      expect(
        ingredientIds.contains('beef'),
        isFalse,
        reason: 'Dish of the day should not require beef when pantry only has chicken & vegetables',
      );
      expect(
        ingredientIds.contains('sausage'),
        isFalse,
        reason: 'Dish of the day should not require sausage when pantry only has chicken & vegetables',
      );

      // The chosen dish should be cookable or almost cookable from chicken & veggies
      expect(ingredientIds.contains('chicken'), isTrue);
    });

    test('generateMonthPlan selects Dish of the Day matching pantry for today without requiring beef/sausage', () async {
      final today = DateTime(2026, 11, 10);
      final pantry = {'potato', 'onion', 'carrot', 'chicken'};

      final entries = await mealPlanner.generateMonthPlan(
        fromDate: today,
        toDate: today.add(const Duration(days: 3)),
        pantry: pantry,
      );

      final todayStr = PlanDao.formatDate(today);
      final todayEntry = entries.firstWhere((e) => e.date == todayStr);
      final detail = await recipeDao.getRecipeDetail(todayEntry.recipeId);

      expect(detail, isNotNull);
      final ingredientIds = detail!.ingredients
          .map((i) => i.recipeIngredient.ingredientId)
          .toSet();

      expect(ingredientIds.contains('beef'), isFalse);
      expect(ingredientIds.contains('sausage'), isFalse);
    });

    testWidgets('shows all ingredients available when missing == 0', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedToday = DateTime(2026, 11, 10);
      final todayKey = PlanDao.formatDate(fixedToday);

      // Plan chicken soup
      await planDao.upsertEntry(
        date: todayKey,
        recipeId: 'chicken_soup_potato',
        status: MealPlanStatus.planned,
      );

      // Pantry has all non-staple ingredients for chicken soup: chicken, potato, carrot, onion
      // (water, salt, sunflower_oil, etc. are staples and don't block)
      await withClock(Clock.fixed(fixedToday), () async {
        await tester.pumpWidget(
          _createTodayTestWidget(
            db,
            pantry: {'chicken', 'potato', 'carrot', 'onion'},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Блюдо дня'), findsOneWidget);
        expect(find.text('Куриный суп с картошкой'), findsOneWidget);

        // "Все продукты есть дома" is displayed
        expect(find.text('Все продукты есть дома'), findsOneWidget);

        // Banner "Не хватает ..." and replace button are NOT displayed
        expect(find.textContaining('Не хватает'), findsNothing);
        expect(
          find.text('Заменить на то, что можно из имеющегося'),
          findsNothing,
        );

        // Badge "Нужно докупить" is NOT displayed
        expect(find.text('Нужно докупить'), findsNothing);
      });
    });

    testWidgets(
      'does NOT show warning banner or replace button when missing non-staples <= 2',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fixedToday = DateTime(2026, 11, 10);
        final todayKey = PlanDao.formatDate(fixedToday);

        // Plan chicken soup (requires chicken, potato, carrot, onion)
        await planDao.upsertEntry(
          date: todayKey,
          recipeId: 'chicken_soup_potato',
          status: MealPlanStatus.planned,
        );

        // Pantry has chicken and potato, but missing carrot and onion (2 non-staples missing <= 2)
        await withClock(Clock.fixed(fixedToday), () async {
          await tester.pumpWidget(
            _createTodayTestWidget(db, pantry: {'chicken', 'potato'}),
          );
          await tester.pumpAndSettle();

          expect(find.text('Блюдо дня'), findsOneWidget);
          expect(find.text('Куриный суп с картошкой'), findsOneWidget);

          // Warning banner and replace button must NOT be shown when missing <= 2
          expect(find.textContaining('Не хватает'), findsNothing);
          expect(
            find.text('Заменить на то, что можно из имеющегося'),
            findsNothing,
          );

          // Badge "Нужно докупить" must NOT be shown
          expect(find.text('Нужно докупить'), findsNothing);
        });
      },
    );

    testWidgets(
      'shows warning banner, replace button outside banner, and "Нужно докупить" badge when missing > 2',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fixedToday = DateTime(2026, 11, 10);
        final todayKey = PlanDao.formatDate(fixedToday);

        // Plan solyanka (requires beef, sausage, ham, pickles, onion, tomato_paste, etc. > 5 non-staples)
        await planDao.upsertEntry(
          date: todayKey,
          recipeId: 'solyanka',
          status: MealPlanStatus.planned,
        );

        // Pantry only has onion (missing > 2 items)
        await withClock(Clock.fixed(fixedToday), () async {
          await tester.pumpWidget(
            _createTodayTestWidget(db, pantry: {'onion'}),
          );
          await tester.pumpAndSettle();

          expect(find.text('Блюдо дня'), findsOneWidget);
          expect(find.text('Солянка мясная'), findsOneWidget);

          // Badge "Нужно докупить" IS shown
          expect(find.text('Нужно докупить'), findsOneWidget);

          // Warning banner "Не хватает: ..." IS shown
          expect(find.textContaining('Не хватает'), findsOneWidget);

          // Button "Заменить на то, что можно из имеющегося" IS shown
          expect(
            find.text('Заменить на то, что можно из имеющегося'),
            findsOneWidget,
          );
        });
      },
    );
  });
}
