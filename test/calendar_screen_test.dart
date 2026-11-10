import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/calendar/meal_planner.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/ingredient_dao.dart';
import 'package:chto_prigotovit/core/db/daos/plan_dao.dart';
import 'package:chto_prigotovit/core/db/daos/recipe_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/calendar/calendar_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Widget _createCalendarTestWidget(AppDatabase db, {Set<String>? pantry}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      if (pantry != null)
        pantryProvider.overrideWith(() => _MockPantryNotifier(pantry)),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: const CalendarScreen(),
    ),
  );
}

class _MockPantryNotifier extends PantryNotifier {
  _MockPantryNotifier(this._initial);
  final Set<String> _initial;

  @override
  Future<Set<String>> build() async => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PlanDao planDao;
  late RecipeDao recipeDao;

  setUpAll(() async {
    await initializeDateFormatting('ru', null);
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();
    planDao = PlanDao(db);
    recipeDao = RecipeDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CalendarScreen (S5-01 / TZ 8.1, 7.2)', () {
    testWidgets('renders calendar grid and empty day state', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_createCalendarTestWidget(db));
      await tester.pumpAndSettle();

      expect(find.text('Календарь'), findsOneWidget);
      expect(find.text('На этот день ничего не запланировано'), findsOneWidget);
      expect(find.text('Выбрать блюдо'), findsOneWidget);
      expect(find.text('Составить план на месяц'), findsOneWidget);
    });

    testWidgets('renders day with planned meal, badges, and lock', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedToday = DateTime(2026, 11, 14);
      final dateStr = PlanDao.formatDate(fixedToday);

      await withClock(Clock.fixed(fixedToday), () async {
        await planDao.upsertEntry(
          date: dateStr,
          recipeId: 'borscht',
          status: MealPlanStatus.planned,
          locked: true,
        );

        await tester.pumpWidget(_createCalendarTestWidget(db));
        await tester.pumpAndSettle();

        // Card should display planned dish details
        expect(find.text('Борщ с говядиной'), findsOneWidget);
        expect(find.text('Суп'), findsWidgets);
        expect(find.text('Запланировано'), findsWidgets);
        expect(find.text('Закреплено'), findsWidgets);
        expect(find.text('Посмотреть рецепт'), findsOneWidget);
        expect(find.text('Открепить'), findsOneWidget);
        expect(find.text('Заменить'), findsOneWidget);
        expect(find.text('Отметить приготовленным'), findsOneWidget);
      });
    });

    testWidgets('toggles lock and updates status to cooked', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedToday = DateTime(2026, 11, 14);
      final dateStr = PlanDao.formatDate(fixedToday);

      await withClock(Clock.fixed(fixedToday), () async {
        await planDao.upsertEntry(
          date: dateStr,
          recipeId: 'borscht',
          status: MealPlanStatus.planned,
          locked: false,
        );

        await tester.pumpWidget(_createCalendarTestWidget(db));
        await tester.pumpAndSettle();

        expect(find.text('Закрепить'), findsOneWidget);

        // Tap "Закрепить"
        await tester.tap(find.text('Закрепить'));
        await tester.pumpAndSettle();

        final updated = await planDao.getEntryForDate(dateStr);
        expect(updated!.entry.locked, isTrue);

        // Tap "Отметить приготовленным"
        await tester.tap(find.text('Отметить приготовленным'));
        await tester.pumpAndSettle();

        final cooked = await planDao.getEntryForDate(dateStr);
        expect(cooked!.entry.status, MealPlanStatus.cooked);
        expect(find.text('Приготовлено'), findsWidgets);
      });
    });

    testWidgets('opens recipe picker bottom sheet and selects recipe', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedToday = DateTime(2026, 11, 14);
      final dateStr = PlanDao.formatDate(fixedToday);

      await withClock(Clock.fixed(fixedToday), () async {
        await tester.pumpWidget(_createCalendarTestWidget(db));
        await tester.pumpAndSettle();

        // Tap "Выбрать блюдо"
        await tester.tap(find.text('Выбрать блюдо'));
        await tester.pumpAndSettle();

        // Bottom sheet open with search
        expect(find.byType(TextField), findsOneWidget);

        // The catalog has ~2000 recipes and the list is lazy: search first.
        await tester.enterText(find.byType(TextField), 'Борщ с говядиной');
        await tester.pumpAndSettle();
        // The first match is the text typed into the field, the last one is the list item.
        final borschtItem = find.text('Борщ с говядиной').last;
        expect(borschtItem, findsOneWidget);

        // Select borscht
        await tester.tap(borschtItem);
        await tester.pumpAndSettle();

        final entry = await planDao.getEntryForDate(dateStr);
        expect(entry, isNotNull);
        expect(entry!.recipe?.id, 'borscht');
        expect(find.text('Борщ с говядиной'), findsOneWidget);
      });
    });

    testWidgets('displays missing ingredients when pantry lacks products', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedToday = DateTime(2026, 11, 14);
      final dateStr = PlanDao.formatDate(fixedToday);

      await withClock(Clock.fixed(fixedToday), () async {
        await planDao.upsertEntry(
          date: dateStr,
          recipeId: 'borscht',
          status: MealPlanStatus.planned,
        );

        // Empty pantry -> missing ingredients shown
        await tester.pumpWidget(
          _createCalendarTestWidget(db, pantry: const <String>{}),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Не хватает:'), findsOneWidget);
        expect(
          find.text('Заменить на то, что можно из имеющегося'),
          findsOneWidget,
        );
      });
    });

    testWidgets(
      'make month plan button generates plan and updates calendar grid',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fixedToday = DateTime(2026, 11, 14);

        await withClock(Clock.fixed(fixedToday), () async {
          await tester.pumpWidget(_createCalendarTestWidget(db));
          await tester.pumpAndSettle();

          // Tap "Составить план на месяц"
          final makePlanButton = find.byKey(
            const Key('calendar_make_month_plan_button'),
          );
          expect(makePlanButton, findsOneWidget);
          await tester.tap(makePlanButton);
          await tester.pumpAndSettle();

          // Verify SnackBar and plan created in database
          expect(find.textContaining('План составлен:'), findsOneWidget);

          final entries = await planDao.allWithRecipes();
          expect(entries.length, greaterThanOrEqualTo(10));
        });
      },
    );

    testWidgets(
      'Scenario 4 (TZ 11, S5-04): lock favorite dish on Saturday -> generate month plan -> Saturday unchanged -> replace one day',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // 1. Wednesday 2026-11-04 as starting date; nearest Saturday is 2026-11-07
        final fixedToday = DateTime(2026, 11, 4);
        final saturdayDate = DateTime(2026, 11, 7);
        final saturdayKey = PlanDao.formatDate(saturdayDate);

        final allRecipes = await recipeDao.allWithIngredients();
        // Pick favorite recipe: e.g. "Борщ с говядиной"
        final favoriteRecipe = allRecipes.firstWhere(
          (r) => r.recipe.dishType == DishType.soup,
        );
        await recipeDao.setFavorite(favoriteRecipe.recipe.id, true);

        // Step 1: Pre-lock Saturday with favorite dish
        await planDao.upsertEntry(
          date: saturdayKey,
          recipeId: favoriteRecipe.recipe.id,
          status: MealPlanStatus.planned,
          locked: true,
        );

        await withClock(Clock.fixed(fixedToday), () async {
          await tester.pumpWidget(_createCalendarTestWidget(db));
          await tester.pumpAndSettle();

          // Tap "Составить план на месяц"
          final makePlanButton = find.byKey(
            const Key('calendar_make_month_plan_button'),
          );
          expect(makePlanButton, findsOneWidget);
          await tester.tap(makePlanButton);
          await tester.pumpAndSettle();

          // Expect plan created
          expect(find.textContaining('План составлен:'), findsOneWidget);

          // All days until end of month (Nov 4..Nov 30 = 27 days) are planned
          final entriesAfterPlan = await planDao.getEntriesForRange(
            '2026-11-04',
            '2026-11-30',
          );
          expect(entriesAfterPlan.length, 27);

          // Saturday is still the exact favorite dish and locked
          final saturdayEntry = await planDao.getEntryForDate(saturdayKey);
          expect(saturdayEntry, isNotNull);
          expect(saturdayEntry!.entry.locked, isTrue);
          expect(saturdayEntry.entry.recipeId, favoriteRecipe.recipe.id);

          // All rules of 8.1 are satisfied across the plan
          final byId = {for (final r in allRecipes) r.recipe.id: r};
          final scheduledDays = [
            for (final item in entriesAfterPlan)
              ScheduledDay(
                date: DateTime.parse(item.entry.date),
                recipe: byId[item.entry.recipeId] ?? allRecipes.first,
                locked: item.entry.locked,
              ),
          ];
          final mealPlanner = MealPlanner(
            recipeDao: recipeDao,
            planDao: planDao,
            ingredientDao: IngredientDao(db),
            preferenceService: PreferenceService(db),
            db: db,
          );
          final validation = mealPlanner.validatePlan(scheduledDays);
          expect(
            validation.isValid,
            isTrue,
            reason: 'Plan violations: ${validation.violations}',
          );

          // Step 2: Replace one day (Thursday Nov 5) using "Заменить"
          // Select Thursday 5
          final fives = find.text('5');
          await tester.tap(fives.first);
          await tester.pumpAndSettle();

          final replaceButton = find.widgetWithText(OutlinedButton, 'Заменить');
          expect(replaceButton, findsOneWidget);
          await tester.tap(replaceButton);
          await tester.pumpAndSettle();

          // In bottom sheet, search for a different recipe to ensure it is visible
          final differentRecipe = allRecipes.firstWhere(
            (r) =>
                r.recipe.id != favoriteRecipe.recipe.id &&
                r.recipe.dishType == DishType.main,
          );
          await tester.enterText(
            find.byType(TextField),
            differentRecipe.recipe.title,
          );
          await tester.pumpAndSettle();

          await tester.tap(
            find.widgetWithText(ListTile, differentRecipe.recipe.title),
          );
          await tester.pumpAndSettle();

          // Verify Thursday is replaced
          final thursdayEntry = await planDao.getEntryForDate('2026-11-05');
          expect(thursdayEntry, isNotNull);
          expect(thursdayEntry!.entry.recipeId, differentRecipe.recipe.id);

          // Saturday is still intact and locked!
          final saturdayEntryAfterReplace = await planDao.getEntryForDate(
            saturdayKey,
          );
          expect(saturdayEntryAfterReplace!.entry.locked, isTrue);
          expect(
            saturdayEntryAfterReplace.entry.recipeId,
            favoriteRecipe.recipe.id,
          );
        });
      },
    );

    testWidgets(
      'replace with available dishes button opens picker with available filter',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fixedToday = DateTime(2026, 11, 4);
        final dateKey = PlanDao.formatDate(fixedToday);

        final allWithIng = await recipeDao.allWithIngredients();
        final soupWithBeef = allWithIng.firstWhere(
          (r) => r.recipe.title.contains('Борщ'),
        );

        await planDao.upsertEntry(
          date: dateKey,
          recipeId: soupWithBeef.recipe.id,
          status: MealPlanStatus.planned,
          locked: false,
        );

        // Pantry with only potato and carrot (beef and cabbage missing)
        final pantry = {'potato', 'carrot'};

        await withClock(Clock.fixed(fixedToday), () async {
          await tester.pumpWidget(
            _createCalendarTestWidget(db, pantry: pantry),
          );
          await tester.pumpAndSettle();

          // Expect missing ingredients warning and "Заменить на то, что можно из имеющегося"
          final replaceAvailBtn = find.widgetWithText(
            OutlinedButton,
            'Заменить на то, что можно из имеющегося',
          );
          expect(replaceAvailBtn, findsOneWidget);

          await tester.tap(replaceAvailBtn);
          await tester.pumpAndSettle();

          // Expect sheet opens and has filter chips
          expect(find.text('Есть дома'), findsOneWidget);
          expect(find.text('Избранные'), findsOneWidget);
        });
      },
    );
  });
}
