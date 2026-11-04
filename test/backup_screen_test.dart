import 'dart:convert';

import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/backup/backup_service.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/settings/backup_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PreferenceService prefService;
  late HistoryDao historyDao;
  late BackupService backupService;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') return null;
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': ''};
          }
          return null;
        });

    db = AppDatabase(NativeDatabase.memory(), seed: true);
    await db.customSelect('SELECT 1').get();
    prefService = PreferenceService(db);
    historyDao = HistoryDao(db, preferenceService: prefService);
    backupService = BackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestScreen() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        preferenceServiceProvider.overrideWithValue(prefService),
        historyDaoProvider.overrideWithValue(historyDao),
        backupServiceProvider.overrideWithValue(backupService),
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
        home: const BackupScreen(),
      ),
    );
  }

  testWidgets('renders BackupScreen with export and import sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.text('Резервная копия'), findsOneWidget);
    expect(find.text('Экспорт (сохранить)'), findsOneWidget);
    expect(find.text('Скопировать резервную копию'), findsOneWidget);
    expect(find.text('Импорт (восстановить)'), findsOneWidget);
    expect(find.text('Вставить из буфера'), findsOneWidget);
    expect(find.text('Восстановить данные'), findsOneWidget);
  });

  testWidgets('export button generates backup and shows success feedback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await historyDao.recordCooked(
      recipeId: 'chicken_soup_potato',
      rating: 5,
      note: 'Вкусно',
    );

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Скопировать резервную копию'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Export summary badge appears
    expect(find.textContaining('В копии: 1 записей истории'), findsOneWidget);
    // SnackBar appears
    expect(find.textContaining('скопирована в буфер обмена'), findsOneWidget);
  });

  testWidgets('shows validation error when attempting import with empty text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Восстановить данные'));
    await tester.pumpAndSettle();

    expect(
      find.text('Пожалуйста, вставьте текст резервной копии'),
      findsOneWidget,
    );
  });

  testWidgets('import button restores data after confirmation dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Prepare valid backup payload
    final payload = {
      'version': 1,
      'app': 'chto_prigotovit',
      'exported_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      'data': {
        'preference_profile': [],
        'pantry_items': [],
        'cooked_entries': [
          {
            'id': 'test_entry_1',
            'createdAt': 1730700000000,
            'updatedAt': 1730700000000,
            'deletedAt': null,
            'recipeId': 'chicken_soup_potato',
            'cookedOn': '2026-11-04',
            'rating': 5,
            'portions': 2,
            'wouldRepeat': true,
            'note': 'Восстановленная запись',
          },
        ],
        'meal_plan_entries': [],
        'feedback_events': [],
        'recipes': [],
        'recipe_ingredients': [],
        'recipe_steps': [],
        'ingredients': [],
        'ai_requests': [],
      },
    };
    final jsonStr = jsonEncode(payload);

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    // Enter backup JSON
    await tester.enterText(find.byType(TextField), jsonStr);
    await tester.pumpAndSettle();

    // Tap import button
    await tester.tap(find.text('Восстановить данные'));
    await tester.pumpAndSettle();

    // Confirmation dialog
    expect(find.text('Восстановить данные?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Восстановить'));
    await tester.pumpAndSettle();

    // SnackBar with restore success
    expect(
      find.text('Данные успешно восстановлены: 1 записей истории'),
      findsOneWidget,
    );

    // Verify row in database
    final entries = await db.select(db.cookedEntries).get();
    expect(entries.length, 1);
    expect(entries.first.note, 'Восстановленная запись');
  });
}
