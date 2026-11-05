import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/core/services/notification_service.dart';
import 'package:chto_prigotovit/features/recipe/cooking_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCookingNotificationService extends Fake
    implements CookingNotificationService {
  final List<int> scheduled = [];
  final List<int> cancelled = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleTimer({
    required int id,
    required String recipeTitle,
    required int stepNumber,
    required int seconds,
  }) async {
    scheduled.add(id);
  }

  @override
  Future<void> cancelTimer(int id) async {
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async {}
}

Widget _createCookingTestWidget(
  AppDatabase db,
  String recipeId, {
  CookingNotificationService? notificationService,
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      if (notificationService != null)
        notificationServiceProvider.overrideWithValue(notificationService),
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
      home: CookingScreen(recipeId: recipeId),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    // Trigger seed
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  group('CookingScreen (S2-02 / TZ 7.2)', () {
    testWidgets(
      'renders step 1 with 28 sp text, progress indicator, and next button',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _createCookingTestWidget(db, 'chicken_soup_potato'),
        );
        await tester.pumpAndSettle();

        // Recipe title in AppBar
        expect(find.text('Куриный суп с картошкой'), findsOneWidget);

        // Progress indicator: 5 steps in chicken_soup_potato
        expect(find.text('Шаг 1 из 5'), findsOneWidget);

        // Next button is present
        expect(find.text('Дальше'), findsOneWidget);
        expect(find.text('Назад'), findsOneWidget);

        // Read aloud (TTS) button is present
        expect(find.text('Прочитать вслух'), findsOneWidget);
      },
    );

    testWidgets('advances to next step and back, shows Готово on last step', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _createCookingTestWidget(db, 'chicken_soup_potato'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Шаг 1 из 5'), findsOneWidget);

      // Step 1 -> Step 2
      await tester.tap(find.text('Дальше'));
      await tester.pumpAndSettle();
      expect(find.text('Шаг 2 из 5'), findsOneWidget);

      // Step 2 has a 1500s (25 min) timer
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('Запустить таймер'), findsOneWidget);

      // Step 2 -> Step 3
      await tester.tap(find.text('Дальше'));
      await tester.pumpAndSettle();
      expect(find.text('Шаг 3 из 5'), findsOneWidget);

      // Step 3 -> Step 4
      await tester.tap(find.text('Дальше'));
      await tester.pumpAndSettle();
      expect(find.text('Шаг 4 из 5'), findsOneWidget);

      // Step 4 -> Step 5 (last step)
      await tester.tap(find.text('Дальше'));
      await tester.pumpAndSettle();
      expect(find.text('Шаг 5 из 5'), findsOneWidget);

      // On last step, button is «Готово!»
      expect(find.text('Готово!'), findsOneWidget);

      // Can go back to step 4
      await tester.tap(find.text('Назад'));
      await tester.pumpAndSettle();
      expect(find.text('Шаг 4 из 5'), findsOneWidget);
    });

    testWidgets('starts and pauses the step timer on tap', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _createCookingTestWidget(db, 'chicken_soup_potato'),
      );
      await tester.pumpAndSettle();

      // Advance to step 2 which has a 25 min timer
      await tester.tap(find.text('Дальше'));
      await tester.pumpAndSettle();

      expect(find.text('25:00'), findsOneWidget);
      final startTimerButton = find.text('Запустить таймер');
      expect(startTimerButton, findsOneWidget);

      // Start timer
      await tester.tap(startTimerButton);
      await tester.pump();

      // Ticks 1 second
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('24:59'), findsOneWidget);
      expect(find.text('Пауза'), findsOneWidget);

      // Pause timer
      await tester.tap(find.text('Пауза'));
      await tester.pump();
      expect(find.text('Продолжить'), findsOneWidget);
    });

    testWidgets(
      'starting timer schedules exact notification and pausing cancels it (S2-03)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeNotifications = FakeCookingNotificationService();

        await tester.pumpWidget(
          _createCookingTestWidget(
            db,
            'chicken_soup_potato',
            notificationService: fakeNotifications,
          ),
        );
        await tester.pumpAndSettle();

        // Move to step 2 with timer
        await tester.tap(find.text('Дальше'));
        await tester.pumpAndSettle();

        // Start timer -> schedules notification
        await tester.tap(find.text('Запустить таймер'));
        await tester.pump();

        expect(fakeNotifications.scheduled, contains(1));

        // Pause timer -> cancels notification
        await tester.tap(find.text('Пауза'));
        await tester.pump();

        expect(fakeNotifications.cancelled, contains(1));
      },
    );

    testWidgets(
      'tapping Готово opens rating sheet and records to cooked_entries (S2-04)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _createCookingTestWidget(db, 'chicken_soup_potato'),
        );
        await tester.pumpAndSettle();

        // Advance to last step (step 5)
        for (int i = 0; i < 4; i++) {
          await tester.tap(find.text('Дальше'));
          await tester.pumpAndSettle();
        }

        // Tap «Готово!»
        await tester.tap(find.text('Готово!'));
        await tester.pumpAndSettle();

        // Rating modal sheet is visible
        expect(find.text('Как получилось?'), findsOneWidget);
        expect(find.text('Куриный суп с картошкой'), findsWidgets);
        expect(find.text('Очень вкусно!'), findsOneWidget);
        expect(find.text('Хочу приготовить снова'), findsOneWidget);

        // Tap «Сохранить»
        await tester.tap(find.text('Сохранить'));
        await tester.pumpAndSettle();

        // Confirm snackbar
        expect(find.text('Блюдо записано в историю'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));

        // Verify DB entry
        final historyDao = HistoryDao(db);
        final history = await historyDao.allWithRecipes();
        expect(history.length, 1);
        expect(history.first.entry.recipeId, 'chicken_soup_potato');
        expect(history.first.entry.rating, 5);
      },
    );
  });
}
