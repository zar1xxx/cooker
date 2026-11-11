import 'package:chto_prigotovit/core/widgets/simplified_card_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the template marker shows the badge', () {
    expect(SimplifiedCardBadge.appliesTo('template'), isTrue);
    expect(SimplifiedCardBadge.appliesTo('curated'), isFalse);
    expect(SimplifiedCardBadge.appliesTo(null), isFalse);
  });

  testWidgets('shows the label and opens the explanation on tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SimplifiedCardBadge())),
    );
    expect(find.text('Упрощённая карточка'), findsOneWidget);

    await tester.tap(find.byType(SimplifiedCardBadge));
    await tester.pumpAndSettle();

    expect(find.text(SimplifiedCardBadge.explanation), findsOneWidget);
  });

  testWidgets('compact badge fits a narrow card without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            child: SimplifiedCardBadge(isCompact: true),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
