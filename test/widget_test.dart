import 'package:chto_prigotovit/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test loads with Russian localization and theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ChtoPrigotovitApp()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Сегодня'), findsWidgets);
  });
}
