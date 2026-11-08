import 'dart:convert';
import 'dart:typed_data';

import 'package:chto_prigotovit/core/ai/ai_provider.dart';
import 'package:chto_prigotovit/core/ai/ai_router.dart';
import 'package:chto_prigotovit/core/ai/gigachat_provider.dart';
import 'package:chto_prigotovit/core/ai/lm_studio_provider.dart';
import 'package:chto_prigotovit/core/ai/pc_discovery.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:clock/clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_info_plus/network_info_plus.dart';

class FakeConnectivity implements Connectivity {
  FakeConnectivity(this.current);
  List<ConnectivityResult> current;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => current;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.value(current);
}

class FakeNetworkInfo implements NetworkInfo {
  FakeNetworkInfo(this.ip);
  String? ip;

  @override
  Future<String?> getWifiIP() async => ip;

  @override
  Future<String?> getWifiBSSID() async => null;
  @override
  Future<String?> getWifiBroadcast() async => null;
  @override
  Future<String?> getWifiGatewayIP() async => null;
  @override
  Future<String?> getWifiName() async => 'TestWiFi';
  @override
  Future<String?> getWifiSubmask() async => '255.255.255.0';
  @override
  Future<String?> getWifiIPv6() async => null;
}

class MockHttpClientAdapter implements HttpClientAdapter {
  MockHttpClientAdapter(this.handler);
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

ResponseBody _createJsonResponse(
  Map<String, dynamic> data, {
  int statusCode = 200,
}) {
  return ResponseBody.fromBytes(
    utf8.encode(jsonEncode(data)),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  group('PcDiscovery (S3-04)', () {
    test('returns null when not connected to Wi-Fi', () async {
      final discovery = PcDiscovery(
        connectivity: FakeConnectivity([ConnectivityResult.mobile]),
        networkInfo: FakeNetworkInfo('192.168.1.55'),
      );

      final result = await discovery.discover(savedHost: '192.168.1.100');
      expect(result, isNull);
    });

    test('probes saved host first and returns if responding', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.path == 'http://192.168.1.100:1234/v1/models') {
          return _createJsonResponse({
            'data': [
              {'id': 'model-1'},
            ],
          });
        }
        throw DioException(requestOptions: options);
      });

      final discovery = PcDiscovery(
        connectivity: FakeConnectivity([ConnectivityResult.wifi]),
        networkInfo: FakeNetworkInfo('192.168.1.55'),
        dio: dio,
      );

      final result = await discovery.discover(savedHost: '192.168.1.100');
      expect(result, '192.168.1.100');
    });

    test(
      'scans subnet and returns found host if savedHost does not respond',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = MockHttpClientAdapter((options) async {
          if (options.path == 'http://192.168.1.15:1234/v1/models') {
            return _createJsonResponse({
              'data': [
                {'id': 'pc-model'},
              ],
            });
          }
          throw DioException(requestOptions: options);
        });

        final discovery = PcDiscovery(
          connectivity: FakeConnectivity([ConnectivityResult.wifi]),
          networkInfo: FakeNetworkInfo('192.168.1.55'),
          dio: dio,
        );

        final result = await discovery.discover(
          savedHost: '192.168.1.99', // doesn't respond
        );
        expect(result, '192.168.1.15');
      },
    );

    test(
      'probeHost configures connectTimeout on Dio options (R1-01)',
      () async {
        Duration? capturedConnectTimeout;
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              capturedConnectTimeout = options.connectTimeout;
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionTimeout,
                ),
              );
            },
          ),
        );
        final discovery = PcDiscovery(
          connectivity: FakeConnectivity([ConnectivityResult.wifi]),
          networkInfo: FakeNetworkInfo('192.168.1.55'),
          dio: dio,
        );

        final result = await discovery.probeHost(
          '192.168.1.100',
          1234,
          timeout: const Duration(milliseconds: 350),
        );
        expect(result, isFalse);
        expect(
          capturedConnectTimeout,
          equals(const Duration(milliseconds: 350)),
        );
      },
    );
  });

  group('AiRouter (S3-04 / TZ 6.1.1)', () {
    late Dio lmDio;
    late Dio gigaDio;
    late LmStudioProvider lmProvider;
    late GigaChatProvider gigaProvider;
    late FakeConnectivity connectivity;
    late AiRouter router;

    setUp(() {
      lmDio = Dio();
      gigaDio = Dio();

      lmProvider = LmStudioProvider(
        baseUrl: 'http://192.168.1.100:1234',
        model: 'llama-3',
        dio: lmDio,
      );
      gigaProvider = GigaChatProvider(authKey: 'test-giga-key', dio: gigaDio);
      connectivity = FakeConnectivity([ConnectivityResult.wifi]);

      router = AiRouter(
        lmStudioProvider: lmProvider,
        gigaChatProvider: gigaProvider,
        connectivity: connectivity,
      );
    });

    test('Wi-Fi and recent PC success selects LM Studio', () async {
      final now = DateTime(2026, 11, 4, 12, 0);

      await withClock(Clock.fixed(now), () async {
        router.markPcSuccess(now.subtract(const Duration(seconds: 25)));

        final provider = await router.getActiveProvider();
        expect(provider, isA<LmStudioProvider>());
        expect(await router.getMode(), AiMode.localPc);
      });
    });

    test(
      'Wi-Fi without recent check performs health-check and succeeds',
      () async {
        lmDio.httpClientAdapter = MockHttpClientAdapter((options) async {
          return _createJsonResponse({
            'data': [
              {'id': 'llama-3'},
            ],
          });
        });

        final provider = await router.getActiveProvider();
        expect(provider, isA<LmStudioProvider>());
        expect(router.lastPcSuccess, isNotNull);
        expect(await router.getMode(), AiMode.localPc);
      },
    );

    test('Wi-Fi with failing health-check marks PC failed and falls back to GigaChat', () async {
      lmDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        throw DioException(requestOptions: options);
      });

      final provider = await router.getActiveProvider();
      expect(provider, isA<GigaChatProvider>());
      expect(router.lastPcFailure, isNotNull);
      expect(await router.getMode(), AiMode.gigaChat);
    });

    test('mobile network selects GigaChat without probing PC', () async {
      connectivity.current = [ConnectivityResult.mobile];
      router.markPcSuccess(); // even if PC was marked successful earlier

      final provider = await router.getActiveProvider();
      expect(provider, isA<GigaChatProvider>());
      expect(await router.getMode(), AiMode.gigaChat);
    });

    test('neither available returns null (offline mode)', () async {
      connectivity.current = [ConnectivityResult.none];
      final emptyGigaProvider = GigaChatProvider(
        authKey: '', // no key
        dio: gigaDio,
      );
      final offlineRouter = AiRouter(
        lmStudioProvider: lmProvider,
        gigaChatProvider: emptyGigaProvider,
        connectivity: connectivity,
      );

      final provider = await offlineRouter.getActiveProvider();
      expect(provider, isNull);
      expect(await offlineRouter.getMode(), AiMode.offline);
    });

    test('executeChatWithFallback switches from LM Studio to GigaChat on network failure', () async {
      // LM Studio fails on chat call
      lmDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.path.contains('/models')) {
          return _createJsonResponse({
            'data': [
              {'id': 'llama-3'},
            ],
          });
        }
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
      });

      // GigaChat succeeds
      gigaDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.path.contains('/oauth')) {
          return _createJsonResponse({
            'access_token': 'giga-token',
            'expires_at': DateTime.now()
                .add(const Duration(minutes: 30))
                .millisecondsSinceEpoch,
          });
        }
        return _createJsonResponse({
          'choices': [
            {
              'message': {'content': '{"dish": "Борщ"}'},
            },
          ],
        });
      });

      final response = await router.executeChatWithFallback(
        const AiChatRequest(messages: [AiChatMessage.user('Dinner')]),
      );

      expect(response, isNotNull);
      expect(response.providerName, 'gigachat');
      expect(response.rawContent, contains('Борщ'));
      expect(router.lastPcFailure, isNotNull);
    });

    test(
      'executeChatWithFallback retries once on format validation failure',
      () async {
        int lmAttempts = 0;
        lmDio.httpClientAdapter = MockHttpClientAdapter((options) async {
          if (options.path.contains('/models')) {
            return _createJsonResponse({
              'data': [
                {'id': 'llama-3'},
              ],
            });
          }
          lmAttempts++;
          if (lmAttempts == 1) {
            // Bad non-json response
            return _createJsonResponse({
              'choices': [
                {
                  'message': {'content': 'Не знаю что ответить'},
                },
              ],
            });
          }
          // Good json response on retry
          return _createJsonResponse({
            'choices': [
              {
                'message': {'content': '{"valid": true}'},
              },
            ],
          });
        });

        final response = await router.executeChatWithFallback(
          const AiChatRequest(messages: [AiChatMessage.user('Hi')]),
          validateContent: (raw) {
            return raw.contains('valid') ? null : 'JSON must contain "valid"';
          },
        );

        expect(response, isNotNull);
        expect(lmAttempts, 2);
        expect(response.rawContent, '{"valid": true}');
      },
    );

    test('executeChatWithFallback switches to GigaChat after LM Studio returns invalid JSON twice and does not mark PC failed (R1-01 / TZ 6.1.1 p.4)', () async {
      int lmCalls = 0;
      lmDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.path.contains('/models')) {
          return _createJsonResponse({
            'data': [
              {'id': 'llama-3'},
            ],
          });
        }
        lmCalls++;
        return _createJsonResponse({
          'choices': [
            {
              'message': {'content': 'Not valid JSON attempt $lmCalls'},
            },
          ],
        });
      });

      gigaDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.path.contains('/oauth')) {
          return _createJsonResponse({
            'access_token': 'giga-token',
            'expires_at': DateTime.now()
                .add(const Duration(minutes: 30))
                .millisecondsSinceEpoch,
          });
        }
        return _createJsonResponse({
          'choices': [
            {
              'message': {'content': '{"dish": "Борщ из GigaChat"}'},
            },
          ],
        });
      });

      final response = await router.executeChatWithFallback(
        const AiChatRequest(messages: [AiChatMessage.user('Dinner')]),
        validateContent: (raw) => raw.contains('dish') ? null : 'Missing dish',
      );

      expect(response, isNotNull);
      expect(response.providerName, 'gigachat');
      expect(response.rawContent, contains('Борщ из GigaChat'));
      expect(lmCalls, 2); // 1 initial + 1 retry before fallback
      expect(
        router.lastPcFailure,
        isNull,
      ); // PC is reachable, format was invalid
    });

    test('R5-07: finish_reason == "length" triggers retry with temperature 0.2 and then falls back to GigaChat', () async {
      int lmCalls = 0;
      final recordedTemperatures = <double>[];
      lmDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.path.contains('/models')) {
          return _createJsonResponse({
            'data': [
              {'id': 'llama-3'},
            ],
          });
        }
        lmCalls++;
        final data = options.data as Map<String, dynamic>;
        recordedTemperatures.add((data['temperature'] as num).toDouble());
        // Return length cutoff twice
        return _createJsonResponse({
          'choices': [
            {
              'message': {'content': '{"dish": "Куриный'},
              'finish_reason': 'length',
            },
          ],
        });
      });

      gigaDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.path.contains('/oauth')) {
          return _createJsonResponse({
            'access_token': 'giga-token',
            'expires_at': DateTime.now()
                .add(const Duration(minutes: 30))
                .millisecondsSinceEpoch,
          });
        }
        return _createJsonResponse({
          'choices': [
            {
              'message': {'content': '{"dish": "Плов из GigaChat"}'},
              'finish_reason': 'stop',
            },
          ],
        });
      });

      final response = await router.executeChatWithFallback(
        const AiChatRequest(
          messages: [AiChatMessage.user('Dinner')],
          temperature: 0.7,
          maxTokens: 1200,
        ),
      );

      expect(response, isNotNull);
      expect(response.providerName, 'gigachat');
      expect(response.rawContent, contains('Плов из GigaChat'));
      expect(lmCalls, 2); // Initial attempt + retry with temp 0.2
      expect(recordedTemperatures, [0.7, 0.2]);
    });

    test(
      'R5-07: max_tokens is present in LM Studio and GigaChat request bodies',
      () async {
        int? capturedLmMaxTokens;
        lmDio.httpClientAdapter = MockHttpClientAdapter((options) async {
          if (options.path.contains('/models')) {
            return _createJsonResponse({
              'data': [
                {'id': 'llama-3'},
              ],
            });
          }
          final data = options.data as Map<String, dynamic>;
          capturedLmMaxTokens = data['max_tokens'] as int?;
          return _createJsonResponse({
            'choices': [
              {
                'message': {'content': '{"ok": true}'},
                'finish_reason': 'stop',
              },
            ],
          });
        });

        final response = await router.executeChatWithFallback(
          const AiChatRequest(
            messages: [AiChatMessage.user('Test')],
            maxTokens: 1200,
          ),
        );

        expect(response.rawContent, contains('{"ok": true}'));
        expect(capturedLmMaxTokens, equals(1200));
      },
    );

    test('R4-02: Router does not wait for 10-second LAN discovery when GigaChat is configured', () async {
      FlutterSecureStorage.setMockInitialValues({
        'ai_gigachat_auth_key': 'test_giga_auth_key',
      });

      final fakeDiscovery = _SlowPcDiscovery(
        delay: const Duration(seconds: 10),
      );

      final container = ProviderContainer(
        overrides: [
          pcDiscoveryProvider.overrideWithValue(fakeDiscovery),
          connectivityProvider.overrideWithValue(
            FakeConnectivity([ConnectivityResult.wifi]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(aiRouterProvider);

      final stopwatch = Stopwatch()..start();
      final provider = await router.getActiveProvider();
      stopwatch.stop();

      // Must resolve to GigaChat immediately without waiting for 10s discovery!
      expect(provider, isNotNull);
      expect(provider!.name, equals('gigachat'));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}

class _SlowPcDiscovery extends PcDiscovery {
  _SlowPcDiscovery({required this.delay});
  final Duration delay;

  @override
  Future<bool> isWifiConnected() async => true;

  @override
  Future<String?> discover({
    String? savedHost,
    int port = 1234,
    List<int>? candidatePorts,
    bool force = false,
  }) async {
    await Future.delayed(delay);
    return null;
  }
}
