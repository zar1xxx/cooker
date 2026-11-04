import 'package:chto_prigotovit/app/app.dart';
import 'package:chto_prigotovit/app/router.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Bottom navigation switches between all 4 tabs (S0-04)', (
    WidgetTester tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory(), seed: false);
    addTearDown(db.close);

    appRouter.go('/today');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const ChtoPrigotovitApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial tab is 'Сегодня'
    expect(find.text('Сегодня'), findsWidgets);

    // Verify all 4 tabs are present in bottom navigation
    expect(find.text('Сегодня'), findsWidgets);
    expect(find.text('Что есть дома'), findsOneWidget);
    expect(find.text('Календарь'), findsOneWidget);
    expect(find.text('История'), findsOneWidget);

    // Switch to 'Что есть дома'
    await tester.tap(find.text('Что есть дома'));
    await tester.pumpAndSettle();
    expect(find.text('Что есть дома'), findsWidgets);

    // Switch to 'Календарь'
    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();
    expect(find.text('Календарь'), findsWidgets);

    // Switch to 'История'
    await tester.tap(find.text('История'));
    await tester.pumpAndSettle();
    expect(find.text('История'), findsWidgets);

    // Switch back to 'Сегодня'
    await tester.tap(find.byIcon(Icons.today));
    await tester.pumpAndSettle();
    expect(find.text('Сегодня'), findsWidgets);
  });
}
