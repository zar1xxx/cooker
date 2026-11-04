import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/pantry/pantry_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _createTestWidget(AppDatabase db) {
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
      home: const PantryScreen(),
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory(), seed: true);
    // Trigger seed
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  group('PantryScreen (S1-03 / TZ 7.2)', () {
    testWidgets(
      'renders search bar, voice button, frequent items, categories and show dishes button',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_createTestWidget(db));
        await tester.pumpAndSettle();

        // Search bar and voice button
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Голос'), findsOneWidget);

        // Sections
        expect(find.text('Часто выбираете'), findsOneWidget);
        expect(find.text('Категории продуктов'), findsOneWidget);

        // Category tiles
        expect(find.text('Овощи'), findsOneWidget);
        expect(find.text('Мясо'), findsOneWidget);

        // Bottom button «Показать блюда (0)» initially
        expect(find.textContaining('Показать блюда'), findsOneWidget);
      },
    );

    testWidgets('toggling frequent ingredient updates pantry and dish count', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_createTestWidget(db));
      await tester.pumpAndSettle();

      // Find frequent chip for "Картофель"
      final chip = find.widgetWithText(FilterChip, 'Картофель');
      expect(chip, findsOneWidget);

      // Tap to toggle on
      await tester.tap(chip);
      await tester.pumpAndSettle();

      // Chip should now be selected
      final filterChipWidget = tester.widget<FilterChip>(chip);
      expect(filterChipWidget.selected, isTrue);

      // Category "Овощи" should show selected count
      expect(find.text('1'), findsWidgets);
    });

    testWidgets(
      'tapping category opens bottom sheet with category ingredients',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_createTestWidget(db));
        await tester.pumpAndSettle();

        // Tap on "Овощи" category
        final vegCategory = find.text('Овощи');
        expect(vegCategory, findsOneWidget);
        await tester.tap(vegCategory);
        await tester.pumpAndSettle();

        // Bottom sheet is visible with close button and ingredient items
        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.text('Морковь'), findsWidgets);

        // Close bottom sheet
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.close), findsNothing);
      },
    );

    testWidgets(
      'search filters ingredients and shows custom prompt for unknown products',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_createTestWidget(db));
        await tester.pumpAndSettle();

        // Enter known search term
        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'морков');
        await tester.pumpAndSettle();

        expect(find.text('Морковь'), findsOneWidget);

        // Enter unknown search term
        await tester.enterText(searchField, 'неведомыйпродукт123');
        await tester.pumpAndSettle();

        expect(find.text('Ничего не нашлось'), findsOneWidget);
        expect(
          find.textContaining('Добавить «неведомыйпродукт123»'),
          findsOneWidget,
        );
      },
    );
  });
}
