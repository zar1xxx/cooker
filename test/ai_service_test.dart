import 'dart:convert';
import 'dart:io';

import 'package:chto_prigotovit/core/ai/ai_failure.dart';
import 'package:chto_prigotovit/core/ai/ai_provider.dart';
import 'package:chto_prigotovit/core/ai/ai_router.dart';
import 'package:chto_prigotovit/core/ai/ai_service.dart';
import 'package:chto_prigotovit/core/ai/fake_ai_provider.dart';
import 'package:chto_prigotovit/core/ai/recipe_validator.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

class _SimpleRouter extends AiRouter {
  _SimpleRouter(this._provider);
  final AiProvider? _provider;

  @override
  Future<({AiProvider? provider, AiFailure? failure})> determineProvider({
    Duration healthCheckTimeout = const Duration(milliseconds: 1500),
  }) async => (
    provider: _provider,
    failure: _provider == null ? const AiFailure.notConfigured() : null,
  );

  @override
  Future<AiProvider?> getActiveProvider({
    Duration healthCheckTimeout = const Duration(milliseconds: 1500),
  }) async => _provider;

  @override
  Future<AiCompletionResponse> executeChatWithFallback(
    AiChatRequest request, {
    String? Function(String content)? validateContent,
    Future<void> Function({
      required String provider,
      required String status,
      required String responseJson,
    })?
    onAttempt,
  }) async {
    final p = _provider;
    if (p == null) throw const AiException(AiFailure.notConfigured());
    return p.chat(request);
  }
}

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

  group('AiService.suggestDishes (S3-06)', () {
    test('returns dishes list when AI responds with valid json', () async {
      final fake = FakeAiProvider(defaultFixtureName: 'suggest_dishes_ok.json');
      final router = _SimpleRouter(fake);
      final service = AiService(router: router, validator: validator, db: db);

      final result = await service.suggestDishes(
        availableIngredients: ['картофель', 'лук', 'яйца'],
      );

      expect(result.isSuccess, isTrue);
      final dishes = result.data;
      expect(dishes, isNotEmpty);
      expect(dishes.length, equals(2));
      expect(dishes.first.title, equals('Картофельные драники'));
      expect(dishes.first.dishType, equals('main'));
      expect(dishes.first.totalMinutes, equals(40));

      // Verify request logged to ai_requests table
      final requests = await db.select(db.aiRequests).get();
      expect(requests.length, equals(1));
      expect(requests.first.kind, equals('suggest_dishes'));
      expect(requests.first.status, equals('ok'));
    });

    test(
      'retries once when first response is invalid JSON, succeeds on second',
      () async {
        final fake = FakeAiProvider();
        fake.queueResponse(
          'Вот блюда: {"dishes": [{"title": "Х", "dish_type": "invalid"}]}',
        ); // invalid
        fake.queueFixture('suggest_dishes_ok.json'); // valid retry

        final router = _SimpleRouter(fake);
        final service = AiService(router: router, validator: validator, db: db);

        final result = await service.suggestDishes(
          availableIngredients: ['картофель', 'лук', 'яйца'],
        );

        expect(result.isSuccess, isTrue);
        final dishes = result.data;
        expect(dishes, isNotEmpty);
        expect(dishes.first.title, equals('Картофельные драники'));
        expect(fake.recordedRequests.length, equals(2));
        // Second request mentions rejection error
        expect(
          fake.recordedRequests[1].messages.last.content,
          contains('Ответ отклонён'),
        );
      },
    );

    test('returns failure result without throwing when both attempts fail validation', () async {
      final fake = FakeAiProvider();
      fake.queueResponse('Некорректный ответ ИИ');
      fake.queueResponse('Ещё один некорректный ответ');

      final router = _SimpleRouter(fake);
      final service = AiService(router: router, validator: validator, db: db);

      final result = await service.suggestDishes(
        availableIngredients: ['картофель'],
      );

      expect(result.isFailure, isTrue);
      expect(result.failure, isA<AiFailureRejected>());
      expect(fake.recordedRequests.length, equals(2));
    });

    test('returns failure when offline (no active provider)', () async {
      final router = _SimpleRouter(null);
      final service = AiService(router: router, validator: validator, db: db);

      final result = await service.suggestDishes(
        availableIngredients: ['картофель'],
      );

      expect(result.isFailure, isTrue);
      expect(result.failure, isA<AiFailureNotConfigured>());
    });
  });

  group('AiService.fullRecipe (S3-06)', () {
    test('returns recipe map when AI responds with valid recipe', () async {
      final fake = FakeAiProvider(defaultFixtureName: 'full_recipe_ok.json');
      final router = _SimpleRouter(fake);
      final service = AiService(router: router, validator: validator, db: db);

      final result = await service.fullRecipe(
        title: 'Картофельные драники',
        dishType: 'main',
        difficulty: 'medium',
        mainIngredients: ['картофель', 'лук', 'яйца'],
        availableIngredients: ['картофель', 'лук', 'яйца', 'мука'],
      );

      expect(result.isSuccess, isTrue);
      final recipe = result.data;
      expect(recipe['title'], equals('Картофельные драники'));
      expect((recipe['steps'] as List).length, equals(3));
    });

    test(
      'retries once when undercooked recipe received, succeeds on retry',
      () async {
        final fake = FakeAiProvider();
        fake.queueFixture(
          'full_recipe_undercooked.json',
        ); // retryable (chicken 3 min)
        fake.queueFixture('full_recipe_ok.json'); // valid retry

        final router = _SimpleRouter(fake);
        final service = AiService(router: router, validator: validator, db: db);

        final result = await service.fullRecipe(
          title: 'Курица на сковороде',
          dishType: 'main',
          difficulty: 'easy',
          mainIngredients: ['куриное филе'],
          availableIngredients: ['куриное филе', 'соль'],
          resolveIngredientId: (name) =>
              name == 'куриное филе' ? 'chicken_fillet' : null,
        );

        expect(result.isSuccess, isTrue);
        expect(fake.recordedRequests.length, equals(2));
        expect(
          fake.recordedRequests[1].messages.last.content,
          contains('Рецепт отклонён'),
        );
      },
    );

    test('returns failure without throwing when offline', () async {
      final router = _SimpleRouter(null);
      final service = AiService(router: router, validator: validator, db: db);

      final result = await service.fullRecipe(
        title: 'Борщ',
        dishType: 'soup',
        difficulty: 'medium',
        mainIngredients: ['говядина'],
        availableIngredients: ['говядина'],
      );

      expect(result.isFailure, isTrue);
      expect(result.failure, isA<AiFailureNotConfigured>());
    });
  });

  group('AiService saving and token accounting', () {
    test('saveAiRecipeToDatabase inserts recipe, ingredients, and steps with source=ai', () async {
      final recipeJson = _loadJson('test/fixtures/ai/full_recipe_ok.json');
      final router = _SimpleRouter(FakeAiProvider());
      final service = AiService(router: router, validator: validator, db: db);

      final saved = await service.saveAiRecipeToDatabase(
        recipeJson,
        aiModel: 'test-model',
      );

      expect(saved, isNotNull);
      expect(saved!.title, equals('Картофельные драники'));
      expect(saved.source, equals(RecipeSource.ai));
      expect(saved.aiModel, equals('test-model'));
      expect(saved.fingerprint, contains('main:'));

      final ings = await (db.select(
        db.recipeIngredients,
      )..where((tbl) => tbl.recipeId.equals(saved.id))).get();
      expect(ings.length, equals(7));

      final steps = await (db.select(
        db.recipeSteps,
      )..where((tbl) => tbl.recipeId.equals(saved.id))).get();
      expect(steps.length, equals(3));
    });

    test('getMonthlyTokensUsed sums tokens from ai_requests', () async {
      final fake = FakeAiProvider(defaultFixtureName: 'suggest_dishes_ok.json');
      final router = _SimpleRouter(fake);
      final service = AiService(router: router, validator: validator, db: db);

      await service.suggestDishes(availableIngredients: ['картофель']);
      await service.suggestDishes(availableIngredients: ['морковь']);

      final tokens = await service.getMonthlyTokensUsed();
      expect(tokens, greaterThan(0));
    });
  });
}
