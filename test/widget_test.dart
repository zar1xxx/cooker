import 'package:chto_prigotovit/app/app.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/core/services/daily_notification_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'daily_notification_service_test.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru', null);
  });

  testWidgets('App smoke test loads with Russian localization and theme', (
    WidgetTester tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory(), seed: false);
    await db.customSelect('SELECT 1').get();
    addTearDown(db.close);

    final fakeNotifService = DailyNotificationService(
      plugin: RecordingNotificationPlugin(),
      storage: FakeSecureStorage(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          dailyNotificationServiceProvider.overrideWithValue(fakeNotifService),
        ],
        child: const ChtoPrigotovitApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Сегодня'), findsWidgets);
  });
}
