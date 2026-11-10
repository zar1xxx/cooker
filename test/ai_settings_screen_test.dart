import 'package:chto_prigotovit/app/router.dart';
import 'package:chto_prigotovit/core/ai/ai_router.dart';
import 'package:chto_prigotovit/core/ai/pc_discovery.dart';
import 'package:chto_prigotovit/core/ai/recipe_validator.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/settings/ai_diagnostics_screen.dart';
import 'package:chto_prigotovit/features/settings/ai_settings_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePcDiscovery extends PcDiscovery {
  String? fakeFoundHost;

  @override
  Future<bool> probeHost(
    String host,
    int port, {
    Duration timeout = const Duration(milliseconds: 300),
  }) async {
    return fakeFoundHost != null;
  }

  @override
  Future<String?> discover({
    String? savedHost,
    int port = 1234,
    List<int>? candidatePorts,
    bool force = false,
  }) async {
    return fakeFoundHost;
  }
}

class _FakeConnectionChecker extends AiConnectionChecker {
  bool pcOk = true;
  bool gigaOk = false;

  @override
  Future<bool> checkPc(String host, int port) async => pcOk;

  @override
  Future<bool> checkGigaChat(String authKey, String baseUrl) async => gigaOk;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _FakePcDiscovery fakeDiscovery;
  late _FakeConnectionChecker fakeChecker;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'ai_lm_studio_host': '192.168.1.55',
      'ai_lm_studio_port': '1234',
      'ai_lm_studio_model': 'qwen2.5-7b',
    });
    db = AppDatabase(NativeDatabase.memory(), seed: false);
    fakeDiscovery = _FakePcDiscovery()..fakeFoundHost = '192.168.1.77';
    fakeChecker = _FakeConnectionChecker();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestScreen({AiRouter? router}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        pcDiscoveryProvider.overrideWithValue(fakeDiscovery),
        aiRouterProvider.overrideWithValue(router ?? AiRouter()),
        aiConnectionCheckerProvider.overrideWithValue(fakeChecker),
        recipeValidatorProvider.overrideWith(
          (ref) async => const RecipeValidator(safetyMinimums: {}),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AiSettingsScreen(),
      ),
    );
  }

  group('AiSettingsScreen (S3-08)', () {
    testWidgets('renders all sections and initial values from storage', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Настройки ИИ'), findsOneWidget);
      expect(find.text('Домашний компьютер (LM Studio)'), findsOneWidget);
      expect(find.text('GigaChat (Сбер)'), findsOneWidget);
      expect(find.text('Найти компьютер'), findsOneWidget);
      expect(find.text('Проверить связь'), findsOneWidget);
      expect(find.text('Сохранить настройки'), findsOneWidget);

      expect(find.text('192.168.1.55'), findsOneWidget);
      expect(find.text('1234'), findsOneWidget);
      expect(find.text('qwen2.5-7b'), findsOneWidget);
    });

    testWidgets('finds PC when clicking "Найти компьютер"', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Найти компьютер'));
      await tester.pumpAndSettle();

      // Should fill with fakeFoundHost '192.168.1.77'
      expect(find.text('192.168.1.77'), findsOneWidget);
      expect(
        find.textContaining('Компьютер найден: 192.168.1.77'),
        findsOneWidget,
      );
    });

    testWidgets('executes check connection and displays status badges', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Проверить связь'));
      await tester.pumpAndSettle();

      expect(find.text('Домашний ПК: подключён'), findsOneWidget);
      expect(find.text('GigaChat: ключ не введён'), findsOneWidget);
    });

    testWidgets('saves settings and displays snackbar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Сохранить настройки'));
      await tester.pumpAndSettle();

      expect(find.text('Настройки успешно сохранены'), findsOneWidget);
    });

    testWidgets(
      'paste button is present and saving cleans GigaChat key (R3-06)',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestScreen());
        await tester.pumpAndSettle();

        final pasteBtn = find.byKey(const Key('btn_paste_gigachat_key'));
        expect(pasteBtn, findsOneWidget);

        // Enter dirty key
        final keyField = find.widgetWithText(
          TextFormField,
          'Авторизационные данные (Client Secret)',
        );
        expect(keyField, findsOneWidget);
        await tester.enterText(keyField, '  "Basic MDE5YzAw...=="\n');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Сохранить настройки'));
        await tester.pumpAndSettle();

        // Check that the storage received the sanitized key without quotes, Basic prefix, or spaces
        final storage = const FlutterSecureStorage();
        final savedKey = await storage.read(key: 'ai_gigachat_auth_key');
        expect(savedKey, equals('MDE5YzAw...=='));
      },
    );

    testWidgets('TodayScreen title long-press navigates to /settings/ai', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            pcDiscoveryProvider.overrideWithValue(fakeDiscovery),
            aiConnectionCheckerProvider.overrideWithValue(fakeChecker),
          ],
          child: MaterialApp.router(
            routerConfig: appRouter,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Long press Today title in AppBar
      final appBarTitle = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Сегодня'),
      );
      expect(appBarTitle, findsOneWidget);

      await tester.longPress(appBarTitle);
      await tester.pumpAndSettle();

      // Navigated to settings screen
      expect(find.text('Настройки ИИ'), findsOneWidget);
    });

    testWidgets('has diagnostics button that navigates to diagnostics screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            pcDiscoveryProvider.overrideWithValue(fakeDiscovery),
            aiConnectionCheckerProvider.overrideWithValue(fakeChecker),
          ],
          child: MaterialApp.router(
            routerConfig: appRouter,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      appRouter.go('/settings/ai');
      await tester.pumpAndSettle();

      final diagBtn = find.byKey(const Key('btn_open_diagnostics'));
      expect(diagBtn, findsOneWidget);

      await tester.tap(diagBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AiDiagnosticsScreen), findsOneWidget);
      expect(find.text('Проверка ИИ'), findsOneWidget);
    });
  });
}
