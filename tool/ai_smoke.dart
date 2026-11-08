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

  final lmOk = await _testLmStudio(
    templates: templates,
    validator: validator,
    suggestSchema: suggestSchema,
    fullRecipeSchema: fullRecipeSchema,
    candidatePorts: candidatePorts,
  );

  stdout.writeln();

  final gigaOk = await _testGigaChat(
    templates: templates,
    validator: validator,
    suggestSchema: suggestSchema,
    fullRecipeSchema: fullRecipeSchema,
  );

  stdout.writeln('\n========================================');
  stdout.writeln('  AI Smoke Test Completed               ');
  stdout.writeln('========================================');

  if (!lmOk || !gigaOk) {
    exit(1);
  }
}

Future<bool> _testLmStudio({
  required PromptTemplates templates,
  required RecipeValidator validator,
  required Map<String, dynamic> suggestSchema,
  required Map<String, dynamic> fullRecipeSchema,
  List<int> candidatePorts = const [1234, 1235],
}) async {
  final rawLog = <String, dynamic>{
    'timestamp': DateTime.now().toIso8601String(),
    'candidate_ports': candidatePorts,
  };

  void saveRawLog() {
    try {
      final f = File('docs/reports/last_ai_smoke_raw.json');
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rawLog));
    } catch (e) {
      stdout.writeln('[Smoke] Warning: could not write raw log: $e');
    }
  }

  stdout.writeln(
    '[LM Studio] Checking server at candidate ports: ${candidatePorts.join(', ')} ...',
  );

  LmStudioProvider? connectedProvider;
  String? connectedModelId;
  int? connectedPort;

  for (final port in candidatePorts) {
    stdout.writeln('[LM Studio] Probing http://127.0.0.1:$port ...');
    final modelOverride = Platform.environment['LMSTUDIO_MODEL'];
    final provider = LmStudioProvider(
      baseUrl: 'http://127.0.0.1:$port',
      model: (modelOverride == null || modelOverride.trim().isEmpty)
          ? null
          : modelOverride.trim(),
    );
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

  if (connectedProvider == null ||
      connectedModelId == null ||
      connectedPort == null) {
    stdout.writeln(
      '[LM Studio] NOT RUNNING / NOT REACHABLE on candidate ports: ${candidatePorts.join(', ')}',
    );
    stdout.writeln(
      '[LM Studio] (Start LM Studio on this PC, load a model, and start the local server via tool\\start_lmstudio_server.bat)',
    );
    rawLog['error'] = 'LM Studio not reachable on ports: $candidatePorts';
    saveRawLog();
    return false;
  }

  final provider = connectedProvider;
  final modelId = connectedModelId;
  final port = connectedPort;
  rawLog['selected_model'] = modelId;
  rawLog['selected_port'] = port;
  stdout.writeln(
    '[LM Studio] Selected port $port with model: $connectedModelId',
  );

  await _printLoadedModelInfo(port, connectedModelId);

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
        maxTokens: AiMaxTokens.suggestDishes,
        jsonSchema: suggestSchema,
        schemaName: 'suggest_dishes',
        timeout: const Duration(seconds: 45),
      ),
    );
    sw1.stop();
  } catch (e) {
    sw1.stop();
    stdout.writeln(
      '[LM Studio] suggest_dishes query FAILED in ${sw1.elapsed.inSeconds}s: $e',
    );
    rawLog['suggest_dishes_error'] = e.toString();
    saveRawLog();
    return false;
  }

  stdout.writeln(
    '[LM Studio] suggest_dishes completed in ${sw1.elapsed.inMilliseconds} ms',
  );
  stdout.writeln(
    '[LM Studio] Usage: prompt_tokens=${resp1.promptTokens}, completion_tokens=${resp1.completionTokens}',
  );
  stdout.writeln('[LM Studio] finish_reason: ${resp1.finishReason}');
  _printSpeedAndCheck(resp1, sw1.elapsed);

  if (resp1.finishReason == 'length') {
    stdout.writeln(
      '[LM Studio] finish_reason is length! Retrying suggest_dishes once with temperature 0.2 per R5-07 ...',
    );
    final swRetryLen = Stopwatch()..start();
    try {
      final retryResp = await provider.chat(
        AiChatRequest(
          messages: [
            AiChatMessage.system(suggestSystem),
            AiChatMessage.user(suggestUser),
          ],
          model: modelId,
          temperature: 0.2,
          maxTokens: AiMaxTokens.suggestDishes,
          jsonSchema: suggestSchema,
          schemaName: 'suggest_dishes',
          timeout: const Duration(seconds: 45),
        ),
      );
      swRetryLen.stop();
      stdout.writeln(
        '[LM Studio] suggest_dishes length retry completed in ${swRetryLen.elapsed.inMilliseconds} ms (finish_reason: ${retryResp.finishReason})',
      );
      resp1 = retryResp;
      _printSpeedAndCheck(resp1, swRetryLen.elapsed);
    } catch (e) {
      stdout.writeln('[LM Studio] length retry failed: $e');
    }
  }

  rawLog['suggest_dishes'] = {
    'finish_reason': resp1.finishReason,
    'prompt_tokens': resp1.promptTokens,
    'completion_tokens': resp1.completionTokens,
    'duration_ms': sw1.elapsedMilliseconds,
    'time_to_first_token_ms': resp1.timeToFirstToken?.inMilliseconds,
    'speed_tok_s': sw1.elapsedMilliseconds > 0
        ? (resp1.completionTokens / (sw1.elapsedMilliseconds / 1000.0))
        : 0.0,
    'raw_content': resp1.rawContent,
  };

  String firstDishTitle = 'Куриный суп с картофелем';
  String firstDishType = 'soup';
  String firstDishDifficulty = 'easy';
  List<String> firstDishMainIngredients = ['куриное филе', 'картофель'];
  bool val1Ok = false;
  try {
    final parsed = jsonDecode(resp1.rawContent) as Map<String, dynamic>;
    var valResult = validator.validateDishes(parsed);
    stdout.writeln('[LM Studio] suggest_dishes validation: $valResult');
    if (valResult is Valid) {
      val1Ok = true;
    } else if (valResult is Retryable) {
      stdout.writeln(
        '[LM Studio] Retrying suggest_dishes once: ${valResult.reasonForModel} ...',
      );
      final retryResp = await provider.chat(
        AiChatRequest(
          messages: [
            AiChatMessage.system(suggestSystem),
            AiChatMessage.user(suggestUser),
            AiChatMessage.assistant(resp1.rawContent),
            AiChatMessage.user(
              'Ответ отклонён: ${valResult.reasonForModel}. Пожалуйста, исправь ошибки и верни строго валидный JSON по схеме.',
            ),
          ],
          model: modelId,
          temperature: 0.2,
          maxTokens: AiMaxTokens.suggestDishes,
          jsonSchema: suggestSchema,
          schemaName: 'suggest_dishes',
          timeout: const Duration(seconds: 45),
        ),
      );
      final retryParsed =
          jsonDecode(retryResp.rawContent) as Map<String, dynamic>;
      valResult = validator.validateDishes(retryParsed);
      stdout.writeln('[LM Studio] suggest_dishes retry validation: $valResult');
      if (valResult is Valid) {
        val1Ok = true;
        parsed.clear();
        parsed.addAll(retryParsed);
      }
    } else {
      stdout.writeln(
        '[LM Studio] Warning/Invalid suggest_dishes: finish_reason=${resp1.finishReason}',
      );
      stdout.writeln(
        'First 500 characters of response:\n${resp1.rawContent.length > 500 ? resp1.rawContent.substring(0, 500) : resp1.rawContent}',
      );
    }
    final dishes = parsed['dishes'] as List?;
    if (dishes != null && dishes.isNotEmpty && dishes.first is Map) {
      final firstMap = dishes.first as Map<String, dynamic>;
      final title = firstMap['title'];
      if (title is String && title.isNotEmpty) {
        firstDishTitle = title;
      }
      final dType = firstMap['dish_type'];
      if (dType is String && dType.isNotEmpty) {
        firstDishType = dType;
      }
      final diff = firstMap['difficulty'];
      if (diff is String && diff.isNotEmpty) {
        firstDishDifficulty = diff;
      }
      final mainIngs = firstMap['main_ingredients'];
      if (mainIngs is List && mainIngs.isNotEmpty) {
        firstDishMainIngredients = mainIngs.cast<String>();
      }
    }
  } catch (e) {
    stdout.writeln(
      '[LM Studio] Error parsing/validating suggest_dishes response: $e (finish_reason: ${resp1.finishReason})',
    );
    stdout.writeln(
      'First 500 characters of response:\n${resp1.rawContent.length > 500 ? resp1.rawContent.substring(0, 500) : resp1.rawContent}',
    );
  }

  if (!val1Ok) {
    saveRawLog();
    return false;
  }

  // 2. full_recipe
  stdout.writeln(
    '\n[LM Studio] 2/2: Testing full_recipe for "$firstDishTitle" ($firstDishType, $firstDishDifficulty) ...',
  );
  final recipeSystem = templates.buildSystem(
    schemaJson: jsonEncode(fullRecipeSchema),
    schemaInPrompt: false,
  );
  final recipeUser = templates.buildFullRecipe(
    title: firstDishTitle,
    dishType: firstDishType,
    difficulty: firstDishDifficulty,
    mainIngredients: firstDishMainIngredients,
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
        maxTokens: AiMaxTokens.fullRecipe,
        jsonSchema: fullRecipeSchema,
        schemaName: 'full_recipe',
        timeout: const Duration(seconds: 45),
      ),
    );
    sw2.stop();
  } catch (e) {
    sw2.stop();
    stdout.writeln(
      '[LM Studio] full_recipe query FAILED in ${sw2.elapsed.inSeconds}s: $e',
    );
    rawLog['full_recipe_error'] = e.toString();
    saveRawLog();
    return false;
  }

  stdout.writeln(
    '[LM Studio] full_recipe completed in ${sw2.elapsed.inMilliseconds} ms',
  );
  stdout.writeln(
    '[LM Studio] Usage: prompt_tokens=${resp2.promptTokens}, completion_tokens=${resp2.completionTokens}',
  );
  stdout.writeln('[LM Studio] finish_reason: ${resp2.finishReason}');
  _printSpeedAndCheck(resp2, sw2.elapsed);

  if (resp2.finishReason == 'length') {
    stdout.writeln(
      '[LM Studio] finish_reason is length! Retrying full_recipe once with temperature 0.2 per R5-07 ...',
    );
    final swRetryLen = Stopwatch()..start();
    try {
      final retryResp = await provider.chat(
        AiChatRequest(
          messages: [
            AiChatMessage.system(recipeSystem),
            AiChatMessage.user(recipeUser),
          ],
          model: modelId,
          temperature: 0.2,
          maxTokens: AiMaxTokens.fullRecipe,
          jsonSchema: fullRecipeSchema,
          schemaName: 'full_recipe',
          timeout: const Duration(seconds: 45),
        ),
      );
      swRetryLen.stop();
      stdout.writeln(
        '[LM Studio] full_recipe length retry completed in ${swRetryLen.elapsed.inMilliseconds} ms (finish_reason: ${retryResp.finishReason})',
      );
      resp2 = retryResp;
      _printSpeedAndCheck(resp2, swRetryLen.elapsed);
    } catch (e) {
      stdout.writeln('[LM Studio] length retry failed: $e');
    }
  }

  rawLog['full_recipe'] = {
    'finish_reason': resp2.finishReason,
    'prompt_tokens': resp2.promptTokens,
    'completion_tokens': resp2.completionTokens,
    'duration_ms': sw2.elapsedMilliseconds,
    'time_to_first_token_ms': resp2.timeToFirstToken?.inMilliseconds,
    'speed_tok_s': sw2.elapsedMilliseconds > 0
        ? (resp2.completionTokens / (sw2.elapsedMilliseconds / 1000.0))
        : 0.0,
    'raw_content': resp2.rawContent,
  };
  saveRawLog();

  bool val2Ok = false;
  try {
    final parsedRecipe = jsonDecode(resp2.rawContent) as Map<String, dynamic>;
    var valResult = validator.validate(parsedRecipe);
    stdout.writeln('[LM Studio] full_recipe validation: $valResult');
    if (valResult is Valid) {
      val2Ok = true;
    } else if (valResult is Retryable) {
      stdout.writeln(
        '[LM Studio] Retrying full_recipe once: ${valResult.reasonForModel} ...',
      );
      final swRetry = Stopwatch()..start();
      final retryResp = await provider.chat(
        AiChatRequest(
          messages: [
            AiChatMessage.system(recipeSystem),
            AiChatMessage.user(recipeUser),
            AiChatMessage.assistant(resp2.rawContent),
            AiChatMessage.user(
              'Ответ отклонён: ${valResult.reasonForModel}. Пожалуйста, исправь ошибки и верни строго валидный JSON по схеме.',
            ),
          ],
          model: modelId,
          temperature: 0.2,
          maxTokens: AiMaxTokens.fullRecipe,
          jsonSchema: fullRecipeSchema,
          schemaName: 'full_recipe',
          timeout: const Duration(seconds: 45),
        ),
      );
      swRetry.stop();
      stdout.writeln(
        '[LM Studio] full_recipe retry completed in ${swRetry.elapsed.inMilliseconds} ms (finish_reason: ${retryResp.finishReason})',
      );
      final retryParsed =
          jsonDecode(retryResp.rawContent) as Map<String, dynamic>;
      valResult = validator.validate(retryParsed);
      stdout.writeln('[LM Studio] full_recipe retry validation: $valResult');
      if (valResult is Valid) {
        val2Ok = true;
      }
    } else {
      stdout.writeln(
        '[LM Studio] Warning/Invalid full_recipe: finish_reason=${resp2.finishReason}',
      );
      stdout.writeln(
        'First 500 characters of response:\n${resp2.rawContent.length > 500 ? resp2.rawContent.substring(0, 500) : resp2.rawContent}',
      );
    }
  } catch (e) {
    stdout.writeln(
      '[LM Studio] Error parsing/validating full_recipe response: $e (finish_reason: ${resp2.finishReason})',
    );
    stdout.writeln(
      'First 500 characters of response:\n${resp2.rawContent.length > 500 ? resp2.rawContent.substring(0, 500) : resp2.rawContent}',
    );
  }

  return val2Ok;
}

Future<bool> _testGigaChat({
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
    return true; // Skipped intentionally, not a failure
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
        maxTokens: AiMaxTokens.suggestDishes,
        jsonSchema: suggestSchema,
        schemaName: 'suggest_dishes',
        timeout: const Duration(seconds: 45),
      ),
    );
    sw1.stop();
  } catch (e) {
    sw1.stop();
    stdout.writeln(
      '[GigaChat] suggest_dishes query FAILED in ${sw1.elapsed.inSeconds}s: $e',
    );
    return false;
  }

  stdout.writeln(
    '[GigaChat] suggest_dishes completed in ${sw1.elapsed.inMilliseconds} ms',
  );
  stdout.writeln(
    '[GigaChat] Usage: prompt_tokens=${resp1.promptTokens}, completion_tokens=${resp1.completionTokens}',
  );
  stdout.writeln('[GigaChat] finish_reason: ${resp1.finishReason}');

  String firstDishTitle = 'Куриный суп с картофелем';
  bool val1Ok = false;
  try {
    final parsed = jsonDecode(resp1.rawContent) as Map<String, dynamic>;
    final valResult = validator.validateDishes(parsed);
    stdout.writeln('[GigaChat] suggest_dishes validation: $valResult');
    if (valResult is Valid) {
      val1Ok = true;
    }
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

  if (!val1Ok) return false;

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
        maxTokens: AiMaxTokens.fullRecipe,
        jsonSchema: fullRecipeSchema,
        schemaName: 'full_recipe',
        timeout: const Duration(seconds: 45),
      ),
    );
    sw2.stop();
  } catch (e) {
    sw2.stop();
    stdout.writeln(
      '[GigaChat] full_recipe query FAILED in ${sw2.elapsed.inSeconds}s: $e',
    );
    return false;
  }

  stdout.writeln(
    '[GigaChat] full_recipe completed in ${sw2.elapsed.inMilliseconds} ms',
  );
  stdout.writeln(
    '[GigaChat] Usage: prompt_tokens=${resp2.promptTokens}, completion_tokens=${resp2.completionTokens}',
  );
  stdout.writeln('[GigaChat] finish_reason: ${resp2.finishReason}');

  bool val2Ok = false;
  try {
    final parsedRecipe = jsonDecode(resp2.rawContent) as Map<String, dynamic>;
    final valResult = validator.validate(parsedRecipe);
    stdout.writeln('[GigaChat] full_recipe validation: $valResult');
    if (valResult is Valid) {
      val2Ok = true;
    }
  } catch (e) {
    stdout.writeln(
      '[GigaChat] Error parsing/validating full_recipe response: $e',
    );
  }

  return val2Ok;
}

void _printSpeedAndCheck(AiCompletionResponse resp, Duration duration) {
  final elapsedSec = duration.inMilliseconds / 1000.0;
  final tokPerSec = elapsedSec > 0 ? (resp.completionTokens / elapsedSec) : 0.0;
  stdout.writeln(
    '[LM Studio] Speed: ${tokPerSec.toStringAsFixed(1)} tok/s (${resp.completionTokens} completion tokens in ${elapsedSec.toStringAsFixed(2)}s)',
  );
  if (resp.timeToFirstToken != null) {
    final ttftSec = resp.timeToFirstToken!.inMilliseconds / 1000.0;
    stdout.writeln(
      '[LM Studio] Time to first token (TTFT): ${ttftSec.toStringAsFixed(2)}s',
    );
  }
  if (tokPerSec < 5.0) {
    stdout.writeln(
      '[LM Studio] Видеопамяти не хватает: см. docs/INSTALL.md раздел 2.4',
    );
  }
}

Future<void> _printLoadedModelInfo(int port, String fallbackModelId) async {
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    final req = await client.getUrl(
      Uri.parse('http://127.0.0.1:$port/api/v1/models'),
    );
    final resp = await req.close();
    if (resp.statusCode == 200) {
      final text = await resp.transform(utf8.decoder).join();
      final data = jsonDecode(text);
      if (data is Map && data['models'] is List) {
        for (final m in data['models'] as List) {
          if (m is Map &&
              m['loaded_instances'] is List &&
              (m['loaded_instances'] as List).isNotEmpty) {
            final instance = (m['loaded_instances'] as List).first as Map;
            final config = instance['config'] as Map?;
            final id = instance['id'] ?? m['key'];
            final ctx =
                config?['context_length'] ?? m['max_context_length'] ?? '?';
            final parallel = config?['parallel'] ?? '?';
            stdout.writeln(
              '[LM Studio] Model info: $id (context: $ctx, parallel: $parallel)',
            );
            client.close();
            return;
          }
        }
      }
    }
    client.close();
  } catch (_) {}

  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    final req = await client.getUrl(
      Uri.parse('http://127.0.0.1:$port/api/v0/models'),
    );
    final resp = await req.close();
    if (resp.statusCode == 200) {
      final text = await resp.transform(utf8.decoder).join();
      final data = jsonDecode(text);
      if (data is Map && data['data'] is List) {
        for (final m in data['data'] as List) {
          if (m is Map && m['state'] == 'loaded') {
            final id = m['id'];
            final ctx =
                m['loaded_context_length'] ?? m['max_context_length'] ?? '?';
            stdout.writeln(
              '[LM Studio] Model info: $id (context: $ctx, parallel: 1)',
            );
            client.close();
            return;
          }
        }
      }
    }
    client.close();
  } catch (_) {}

  stdout.writeln('[LM Studio] Model info: $fallbackModelId');
}
