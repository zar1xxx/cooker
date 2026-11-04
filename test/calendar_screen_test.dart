import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/plan_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
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

  setUpAll(() async {
    await initializeDateFormatting('ru', null);
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();
    planDao = PlanDao(db);
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
        expect(find.text('Борщ с говядиной'), findsOneWidget);

        // Select borscht
        await tester.tap(find.text('Борщ с говядиной'));
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
  });
}
