import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chto_prigotovit/core/ai/ai_failure.dart';
import 'package:chto_prigotovit/core/ai/ai_router.dart';
import 'package:chto_prigotovit/core/ai/ai_service.dart';
import 'package:chto_prigotovit/core/ai/gigachat_provider.dart';
import 'package:chto_prigotovit/core/ai/lm_studio_provider.dart';
import 'package:chto_prigotovit/core/ai/recipe_validator.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectivity extends Fake implements Connectivity {
  _FakeConnectivity(this._results);
  final List<ConnectivityResult> _results;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _results;
}

class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  late RecipeValidator validator;
  late AppDatabase db;

  setUp(() {
    validator = RecipeValidator(
      safetyMinimums: _loadJson('spec/ai/safety_minimums.json'),
    );
    db = AppDatabase(NativeDatabase.memory(), seed: false);
  });

  tearDown(() async {
    await db.close();
  });

  group('R3-01: AiFailure on each reason with mock Dio', () {
    test('1. notConfigured: neither provider is configured', () async {
      final router = AiRouter(
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );
      final service = AiService(router: router, validator: validator, db: db);

      final dishesResult = await service.suggestDishes(
        availableIngredients: ['картофель', 'лук'],
      );

      expect(dishesResult.isFailure, isTrue);
      expect(dishesResult.failure, isA<AiFailureNotConfigured>());
      expect(dishesResult.failure.code, equals('not_configured'));

      final fullResult = await service.fullRecipe(
        title: 'Суп',
        dishType: 'soup',
        difficulty: 'easy',
        mainIngredients: ['картофель'],
        availableIngredients: ['картофель'],
      );

      expect(fullResult.isFailure, isTrue);
      expect(fullResult.failure, isA<AiFailureNotConfigured>());

      final logs = await db.select(db.aiRequests).get();
      expect(logs.length, equals(2));
      expect(logs.first.status, equals('error'));
      expect(logs.first.responseJson, contains('Помощник не настроен'));
    });

    test('2. noWifi: LM Studio configured but device on cellular', () async {
      final dio = Dio();
      final router = AiRouter(
        connectivity: _FakeConnectivity([ConnectivityResult.mobile]),
        lmStudioProvider: LmStudioProvider(
          baseUrl: 'http://192.168.1.100:1234',
          dio: dio,
        ),
      );
      final service = AiService(router: router, validator: validator, db: db);

      final dishesResult = await service.suggestDishes(
        availableIngredients: ['картофель'],
      );

      expect(dishesResult.isFailure, isTrue);
      expect(dishesResult.failure, isA<AiFailureNoWifi>());
      expect(dishesResult.failure.code, equals('no_wifi'));

      final logs = await db.select(db.aiRequests).get();
      expect(logs.last.status, equals('error'));
      expect(logs.last.responseJson, contains('Wi-Fi'));
    });

    test('3. pcNotFound: LM Studio connection refused / unreachable', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockAdapter((options) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'Connection refused',
          error: const SocketException('Connection refused to 192.168.1.100'),
        );
      });

      final router = AiRouter(
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
        lmStudioProvider: LmStudioProvider(
          baseUrl: 'http://192.168.1.100:1234',
          dio: dio,
        ),
      );
      final service = AiService(router: router, validator: validator, db: db);

      final dishesResult = await service.suggestDishes(
        availableIngredients: ['картофель'],
      );

      expect(dishesResult.isFailure, isTrue);
      expect(dishesResult.failure, isA<AiFailurePcNotFound>());
      expect(dishesResult.failure.code, equals('pc_not_found'));

      final logs = await db.select(db.aiRequests).get();
      expect(logs.last.status, equals('error'));
      expect(logs.last.responseJson, contains('Компьютер не найден'));
    });

    test('4. pcNoModel: LM Studio responds with empty models list', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockAdapter((options) {
        if (options.path.endsWith('/v1/models')) {
          return ResponseBody.fromString(
            jsonEncode({'data': []}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('{}', 200);
      });

      final router = AiRouter(
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
        lmStudioProvider: LmStudioProvider(
          baseUrl: 'http://192.168.1.100:1234',
          dio: dio,
        ),
      );
      final service = AiService(router: router, validator: validator, db: db);

      final dishesResult = await service.suggestDishes(
        availableIngredients: ['картофель'],
      );

      expect(dishesResult.isFailure, isTrue);
      expect(dishesResult.failure, isA<AiFailurePcNoModel>());
      expect(dishesResult.failure.code, equals('pc_no_model'));

      final logs = await db.select(db.aiRequests).get();
      expect(logs.last.status, equals('error'));
      expect(logs.last.responseJson, contains('не загружена модель'));
    });

    test(
      '5. gigaChatBadKey: GigaChat OAuth returns 401 unauthorized',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = _MockAdapter((options) {
          if (options.path.contains('/oauth')) {
            return ResponseBody.fromString(
              jsonEncode({'message': 'Invalid client'}),
              401,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
          return ResponseBody.fromString('{}', 200);
        });

        final router = AiRouter(
          connectivity: _FakeConnectivity([ConnectivityResult.mobile]),
          gigaChatProvider: GigaChatProvider(
            authKey: 'invalid-base64-secret-token',
            dio: dio,
          ),
        );
        final service = AiService(router: router, validator: validator, db: db);

        final dishesResult = await service.suggestDishes(
          availableIngredients: ['картофель'],
        );

        expect(dishesResult.isFailure, isTrue);
        expect(dishesResult.failure, isA<AiFailureGigaChatBadKey>());
        expect(dishesResult.failure.code, equals('gigachat_bad_key'));

        final logs = await db.select(db.aiRequests).get();
        expect(logs.last.status, equals('error'));
        // Must not contain the authKey
        expect(logs.last.responseJson, isNot(contains('invalid-base64')));
        expect(logs.last.responseJson, contains('Ключ GigaChat'));
      },
    );

    test('6. gigaChatCert: GigaChat fails with HandshakeException', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockAdapter((options) {
        throw DioException(
          requestOptions: options,
          error: const HandshakeException(
            'CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate',
          ),
          message: 'HandshakeException: CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate',
        );
      });

      final router = AiRouter(
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
        gigaChatProvider: GigaChatProvider(authKey: 'valid-key', dio: dio),
      );
      final service = AiService(router: router, validator: validator, db: db);

      final dishesResult = await service.suggestDishes(
        availableIngredients: ['картофель'],
      );

      expect(dishesResult.isFailure, isTrue);
      expect(dishesResult.failure, isA<AiFailureGigaChatCert>());
      expect(dishesResult.failure.code, equals('gigachat_cert'));

      final logs = await db.select(db.aiRequests).get();
      expect(logs.last.status, equals('error'));
      expect(logs.last.responseJson, contains('сертификат'));
    });

    test('7. noInternet: external GigaChat host unreachable', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockAdapter((options) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'Failed to resolve host ngw.devices.sberbank.ru',
          error: const SocketException('No address associated with hostname'),
        );
      });

      final router = AiRouter(
        connectivity: _FakeConnectivity([ConnectivityResult.mobile]),
        gigaChatProvider: GigaChatProvider(authKey: 'valid-key', dio: dio),
      );
      final service = AiService(router: router, validator: validator, db: db);

      final dishesResult = await service.suggestDishes(
        availableIngredients: ['картофель'],
      );

      expect(dishesResult.isFailure, isTrue);
      expect(dishesResult.failure, isA<AiFailureNoInternet>());
      expect(dishesResult.failure.code, equals('no_internet'));

      final logs = await db.select(db.aiRequests).get();
      expect(logs.last.status, equals('error'));
      expect(logs.last.responseJson, contains('Нет подключения к интернету'));
    });

    test('8. timeout: LM Studio request times out', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockAdapter((options) {
        if (options.path.endsWith('/v1/models')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': [
                {'id': 'qwen2.5-7b'},
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
          message: 'Receive timeout after 60000ms',
        );
      });

      final router = AiRouter(
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
        lmStudioProvider: LmStudioProvider(
          baseUrl: 'http://192.168.1.100:1234',
          dio: dio,
        ),
      );
      final service = AiService(router: router, validator: validator, db: db);

      final dishesResult = await service.suggestDishes(
        availableIngredients: ['картофель'],
      );

      expect(dishesResult.isFailure, isTrue);
      expect(dishesResult.failure, isA<AiFailureTimeout>());
      expect(dishesResult.failure.code, equals('timeout'));

      final logs = await db.select(db.aiRequests).get();
      expect(logs.last.status, equals('error'));
      expect(logs.last.responseJson, contains('ожидания'));
    });

    test('9. badResponse: server returns 500 or broken payload', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockAdapter((options) {
        if (options.path.endsWith('/v1/models')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': [
                {'id': 'qwen2.5-7b'},
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString(
          '{"error": "Internal server crash"}',
          500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final router = AiRouter(
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
        lmStudioProvider: LmStudioProvider(
          baseUrl: 'http://192.168.1.100:1234',
          dio: dio,
        ),
      );
      final service = AiService(router: router, validator: validator, db: db);

      final dishesResult = await service.suggestDishes(
        availableIngredients: ['картофель'],
      );

      expect(dishesResult.isFailure, isTrue);
      expect(dishesResult.failure, isA<AiFailureBadResponse>());
      expect(dishesResult.failure.code, equals('bad_response'));

      final logs = await db.select(db.aiRequests).get();
      expect(logs.last.status, equals('error'));
    });

    test(
      '10. rejected: model returns dishes with toxic / forbidden substance',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = _MockAdapter((options) {
          if (options.path.endsWith('/v1/models')) {
            return ResponseBody.fromString(
              jsonEncode({
                'data': [
                  {'id': 'qwen2.5-7b'},
                ],
              }),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
          // Returns dishes containing toxic substance 'бледная поганка'
          return ResponseBody.fromString(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': jsonEncode({
                      'dishes': [
                        {
                          'title': 'Суп из поганки',
                          'dish_type': 'soup',
                          'difficulty': 'easy',
                          'total_minutes': 30,
                          'main_ingredients': ['бледная поганка', 'вода'],
                          'missing': [],
                          'why': 'Вкусно',
                        },
                      ],
                    }),
                  },
                },
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final router = AiRouter(
          connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
          lmStudioProvider: LmStudioProvider(
            baseUrl: 'http://192.168.1.100:1234',
            dio: dio,
          ),
        );
        final service = AiService(router: router, validator: validator, db: db);

        final dishesResult = await service.suggestDishes(
          availableIngredients: ['вода'],
        );

        expect(dishesResult.isFailure, isTrue);
        expect(dishesResult.failure, isA<AiFailureRejected>());
        expect(dishesResult.failure.code, equals('rejected'));

        final logs = await db.select(db.aiRequests).get();
        expect(logs.last.status, equals('rejected'));
        expect(logs.last.responseJson, contains('бледная поганка'));
      },
    );

    test('11. R5-03: LM Studio timeout -> repeats via GigaChat and records both attempts in ai_requests', () async {
      final lmDio = Dio();
      lmDio.httpClientAdapter = _MockAdapter((options) {
        if (options.path.endsWith('/v1/models')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': [
                {'id': 'qwen2.5-7b'},
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
          message: 'Receive timeout after 45000ms',
        );
      });

      final gigaDio = Dio();
      gigaDio.httpClientAdapter = _MockAdapter((options) {
        if (options.path.contains('/oauth')) {
          return ResponseBody.fromString(
            jsonEncode({
              'access_token': 'giga-token-xyz',
              'expires_at': DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch,
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'dishes': [
                      {
                        'title': 'Плов с курицей',
                        'dish_type': 'main',
                        'difficulty': 'medium',
                        'total_minutes': 45,
                        'main_ingredients': ['рис', 'курица'],
                        'missing': [],
                        'why': 'Из GigaChat',
                      },
                    ],
                  }),
                },
                'finish_reason': 'stop',
              },
            ],
            'model': 'GigaChat-Pro',
            'usage': {'prompt_tokens': 100, 'completion_tokens': 150},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final router = AiRouter(
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
        lmStudioProvider: LmStudioProvider(
          baseUrl: 'http://192.168.1.100:1235',
          dio: lmDio,
        ),
        gigaChatProvider: GigaChatProvider(
          authKey: 'test-gigachat-auth-key',
          dio: gigaDio,
        ),
      );
      final service = AiService(router: router, validator: validator, db: db);

      final dishesResult = await service.suggestDishes(
        availableIngredients: ['рис', 'курица'],
      );

      expect(dishesResult.isSuccess, isTrue);
      expect(dishesResult.data.first.title, equals('Плов с курицей'));

      final logs = await db.select(db.aiRequests).get();
      expect(logs.length, equals(2));
      expect(logs[0].status, equals('error'));
      expect(logs[0].model, equals('lm_studio'));
      expect(logs[0].responseJson, contains('Компьютер долго отвечает'));

      expect(logs[1].status, equals('ok'));
      expect(logs[1].model, equals('GigaChat-Pro'));
      expect(logs[1].responseJson, contains('Плов с курицей'));
    });

    test('12. R5-03: LM Studio connectionError -> repeats via GigaChat and records both attempts in ai_requests', () async {
      final lmDio = Dio();
      lmDio.httpClientAdapter = _MockAdapter((options) {
        if (options.path.endsWith('/v1/models')) {
          return ResponseBody.fromString(
            jsonEncode({
              'data': [
                {'id': 'qwen2.5-7b'},
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'Connection refused',
          error: const SocketException('Connection refused'),
        );
      });

      final gigaDio = Dio();
      gigaDio.httpClientAdapter = _MockAdapter((options) {
        if (options.path.contains('/oauth')) {
          return ResponseBody.fromString(
            jsonEncode({
              'access_token': 'giga-token-xyz',
              'expires_at': DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch,
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'dishes': [
                      {
                        'title': 'Гречневая каша',
                        'dish_type': 'main',
                        'difficulty': 'easy',
                        'total_minutes': 25,
                        'main_ingredients': ['гречка'],
                        'missing': [],
                        'why': 'Быстро и вкусно',
                      },
                    ],
                  }),
                },
                'finish_reason': 'stop',
              },
            ],
            'model': 'GigaChat-Pro',
            'usage': {'prompt_tokens': 100, 'completion_tokens': 120},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final router = AiRouter(
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
        lmStudioProvider: LmStudioProvider(
          baseUrl: 'http://192.168.1.100:1235',
          dio: lmDio,
        ),
        gigaChatProvider: GigaChatProvider(
          authKey: 'test-gigachat-auth-key',
          dio: gigaDio,
        ),
      );
      final service = AiService(router: router, validator: validator, db: db);

      final dishesResult = await service.suggestDishes(
        availableIngredients: ['гречка'],
      );

      expect(dishesResult.isSuccess, isTrue);
      expect(dishesResult.data.first.title, equals('Гречневая каша'));

      final logs = await db.select(db.aiRequests).get();
      expect(logs.length, equals(2));
      expect(logs[0].status, equals('error'));
      expect(logs[0].model, equals('lm_studio'));

      expect(logs[1].status, equals('ok'));
      expect(logs[1].model, equals('GigaChat-Pro'));
      expect(logs[1].responseJson, contains('Гречневая каша'));
    });
  });
}
