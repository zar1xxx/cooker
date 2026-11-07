import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/enums.dart';
import 'ai_failure.dart';
import 'ai_provider.dart';
import 'ai_router.dart';
import 'anti_repeat.dart';
import 'prompts.dart';
import 'recipe_validator.dart';

/// Structured dish suggestion returned by `suggest_dishes` query.
class AiDishSuggestion {
  final String title;
  final String dishType;
  final String difficulty;
  final int totalMinutes;
  final List<String> mainIngredients;
  final List<String> missing;
  final String why;
  final Map<String, dynamic> raw;

  const AiDishSuggestion({
    required this.title,
    required this.dishType,
    required this.difficulty,
    required this.totalMinutes,
    required this.mainIngredients,
    required this.missing,
    required this.why,
    required this.raw,
  });

  factory AiDishSuggestion.fromJson(Map<String, dynamic> json) {
    return AiDishSuggestion(
      title: json['title'] as String? ?? '',
      dishType: json['dish_type'] as String? ?? 'main',
      difficulty: json['difficulty'] as String? ?? 'easy',
      totalMinutes: (json['total_minutes'] as num?)?.toInt() ?? 30,
      mainIngredients: ((json['main_ingredients'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      missing: ((json['missing'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      why: json['why'] as String? ?? '',
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;

  @override
  String toString() =>
      'AiDishSuggestion($title, $dishType, $difficulty, $totalMinutes min)';
}

/// Structured day in a meal plan returned by `month_plan` query.
class AiPlanDay {
  final String date;
  final String title;
  final String dishType;
  final String difficulty;
  final List<String> mainIngredients;
  final Map<String, dynamic> raw;

  const AiPlanDay({
    required this.date,
    required this.title,
    required this.dishType,
    required this.difficulty,
    required this.mainIngredients,
    required this.raw,
  });

  factory AiPlanDay.fromJson(Map<String, dynamic> json) {
    return AiPlanDay(
      date: json['date'] as String? ?? '',
      title: json['title'] as String? ?? '',
      dishType: json['dish_type'] as String? ?? 'main',
      difficulty: json['difficulty'] as String? ?? 'easy',
      mainIngredients: ((json['main_ingredients'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;

  @override
  String toString() => 'AiPlanDay($date: $title, $dishType, $difficulty)';
}

/// Orchestrates AI dish suggestions and full recipe generations with routing,
/// schema validation, automatic retry on invalid JSON, and request journaling.
class AiService {
  AiService({
    required this.router,
    required this.validator,
    PromptTemplates? promptTemplates,
    this.db,
  }) : promptTemplates = promptTemplates ?? PromptTemplates.defaults();

  final AiRouter router;
  final RecipeValidator validator;
  final PromptTemplates promptTemplates;
  final AppDatabase? db;

  /// Requests 5-8 dish suggestions based on available pantry items and profile preferences.
  ///
  /// Adheres to ТЗ 6.2 and `spec/ai/schemas/suggest_dishes.schema.json`.
  /// Performs 1 automatic retry if the model returns invalid JSON.
  /// Returns [AiResult] carrying structured dish suggestions on success or
  /// a concrete [AiFailure] on error without throwing or swallowing.
  Future<AiResult<List<AiDishSuggestion>>> suggestDishes({
    required List<String> availableIngredients,
    List<String> forbiddenIngredients = const [],
    List<String> doNotSuggest = const [],
    String? dishTypeFilter,
    String? difficultyFilter,
    int? maxTotalMinutes,
    List<String> likes = const [],
    List<String> dislikes = const [],
    List<String> topRated = const [],
    int count = 6,
    Map<String, dynamic>? profile,
    Map<String, List<String>>? ingredientHierarchy,
    String? Function(String name)? resolveIngredientId,
    Map<String, List<String>>? forbiddenTerms,
    bool bypassCache = false,
  }) async {
    final database = db;
    // 1. Check cache first unless bypassCache is requested per ТЗ 6.3
    if (!bypassCache && database != null) {
      final cached = await AntiRepeat.getCachedSuggestions(
        database,
        availableIngredientIds: availableIngredients,
        dishTypeFilter: dishTypeFilter,
        difficultyFilter: difficultyFilter,
      );
      if (cached != null && cached.isNotEmpty) {
        return AiResult.success(cached);
      }
    }

    final resolution = await router.determineProvider();
    final activeProvider = resolution.provider;
    if (activeProvider == null) {
      final failure = resolution.failure ?? const AiFailure.notConfigured();
      await _logRequest(
        kind: 'suggest_dishes',
        prompt: 'suggest_dishes',
        responseJson: failure.message,
        model: 'none',
        status: 'error',
      );
      return AiResult.failure(failure);
    }

    // 2. Augment doNotSuggest list from database per ТЗ 6.3
    var fullDoNotSuggest = doNotSuggest;
    if (database != null) {
      final dbDoNotSuggest = await AntiRepeat.getDoNotSuggestList(database);
      fullDoNotSuggest = {...doNotSuggest, ...dbDoNotSuggest}.toList();
    }

    final schema = await AiSchemas.loadSuggestDishesSchema();
    final schemaInPrompt = activeProvider.name == 'gigachat';

    final systemPrompt = promptTemplates.buildSystem(
      schemaJson: jsonEncode(schema),
      schemaInPrompt: schemaInPrompt,
    );

    final userPrompt = promptTemplates.buildSuggestDishes(
      availableIngredients: availableIngredients,
      forbiddenIngredients: forbiddenIngredients,
      doNotSuggest: fullDoNotSuggest,
      dishTypeFilter: dishTypeFilter,
      difficultyFilter: difficultyFilter,
      maxTotalMinutes: maxTotalMinutes,
      likes: likes,
      dislikes: dislikes,
      topRated: topRated,
      count: count,
    );

    final request = AiChatRequest(
      messages: [
        AiChatMessage.system(systemPrompt),
        AiChatMessage.user(userPrompt),
      ],
      jsonSchema: schema,
      schemaName: 'suggest_dishes',
      timeout: activeProvider.name == 'lm_studio'
          ? const Duration(seconds: 60)
          : const Duration(seconds: 30),
    );

    AiCompletionResponse? response;
    try {
      response = await router.executeChatWithFallback(request);
    } catch (e) {
      final failure = e is AiException
          ? e.failure
          : mapExceptionToFailure(
              e,
              isGigaChat: activeProvider.name == 'gigachat',
            );
      await _logRequest(
        kind: 'suggest_dishes',
        prompt: userPrompt,
        responseJson: failure.message,
        model: activeProvider.name,
        status: 'error',
      );
      return AiResult.failure(failure);
    }

    var validation = validator.validateRawDishesJson(
      response.rawContent,
      profile: profile,
      ingredientHierarchy: ingredientHierarchy,
      resolveIngredientId: resolveIngredientId,
      forbiddenTerms: forbiddenTerms,
      attempt: 1,
    );

    // One automatic retry with validator error message per ТЗ 6.2
    if (validation is Retryable) {
      final retryRequest = AiChatRequest(
        messages: [
          AiChatMessage.system(systemPrompt),
          AiChatMessage.user(userPrompt),
          AiChatMessage.assistant(response.rawContent),
          AiChatMessage.user(
            'Ответ отклонён: ${validation.reasonForModel}. Пожалуйста, исправь ошибки и верни строго валидный JSON по схеме.',
          ),
        ],
        jsonSchema: schema,
        schemaName: 'suggest_dishes',
        timeout: const Duration(seconds: 45),
      );

      try {
        final retryResponse = await router.executeChatWithFallback(
          retryRequest,
        );
        response = retryResponse;
        validation = validator.validateRawDishesJson(
          response.rawContent,
          profile: profile,
          ingredientHierarchy: ingredientHierarchy,
          resolveIngredientId: resolveIngredientId,
          forbiddenTerms: forbiddenTerms,
          attempt: 2,
        );
      } catch (e) {
        final failure = e is AiException
            ? e.failure
            : mapExceptionToFailure(
                e,
                isGigaChat: activeProvider.name == 'gigachat',
              );
        await _logRequest(
          kind: 'suggest_dishes',
          prompt: userPrompt,
          responseJson: failure.message,
          model: response?.model ?? activeProvider.name,
          tokensIn: response?.promptTokens,
          tokensOut: response?.completionTokens,
          status: 'error',
        );
        return AiResult.failure(failure);
      }
    }

    if (validation is! Valid) {
      final reason = validation is Rejected
          ? validation.reason
          : (validation is Retryable
                ? validation.reasonForModel
                : 'Некорректный формат блюд');
      final failure = AiFailure.rejected(reason);
      await _logRequest(
        kind: 'suggest_dishes',
        prompt: userPrompt,
        responseJson: failure.message,
        model: response.model,
        tokensIn: response.promptTokens,
        tokensOut: response.completionTokens,
        status: 'rejected',
      );
      return AiResult.failure(failure);
    }

    if (database != null) {
      await AntiRepeat.cacheSuggestions(
        database,
        availableIngredientIds: availableIngredients,
        dishTypeFilter: dishTypeFilter,
        difficultyFilter: difficultyFilter,
        responseJson: response.rawContent,
        model: response.model,
        tokensIn: response.promptTokens,
        tokensOut: response.completionTokens,
      );
    }

    try {
      final decoded = jsonDecode(
        extractJsonPayload(response.rawContent),
      ) as Map<String, dynamic>;
      final dishesRaw = (decoded['dishes'] as List?) ?? const [];
      final dishes = dishesRaw
          .whereType<Map<String, dynamic>>()
          .map(AiDishSuggestion.fromJson)
          .toList();

      return AiResult.success(dishes);
    } catch (_) {
      const failure = AiFailure.badResponse('Не удалось разобрать JSON ответа');
      await _logRequest(
        kind: 'suggest_dishes',
        prompt: userPrompt,
        responseJson: failure.message,
        model: response.model,
        tokensIn: response.promptTokens,
        tokensOut: response.completionTokens,
        status: 'error',
      );
      return const AiResult.failure(failure);
    }
  }

  /// Requests a full recipe for a selected dish suggestion.
  ///
  /// Adheres to ТЗ 6.2 and `spec/ai/schemas/full_recipe.schema.json`.
  /// Performs 1 automatic retry if the model returns invalid JSON or fails safety checks.
  /// Returns [AiResult] carrying recipe JSON map on success or [AiFailure] on error.
  Future<AiResult<Map<String, dynamic>>> fullRecipe({
    required String title,
    required String dishType,
    required String difficulty,
    required List<String> mainIngredients,
    required List<String> availableIngredients,
    int servings = 2,
    List<String> forbiddenIngredients = const [],
    Map<String, dynamic>? profile,
    Map<String, List<String>>? ingredientHierarchy,
    String? Function(String name)? resolveIngredientId,
    Map<String, List<String>>? forbiddenTerms,
  }) async {
    final resolution = await router.determineProvider();
    final activeProvider = resolution.provider;
    if (activeProvider == null) {
      final failure = resolution.failure ?? const AiFailure.notConfigured();
      await _logRequest(
        kind: 'full_recipe',
        prompt: title,
        responseJson: failure.message,
        model: 'none',
        status: 'error',
      );
      return AiResult.failure(failure);
    }

    final schema = await AiSchemas.loadFullRecipeSchema();
    final schemaInPrompt = activeProvider.name == 'gigachat';

    final systemPrompt = promptTemplates.buildSystem(
      schemaJson: jsonEncode(schema),
      schemaInPrompt: schemaInPrompt,
    );

    final userPrompt = promptTemplates.buildFullRecipe(
      title: title,
      dishType: dishType,
      difficulty: difficulty,
      servings: servings,
      mainIngredients: mainIngredients,
      availableIngredients: availableIngredients,
      forbiddenIngredients: forbiddenIngredients,
    );

    final request = AiChatRequest(
      messages: [
        AiChatMessage.system(systemPrompt),
        AiChatMessage.user(userPrompt),
      ],
      jsonSchema: schema,
      schemaName: 'full_recipe',
      timeout: activeProvider.name == 'lm_studio'
          ? const Duration(seconds: 90)
          : const Duration(seconds: 45),
    );

    AiCompletionResponse? response;
    try {
      response = await router.executeChatWithFallback(request);
    } catch (e) {
      final failure = e is AiException
          ? e.failure
          : mapExceptionToFailure(
              e,
              isGigaChat: activeProvider.name == 'gigachat',
            );
      await _logRequest(
        kind: 'full_recipe',
        prompt: userPrompt,
        responseJson: failure.message,
        model: activeProvider.name,
        status: 'error',
      );
      return AiResult.failure(failure);
    }

    var validation = validator.validateRawRecipeJson(
      response.rawContent,
      profile: profile,
      ingredientHierarchy: ingredientHierarchy,
      resolveIngredientId: resolveIngredientId,
      forbiddenTerms: forbiddenTerms,
      attempt: 1,
    );

    // One automatic retry with validator error message per ТЗ 6.2
    if (validation is Retryable) {
      final retryRequest = AiChatRequest(
        messages: [
          AiChatMessage.system(systemPrompt),
          AiChatMessage.user(userPrompt),
          AiChatMessage.assistant(response.rawContent),
          AiChatMessage.user(
            'Рецепт отклонён: ${validation.reasonForModel}. Пожалуйста, исправь ошибки и верни строго валидный JSON по схеме.',
          ),
        ],
        jsonSchema: schema,
        schemaName: 'full_recipe',
        timeout: const Duration(seconds: 60),
      );

      try {
        final retryResponse = await router.executeChatWithFallback(
          retryRequest,
        );
        response = retryResponse;
        validation = validator.validateRawRecipeJson(
          response.rawContent,
          profile: profile,
          ingredientHierarchy: ingredientHierarchy,
          resolveIngredientId: resolveIngredientId,
          forbiddenTerms: forbiddenTerms,
          attempt: 2,
        );
      } catch (e) {
        final failure = e is AiException
            ? e.failure
            : mapExceptionToFailure(
                e,
                isGigaChat: activeProvider.name == 'gigachat',
              );
        await _logRequest(
          kind: 'full_recipe',
          prompt: userPrompt,
          responseJson: failure.message,
          model: response?.model ?? activeProvider.name,
          tokensIn: response?.promptTokens,
          tokensOut: response?.completionTokens,
          status: 'error',
        );
        return AiResult.failure(failure);
      }
    }

    if (validation is! Valid) {
      final reason = validation is Rejected
          ? validation.reason
          : (validation is Retryable
                ? validation.reasonForModel
                : 'Некорректный формат рецепта');
      final failure = AiFailure.rejected(reason);
      await _logRequest(
        kind: 'full_recipe',
        prompt: userPrompt,
        responseJson: failure.message,
        model: response.model,
        tokensIn: response.promptTokens,
        tokensOut: response.completionTokens,
        status: 'rejected',
      );
      return AiResult.failure(failure);
    }

    await _logRequest(
      kind: 'full_recipe',
      prompt: userPrompt,
      responseJson: response.rawContent,
      model: response.model,
      tokensIn: response.promptTokens,
      tokensOut: response.completionTokens,
      status: 'ok',
    );

    try {
      final decoded = jsonDecode(
        extractJsonPayload(response.rawContent),
      ) as Map<String, dynamic>;
      return AiResult.success(decoded);
    } catch (_) {
      const failure = AiFailure.badResponse(
        'Не удалось разобрать JSON рецепта',
      );
      await _logRequest(
        kind: 'full_recipe',
        prompt: userPrompt,
        responseJson: failure.message,
        model: response.model,
        tokensIn: response.promptTokens,
        tokensOut: response.completionTokens,
        status: 'error',
      );
      return const AiResult.failure(failure);
    }
  }

  /// Requests a plan for a week (up to 7 days) adhering to TZ 8.1 and
  /// `spec/ai/schemas/month_plan.schema.json`.
  /// Performs 1 retry if the model returns invalid JSON.
  /// If offline or on failure, returns null without throwing errors.
  Future<List<AiPlanDay>?> generatePlanWeek({
    required String dateFrom,
    required String dateTo,
    List<String> lockedDays = const [],
    List<String> history30d = const [],
    List<String> forbiddenIngredients = const [],
    List<String> likes = const [],
    List<String> dislikes = const [],
    Map<String, double>? dishTypeShares,
    bool soupsDisliked = false,
    Map<String, dynamic>? profile,
    Map<String, List<String>>? ingredientHierarchy,
    String? Function(String name)? resolveIngredientId,
    Map<String, List<String>>? forbiddenTerms,
  }) async {
    final resolution = await router.determineProvider();
    final activeProvider = resolution.provider;
    if (activeProvider == null) {
      final failure = resolution.failure ?? const AiFailure.notConfigured();
      await _logRequest(
        kind: 'month_plan',
        prompt: '$dateFrom - $dateTo',
        responseJson: failure.message,
        model: 'none',
        status: 'error',
      );
      return null;
    }

    final schema = await AiSchemas.loadMonthPlanSchema();
    final schemaInPrompt = activeProvider.name == 'gigachat';

    final systemPrompt = promptTemplates.buildSystem(
      schemaJson: jsonEncode(schema),
      schemaInPrompt: schemaInPrompt,
    );

    final userPrompt = promptTemplates.buildMonthPlan(
      dateFrom: dateFrom,
      dateTo: dateTo,
      lockedDays: lockedDays,
      history30d: history30d,
      forbiddenIngredients: forbiddenIngredients,
      likes: likes,
      dislikes: dislikes,
      dishTypeShares: dishTypeShares,
      soupsDisliked: soupsDisliked,
    );

    final request = AiChatRequest(
      messages: [
        AiChatMessage.system(systemPrompt),
        AiChatMessage.user(userPrompt),
      ],
      jsonSchema: schema,
      schemaName: 'month_plan',
      timeout: const Duration(seconds: 90),
    );

    AiCompletionResponse? response;
    try {
      response = await router.executeChatWithFallback(request);
    } catch (e) {
      final failure = e is AiException
          ? e.failure
          : mapExceptionToFailure(
              e,
              isGigaChat: activeProvider.name == 'gigachat',
            );
      await _logRequest(
        kind: 'month_plan',
        prompt: userPrompt,
        responseJson: failure.message,
        model: activeProvider.name,
        status: 'error',
      );
      return null;
    }

    var validation = validator.validateRawMonthPlanJson(
      response.rawContent,
      profile: profile,
      ingredientHierarchy: ingredientHierarchy,
      resolveIngredientId: resolveIngredientId,
      forbiddenTerms: forbiddenTerms,
      attempt: 1,
    );

    if (validation is Retryable) {
      final retryRequest = AiChatRequest(
        messages: [
          AiChatMessage.system(systemPrompt),
          AiChatMessage.user(userPrompt),
          AiChatMessage.assistant(response.rawContent),
          AiChatMessage.user(
            'План отклонён: ${validation.reasonForModel}. Пожалуйста, исправь ошибки и верни строго валидный JSON по схеме month_plan.',
          ),
        ],
        jsonSchema: schema,
        schemaName: 'month_plan',
        timeout: const Duration(seconds: 90),
      );

      try {
        final retryResponse = await router.executeChatWithFallback(
          retryRequest,
        );
        response = retryResponse;
        validation = validator.validateRawMonthPlanJson(
          response.rawContent,
          profile: profile,
          ingredientHierarchy: ingredientHierarchy,
          resolveIngredientId: resolveIngredientId,
          forbiddenTerms: forbiddenTerms,
          attempt: 2,
        );
      } catch (e) {
        final failure = e is AiException
            ? e.failure
            : mapExceptionToFailure(
                e,
                isGigaChat: activeProvider.name == 'gigachat',
              );
        await _logRequest(
          kind: 'month_plan',
          prompt: userPrompt,
          responseJson: failure.message,
          model: response?.model ?? activeProvider.name,
          tokensIn: response?.promptTokens,
          tokensOut: response?.completionTokens,
          status: 'error',
        );
        return null;
      }
    }

    if (validation is! Valid) {
      final reason = validation is Rejected
          ? validation.reason
          : (validation is Retryable
                ? validation.reasonForModel
                : 'Некорректный формат плана');
      final failure = AiFailure.rejected(reason);
      await _logRequest(
        kind: 'month_plan',
        prompt: userPrompt,
        responseJson: failure.message,
        model: response.model,
        tokensIn: response.promptTokens,
        tokensOut: response.completionTokens,
        status: 'rejected',
      );
      return null;
    }

    await _logRequest(
      kind: 'month_plan',
      prompt: userPrompt,
      responseJson: response.rawContent,
      model: response.model,
      tokensIn: response.promptTokens,
      tokensOut: response.completionTokens,
      status: 'ok',
    );

    try {
      final decoded = jsonDecode(
        extractJsonPayload(response.rawContent),
      ) as Map<String, dynamic>;
      final daysRaw = (decoded['days'] as List?) ?? const [];
      return daysRaw
          .whereType<Map<String, dynamic>>()
          .map(AiPlanDay.fromJson)
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Saves or resolves a recipe for an AI-generated plan day.
  /// If a duplicate/existing recipe is found, reuses it.
  /// Otherwise inserts a stub recipe (with source = ai) and its main ingredients.
  Future<Recipe?> savePlanDayRecipe(
    AiPlanDay day, {
    String? aiModel,
    String? Function(String name)? resolveIngredientId,
  }) async {
    final database = db;
    if (database == null) return null;

    final title = day.title;
    final normalizedTitle = title.toLowerCase().trim();
    final dishTypeStr = day.dishType;
    final difficultyStr = day.difficulty;

    final dishType = DishType.values.byName(dishTypeStr);
    final difficulty = Difficulty.values.byName(difficultyStr);

    final sortedIngIds = <String>[];
    for (final name in day.mainIngredients) {
      var id = '';
      if (resolveIngredientId != null) {
        id = resolveIngredientId(name) ?? '';
      }
      if (id.isEmpty && name.isNotEmpty) {
        id = name.toLowerCase().replaceAll(' ', '_');
      }
      if (id.isNotEmpty) sortedIngIds.add(id);
    }
    sortedIngIds.sort();
    final fingerprint = '$dishTypeStr:${sortedIngIds.take(4).join(',')}';

    final duplicate = await AntiRepeat.findDuplicate(
      database,
      title: title,
      dishType: dishTypeStr,
      ingredientIds: sortedIngIds,
    );
    if (duplicate != null) {
      return duplicate;
    }

    final recipeId = const Uuid().v4();
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;

    return database.transaction(() async {
      await database
          .into(database.recipes)
          .insert(
            RecipesCompanion(
              id: Value(recipeId),
              title: Value(title),
              normalizedTitle: Value(normalizedTitle),
              dishType: Value(dishType),
              difficulty: Value(difficulty),
              cuisine: const Value('домашняя'),
              totalMinutes: const Value(30),
              activeMinutes: const Value(15),
              servings: const Value(2),
              description: const Value(
                'Рецепт для плана на месяц от помощника',
              ),
              source: const Value(RecipeSource.ai),
              fingerprint: Value(fingerprint),
              aiModel: Value(aiModel),
              isFavorite: const Value(false),
              createdAt: Value(nowMs),
              updatedAt: Value(nowMs),
            ),
          );

      for (final name in day.mainIngredients) {
        var id = '';
        if (resolveIngredientId != null) {
          id = resolveIngredientId(name) ?? '';
        }
        if (id.isEmpty && name.isNotEmpty) {
          id = name.toLowerCase().replaceAll(' ', '_');
        }
        if (id.isNotEmpty) {
          await database
              .into(database.recipeIngredients)
              .insert(
                RecipeIngredientsCompanion(
                  id: Value(const Uuid().v4()),
                  recipeId: Value(recipeId),
                  ingredientId: Value(id),
                  amount: const Value(1.0),
                  unit: const Value('to_taste'),
                  isOptional: const Value(false),
                  createdAt: Value(nowMs),
                  updatedAt: Value(nowMs),
                ),
              );
        }
      }

      return (database.select(
        database.recipes,
      )..where((tbl) => tbl.id.equals(recipeId))).getSingle();
    });
  }

  /// Saves an AI-generated recipe to the database (`recipes`, `recipe_ingredients`, `recipe_steps`).
  Future<Recipe?> saveAiRecipeToDatabase(
    Map<String, dynamic> recipeJson, {
    String? aiModel,
    String? Function(String name)? resolveIngredientId,
  }) async {
    final database = db;
    if (database == null) return null;

    final title = recipeJson['title'] as String;
    final normalizedTitle = title.toLowerCase().trim();
    final dishTypeStr = recipeJson['dish_type'] as String? ?? 'main';
    final difficultyStr = recipeJson['difficulty'] as String? ?? 'easy';

    final dishType = DishType.values.byName(dishTypeStr);
    final difficulty = Difficulty.values.byName(difficultyStr);
    final cuisine = recipeJson['cuisine'] as String? ?? 'домашняя';
    final totalMinutes = (recipeJson['total_minutes'] as num?)?.toInt() ?? 30;
    final activeMinutes =
        (recipeJson['active_minutes'] as num?)?.toInt() ?? (totalMinutes ~/ 2);
    final servings = (recipeJson['servings'] as num?)?.toInt() ?? 2;
    final description = recipeJson['description'] as String? ?? '';

    final rawIngredients = (recipeJson['ingredients'] as List?) ?? const [];
    final rawSteps = (recipeJson['steps'] as List?) ?? const [];

    final recipeId = const Uuid().v4();
    final nowMs = clock.now().toUtc().millisecondsSinceEpoch;

    final sortedIngIds = <String>[];
    for (final ing in rawIngredients) {
      if (ing is Map<String, dynamic>) {
        final name = ing['name']?.toString() ?? '';
        var id = ing['ingredient_id']?.toString() ?? '';
        if (id.isEmpty && name.isNotEmpty && resolveIngredientId != null) {
          id = resolveIngredientId(name) ?? '';
        }
        if (id.isEmpty && name.isNotEmpty) {
          id = name.toLowerCase().replaceAll(' ', '_');
        }
        if (id.isNotEmpty) sortedIngIds.add(id);
      }
    }
    sortedIngIds.sort();
    final fingerprint = '$dishTypeStr:${sortedIngIds.take(4).join(',')}';

    // Check for duplicate recipe per ТЗ 6.3 (title match or Jaccard similarity >= 0.8)
    final duplicate = await AntiRepeat.findDuplicate(
      database,
      title: title,
      dishType: dishTypeStr,
      ingredientIds: sortedIngIds,
    );
    if (duplicate != null) {
      return duplicate;
    }

    return database.transaction(() async {
      await database
          .into(database.recipes)
          .insert(
            RecipesCompanion(
              id: Value(recipeId),
              title: Value(title),
              normalizedTitle: Value(normalizedTitle),
              dishType: Value(dishType),
              difficulty: Value(difficulty),
              cuisine: Value(cuisine),
              totalMinutes: Value(totalMinutes),
              activeMinutes: Value(activeMinutes),
              servings: Value(servings),
              description: Value(description),
              source: const Value(RecipeSource.ai),
              fingerprint: Value(fingerprint),
              aiModel: Value(aiModel),
              isFavorite: const Value(false),
              createdAt: Value(nowMs),
              updatedAt: Value(nowMs),
            ),
          );

      for (final ing in rawIngredients) {
        if (ing is! Map<String, dynamic>) continue;
        final name = ing['name']?.toString() ?? '';
        var id = ing['ingredient_id']?.toString() ?? '';
        if (id.isEmpty && name.isNotEmpty && resolveIngredientId != null) {
          id = resolveIngredientId(name) ?? '';
        }
        if (id.isEmpty && name.isNotEmpty) {
          id = name.toLowerCase().replaceAll(' ', '_');
        }

        await database
            .into(database.recipeIngredients)
            .insert(
              RecipeIngredientsCompanion(
                id: Value(const Uuid().v4()),
                recipeId: Value(recipeId),
                ingredientId: Value(id),
                amount: Value((ing['amount'] as num?)?.toDouble()),
                unit: Value(ing['unit']?.toString()),
                isOptional: Value(ing['is_optional'] as bool? ?? false),
                note: Value(ing['note']?.toString()),
                createdAt: Value(nowMs),
                updatedAt: Value(nowMs),
              ),
            );
      }

      for (int i = 0; i < rawSteps.length; i++) {
        final s = rawSteps[i];
        if (s is! Map<String, dynamic>) continue;
        await database
            .into(database.recipeSteps)
            .insert(
              RecipeStepsCompanion(
                id: Value(const Uuid().v4()),
                recipeId: Value(recipeId),
                position: Value(i + 1),
                textContent: Value(s['text']?.toString() ?? ''),
                timerSeconds: Value((s['timer_seconds'] as num?)?.toInt()),
                tip: Value(s['tip']?.toString()),
                createdAt: Value(nowMs),
                updatedAt: Value(nowMs),
              ),
            );
      }

      return (database.select(
        database.recipes,
      )..where((tbl) => tbl.id.equals(recipeId))).getSingle();
    });
  }

  /// Returns total tokens consumed during the current calendar month.
  ///
  /// Can optionally be filtered by [modelFilter] (e.g. 'gigachat' per ТЗ 6.1.1).
  Future<int> getMonthlyTokensUsed({String? modelFilter}) async {
    final database = db;
    if (database == null) return 0;

    final now = clock.now();
    final startOfMonth = DateTime.utc(
      now.year,
      now.month,
      1,
    ).millisecondsSinceEpoch;

    final rows = await (database.select(
      database.aiRequests,
    )..where((tbl) => tbl.at.isBiggerOrEqualValue(startOfMonth))).get();

    int sum = 0;
    for (final row in rows) {
      if (modelFilter != null &&
          !row.model.toLowerCase().contains(modelFilter.toLowerCase())) {
        continue;
      }
      sum += (row.tokensIn ?? 0) + (row.tokensOut ?? 0);
    }
    return sum;
  }

  Future<void> _logRequest({
    required String kind,
    required String prompt,
    required String responseJson,
    required String model,
    int? tokensIn,
    int? tokensOut,
    required String status,
  }) async {
    final database = db;
    if (database == null) return;

    final promptHash = prompt.hashCode.toRadixString(16);
    try {
      await database
          .into(database.aiRequests)
          .insert(
            AiRequestsCompanion(
              id: Value(const Uuid().v4()),
              kind: Value(kind),
              promptHash: Value(promptHash),
              responseJson: Value(responseJson),
              model: Value(model),
              tokensIn: Value(tokensIn),
              tokensOut: Value(tokensOut),
              status: Value(status),
              at: Value(clock.now().toUtc().millisecondsSinceEpoch),
              createdAt: Value(clock.now().toUtc().millisecondsSinceEpoch),
              updatedAt: Value(clock.now().toUtc().millisecondsSinceEpoch),
            ),
          );
    } catch (_) {
      // Logging error must never crash user flow
    }
  }
}
