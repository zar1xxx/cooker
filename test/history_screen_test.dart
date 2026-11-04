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

  group('HistoryScreen (S2-05 / TZ 7.2)', () {
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
      expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);
    });

    testWidgets(
      'renders date-grouped entries with rating, note, type, and cook again button',
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

          // Header for today
          expect(find.textContaining('Сегодня'), findsOneWidget);
          // Header for yesterday
          expect(find.textContaining('Вчера'), findsOneWidget);

          // Titles
          expect(find.text('Куриный суп с картошкой'), findsOneWidget);
          expect(find.text('Картофельное пюре'), findsOneWidget);

          // Types
          expect(find.text('Суп'), findsOneWidget);
          expect(find.text('Гарнир'), findsOneWidget);

          // Ratings
          expect(find.text('Оценка: 5 из 5'), findsOneWidget);
          expect(find.text('Оценка: 4 из 5'), findsOneWidget);

          // Note & wouldRepeat badge
          expect(find.text('Хочу повторить'), findsOneWidget);
          expect(
            find.text('Получилось отлично, добавила зелень'),
            findsOneWidget,
          );

          // Buttons
          expect(find.text('Посмотреть рецепт'), findsNWidgets(2));
        });
      },
    );
  });
}
