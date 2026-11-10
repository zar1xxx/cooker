import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/history/history_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _createHistoryTestWidget(AppDatabase db) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
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
      home: const HistoryScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  group('HistoryScreen (S4-01 / TZ 8.2)', () {
    testWidgets('renders empty state when no cooked entries exist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_createHistoryTestWidget(db));
      await tester.pumpAndSettle();

      expect(find.text('История'), findsOneWidget);
      expect(find.text('Вы ещё ничего не приготовили'), findsOneWidget);
      expect(find.text('Подобрать рецепт'), findsOneWidget);
      // Only the button in the empty body: the FAB is hidden while empty.
      expect(find.text('Записать блюдо'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);
    });

    testWidgets(
      'renders month summary, search, filters, and date-grouped entries',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fixedNow = DateTime(2026, 11, 4, 12, 0);

        await withClock(Clock.fixed(fixedNow), () async {
          final historyDao = HistoryDao(db);

          // Today's entry
          await historyDao.recordCooked(
            recipeId: 'chicken_soup_potato',
            rating: 5,
            wouldRepeat: true,
            note: 'Получилось отлично, добавила зелень',
            date: fixedNow,
          );

          // Yesterday's entry
          await historyDao.recordCooked(
            recipeId: 'mashed_potato',
            rating: 4,
            wouldRepeat: false,
            date: fixedNow.subtract(const Duration(days: 1)),
          );

          await tester.pumpWidget(_createHistoryTestWidget(db));
          await tester.pumpAndSettle();

          // Month summary card
          expect(find.textContaining('Сводка за'), findsOneWidget);
          expect(find.textContaining('Приготовлено: 2'), findsOneWidget);
          expect(find.textContaining('Новых блюд: 2'), findsOneWidget);

          // Search bar
          expect(find.byIcon(Icons.search), findsOneWidget);

          // Headers
          expect(find.textContaining('Сегодня'), findsOneWidget);
          expect(find.textContaining('Вчера'), findsOneWidget);

          // Titles
          expect(find.text('Куриный суп с картошкой'), findsOneWidget);
          expect(find.text('Картофельное пюре'), findsOneWidget);

          // Ratings
          expect(find.text('Оценка: 5 из 5'), findsOneWidget);
          expect(find.text('Оценка: 4 из 5'), findsOneWidget);

          // Note & wouldRepeat badge
          expect(find.text('Хочу повторить'), findsOneWidget);
          expect(
            find.text('Получилось отлично, добавила зелень'),
            findsOneWidget,
          );

          // Action buttons: 2 recipe view buttons, 2 delete buttons
          expect(find.text('Посмотреть рецепт'), findsNWidgets(2));
          expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
        });
      },
    );

    testWidgets('search bar filters entries by title or note', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedNow = DateTime(2026, 11, 4, 12, 0);

      await withClock(Clock.fixed(fixedNow), () async {
        final historyDao = HistoryDao(db);

        await historyDao.recordCooked(
          recipeId: 'chicken_soup_potato',
          rating: 5,
          note: 'Свежая зелень',
          date: fixedNow,
        );

        await historyDao.recordCooked(
          recipeId: 'mashed_potato',
          rating: 4,
          note: 'Сливочное масло',
          date: fixedNow,
        );

        await tester.pumpWidget(_createHistoryTestWidget(db));
        await tester.pumpAndSettle();

        expect(find.text('Куриный суп с картошкой'), findsOneWidget);
        expect(find.text('Картофельное пюре'), findsOneWidget);

        // Filter by note keyword
        await tester.enterText(find.byType(TextField).first, 'Сливочное');
        await tester.pumpAndSettle();

        expect(find.text('Картофельное пюре'), findsOneWidget);
        expect(find.text('Куриный суп с картошкой'), findsNothing);

        // Clear search
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        expect(find.text('Куриный суп с картошкой'), findsOneWidget);
        expect(find.text('Картофельное пюре'), findsOneWidget);
      });
    });

    testWidgets('filter chips filter entries by dish type', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedNow = DateTime(2026, 11, 4, 12, 0);

      await withClock(Clock.fixed(fixedNow), () async {
        final historyDao = HistoryDao(db);

        await historyDao.recordCooked(
          recipeId: 'chicken_soup_potato',
          date: fixedNow,
        );

        await historyDao.recordCooked(
          recipeId: 'mashed_potato',
          date: fixedNow,
        );

        await tester.pumpWidget(_createHistoryTestWidget(db));
        await tester.pumpAndSettle();

        // Tap filter chip "Суп"
        final soupChip = find.widgetWithText(FilterChip, 'Суп');
        await tester.tap(soupChip);
        await tester.pumpAndSettle();

        expect(find.text('Куриный суп с картошкой'), findsOneWidget);
        expect(find.text('Картофельное пюре'), findsNothing);

        // Reset to "Все"
        final allChip = find.widgetWithText(FilterChip, 'Все');
        await tester.tap(allChip);
        await tester.pumpAndSettle();

        expect(find.text('Куриный суп с картошкой'), findsOneWidget);
        expect(find.text('Картофельное пюре'), findsOneWidget);
      });
    });

    testWidgets(
      'soft delete removes entry with 5-second SnackBar and undo restores it',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fixedNow = DateTime(2026, 11, 4, 12, 0);

        await withClock(Clock.fixed(fixedNow), () async {
          final historyDao = HistoryDao(db);

          await historyDao.recordCooked(
            recipeId: 'chicken_soup_potato',
            date: fixedNow,
          );

          await tester.pumpWidget(_createHistoryTestWidget(db));
          await tester.pumpAndSettle();

          expect(find.text('Куриный суп с картошкой'), findsOneWidget);

          // Tap delete button on the card
          await tester.tap(find.byIcon(Icons.delete_outline).first);
          await tester.pumpAndSettle();

          // Entry is gone from list
          expect(find.text('Куриный суп с картошкой'), findsNothing);

          // SnackBar is shown with "Отменить"
          expect(find.text('Запись удалена из истории'), findsOneWidget);
          expect(find.text('Отменить'), findsOneWidget);

          // Tap undo
          await tester.tap(find.text('Отменить'));
          await tester.pumpAndSettle();

          // Entry is restored in list
          expect(find.text('Куриный суп с картошкой'), findsOneWidget);
        });
      },
    );

    testWidgets('manual dish addition creates entry and user recipe', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fixedNow = DateTime(2026, 11, 4, 12, 0);

      await withClock(Clock.fixed(fixedNow), () async {
        await tester.pumpWidget(_createHistoryTestWidget(db));
        await tester.pumpAndSettle();

        // Open add dish dialog via the button of the empty history view
        await tester.tap(find.widgetWithText(OutlinedButton, 'Записать блюдо'));
        await tester.pumpAndSettle();

        expect(find.text('Записать приготовленное'), findsOneWidget);

        // Enter dish title
        final titleField = find.widgetWithText(
          TextField,
          'Например, Домашние оладьи',
        );
        await tester.enterText(titleField, 'Бабушкины драники');
        await tester.pumpAndSettle();

        // Tap save button
        final saveButton = find.widgetWithText(FilledButton, 'Сохранить');
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Modal closed, dish appears in list
        expect(find.text('Записать приготовленное'), findsNothing);
        expect(find.text('Бабушкины драники'), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'Второе'), findsOneWidget);
      });
    });
  });
}
