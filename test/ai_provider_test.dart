import 'dart:io';

import 'package:chto_prigotovit/core/ai/ai_provider.dart';
import 'package:chto_prigotovit/core/ai/fake_ai_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiProvider and models (S3-01)', () {
    test(
      'AiChatMessage creates system, user, assistant and converts to/from JSON',
      () {
        const msg1 = AiChatMessage.system('You are a chef');
        const msg2 = AiChatMessage.user('Suggest dinner');
        const msg3 = AiChatMessage.assistant('Here is dinner');

        expect(msg1.role, 'system');
        expect(msg1.content, 'You are a chef');
        expect(msg2.role, 'user');
        expect(msg3.role, 'assistant');

        final json = msg1.toJson();
        expect(json, {'role': 'system', 'content': 'You are a chef'});

        final fromJson = AiChatMessage.fromJson(json);
        expect(fromJson.role, msg1.role);
        expect(fromJson.content, msg1.content);
      },
    );

    test('extractJsonPayload strips markdown fences and preamble text', () {
      const rawWrapped = '''
Вот подходящие блюда:
```json
{"dishes": [{"title": "Гречка", "dish_type": "main"}]}
```
Приятного аппетита!
''';
      final extracted = extractJsonPayload(rawWrapped);
      expect(
        extracted,
        '{"dishes": [{"title": "Гречка", "dish_type": "main"}]}',
      );

      const rawPlain = 'Текст до {"key": "value"} текст после';
      expect(extractJsonPayload(rawPlain), '{"key": "value"}');

      const rawArray = 'Список: [{"id": 1}, {"id": 2}]';
      expect(extractJsonPayload(rawArray), '[{"id": 1}, {"id": 2}]');
    });

    test('AiCompletionResponse extracts and decodes json', () {
      const response = AiCompletionResponse(
        rawContent: 'Ответ: ```json\n{"ok": true, "val": 42}\n```',
        model: 'test-model',
        providerName: 'test',
        promptTokens: 10,
        completionTokens: 20,
        totalTokens: 30,
      );

      expect(response.jsonPayload, '{"ok": true, "val": 42}');
      final decoded = response.decodeJson();
      expect(decoded['ok'], isTrue);
      expect(decoded['val'], 42);
    });

    test(
      'AiCompletionResponse decodeJson throws FormatException on invalid json',
      () {
        const brokenResponse = AiCompletionResponse(
          rawContent: '{"title": "incomplete',
          model: 'test-model',
          providerName: 'test',
        );

        expect(
          () => brokenResponse.decodeJson(),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });

  group('FakeAiProvider (S3-01 / spec/fixtures/ai)', () {
    late FakeAiProvider provider;

    setUp(() {
      provider = FakeAiProvider();
    });

    test('loads all 7 standard fixtures from test/fixtures/ai/', () {
      final fixtures = [
        'suggest_dishes_ok.json',
        'suggest_dishes_wrapped.txt',
        'full_recipe_ok.json',
        'full_recipe_allergen.json',
        'full_recipe_undercooked.json',
        'full_recipe_broken.txt',
        'month_plan_week_ok.json',
      ];

      for (final fixture in fixtures) {
        final content = provider.loadFixtureContent(fixture);
        expect(
          content,
          isNotEmpty,
          reason: 'Fixture $fixture must not be empty',
        );
        if (fixture.endsWith('.json')) {
          expect(content.trim().startsWith('{'), isTrue);
        }
      }
    });

    test(
      'queueFixture serves responses in FIFO order and records requests',
      () async {
        provider.queueFixture('suggest_dishes_ok.json');
        provider.queueFixture('full_recipe_ok.json');

        expect(await provider.isAvailable(), isTrue);

        final req1 = const AiChatRequest(
          messages: [AiChatMessage.user('dishes')],
        );
        final res1 = await provider.chat(req1);
        expect(res1.rawContent, contains('Картофельные драники'));
        expect(res1.providerName, 'fake');

        final req2 = const AiChatRequest(
          messages: [AiChatMessage.user('recipe')],
        );
        final res2 = await provider.chat(req2);
        expect(
          res2.rawContent,
          contains('Хрустящие драники из тёртого картофеля'),
        );

        expect(provider.recordedRequests.length, 2);
        expect(provider.lastRequest?.messages.first.content, 'recipe');
      },
    );

    test(
      'extracts valid JSON from suggest_dishes_wrapped.txt fixture',
      () async {
        provider.queueFixture('suggest_dishes_wrapped.txt');

        final res = await provider.chat(
          const AiChatRequest(messages: [AiChatMessage.user('dishes')]),
        );

        final decoded = res.decodeJson();
        expect(decoded.containsKey('dishes'), isTrue);
        final dishes = decoded['dishes'] as List;
        expect(dishes.first['title'], 'Гречка по-купечески');
      },
    );

    test('defaultFixture is returned when queue is empty', () async {
      provider.setDefaultFixture('month_plan_week_ok.json');

      final res = await provider.chat(
        const AiChatRequest(messages: [AiChatMessage.user('plan')]),
      );

      final decoded = res.decodeJson();
      expect(decoded.containsKey('days'), isTrue);
    });

    test('setException throws on chat call', () async {
      provider.setException(const SocketException('Connection refused'));

      expect(
        () => provider.chat(
          const AiChatRequest(messages: [AiChatMessage.user('hi')]),
        ),
        throwsA(isA<SocketException>()),
      );
    });

    test('setAvailable updates isAvailable status', () async {
      expect(await provider.isAvailable(), isTrue);
      provider.setAvailable(false);
      expect(await provider.isAvailable(), isFalse);
    });
  });
}
