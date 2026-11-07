import 'dart:convert';
import 'dart:io';

import 'package:chto_prigotovit/core/ai/ai_provider.dart';
import 'package:chto_prigotovit/core/ai/gigachat_provider.dart';
import 'package:chto_prigotovit/core/ai/lm_studio_provider.dart';
import 'package:chto_prigotovit/core/ai/prompts.dart';
import 'package:chto_prigotovit/core/ai/recipe_validator.dart';

Future<void> main(List<String> args) async {
  stdout.writeln('========================================');
  stdout.writeln('  AI Smoke Test: LM Studio & GigaChat   ');
  stdout.writeln('========================================\n');

  int? portOverride;
  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--port' && i + 1 < args.length) {
      portOverride = int.tryParse(args[i + 1]);
    } else if (args[i].startsWith('--port=')) {
      portOverride = int.tryParse(args[i].substring('--port='.length));
    }
  }
  portOverride ??= int.tryParse(Platform.environment['LMSTUDIO_PORT'] ?? '');

  final candidatePorts = portOverride != null ? [portOverride] : [1234, 1235];

  final templates = await PromptTemplates.load();
  final validator = await RecipeValidator.fromAsset();
  final suggestSchema = await AiSchemas.loadSuggestDishesSchema();
  final fullRecipeSchema = await AiSchemas.loadFullRecipeSchema();

  await _testLmStudio(
    templates: templates,
    validator: validator,
    suggestSchema: suggestSchema,
    fullRecipeSchema: fullRecipeSchema,
    candidatePorts: candidatePorts,
  );

  stdout.writeln();

  await _testGigaChat(
    templates: templates,
    validator: validator,
    suggestSchema: suggestSchema,
    fullRecipeSchema: fullRecipeSchema,
  );

  stdout.writeln('\n========================================');
  stdout.writeln('  AI Smoke Test Completed               ');
  stdout.writeln('========================================');
}

Future<void> _testLmStudio({
  required PromptTemplates templates,
  required RecipeValidator validator,
  required Map<String, dynamic> suggestSchema,
  required Map<String, dynamic> fullRecipeSchema,
  List<int> candidatePorts = const [1234, 1235],
}) async {
  stdout.writeln(
    '[LM Studio] Checking server at candidate ports: ${candidatePorts.join(', ')} ...',
  );

  LmStudioProvider? connectedProvider;
  String? connectedModelId;
  int? connectedPort;

  for (final port in candidatePorts) {
    stdout.writeln('[LM Studio] Probing http://127.0.0.1:$port ...');
    final provider = LmStudioProvider(baseUrl: 'http://127.0.0.1:$port');
    try {
      final modelId = await provider.resolveModel();
      connectedProvider = provider;
      connectedModelId = modelId;
      connectedPort = port;
      stdout.writeln(
        '[LM Studio] Server reachable on port $port! Using model: $modelId',
      );
      break;
    } catch (e) {
      stdout.writeln('[LM Studio] Port $port not answering / error: $e');
    }
  }

  if (connectedProvider == null || connectedModelId == null) {
    stdout.writeln(
      '[LM Studio] NOT RUNNING / NOT REACHABLE on candidate ports: ${candidatePorts.join(', ')}',
    );
    stdout.writeln(
      '[LM Studio] (Start LM Studio on this PC, load a model, and start the local server via tool\\start_lmstudio_server.bat)',
    );
    return;
  }

  final provider = connectedProvider;
  final modelId = connectedModelId;
  stdout.writeln(
    '[LM Studio] Selected port $connectedPort with model: $connectedModelId',
  );

  // 1. suggest_dishes
  stdout.writeln('\n[LM Studio] 1/2: Testing suggest_dishes ...');
  final suggestSystem = templates.buildSystem(
    schemaJson: jsonEncode(suggestSchema),
    schemaInPrompt: false,
  );
  final suggestUser = templates.buildSuggestDishes(
    availableIngredients: [
      'картофель',
      'морковь',
      'лук репчатый',
      'куриное филе',
      'масло растительное',
      'соль',
    ],
  );

  final sw1 = Stopwatch()..start();
  AiCompletionResponse resp1;
  try {
    resp1 = await provider.chat(
      AiChatRequest(
        messages: [
          AiChatMessage.system(suggestSystem),
          AiChatMessage.user(suggestUser),
        ],
        model: modelId,
        temperature: 0.3,
        jsonSchema: suggestSchema,
        schemaName: 'suggest_dishes',
        timeout: const Duration(seconds: 120),
      ),
    );
    sw1.stop();
  } catch (e) {
    sw1.stop();
    stdout.writeln(
      '[LM Studio] suggest_dishes query FAILED in ${sw1.elapsed.inSeconds}s: $e',
    );
    return;
  }

  stdout.writeln(
    '[LM Studio] suggest_dishes completed in ${sw1.elapsed.inMilliseconds} ms',
  );
  stdout.writeln(
    '[LM Studio] Usage: prompt_tokens=${resp1.promptTokens}, completion_tokens=${resp1.completionTokens}',
  );

  String firstDishTitle = 'Куриный суп с картофелем';
  try {
    final parsed = jsonDecode(resp1.rawContent) as Map<String, dynamic>;
    final valResult = validator.validateDishes(parsed);
    stdout.writeln('[LM Studio] suggest_dishes validation: $valResult');
    final dishes = parsed['dishes'] as List?;
    if (dishes != null && dishes.isNotEmpty && dishes.first is Map) {
      final title = (dishes.first as Map)['title'];
      if (title is String && title.isNotEmpty) {
        firstDishTitle = title;
      }
    }
  } catch (e) {
    stdout.writeln(
      '[LM Studio] Error parsing/validating suggest_dishes response: $e',
    );
    stdout.writeln('Raw response:\n${resp1.rawContent}');
  }

  // 2. full_recipe
  stdout.writeln(
    '\n[LM Studio] 2/2: Testing full_recipe for "$firstDishTitle" ...',
  );
  final recipeSystem = templates.buildSystem(
    schemaJson: jsonEncode(fullRecipeSchema),
    schemaInPrompt: false,
  );
  final recipeUser = templates.buildFullRecipe(
    title: firstDishTitle,
    dishType: 'soup',
    difficulty: 'easy',
    mainIngredients: ['куриное филе', 'картофель'],
    availableIngredients: [
      'картофель',
      'морковь',
      'лук репчатый',
      'куриное филе',
      'масло растительное',
      'соль',
    ],
  );

  final sw2 = Stopwatch()..start();
  AiCompletionResponse resp2;
  try {
    resp2 = await provider.chat(
      AiChatRequest(
        messages: [
          AiChatMessage.system(recipeSystem),
          AiChatMessage.user(recipeUser),
        ],
        model: modelId,
        temperature: 0.3,
        jsonSchema: fullRecipeSchema,
        schemaName: 'full_recipe',
        timeout: const Duration(seconds: 180),
      ),
    );
    sw2.stop();
  } catch (e) {
    sw2.stop();
    stdout.writeln(
      '[LM Studio] full_recipe query FAILED in ${sw2.elapsed.inSeconds}s: $e',
    );
    return;
  }

  stdout.writeln(
    '[LM Studio] full_recipe completed in ${sw2.elapsed.inMilliseconds} ms',
  );
  stdout.writeln(
    '[LM Studio] Usage: prompt_tokens=${resp2.promptTokens}, completion_tokens=${resp2.completionTokens}',
  );

  try {
    final parsedRecipe = jsonDecode(resp2.rawContent) as Map<String, dynamic>;
    final valResult = validator.validate(parsedRecipe);
    stdout.writeln('[LM Studio] full_recipe validation: $valResult');
  } catch (e) {
    stdout.writeln(
      '[LM Studio] Error parsing/validating full_recipe response: $e',
    );
    stdout.writeln('Raw response:\n${resp2.rawContent}');
  }
}

Future<void> _testGigaChat({
  required PromptTemplates templates,
  required RecipeValidator validator,
  required Map<String, dynamic> suggestSchema,
  required Map<String, dynamic> fullRecipeSchema,
}) async {
  final rawKey =
      Platform.environment['GIGACHAT_KEY'] ??
      Platform.environment['GIGACHAT_AUTH_KEY'];

  if (rawKey == null || rawKey.trim().isEmpty) {
    stdout.writeln(
      '[GigaChat] GIGACHAT_KEY environment variable is not set. Skipped.',
    );
    stdout.writeln(
      '[GigaChat] (To test GigaChat: set GIGACHAT_KEY=<auth_key> and rerun)',
    );
    return;
  }

  stdout.writeln(
    '[GigaChat] GIGACHAT_KEY detected (key hidden). Initializing provider ...',
  );

  final certFile = File('assets/certs/russian_trusted_root_ca.cer');
  final certBytes = certFile.existsSync() ? certFile.readAsBytesSync() : null;
  final dio = GigaChatProvider.createDioWithCert(certBytes: certBytes);

  // Clean key in case user provided with prefix or whitespace
  final cleanKey = rawKey
      .replaceAll(RegExp(r'^Basic\s+', caseSensitive: false), '')
      .trim();
  final provider = GigaChatProvider(authKey: cleanKey, dio: dio);

  stdout.writeln('[GigaChat] 1/2: Testing suggest_dishes ...');
  final suggestSystem = templates.buildSystem(
    schemaJson: jsonEncode(suggestSchema),
    schemaInPrompt: true,
  );
  final suggestUser = templates.buildSuggestDishes(
    availableIngredients: [
      'картофель',
      'морковь',
      'лук репчатый',
      'куриное филе',
      'масло растительное',
      'соль',
    ],
  );

  final sw1 = Stopwatch()..start();
  AiCompletionResponse resp1;
  try {
    resp1 = await provider.chat(
      AiChatRequest(
        messages: [
          AiChatMessage.system(suggestSystem),
          AiChatMessage.user(suggestUser),
        ],
        temperature: 0.3,
        jsonSchema: suggestSchema,
        schemaName: 'suggest_dishes',
        timeout: const Duration(seconds: 60),
      ),
    );
    sw1.stop();
  } catch (e) {
    sw1.stop();
    stdout.writeln(
      '[GigaChat] suggest_dishes query FAILED in ${sw1.elapsed.inSeconds}s: $e',
    );
    return;
  }

  stdout.writeln(
    '[GigaChat] suggest_dishes completed in ${sw1.elapsed.inMilliseconds} ms',
  );
  stdout.writeln(
    '[GigaChat] Usage: prompt_tokens=${resp1.promptTokens}, completion_tokens=${resp1.completionTokens}',
  );

  String firstDishTitle = 'Куриный суп с картофелем';
  try {
    final parsed = jsonDecode(resp1.rawContent) as Map<String, dynamic>;
    final valResult = validator.validateDishes(parsed);
    stdout.writeln('[GigaChat] suggest_dishes validation: $valResult');
    final dishes = parsed['dishes'] as List?;
    if (dishes != null && dishes.isNotEmpty && dishes.first is Map) {
      final title = (dishes.first as Map)['title'];
      if (title is String && title.isNotEmpty) {
        firstDishTitle = title;
      }
    }
  } catch (e) {
    stdout.writeln(
      '[GigaChat] Error parsing/validating suggest_dishes response: $e',
    );
  }

  stdout.writeln(
    '\n[GigaChat] 2/2: Testing full_recipe for "$firstDishTitle" ...',
  );
  final recipeSystem = templates.buildSystem(
    schemaJson: jsonEncode(fullRecipeSchema),
    schemaInPrompt: true,
  );
  final recipeUser = templates.buildFullRecipe(
    title: firstDishTitle,
    dishType: 'soup',
    difficulty: 'easy',
    mainIngredients: ['куриное филе', 'картофель'],
    availableIngredients: [
      'картофель',
      'морковь',
      'лук репчатый',
      'куриное филе',
      'масло растительное',
      'соль',
    ],
  );

  final sw2 = Stopwatch()..start();
  AiCompletionResponse resp2;
  try {
    resp2 = await provider.chat(
      AiChatRequest(
        messages: [
          AiChatMessage.system(recipeSystem),
          AiChatMessage.user(recipeUser),
        ],
        temperature: 0.3,
        jsonSchema: fullRecipeSchema,
        schemaName: 'full_recipe',
        timeout: const Duration(seconds: 60),
      ),
    );
    sw2.stop();
  } catch (e) {
    sw2.stop();
    stdout.writeln(
      '[GigaChat] full_recipe query FAILED in ${sw2.elapsed.inSeconds}s: $e',
    );
    return;
  }

  stdout.writeln(
    '[GigaChat] full_recipe completed in ${sw2.elapsed.inMilliseconds} ms',
  );
  stdout.writeln(
    '[GigaChat] Usage: prompt_tokens=${resp2.promptTokens}, completion_tokens=${resp2.completionTokens}',
  );

  try {
    final parsedRecipe = jsonDecode(resp2.rawContent) as Map<String, dynamic>;
    final valResult = validator.validate(parsedRecipe);
    stdout.writeln('[GigaChat] full_recipe validation: $valResult');
  } catch (e) {
    stdout.writeln(
      '[GigaChat] Error parsing/validating full_recipe response: $e',
    );
  }
}
