import 'dart:convert';

import 'package:chto_prigotovit/core/ai/pc_discovery.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/settings/ai_diagnostics_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_info_plus/network_info_plus.dart';

class _FakeConnectivity extends Fake implements Connectivity {
  List<ConnectivityResult> results = [ConnectivityResult.wifi];

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => results;
}

class _FakeNetworkInfo extends Fake implements NetworkInfo {
  String? wifiIp = '192.168.1.105';

  @override
  Future<String?> getWifiIP() async => wifiIp;
}

class _FakePcDiscovery extends PcDiscovery {
  bool probeResult = true;
  String? discoverResult = '192.168.1.55';

  @override
  Future<bool> probeHost(
    String host,
    int port, {
    Duration timeout = const Duration(milliseconds: 300),
  }) async => probeResult;

  @override
  Future<String?> discover({
    String? savedHost,
    int port = 1234,
    List<int>? candidatePorts,
    bool force = false,
  }) async => discoverResult;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _FakeConnectivity fakeConnectivity;
  late _FakeNetworkInfo fakeNetworkInfo;
  late _FakePcDiscovery fakePcDiscovery;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'ai_lm_studio_host': '192.168.1.55',
      'ai_lm_studio_port': '1234',
      'ai_lm_studio_model': 'qwen2.5-7b',
      'ai_gigachat_auth_key': '',
    });

    db = AppDatabase(NativeDatabase.memory(), seed: false);
    fakeConnectivity = _FakeConnectivity();
    fakeNetworkInfo = _FakeNetworkInfo();
    fakePcDiscovery = _FakePcDiscovery();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestScreen() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        connectivityProvider.overrideWithValue(fakeConnectivity),
        networkInfoProvider.overrideWithValue(fakeNetworkInfo),
        pcDiscoveryProvider.overrideWithValue(fakePcDiscovery),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('ru'),
        home: AiDiagnosticsScreen(),
      ),
    );
  }

  testWidgets('renders all 8 diagnostic steps and title', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.text('Проверка помощника'), findsOneWidget);

    // Verify all 8 step cards are present
    expect(find.byKey(const Key('diagnostic_step_wifi')), findsOneWidget);
    expect(find.byKey(const Key('diagnostic_step_phone_ip')), findsOneWidget);
    expect(find.byKey(const Key('diagnostic_step_pc_found')), findsOneWidget);
    expect(find.byKey(const Key('diagnostic_step_lm_studio')), findsOneWidget);
    expect(
      find.byKey(const Key('diagnostic_step_model_loaded')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('diagnostic_step_gigachat_key')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('diagnostic_step_gigachat_token')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('diagnostic_step_test_query')), findsOneWidget);

    // Re-run button is present
    expect(find.byKey(const Key('btn_run_diagnostics')), findsOneWidget);
  });

  testWidgets('shows success for Wi-Fi, IP, and PC found when connected', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.text('Телефон подключён к Wi-Fi'), findsOneWidget);
    expect(find.text('Адрес телефона: 192.168.1.105'), findsOneWidget);
    expect(find.text('Компьютер найден: 192.168.1.55:1234'), findsOneWidget);
  });

  testWidgets('shows failure when Wi-Fi is disconnected', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    fakeConnectivity.results = [ConnectivityResult.none];
    fakeNetworkInfo.wifiIp = null;
    fakePcDiscovery.probeResult = false;
    fakePcDiscovery.discoverResult = null;

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.text('Телефон не подключён к Wi-Fi'), findsOneWidget);
    expect(find.text('Не удалось определить IP телефона'), findsOneWidget);
    expect(find.text('Компьютер не найден в локальной сети'), findsOneWidget);
  });

  testWidgets('renders empty history placeholder when no requests exist', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.text('Запросов пока нет'), findsOneWidget);
  });

  testWidgets('renders last 10 requests from database without secrets/tokens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Seed 12 requests in DB
    final secretKey = 'secret_bearer_token_super_confidential_12345';
    for (int i = 0; i < 12; i++) {
      await db
          .into(db.aiRequests)
          .insert(
            AiRequestsCompanion.insert(
              kind: 'suggest_dishes',
              promptHash: 'hash_$i',
              responseJson: i % 2 == 0
                  ? jsonEncode({
                      'dishes': [],
                      'raw_response': 'test_$i $secretKey',
                    })
                  : jsonEncode({
                      'error': 'no_wifi',
                      'message': 'Нет Wi-Fi сети $secretKey',
                    }),
              model: 'qwen2.5-7b',
              status: i % 2 == 0 ? 'ok' : 'error',
              at: drift.Value(1700000000000 + i * 1000),
            ),
          );
    }

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    // Verify exactly 10 history items rendered (not 12)
    final historyItemFinder = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith('history_request_'),
    );
    expect(historyItemFinder, findsNWidgets(10));

    // Verify chips for ok and error
    expect(find.text('Успех'), findsWidgets);
    expect(find.text('Ошибка'), findsWidgets);

    // CRITICAL: Ensure secret token is NEVER displayed
    expect(find.textContaining('super_confidential'), findsNothing);
    expect(find.textContaining(secretKey), findsNothing);
  });

  testWidgets('re-run button triggers diagnostic execution', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    final rerunButton = find.byKey(const Key('btn_run_diagnostics'));
    expect(rerunButton, findsOneWidget);

    await tester.tap(rerunButton);
    await tester.pump(); // starts running
    await tester.pumpAndSettle(); // settles

    expect(find.text('Телефон подключён к Wi-Fi'), findsOneWidget);
  });
}
