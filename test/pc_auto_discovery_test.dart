import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:chto_prigotovit/core/ai/ai_router.dart';
import 'package:chto_prigotovit/core/ai/ai_settings_service.dart';
import 'package:chto_prigotovit/core/ai/lm_studio_provider.dart';
import 'package:chto_prigotovit/core/ai/pc_auto_discovery_service.dart';
import 'package:chto_prigotovit/core/ai/pc_discovery.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_info_plus/network_info_plus.dart';

class _FakeConnectivity extends Fake implements Connectivity {
  _FakeConnectivity(this.current);
  List<ConnectivityResult> current;
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => current;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  void emit(List<ConnectivityResult> results) {
    current = results;
    _controller.add(results);
  }

  void close() {
    _controller.close();
  }
}

class _FakeNetworkInfo extends Fake implements NetworkInfo {
  _FakeNetworkInfo(this.ip);
  String? ip;

  @override
  Future<String?> getWifiIP() async => ip;
}

class _MockHttpClientAdapter implements HttpClientAdapter {
  _MockHttpClientAdapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _createJsonResponse(Map<String, dynamic> data) {
  return ResponseBody.fromBytes(
    utf8.encode(jsonEncode(data)),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PcAutoDiscoveryService (R3-04)', () {
    late _FakeConnectivity connectivity;
    late _FakeNetworkInfo networkInfo;
    late Dio dio;
    late AiSettingsService settingsService;
    late PcDiscovery discovery;
    late AiRouter router;
    late PcAutoDiscoveryService autoDiscovery;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      settingsService = AiSettingsService();
      connectivity = _FakeConnectivity([ConnectivityResult.wifi]);
      networkInfo = _FakeNetworkInfo('192.168.1.15');

      dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        if (options.path.contains('192.168.1.88:1234/v1/models')) {
          return _createJsonResponse({
            'data': [
              {'id': 'qwen2.5-7b-instruct'},
            ],
          });
        }
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
      });

      discovery = PcDiscovery(
        connectivity: connectivity,
        networkInfo: networkInfo,
        dio: dio,
      );

      router = AiRouter(connectivity: connectivity);

      autoDiscovery = PcAutoDiscoveryService(
        discovery: discovery,
        settingsService: settingsService,
        router: router,
        connectivity: connectivity,
      );
    });

    tearDown(() {
      connectivity.close();
      autoDiscovery.dispose();
    });

    test('empty settings + mock server on subnet -> router selects LM Studio', () async {
      // 1. Initial settings are completely empty
      final initialSettings = await settingsService.loadSettings();
      expect(initialSettings.lmStudioHost, isEmpty);
      expect(router.lmStudioProvider, isNull);

      // 2. Perform auto-discovery (as done on startup)
      final found = await autoDiscovery.checkAndDiscover(force: true);
      expect(found, equals('192.168.1.88'));

      // 3. Settings in storage are updated
      final updatedSettings = await settingsService.loadSettings();
      expect(updatedSettings.lmStudioHost, equals('192.168.1.88'));

      // 4. Router now has LM Studio provider attached
      expect(router.lmStudioProvider, isNotNull);
      expect(
        router.lmStudioProvider!.baseUrl,
        equals('http://192.168.1.88:1234'),
      );

      // 5. router.determineProvider() selects LM Studio!
      // Provide LM Studio provider with mock dio so it responds to health check
      router.lmStudioProvider = LmStudioProvider(
        baseUrl: 'http://192.168.1.88:1234',
        dio: dio,
      );
      final resolution = await router.determineProvider();
      expect(resolution.failure, isNull);
      expect(resolution.provider, equals(router.lmStudioProvider));
      expect(resolution.provider!.name, equals('lm_studio'));
    });

    test('keeps saved host when it responds without scanning subnet', () async {
      FlutterSecureStorage.setMockInitialValues({
        'ai_lm_studio_host': '192.168.1.88',
        'ai_lm_studio_port': '1234',
      });

      final found = await autoDiscovery.checkAndDiscover(force: false);
      expect(found, equals('192.168.1.88'));

      expect(router.lmStudioProvider, isNotNull);
      expect(
        router.lmStudioProvider!.baseUrl,
        equals('http://192.168.1.88:1234'),
      );
    });

    test('does not discover when Wi-Fi is disconnected', () async {
      connectivity.current = [ConnectivityResult.mobile];

      final found = await autoDiscovery.checkAndDiscover(force: true);
      expect(found, isNull);
      expect(router.lmStudioProvider, isNull);
    });

    test(
      'listens to Wi-Fi connectivity changes and triggers discovery',
      () async {
        // Start on mobile: no discovery
        connectivity.current = [ConnectivityResult.mobile];
        autoDiscovery.startListening();

        expect(router.lmStudioProvider, isNull);

        // Switch to Wi-Fi
        connectivity.emit([ConnectivityResult.wifi]);

        // Give the stream event time to process; poll instead of a fixed
        // delay so a loaded machine does not make the test flaky.
        var settings = await settingsService.loadSettings();
        for (var i = 0; i < 40 && settings.lmStudioHost.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          settings = await settingsService.loadSettings();
        }

        // Router should now have discovered and configured the PC
        expect(settings.lmStudioHost, equals('192.168.1.88'));
        expect(router.lmStudioProvider, isNotNull);
      },
    );
  });
}
