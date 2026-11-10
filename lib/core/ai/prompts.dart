import 'dart:convert';
import 'dart:io';

typedef AssetStringLoader = Future<String> Function(String path);

/// Simple template renderer for AI prompts supporting `{{#if key}}...{{/if}}`
/// conditional blocks and `{{key}}` variable interpolation without external dependencies.
String renderTemplate(String template, Map<String, dynamic> variables) {
  // 1. Process {{#if key}}...{{/if}} blocks (supports multiline content)
  final ifBlockRegex = RegExp(
    r'{{#if\s+([a-zA-Z0-9_]+)}}(.*?){{/if}}',
    dotAll: true,
  );
  var result = template.replaceAllMapped(ifBlockRegex, (match) {
    final key = match.group(1)!;
    final content = match.group(2)!;
    final val = variables[key];
    final isTruthy = _isTruthy(val);
    return isTruthy ? content : '';
  });

  // 2. Process {{key}} variable replacements
  final varRegex = RegExp(r'{{([a-zA-Z0-9_]+)}}');
  result = result.replaceAllMapped(varRegex, (match) {
    final key = match.group(1)!;
    final val = variables[key];
    return _formatVariableValue(val);
  });

  return result;
}

bool _isTruthy(dynamic val) {
  if (val == null) return false;
  if (val is bool) return val;
  if (val is String) return val.trim().isNotEmpty && val != 'нет';
  if (val is List) return val.isNotEmpty;
  if (val is Map) return val.isNotEmpty;
  if (val is num) return val != 0;
  return true;
}

String _formatVariableValue(dynamic val) {
  if (val == null) return 'нет';
  if (val is List) {
    if (val.isEmpty) return 'нет';
    final nonNull = val
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return nonNull.isEmpty ? 'нет' : nonNull.join(', ');
  }
  final s = val.toString().trim();
  return s.isEmpty ? 'нет' : s;
}

/// Limits for completion token output per R5-07 / R8-07 to prevent infinite generation loops
/// and enforce compact dish cards (<= 250 tokens for 5 dishes).
abstract final class AiMaxTokens {
  static const int suggestDishes = 350;
  static const int fullRecipe = 2500;
  static const int monthPlan = 2000;
  static const int pingQuery = 100;
}

/// Prompt templates for AI generation loaded from assets or default constants.
class PromptTemplates {
  static AssetStringLoader? assetLoader;

  final String systemTemplate;
  final String suggestDishesTemplate;
  final String fullRecipeTemplate;
  final String monthPlanTemplate;

  const PromptTemplates({
    required this.systemTemplate,
    required this.suggestDishesTemplate,
    required this.fullRecipeTemplate,
    required this.monthPlanTemplate,
  });

  /// Default prompt templates aligned with spec/ai/prompts/*.md.
  factory PromptTemplates.defaults() {
    return const PromptTemplates(
      systemTemplate: '''
Ты — опытный повар домашней кухни. Советуешь блюда из продуктов, которые есть у человека. Правила:
- Только реальные, проверенные блюда; без экзотических продуктов.
- Используй продукты из списка «есть». Соль, вода, подсолнечное масло, сахар, чёрный перец считаются имеющимися. Недостающее — не больше 2 продуктов, перечисли в missing.
- Никогда не предлагай блюда из списка «не предлагать» и их варианты (другое название того же блюда тоже нельзя).
- Никогда не используй продукты из списка «нельзя» — это аллергии и исключения.
- Указывай безопасное время тепловой обработки для мяса, птицы, фарша, рыбы и яиц.
- Пиши просто, как для пожилого человека: короткие шаги, глагол в начале, без жаргона.
- Тип блюда (dish_type) и сложность (difficulty) — только из разрешённых значений схемы.
- Отвечай только JSON по схеме, без текста до и после.
{{#if schema_in_prompt}}

Схема ответа (JSON Schema):
{{schema}}
{{/if}}''',
      suggestDishesTemplate: '''
Есть продукты: {{available_ingredients}}
Нельзя (аллергии и исключения): {{forbidden_ingredients}}
Не предлагать (недавно готовили или не понравилось): {{do_not_suggest}}
Фильтры: тип блюда — {{dish_type_filter}}; сложность — {{difficulty_filter}}; время — не больше {{max_total_minutes}} мин.
Вкусы: любит {{likes}}; не любит {{dislikes}}. Хорошо оценённые блюда: {{top_rated}}.

Предложи {{count}} разных блюд. Только короткие карточки: название, тип, время, сложность, 3–5 главных продуктов, одна фраза why. Без шагов и без количеств. Не больше 3 блюд одного типа и не больше 2 с одним главным продуктом.
В поле why — одна короткая фраза, почему это блюдо может понравиться.''',
      fullRecipeTemplate: '''
Напиши полный рецепт блюда «{{title}}» ({{dish_type}}, сложность {{difficulty}}) на {{servings}} порц.
Главные продукты: {{main_ingredients}}. Есть дома: {{available_ingredients}}.
Нельзя: {{forbidden_ingredients}}.

Требования:
- Количества — на {{servings}} порц., единицы только из схемы (g, kg, ml, l, pcs, tbsp, tsp, cup, pinch, to_taste).
- Шаг — не больше 2 предложений. Для каждого шага с ожиданием укажи timer_seconds.
- Сумма времени шагов не должна превышать total_minutes.
{{#if retry_reason}}

Предыдущий ответ отклонён: {{retry_reason}}. Исправь это.
{{/if}}''',
      monthPlanTemplate: '''
Составь меню: одно основное блюдо на каждый день с {{date_from}} по {{date_to}} (включительно).
Уже закреплённые дни (не меняй и учитывай для разнообразия): {{locked_days}}
Последние 30 дней ели: {{history_30d}}
Нельзя: {{forbidden_ingredients}}
Вкусы: любит {{likes}}; не любит {{dislikes}}. Доли типов блюд по вкусу: {{dish_type_shares}}.

Правила:
- Одно блюдо — не чаще раза в 14 дней (учитывая историю и закреплённые дни).
- Один главный продукт — не больше 2 дней подряд.
- Суп — не меньше 2 раз в неделю{{#if soups_disliked}} (кроме случая, когда супы не любят){{/if}}.
- Сложных блюд — не больше 2 в неделю и не в два дня подряд.''',
    );
  }

  /// Loads prompt templates from `assets/ai/prompts/*.md`, falling back to file or defaults.
  static Future<PromptTemplates> load() async {
    try {
      final system = await _loadAssetOrFile('assets/ai/prompts/system.md');
      final suggest = await _loadAssetOrFile(
        'assets/ai/prompts/suggest_dishes.md',
      );
      final recipe = await _loadAssetOrFile('assets/ai/prompts/full_recipe.md');
      final plan = await _loadAssetOrFile('assets/ai/prompts/month_plan.md');

      return PromptTemplates(
        systemTemplate: system,
        suggestDishesTemplate: suggest,
        fullRecipeTemplate: recipe,
        monthPlanTemplate: plan,
      );
    } catch (_) {
      return PromptTemplates.defaults();
    }
  }

  static Future<String> _loadAssetOrFile(String path) async {
    if (assetLoader != null) {
      try {
        return await assetLoader!(path);
      } catch (_) {}
    }
    final f = File(path);
    if (f.existsSync()) return f.readAsStringSync();
    final specFile = File(path.replaceAll('assets/ai/', 'spec/ai/'));
    if (specFile.existsSync()) return specFile.readAsStringSync();
    throw FileSystemException('Cannot find prompt asset or file', path);
  }

  /// Builds the system prompt. If [schemaInPrompt] is true (e.g. for GigaChat),
  /// embeds the JSON Schema string into the system prompt text.
  String buildSystem({
    required String schemaJson,
    bool schemaInPrompt = false,
  }) {
    return renderTemplate(systemTemplate, {
      'schema_in_prompt': schemaInPrompt,
      'schema': schemaJson,
    });
  }

  /// Builds user prompt for `suggest_dishes` adhering to size limits:
  /// - doNotSuggest <= 40
  /// - likes <= 5
  /// - dislikes <= 5
  /// - topRated <= 5
  String buildSuggestDishes({
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
  }) {
    final cappedDoNotSuggest = doNotSuggest.take(40).toList();
    final cappedLikes = likes.take(5).toList();
    final cappedDislikes = dislikes.take(5).toList();
    final cappedTopRated = topRated.take(5).toList();

    return renderTemplate(suggestDishesTemplate, {
      'available_ingredients': availableIngredients,
      'forbidden_ingredients': forbiddenIngredients,
      'do_not_suggest': cappedDoNotSuggest,
      'dish_type_filter': dishTypeFilter ?? 'любой',
      'difficulty_filter': difficultyFilter ?? 'любая',
      'max_total_minutes': maxTotalMinutes?.toString() ?? '120',
      'likes': cappedLikes,
      'dislikes': cappedDislikes,
      'top_rated': cappedTopRated,
      'count': count.toString(),
    });
  }

  /// Builds user prompt for `full_recipe` (with optional [retryReason] from validator).
  String buildFullRecipe({
    required String title,
    required String dishType,
    required String difficulty,
    required List<String> mainIngredients,
    required List<String> availableIngredients,
    int servings = 2,
    List<String> forbiddenIngredients = const [],
    String? retryReason,
  }) {
    return renderTemplate(fullRecipeTemplate, {
      'title': title,
      'dish_type': dishType,
      'difficulty': difficulty,
      'servings': servings.toString(),
      'main_ingredients': mainIngredients,
      'available_ingredients': availableIngredients,
      'forbidden_ingredients': forbiddenIngredients,
      'retry_reason': retryReason,
    });
  }

  /// Builds user prompt for `month_plan`.
  String buildMonthPlan({
    required String dateFrom,
    required String dateTo,
    List<String> lockedDays = const [],
    List<String> history30d = const [],
    List<String> forbiddenIngredients = const [],
    List<String> likes = const [],
    List<String> dislikes = const [],
    Map<String, double>? dishTypeShares,
    bool soupsDisliked = false,
  }) {
    final sharesStr = dishTypeShares != null
        ? dishTypeShares.entries
              .map((e) => '${e.key}: ${(e.value * 100).round()}%')
              .join(', ')
        : 'по умолчанию';

    return renderTemplate(monthPlanTemplate, {
      'date_from': dateFrom,
      'date_to': dateTo,
      'locked_days': lockedDays,
      'history_30d': history30d.take(30).toList(),
      'forbidden_ingredients': forbiddenIngredients,
      'likes': likes.take(5).toList(),
      'dislikes': dislikes.take(5).toList(),
      'dish_type_shares': sharesStr,
      'soups_disliked': soupsDisliked,
    });
  }
}

/// Helper to load JSON schemas for AI queries.
class AiSchemas {
  static AssetStringLoader? assetLoader;

  static Map<String, dynamic>? _cachedSuggestDishes;
  static Map<String, dynamic>? _cachedFullRecipe;
  static Map<String, dynamic>? _cachedMonthPlan;

  static Future<Map<String, dynamic>> loadSuggestDishesSchema() async {
    if (_cachedSuggestDishes != null) return _cachedSuggestDishes!;
    final str = await _loadSchemaAsset(
      'assets/ai/schemas/suggest_dishes.schema.json',
    );
    _cachedSuggestDishes = jsonDecode(str) as Map<String, dynamic>;
    return _cachedSuggestDishes!;
  }

  static Future<Map<String, dynamic>> loadFullRecipeSchema() async {
    if (_cachedFullRecipe != null) return _cachedFullRecipe!;
    final str = await _loadSchemaAsset(
      'assets/ai/schemas/full_recipe.schema.json',
    );
    _cachedFullRecipe = jsonDecode(str) as Map<String, dynamic>;
    return _cachedFullRecipe!;
  }

  static Future<Map<String, dynamic>> loadMonthPlanSchema() async {
    if (_cachedMonthPlan != null) return _cachedMonthPlan!;
    final str = await _loadSchemaAsset(
      'assets/ai/schemas/month_plan.schema.json',
    );
    _cachedMonthPlan = jsonDecode(str) as Map<String, dynamic>;
    return _cachedMonthPlan!;
  }

  static Future<String> _loadSchemaAsset(String path) async {
    if (assetLoader != null) {
      try {
        return await assetLoader!(path);
      } catch (_) {}
    }
    final f = File(path);
    if (f.existsSync()) return f.readAsStringSync();
    final specFile = File(path.replaceAll('assets/ai/', 'spec/ai/'));
    if (specFile.existsSync()) return specFile.readAsStringSync();
    throw FileSystemException('Cannot find schema asset or file', path);
  }
}
