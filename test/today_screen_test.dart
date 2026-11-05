import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/plan_dao.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
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

  group('TodayScreen (S5-05 / TZ 7.2, 8.1)', () {
    late AppDatabase db;
    late PlanDao planDao;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory(), seed: true);
      await db.customSelect('SELECT 1').get();
      planDao = PlanDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders empty state when no dish is planned for today', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedToday = DateTime(2026, 11, 5);

      await withClock(Clock.fixed(fixedToday), () async {
        await tester.pumpWidget(_createTodayTestWidget(db));
        await tester.pumpAndSettle();

        // Empty state headers and buttons
        expect(find.text('На сегодня блюдо не выбрано'), findsOneWidget);
        expect(find.text('Подобрать из того, что есть'), findsOneWidget);
        expect(find.text('Выбрать блюдо'), findsOneWidget);
        expect(find.text('Открыть календарь'), findsOneWidget);
      });
    });

    testWidgets('chooses a dish for today via bottom sheet picker', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedToday = DateTime(2026, 11, 5);
      final todayKey = PlanDao.formatDate(fixedToday);

      await withClock(Clock.fixed(fixedToday), () async {
        await tester.pumpWidget(_createTodayTestWidget(db));
        await tester.pumpAndSettle();

        // Tap "Выбрать блюдо"
        await tester.tap(find.text('Выбрать блюдо'));
        await tester.pumpAndSettle();

        // Filter by searching "борщ"
        await tester.enterText(find.byType(TextField), 'борщ');
        await tester.pumpAndSettle();

        // Tap the list item
        final tileFinder = find.widgetWithText(ListTile, 'Борщ с говядиной');
        expect(tileFinder, findsOneWidget);
        await tester.tap(tileFinder);
        await tester.pumpAndSettle();

        // Verify entry in database
        final entry = await planDao.getEntryForDate(todayKey);
        expect(entry, isNotNull);
        expect(entry!.entry.recipeId, 'borscht');
        expect(entry.entry.status, MealPlanStatus.planned);

        // UI now shows dish of the day card
        expect(find.text('Блюдо дня'), findsOneWidget);
        expect(find.text('Борщ с говядиной'), findsOneWidget);
        expect(find.text('Готовить'), findsOneWidget);
        expect(find.text('Другое блюдо'), findsOneWidget);
      });
    });

    testWidgets(
      'renders planned meal card with badges and replaces it with another dish',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fixedToday = DateTime(2026, 11, 5);
        final todayKey = PlanDao.formatDate(fixedToday);

        await planDao.upsertEntry(
          date: todayKey,
          recipeId: 'borscht',
          status: MealPlanStatus.planned,
        );

        await withClock(Clock.fixed(fixedToday), () async {
          await tester.pumpWidget(_createTodayTestWidget(db));
          await tester.pumpAndSettle();

          // Planned card visible
          expect(find.text('Блюдо дня'), findsOneWidget);
          expect(find.text('Борщ с говядиной'), findsOneWidget);
          expect(find.text('Запланировано'), findsWidgets);
          expect(find.text('Готовить'), findsOneWidget);
          expect(find.text('Другое блюдо'), findsOneWidget);
          expect(find.text('Посмотреть рецепт'), findsOneWidget);

          // Tap "Другое блюдо"
          await tester.tap(find.text('Другое блюдо'));
          await tester.pumpAndSettle();

          // Search for a different dish
          await tester.enterText(find.byType(TextField), 'куриц');
          await tester.pumpAndSettle();

          final chickenTile = find.byType(ListTile).first;
          await tester.tap(chickenTile);
          await tester.pumpAndSettle();

          // Verify dish was replaced
          final updated = await planDao.getEntryForDate(todayKey);
          expect(updated!.entry.recipeId, isNot('borscht'));
        });
      },
    );

    testWidgets('automatically skips past planned days on launch', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedToday = DateTime(2026, 11, 5);
      const pastDate = '2026-11-03';

      await planDao.upsertEntry(
        date: pastDate,
        recipeId: 'borscht',
        status: MealPlanStatus.planned,
      );

      await withClock(Clock.fixed(fixedToday), () async {
        await tester.pumpWidget(_createTodayTestWidget(db));
        await tester.pumpAndSettle();

        // Verify past entry became skipped
        final pastEntry = await planDao.getEntryForDate(pastDate);
        expect(pastEntry!.entry.status, MealPlanStatus.skipped);
      });
    });
  });
}
