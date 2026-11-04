import 'dart:convert';
import 'dart:typed_data';

import 'package:chto_prigotovit/core/ai/ai_provider.dart';
import 'package:chto_prigotovit/core/ai/gigachat_provider.dart';
import 'package:clock/clock.dart';
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
  group('GigaChatProvider (S3-03)', () {
    test('enforces HTTPS for baseUrl and oauthUrl', () {
      expect(
        () => GigaChatProvider(
          authKey: 'test-key',
          baseUrl: 'http://gigachat.devices.sberbank.ru',
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => GigaChatProvider(
          authKey: 'test-key',
          oauthUrl: 'http://ngw.devices.sberbank.ru:9443/api/v2/oauth',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getToken fetches token with RqUID and caches until expires_at - 60s', () async {
      int oauthCalls = 0;
      final dio = Dio();
      final baseTime = DateTime(2026, 11, 4, 12, 0);

      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.path.contains('/oauth')) {
          oauthCalls++;
          expect(options.headers['Authorization'], 'Basic my-auth-key');
          expect(options.headers['RqUID'], isNotEmpty);
          expect(options.data, 'scope=GIGACHAT_API_PERS');

          // Token expires in 30 minutes (1800000 ms)
          final expiresAt = baseTime
              .add(const Duration(minutes: 30))
              .millisecondsSinceEpoch;
          return _createJsonResponse({
            'access_token': 'token-$oauthCalls',
            'expires_at': expiresAt,
          });
        }
        throw UnimplementedError();
      });

      final provider = GigaChatProvider(authKey: 'my-auth-key', dio: dio);

      await withClock(Clock.fixed(baseTime), () async {
        // First fetch -> makes network call
        final t1 = await provider.getToken();
        expect(t1, 'token-1');
        expect(oauthCalls, 1);

        // Immediate subsequent call -> returns cached
        final t2 = await provider.getToken();
        expect(t2, 'token-1');
        expect(oauthCalls, 1);

        // 28 minutes later (within expires_at - 60s) -> still cached
        await withClock(
          Clock.fixed(baseTime.add(const Duration(minutes: 28))),
          () async {
            final t3 = await provider.getToken();
            expect(t3, 'token-1');
            expect(oauthCalls, 1);
          },
        );

        // 29 minutes and 10 seconds later (past expires_at - 60s) -> refreshes
        await withClock(
          Clock.fixed(baseTime.add(const Duration(minutes: 29, seconds: 10))),
          () async {
            final t4 = await provider.getToken();
            expect(t4, 'token-2');
            expect(oauthCalls, 2);
          },
        );
      });
    });

    test(
      'chat appends json schema instructions and handles 401 token refresh',
      () async {
        int chatCalls = 0;
        int oauthCalls = 0;
        final dio = Dio();
        final now = DateTime(2026, 11, 4, 12, 0);

        dio.httpClientAdapter = MockHttpClientAdapter((options) async {
          if (options.path.contains('/oauth')) {
            oauthCalls++;
            return _createJsonResponse({
              'access_token': 'fresh-token-$oauthCalls',
              'expires_at': now
                  .add(const Duration(minutes: 30))
                  .millisecondsSinceEpoch,
            });
          }

          if (options.path.contains('/chat/completions')) {
            chatCalls++;
            if (chatCalls == 1) {
              // Simulate expired token returning 401
              return ResponseBody.fromString(
                '{"error": "Unauthorized"}',
                401,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            }

            expect(options.headers['Authorization'], 'Bearer fresh-token-2');
            final body = options.data as Map<String, dynamic>;
            final messages = body['messages'] as List;
            final systemMsg = messages.first as Map<String, dynamic>;
            expect(systemMsg['content'], contains('JSON Schema'));

            return _createJsonResponse({
              'model': 'GigaChat-2',
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': '{"dishes": [{"title": "Драники"}]}',
                  },
                },
              ],
              'usage': {
                'prompt_tokens': 80,
                'completion_tokens': 30,
                'total_tokens': 110,
              },
            });
          }
          throw UnimplementedError(options.path);
        });

        final provider = GigaChatProvider(authKey: 'test-key', dio: dio);

        await withClock(Clock.fixed(now), () async {
          final schema = {
            'type': 'object',
            'properties': {
              'dishes': {'type': 'array'},
            },
          };

          final response = await provider.chat(
            AiChatRequest(
              messages: const [
                AiChatMessage.system('Ты шеф-повар'),
                AiChatMessage.user('Что приготовить?'),
              ],
              jsonSchema: schema,
            ),
          );

          expect(oauthCalls, 2); // initial + refreshed on 401
          expect(chatCalls, 2); // first failed 401, second succeeded
          expect(response.rawContent, contains('Драники'));
          expect(response.decodeJson()['dishes'], isNotEmpty);
          expect(response.promptTokens, 80);
          expect(response.totalTokens, 110);
        });
      },
    );

    test('serializes concurrent chat calls through queue', () async {
      final dio = Dio();
      final order = <int>[];
      int inFlight = 0;
      int maxConcurrent = 0;

      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.path.contains('/oauth')) {
          return _createJsonResponse({
            'access_token': 'valid-token',
            'expires_at': DateTime.now()
                .add(const Duration(minutes: 30))
                .millisecondsSinceEpoch,
          });
        }

        if (options.path.contains('/chat/completions')) {
          inFlight++;
          if (inFlight > maxConcurrent) maxConcurrent = inFlight;

          final id = (options.data as Map)['messages'][0]['content'] as String;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          order.add(int.parse(id));

          inFlight--;
          return _createJsonResponse({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': '{"ok": true}'},
              },
            ],
          });
        }
        throw UnimplementedError();
      });

      final provider = GigaChatProvider(authKey: 'test-key', dio: dio);

      // Launch 3 requests concurrently
      final futures = [
        provider.chat(const AiChatRequest(messages: [AiChatMessage.user('1')])),
        provider.chat(const AiChatRequest(messages: [AiChatMessage.user('2')])),
        provider.chat(const AiChatRequest(messages: [AiChatMessage.user('3')])),
      ];

      await Future.wait(futures);

      expect(maxConcurrent, 1, reason: 'GigaChat requests must be serialized');
      expect(order, [1, 2, 3]);
    });
  });
}
