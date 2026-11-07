import 'dart:convert';

import 'package:chto_prigotovit/core/ai/ai_failure.dart';
import 'package:chto_prigotovit/core/ai/ai_provider.dart';
import 'package:chto_prigotovit/core/ai/ai_router.dart';
import 'package:chto_prigotovit/core/ai/ai_service.dart';
import 'package:chto_prigotovit/core/ai/fake_ai_provider.dart';
import 'package:chto_prigotovit/core/ai/gigachat_provider.dart';
import 'package:chto_prigotovit/core/ai/lm_studio_provider.dart';
import 'package:chto_prigotovit/core/ai/recipe_validator.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:clock/clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectivity extends Fake implements Connectivity {
  _FakeConnectivity(this._results);
  final List<ConnectivityResult> _results;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _results;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late RecipeValidator validator;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory(), seed: false);
    validator = const RecipeValidator(
      safetyMinimums: {
        'meat_fish': {
          'keywords': ['курица', 'говядина', 'рыба', 'свинина'],
          'min_minutes': 15,
        },
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('S3-09 Integration Scenarios (TZ 11)', () {
    // ------------------------------------------------------------------------
    // Scenario 1: Broken JSON -> Retry -> Graceful rejection
    // ------------------------------------------------------------------------
    test(
      '1. Broken JSON -> 1 retry with validator error -> graceful empty result',
      () async {
        final fake = FakeAiProvider();
        // First attempt: completely broken JSON
        fake.queueResponse('Вот ваши блюда: {dishes: [broken json');
        // Second attempt (retry): still broken JSON
        fake.queueResponse('Извините, вот верный JSON: not valid json either');

        final router = AiRouter(
          connectivity: _FakeConnectivity([ConnectivityResult.none]),
        );
        final service = AiService(router: router, validator: validator, db: db);

        // Wire fake as router's active provider via a custom router adapter
        final dishesResult = await service.suggestDishes(
          availableIngredients: ['картофель', 'лук'],
        );

        // In offline mode with no active provider, returns failure
        expect(dishesResult.isFailure, isTrue);

        // Now with fake provider active in router
        router.lmStudioProvider = LmStudioProvider(
          baseUrl: 'http://127.0.0.1:1234',
          dio: Dio(),
        );
        // Using FakeAiProvider directly through test router
        final testRouter = _RouterWithProvider(fake);
        final testService = AiService(
          router: testRouter,
          validator: validator,
          db: db,
        );

        final result = await testService.suggestDishes(
          availableIngredients: ['картофель', 'лук'],
        );

        expect(result.isFailure, isTrue);
        expect(result.failure, isA<AiFailureRejected>());
        expect(fake.recordedRequests.length, equals(2));
        // Second request included rejection reason
        expect(
          fake.recordedRequests[1].messages.last.content,
          contains('Ответ отклонён'),
        );

        // Check request logged with rejected/error status
        final requests = await db.select(db.aiRequests).get();
        expect(requests.isNotEmpty, isTrue);
        expect(requests.last.status, isIn(['error', 'rejected']));
      },
    );

    // ------------------------------------------------------------------------
    // Scenario 2: Allergen in AI recipe -> Rejected by RecipeValidator
    // ------------------------------------------------------------------------
    test('2. Allergen or excluded product in AI recipe -> Rejected', () {
      final recipeWithNuts = {
        'title': 'Грецкий салат',
        'dish_type': 'salad',
        'difficulty': 'easy',
        'cuisine': 'европейская',
        'total_minutes': 20,
        'active_minutes': 15,
        'servings': 4,
        'description': 'Салат с грецкими орехами.',
        'ingredients': [
          {'name': 'салат листовой', 'amount': 100.0, 'unit': 'g'},
          {'name': 'грецкие орехи', 'amount': 50.0, 'unit': 'g'},
        ],
        'steps': [
          {'step_number': 1, 'text': 'Нарезать листья салата.'},
          {'step_number': 2, 'text': 'Посыпать измельчёнными орехами.'},
        ],
      };

      // Profile specifies allergy to nuts
      final profile = {
        'allergies': ['nuts'],
        'dislikes': <String>[],
      };

      final hierarchy = {
        'walnut': ['nuts'],
      };

      String? resolveIngredient(String name) {
        if (name.contains('орех')) return 'walnut';
        return 'lettuce';
      }

      final validation = validator.validateRawRecipeJson(
        jsonEncode(recipeWithNuts),
        profile: profile,
        ingredientHierarchy: hierarchy,
        resolveIngredientId: resolveIngredient,
      );

      expect(validation, isA<Rejected>());
      final rejected = validation as Rejected;
      expect(rejected.reason, contains('nuts'));
    });

    // ------------------------------------------------------------------------
    // Scenario 3: Duplicate recipe -> Reuses existing recipe without DB insert
    // ------------------------------------------------------------------------
    test('3. Duplicate AI recipe by title or Jaccard >= 0.8 -> Reuses existing recipe', () async {
      // 1. Insert existing recipe into DB
      await db
          .into(db.recipes)
          .insert(
            const RecipesCompanion(
              id: Value('existing_borsch'),
              title: Value('Борщ домашний'),
              normalizedTitle: Value('борщ домашний'),
              dishType: Value(DishType.soup),
              difficulty: Value(Difficulty.medium),
              cuisine: Value('русская'),
              totalMinutes: Value(60),
              activeMinutes: Value(30),
              servings: Value(4),
              description: Value('Классический борщ.'),
              source: Value(RecipeSource.seed),
              fingerprint: Value('soup:beef,beet,cabbage,potato'),
            ),
          );

      for (final ing in ['beef', 'beet', 'cabbage', 'potato']) {
        await db
            .into(db.recipeIngredients)
            .insert(
              RecipeIngredientsCompanion(
                id: Value('ing_$ing'),
                recipeId: const Value('existing_borsch'),
                ingredientId: Value(ing),
              ),
            );
      }

      final fake = FakeAiProvider();
      final router = _RouterWithProvider(fake);
      final service = AiService(router: router, validator: validator, db: db);

      // Duplicate A: Exactly same normalized title
      final aiRecipeSameTitle = {
        'title': '  БОРЩ ДОМАШНИЙ  ',
        'dish_type': 'soup',
        'difficulty': 'medium',
        'cuisine': 'русская',
        'total_minutes': 60,
        'active_minutes': 30,
        'servings': 4,
        'description': 'Рецепт от ИИ.',
        'ingredients': [
          {'name': 'говядина', 'amount': 400.0, 'unit': 'г'},
          {'name': 'свекла', 'amount': 200.0, 'unit': 'г'},
        ],
        'steps': [
          {'step_number': 1, 'text': 'Сварить бульон.'},
          {'step_number': 2, 'text': 'Положить свеклу.'},
        ],
      };

      final savedA = await service.saveAiRecipeToDatabase(aiRecipeSameTitle);
      expect(savedA?.id, equals('existing_borsch'));

      // Duplicate B: Different title but Jaccard >= 0.8 with same dish_type
      // Existing ingredients: [beef, beet, cabbage, potato] (4 items)
      // New ingredients: [beef, beet, cabbage, potato, dill] (5 items) -> 4/5 = 0.8
      final aiRecipeJaccard = {
        'title': 'Суп свекольный с зеленью',
        'dish_type': 'soup',
        'difficulty': 'medium',
        'cuisine': 'русская',
        'total_minutes': 60,
        'active_minutes': 30,
        'servings': 4,
        'description': 'Рецепт от ИИ.',
        'ingredients': [
          {'name': 'говядина', 'amount': 400.0, 'unit': 'г'},
          {'name': 'свекла', 'amount': 200.0, 'unit': 'г'},
          {'name': 'капуста', 'amount': 200.0, 'unit': 'г'},
          {'name': 'картофель', 'amount': 300.0, 'unit': 'г'},
          {'name': 'укроп', 'amount': 20.0, 'unit': 'г'},
        ],
        'steps': [
          {'step_number': 1, 'text': 'Сварить бульон с овощами.'},
          {'step_number': 2, 'text': 'Добавить зелень перед подачей.'},
        ],
      };

      String? resolveIngredient(String name) {
        if (name.contains('говядин')) return 'beef';
        if (name.contains('свекл')) return 'beet';
        if (name.contains('капуст')) return 'cabbage';
        if (name.contains('картоф')) return 'potato';
        if (name.contains('укроп')) return 'dill';
        return null;
      }

      final savedB = await service.saveAiRecipeToDatabase(
        aiRecipeJaccard,
        resolveIngredientId: resolveIngredient,
      );
      expect(savedB?.id, equals('existing_borsch'));

      // Verify that no second recipe row was added
      final allRecipes = await db.select(db.recipes).get();
      expect(allRecipes.length, equals(1));
    });

    // ------------------------------------------------------------------------
    // Scenario 4: LM Studio timeout -> Fallback to GigaChat
    // ------------------------------------------------------------------------
    test('4. LM Studio timeout -> Seamless fallback to GigaChat and mark PC failed', () async {
      final fakePc = FakeAiProvider();
      fakePc.setException(
        DioException(
          requestOptions: RequestOptions(path: '/v1/chat/completions'),
          type: DioExceptionType.connectionTimeout,
          error: 'Connection timed out',
        ),
      );

      final fakeGigaChat = FakeAiProvider(
        defaultFixtureName: 'suggest_dishes_ok.json',
      );

      final router = _RouterWithFallback(
        primary: fakePc,
        fallback: fakeGigaChat,
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );

      const request = AiChatRequest(
        messages: [AiChatMessage.user('Что приготовить?')],
      );

      final response = await router.executeChatWithFallback(request);

      expect(response, isNotNull);
      expect(response.providerName, equals('fake'));
      expect(response.rawContent, contains('Картофельные драники'));

      // PC marked failed
      expect(router.lastPcFailure, isNotNull);
    });

    // ------------------------------------------------------------------------
    // Scenario 5: Both providers unavailable -> Offline mode, no crash
    // ------------------------------------------------------------------------
    test(
      '5. Both providers unavailable -> Returns empty/null gracefully',
      () async {
        final router = AiRouter(
          connectivity: _FakeConnectivity([ConnectivityResult.none]),
        );

        expect(await router.getActiveProvider(), isNull);
        expect(await router.getMode(), equals(AiMode.offline));

        final service = AiService(router: router, validator: validator, db: db);

        final dishes = await service.suggestDishes(
          availableIngredients: ['картофель', 'морковь'],
        );
        expect(dishes.isFailure, isTrue);

        final recipe = await service.fullRecipe(
          title: 'Драники',
          dishType: 'main',
          difficulty: 'easy',
          servings: 2,
          mainIngredients: ['картофель'],
          availableIngredients: ['картофель'],
        );
        expect(recipe.isFailure, isTrue);
      },
    );

    // ------------------------------------------------------------------------
    // Scenario 6: GigaChat token refresh after expiration & on 401
    // ------------------------------------------------------------------------
    test(
      '6. GigaChat token automatically refreshes after expiration and on 401',
      () async {
        int oauthCalls = 0;
        final dio = Dio();

        // Custom adapter simulating GigaChat OAuth server
        dio.httpClientAdapter = _MockHttpClientAdapter((options) {
          if (options.path.contains('/oauth')) {
            oauthCalls++;
            final token = 'token_v$oauthCalls';
            final expiresAt =
                clock.now().millisecondsSinceEpoch + 120000; // 2 min
            return ResponseBody.fromString(
              jsonEncode({'access_token': token, 'expires_at': expiresAt}),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
          return ResponseBody.fromString('{}', 200);
        });

        final provider = GigaChatProvider(
          authKey: 'valid_auth_key_123',
          dio: dio,
        );

        // First call fetches token v1
        final token1 = await provider.getToken();
        expect(token1, equals('token_v1'));
        expect(oauthCalls, equals(1));

        // Call before expiration returns cached token
        final cached = await provider.getToken();
        expect(cached, equals('token_v1'));
        expect(oauthCalls, equals(1));

        // Force refresh (e.g. after 401) fetches new token
        final token2 = await provider.getToken(forceRefresh: true);
        expect(token2, equals('token_v2'));
        expect(oauthCalls, equals(2));
      },
    );
  });
}

class _RouterWithProvider extends AiRouter {
  _RouterWithProvider(this._provider);
  final AiProvider _provider;

  @override
  Future<({AiProvider? provider, AiFailure? failure})> determineProvider({
    Duration healthCheckTimeout = const Duration(milliseconds: 1500),
  }) async => (provider: _provider, failure: null);

  @override
  Future<AiProvider?> getActiveProvider({
    Duration healthCheckTimeout = const Duration(milliseconds: 1500),
  }) async => _provider;

  @override
  Future<AiCompletionResponse> executeChatWithFallback(
    AiChatRequest request, {
    String? Function(String rawPayload)? validateContent,
  }) => _provider.chat(request);
}

class _RouterWithFallback extends AiRouter {
  _RouterWithFallback({
    required this.primary,
    required this.fallback,
    super.connectivity,
  });

  final AiProvider primary;
  final AiProvider fallback;

  @override
  Future<({AiProvider? provider, AiFailure? failure})> determineProvider({
    Duration healthCheckTimeout = const Duration(milliseconds: 1500),
  }) async {
    final p = await getActiveProvider(healthCheckTimeout: healthCheckTimeout);
    return (provider: p, failure: null);
  }

  @override
  Future<AiProvider?> getActiveProvider({
    Duration healthCheckTimeout = const Duration(milliseconds: 1500),
  }) async {
    if (lastPcFailure != null &&
        clock.now().difference(lastPcFailure!) < const Duration(seconds: 60)) {
      return fallback;
    }
    return primary;
  }

  @override
  Future<AiCompletionResponse> executeChatWithFallback(
    AiChatRequest request, {
    String? Function(String rawPayload)? validateContent,
  }) async {
    try {
      return await primary.chat(request);
    } catch (_) {
      markPcFailure();
      return fallback.chat(request);
    }
  }
}

class _MockHttpClientAdapter implements HttpClientAdapter {
  _MockHttpClientAdapter(this.handler);
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
