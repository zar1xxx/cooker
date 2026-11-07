import 'dart:convert';
import 'dart:typed_data';

import 'package:chto_prigotovit/core/ai/ai_failure.dart';
import 'package:chto_prigotovit/core/ai/ai_provider.dart';
import 'package:chto_prigotovit/core/ai/lm_studio_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  MockHttpClientAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _createJsonResponse(
  Map<String, dynamic> data, {
  int statusCode = 200,
}) {
  final bytes = utf8.encode(jsonEncode(data));
  return ResponseBody.fromBytes(
    bytes,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  group('LmStudioProvider (S3-02)', () {
    test(
      'isPrivateOrLocalHost identifies private addresses and rejects public',
      () {
        expect(isPrivateOrLocalHost('localhost'), isTrue);
        expect(isPrivateOrLocalHost('127.0.0.1'), isTrue);
        expect(isPrivateOrLocalHost('::1'), isTrue);
        expect(isPrivateOrLocalHost('desktop.local'), isTrue);
        expect(isPrivateOrLocalHost('192.168.1.15'), isTrue);
        expect(isPrivateOrLocalHost('10.0.0.1'), isTrue);
        expect(isPrivateOrLocalHost('172.16.0.1'), isTrue);
        expect(isPrivateOrLocalHost('172.31.255.255'), isTrue);

        expect(isPrivateOrLocalHost('8.8.8.8'), isFalse);
        expect(isPrivateOrLocalHost('api.openai.com'), isFalse);
        expect(isPrivateOrLocalHost('gigachat.devices.sberbank.ru'), isFalse);
        expect(isPrivateOrLocalHost('172.32.0.1'), isFalse);
        expect(isPrivateOrLocalHost('1.1.1.1'), isFalse);
      },
    );

    test('cleartext HTTP is rejected for public addresses', () {
      final dio = Dio();
      final publicProvider = LmStudioProvider(
        baseUrl: 'http://8.8.8.8:1234',
        dio: dio,
      );

      expect(() => publicProvider.getModels(), throwsA(isA<ArgumentError>()));
      expect(
        () => publicProvider.chat(
          const AiChatRequest(messages: [AiChatMessage.user('hi')]),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getModels calls /v1/models and returns model list', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        expect(options.path, 'http://192.168.1.100:1234/v1/models');
        expect(options.method, 'GET');
        return _createJsonResponse({
          'data': [
            {'id': 'meta-llama-3-8b-instruct'},
            {'id': 'mistral-7b-instruct-v0.3'},
          ],
        });
      });

      final provider = LmStudioProvider(
        baseUrl: 'http://192.168.1.100:1234',
        dio: dio,
      );

      final models = await provider.getModels();
      expect(models, ['meta-llama-3-8b-instruct', 'mistral-7b-instruct-v0.3']);
      expect(await provider.isAvailable(), isTrue);
    });

    test(
      'isAvailable returns false when server returns error or is unreachable',
      () async {
        final dio = Dio();
        dio.httpClientAdapter = MockHttpClientAdapter((options) async {
          throw DioException(
            requestOptions: options,
            error: 'Connection refused',
            type: DioExceptionType.connectionError,
          );
        });

        final provider = LmStudioProvider(
          baseUrl: 'http://192.168.1.100:1234',
          dio: dio,
        );

        expect(await provider.isAvailable(), isFalse);
      },
    );

    test(
      'chat passes messages, temperature and json_schema response_format',
      () async {
        final dio = Dio();
        RequestOptions? capturedOptions;

        dio.httpClientAdapter = MockHttpClientAdapter((options) async {
          capturedOptions = options;
          return _createJsonResponse({
            'model': 'qwen2.5-7b',
            'choices': [
              {
                'index': 0,
                'message': {
                  'role': 'assistant',
                  'content': '{"dishes": [{"title": "Борщ"}]}',
                },
              },
            ],
            'usage': {
              'prompt_tokens': 120,
              'completion_tokens': 45,
              'total_tokens': 165,
            },
          });
        });

        final provider = LmStudioProvider(
          baseUrl: 'http://192.168.1.100:1234/',
          model: 'default-model',
          apiKey: 'secret-token',
          dio: dio,
        );

        final schema = {
          'type': 'object',
          'properties': {
            'dishes': {'type': 'array'},
          },
        };

        final response = await provider.chat(
          AiChatRequest(
            messages: const [
              AiChatMessage.system('You are a chef'),
              AiChatMessage.user('Suggest dishes'),
            ],
            model: 'qwen2.5-7b',
            temperature: 0.5,
            jsonSchema: schema,
            schemaName: 'suggest_dishes',
          ),
        );

        expect(capturedOptions, isNotNull);
        expect(
          capturedOptions!.path,
          'http://192.168.1.100:1234/v1/chat/completions',
        );
        expect(
          capturedOptions!.headers['Authorization'],
          'Bearer secret-token',
        );

        final body = capturedOptions!.data as Map<String, dynamic>;
        expect(body['model'], 'qwen2.5-7b');
        expect(body['temperature'], 0.5);
        expect(body['stream'], isFalse);
        expect(body['messages'], [
          {'role': 'system', 'content': 'You are a chef'},
          {'role': 'user', 'content': 'Suggest dishes'},
        ]);

        final respFormat = body['response_format'] as Map<String, dynamic>;
        expect(respFormat['type'], 'json_schema');
        expect(respFormat['json_schema']['name'], 'suggest_dishes');
        expect(respFormat['json_schema']['strict'], isTrue);
        expect(respFormat['json_schema']['schema'], schema);

        expect(response.rawContent, '{"dishes": [{"title": "Борщ"}]}');
        expect(response.model, 'qwen2.5-7b');
        expect(response.providerName, 'lm_studio');
        expect(response.promptTokens, 120);
        expect(response.completionTokens, 45);
        expect(response.totalTokens, 165);
        expect(response.decodeJson()['dishes'], isNotEmpty);
      },
    );

    group('R3-05: Auto-select LM Studio model', () {
      test('automatically selects first non-embed model when model is not configured and caches it', () async {
        final dio = Dio();
        int modelsCallCount = 0;
        RequestOptions? capturedChatOptions;

        dio.httpClientAdapter = MockHttpClientAdapter((options) async {
          if (options.path.endsWith('/v1/models')) {
            modelsCallCount++;
            return _createJsonResponse({
              'data': [
                {'id': 'text-embedding-nomic-embed-text-v1.5'},
                {'id': 'qwen2.5-7b-instruct'},
                {'id': 'meta-llama-3-8b'},
              ],
            });
          } else if (options.path.endsWith('/v1/chat/completions')) {
            capturedChatOptions = options;
            return _createJsonResponse({
              'choices': [
                {
                  'index': 0,
                  'message': {'role': 'assistant', 'content': 'Готово'},
                },
              ],
            });
          }
          throw DioException(requestOptions: options);
        });

        final provider = LmStudioProvider(
          baseUrl: 'http://192.168.1.100:1234',
          dio: dio,
        );

        expect(provider.model, isNull);
        expect(provider.cachedAutoModel, isNull);

        // 1. First chat query resolves model via /v1/models
        final resp1 = await provider.chat(
          const AiChatRequest(messages: [AiChatMessage.user('Привет')]),
        );

        expect(modelsCallCount, equals(1));
        expect(provider.cachedAutoModel, equals('qwen2.5-7b-instruct'));
        expect(capturedChatOptions, isNotNull);
        final body1 = capturedChatOptions!.data as Map<String, dynamic>;
        expect(body1['model'], equals('qwen2.5-7b-instruct'));
        expect(resp1.model, equals('qwen2.5-7b-instruct'));

        // 2. Second chat query reuses cached model without calling /v1/models again
        await provider.chat(
          const AiChatRequest(messages: [AiChatMessage.user('Ещё раз')]),
        );

        expect(modelsCallCount, equals(1)); // Still 1, didn't re-fetch
      });

      test(
        'throws AiFailure.pcNoModel when /v1/models returns empty list',
        () async {
          final dio = Dio();
          dio.httpClientAdapter = MockHttpClientAdapter((options) async {
            if (options.path.endsWith('/v1/models')) {
              return _createJsonResponse({'data': []});
            }
            throw DioException(requestOptions: options);
          });

          final provider = LmStudioProvider(
            baseUrl: 'http://192.168.1.100:1234',
            dio: dio,
          );

          try {
            await provider.chat(
              const AiChatRequest(messages: [AiChatMessage.user('Привет')]),
            );
            fail('Expected AiException');
          } on AiException catch (e) {
            expect(e.failure, isA<AiFailurePcNoModel>());
            expect(e.failure.code, equals('pc_no_model'));
            expect(
              e.failure.message,
              equals('На компьютере не загружена модель'),
            );
          }

          expect(await provider.isAvailable(), isFalse);
        },
      );

      test(
        'falls back to first model if all models contain embed keyword',
        () async {
          final dio = Dio();
          dio.httpClientAdapter = MockHttpClientAdapter((options) async {
            if (options.path.endsWith('/v1/models')) {
              return _createJsonResponse({
                'data': [
                  {'id': 'all-embed-model-1'},
                  {'id': 'another-embed-model-2'},
                ],
              });
            }
            throw DioException(requestOptions: options);
          });

          final provider = LmStudioProvider(
            baseUrl: 'http://192.168.1.100:1234',
            dio: dio,
          );

          final resolved = await provider.resolveModel();
          expect(resolved, equals('all-embed-model-1'));
          expect(provider.cachedAutoModel, equals('all-embed-model-1'));
        },
      );

      test(
        'does not call /v1/models when model is configured in constructor',
        () async {
          final dio = Dio();
          int modelsCallCount = 0;
          RequestOptions? capturedChatOptions;

          dio.httpClientAdapter = MockHttpClientAdapter((options) async {
            if (options.path.endsWith('/v1/models')) {
              modelsCallCount++;
              return _createJsonResponse({'data': []});
            } else if (options.path.endsWith('/v1/chat/completions')) {
              capturedChatOptions = options;
              return _createJsonResponse({
                'choices': [
                  {
                    'index': 0,
                    'message': {'role': 'assistant', 'content': 'Готово'},
                  },
                ],
              });
            }
            throw DioException(requestOptions: options);
          });

          final provider = LmStudioProvider(
            baseUrl: 'http://192.168.1.100:1234',
            model: 'my-custom-model',
            dio: dio,
          );

          await provider.chat(
            const AiChatRequest(messages: [AiChatMessage.user('Привет')]),
          );

          expect(modelsCallCount, equals(0));
          expect(capturedChatOptions, isNotNull);
          final body = capturedChatOptions!.data as Map<String, dynamic>;
          expect(body['model'], equals('my-custom-model'));
        },
      );
    });
  });
}
