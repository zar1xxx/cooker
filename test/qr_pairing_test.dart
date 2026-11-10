import 'dart:convert';

import 'package:chto_prigotovit/core/ai/ai_router.dart';
import 'package:chto_prigotovit/core/ai/ai_settings_service.dart';
import 'package:chto_prigotovit/core/ai/pc_discovery.dart';
import 'package:chto_prigotovit/core/ai/qr_pairing_parser.dart';
import 'package:chto_prigotovit/core/ai/qr_pairing_service.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/settings/qr_scanner_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class _FakePcDiscovery extends PcDiscovery {
  final Set<String> respondingHosts = {};

  @override
  Future<bool> probeHost(
    String host,
    int port, {
    Duration timeout = const Duration(milliseconds: 300),
  }) async {
    return respondingHosts.contains(host);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QR Pairing Parser (R4-11)', () {
    test('isPrivateIpv4 correctly validates RFC1918 addresses', () {
      expect(isPrivateIpv4('10.0.0.1'), isTrue);
      expect(isPrivateIpv4('10.255.255.255'), isTrue);
      expect(isPrivateIpv4('172.16.0.1'), isTrue);
      expect(isPrivateIpv4('172.31.255.255'), isTrue);
      expect(isPrivateIpv4('192.168.0.1'), isTrue);
      expect(isPrivateIpv4('192.168.50.224'), isTrue);

      // Disallowed / Public
      expect(isPrivateIpv4('8.8.8.8'), isFalse);
      expect(isPrivateIpv4('1.1.1.1'), isFalse);
      expect(isPrivateIpv4('127.0.0.1'), isFalse);
      expect(isPrivateIpv4('169.254.1.1'), isFalse);
      expect(isPrivateIpv4('198.18.0.1'), isFalse);
      expect(isPrivateIpv4('198.19.0.1'), isFalse);
      expect(isPrivateIpv4('172.15.0.1'), isFalse);
      expect(isPrivateIpv4('172.32.0.1'), isFalse);
      expect(isPrivateIpv4('not-an-ip'), isFalse);
    });

    test('parses valid payload with full details and gigachat key', () {
      final jsonStr = jsonEncode({
        'app': 'chto-prigotovit',
        'v': 1,
        'hosts': ['192.168.1.100', '10.0.0.5'],
        'port': 1235,
        'model': 'gemma-4-12b',
        'gigachat_key': 'abc123secret',
      });

      final result = parsePairingQr(jsonStr);
      expect(result, isA<QrParseSuccess>());
      final data = (result as QrParseSuccess).data;
      expect(data.hosts, ['192.168.1.100', '10.0.0.5']);
      expect(data.port, 1235);
      expect(data.model, 'gemma-4-12b');
      expect(data.gigaChatKey, 'abc123secret');
    });

    test('filters out public or invalid IPs and keeps only private IPs', () {
      final jsonStr = jsonEncode({
        'app': 'chto-prigotovit',
        'v': 1,
        'hosts': ['8.8.8.8', '192.168.1.20', '198.18.0.1', '10.5.0.1'],
        'port': 1234,
        'model': 'model1',
      });

      final result = parsePairingQr(jsonStr);
      expect(result, isA<QrParseSuccess>());
      final data = (result as QrParseSuccess).data;
      expect(data.hosts, ['192.168.1.20', '10.5.0.1']);
      expect(data.gigaChatKey, isNull);
    });

    test('fails when app is invalid', () {
      final jsonStr = jsonEncode({
        'app': 'another-app',
        'v': 1,
        'hosts': ['192.168.1.10'],
      });
      final result = parsePairingQr(jsonStr);
      expect(result, isA<QrParseFailure>());
      expect(
        (result as QrParseFailure).error,
        contains('не QR-код приложения'),
      );
    });

    test('fails when version is not 1', () {
      final jsonStr = jsonEncode({
        'app': 'chto-prigotovit',
        'v': 2,
        'hosts': ['192.168.1.10'],
      });
      final result = parsePairingQr(jsonStr);
      expect(result, isA<QrParseFailure>());
    });

    test('fails when hosts is empty or missing', () {
      final jsonStr = jsonEncode({
        'app': 'chto-prigotovit',
        'v': 1,
        'hosts': [],
      });
      final result = parsePairingQr(jsonStr);
      expect(result, isA<QrParseFailure>());
      expect((result as QrParseFailure).error, contains('не указаны адреса'));
    });

    test('fails when only public IPs are provided', () {
      final jsonStr = jsonEncode({
        'app': 'chto-prigotovit',
        'v': 1,
        'hosts': ['8.8.8.8', '1.1.1.1', '127.0.0.1'],
      });
      final result = parsePairingQr(jsonStr);
      expect(result, isA<QrParseFailure>());
      expect((result as QrParseFailure).error, contains('публичные IP-адреса'));
    });

    test('fails gracefully on invalid JSON', () {
      final result = parsePairingQr('not a json at all {]');
      expect(result, isA<QrParseFailure>());
    });
  });

  group('QrPairingService (R4-11)', () {
    late _FakePcDiscovery fakeDiscovery;
    late AiSettingsService settingsService;
    late AiRouter router;
    late QrPairingService service;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      fakeDiscovery = _FakePcDiscovery();
      settingsService = AiSettingsService(
        storage: const FlutterSecureStorage(),
      );
      router = AiRouter();
      service = QrPairingService(
        discovery: fakeDiscovery,
        settingsService: settingsService,
        router: router,
      );
    });

    test(
      'selects responding host and applies settings with gigaChatKey',
      () async {
        fakeDiscovery.respondingHosts.add('192.168.1.150');

        const data = QrPairingData(
          hosts: ['192.168.1.10', '192.168.1.150'],
          port: 1235,
          model: 'test-model',
          gigaChatKey: 'test_giga_key',
        );

        final result = await service.applyPairingData(data);

        expect(result.isResponding, isTrue);
        expect(result.host, '192.168.1.150');
        expect(result.port, 1235);
        expect(result.model, 'test-model');
        expect(result.hasGigaChatKey, isTrue);

        final saved = await settingsService.loadSettings();
        expect(saved.lmStudioHost, '192.168.1.150');
        expect(saved.lmStudioPort, 1235);
        expect(saved.lmStudioModel, 'test-model');
        expect(saved.gigaChatAuthKey, 'test_giga_key');

        expect(router.lmStudioProvider?.baseUrl, 'http://192.168.1.150:1235');
        expect(router.lmStudioProvider?.model, 'test-model');
      },
    );

    test('falls back to first host when none respond', () async {
      const data = QrPairingData(
        hosts: ['192.168.1.10', '192.168.1.20'],
        port: 1235,
        model: 'test-model',
      );

      final result = await service.applyPairingData(data);

      expect(result.isResponding, isFalse);
      expect(result.host, '192.168.1.10');
      final saved = await settingsService.loadSettings();
      expect(saved.lmStudioHost, '192.168.1.10');
    });
  });

  group('QrScannerScreen Widget Tests (R4-11)', () {
    late _FakePcDiscovery fakeDiscovery;
    late AiSettingsService settingsService;
    late AiRouter router;
    late void Function(BarcodeCapture capture)? onDetectCallback;
    MobileScannerException? mockScannerError;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      fakeDiscovery = _FakePcDiscovery();
      settingsService = AiSettingsService(
        storage: const FlutterSecureStorage(),
      );
      router = AiRouter();
      onDetectCallback = null;
      mockScannerError = null;
    });

    Widget buildTestScreen({Future<bool> Function()? openSettings}) {
      return ProviderScope(
        overrides: [
          pcDiscoveryProvider.overrideWithValue(fakeDiscovery),
          aiSettingsServiceProvider.overrideWithValue(settingsService),
          aiRouterProvider.overrideWithValue(router),
          qrScannerWidgetBuilderProvider.overrideWithValue((
            context,
            controller,
            onDetect,
            errorBuilder,
          ) {
            onDetectCallback = onDetect;
            if (mockScannerError != null && errorBuilder != null) {
              return errorBuilder(context, mockScannerError!);
            }
            return Container(key: const ValueKey('mock_camera_view'));
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: QrScannerScreen(openSettings: openSettings),
        ),
      );
    }

    testWidgets('renders camera placeholder, viewfinder and hint overlay', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Подключение QR'), findsOneWidget);
      expect(find.byKey(const ValueKey('mock_camera_view')), findsOneWidget);
      expect(find.byKey(const Key('qr_viewfinder_overlay')), findsOneWidget);
      expect(
        find.text('Наведите камеру на QR-код на экране компьютера'),
        findsOneWidget,
      );
    });

    testWidgets(
      'R5-05: renders permission error, hides viewfinder overlay, and Open Settings calls handler',
      (tester) async {
        bool settingsOpened = false;
        mockScannerError = const MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        );

        await tester.pumpWidget(
          buildTestScreen(
            openSettings: () async {
              settingsOpened = true;
              return true;
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Для сканирования QR-кода нужен доступ к камере'),
          findsOneWidget,
        );
        expect(find.text('Открыть настройки'), findsOneWidget);
        expect(find.byIcon(Icons.videocam_off_outlined), findsOneWidget);
        // Viewfinder overlay must NOT be painted when camera error occurs
        expect(find.byKey(const Key('qr_viewfinder_overlay')), findsNothing);

        await tester.tap(find.byKey(const Key('btn_open_app_settings')));
        await tester.pumpAndSettle();
        expect(settingsOpened, isTrue);
      },
    );

    testWidgets(
      'R5-05: renders distinct camera unavailable error and hides viewfinder overlay',
      (tester) async {
        mockScannerError = const MobileScannerException(
          errorCode: MobileScannerErrorCode.unsupported,
        );

        await tester.pumpWidget(buildTestScreen());
        await tester.pumpAndSettle();

        expect(
          find.text('Камера недоступна на этом устройстве'),
          findsOneWidget,
        );
        expect(
          find.text('Для сканирования QR-кода нужен доступ к камере'),
          findsNothing,
        );
        expect(find.byKey(const Key('qr_viewfinder_overlay')), findsNothing);
      },
    );

    testWidgets(
      'successful QR scan probes host, shows success SnackBar and pops',
      (tester) async {
        fakeDiscovery.respondingHosts.add('192.168.1.100');

        await tester.pumpWidget(buildTestScreen());
        await tester.pumpAndSettle();

        expect(onDetectCallback, isNotNull);

        final qrJson = jsonEncode({
          'app': 'chto-prigotovit',
          'v': 1,
          'hosts': ['192.168.1.100'],
          'port': 1235,
          'model': 'gemma-4-12b',
        });

        onDetectCallback!(
          BarcodeCapture(
            barcodes: [Barcode(rawValue: qrJson, format: BarcodeFormat.qrCode)],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('ПК найден: 192.168.1.100'), findsOneWidget);
      },
    );

    testWidgets('scan with non-responding host shows warning SnackBar', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(onDetectCallback, isNotNull);

      final qrJson = jsonEncode({
        'app': 'chto-prigotovit',
        'v': 1,
        'hosts': ['192.168.1.100'],
        'port': 1235,
        'model': 'gemma-4-12b',
      });

      onDetectCallback!(
        BarcodeCapture(
          barcodes: [Barcode(rawValue: qrJson, format: BarcodeFormat.qrCode)],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ПК не отвечает по указанным адресам'), findsOneWidget);
    });

    testWidgets('invalid QR code shows error SnackBar and does not pop', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(onDetectCallback, isNotNull);

      onDetectCallback!(
        const BarcodeCapture(
          barcodes: [
            Barcode(
              rawValue: 'https://google.com',
              format: BarcodeFormat.qrCode,
            ),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Это не QR-код приложения'), findsOneWidget);
      expect(find.byType(QrScannerScreen), findsOneWidget);
    });
  });
}
