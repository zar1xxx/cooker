import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

import 'ai_provider.dart';

sealed class ValidationResult {
  const ValidationResult();
}

class Valid extends ValidationResult {
  final List<String> warnings;
  const Valid([this.warnings = const []]);

  @override
  String toString() => 'Valid(warnings: $warnings)';
}

class Retryable extends ValidationResult {
  final String reasonForModel;
  const Retryable(this.reasonForModel);

  @override
  String toString() => 'Retryable(reason: $reasonForModel)';
}

class Rejected extends ValidationResult {
  final String reason;
  const Rejected(this.reason);

  @override
  String toString() => 'Rejected(reason: $reason)';
}

/// Allowed dish types per ТЗ 4.2 & spec/data/enums.json
const allowedDishTypes = <String>{
  'soup',
  'main',
  'side',
  'salad',
  'breakfast',
  'snack',
  'baking',
  'dessert',
  'drink',
  'preserve',
};

/// Allowed recipe difficulty levels per ТЗ 4.2 & spec/data/enums.json
const allowedDifficulties = <String>{'easy', 'medium', 'hard'};

/// Allowed units of measurement per spec/data/enums.json & full_recipe.schema.json
const allowedUnits = <String>{
  'g',
  'kg',
  'ml',
  'l',
  'pcs',
  'tbsp',
  'tsp',
  'cup',
  'pinch',
  'to_taste',
};

/// Full recipe and dish validator per ТЗ 9.1 and `spec/ai/safety_minimums.json`.
class RecipeValidator {
  final Map<String, dynamic> safetyMinimums;

  const RecipeValidator({required this.safetyMinimums});

  static Future<RecipeValidator> fromAsset({String? jsonString}) async {
    String content;
    if (jsonString != null) {
      content = jsonString;
    } else {
      try {
        content = await rootBundle.loadString('assets/ai/safety_minimums.json');
      } catch (_) {
        final f = File('assets/ai/safety_minimums.json');
        if (f.existsSync()) {
          content = f.readAsStringSync();
        } else {
          content = File('spec/ai/safety_minimums.json').readAsStringSync();
        }
      }
    }
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    return RecipeValidator(safetyMinimums: decoded);
  }

  /// Validates a single full recipe against schema, structure, heat treatment,
  /// stop-list, allergens, and per-serving ingredient limits (ТЗ 9.1).
  ///
  /// On [attempt] >= 2, recoverable issues that would produce [Retryable] return
  /// [Rejected] instead per ТЗ 9.1 ("Повтор запроса с текстом ошибки, затем отказ").
  ValidationResult validate(
    Map<String, dynamic> recipe, {
    Map<String, dynamic>? profile,
    Map<String, List<String>>? ingredientHierarchy, // child -> parents
    // Maps an ingredient name from an AI response to a catalog id
    // (IngredientNormalizer). AI recipes carry `name`, not `ingredient_id`.
    String? Function(String name)? resolveIngredientId,
    // Forbidden id -> words to search in recipe text: name, synonyms and the
    // names of all descendants (e.g. nuts -> орехи, грецкие орехи, фундук).
    Map<String, List<String>>? forbiddenTerms,
    int attempt = 1,
    bool strictSchema = false,
  }) {
    ValidationResult fail(String reason) =>
        attempt >= 2 ? Rejected(reason) : Retryable(reason);

    // 1. Schema & Structure checks
    final title = recipe['title'];
    if (title is! String ||
        title.trim().length < 2 ||
        title.trim().length > 80) {
      return fail('Название блюда должно быть строкой от 2 до 80 символов.');
    }

    final dishType = recipe['dish_type']?.toString();
    if (dishType == null || !allowedDishTypes.contains(dishType)) {
      return fail(
        'Недопустимый тип блюда: $dishType. Допустимые: ${allowedDishTypes.join(', ')}.',
      );
    }

    final difficulty = recipe['difficulty']?.toString();
    if (difficulty != null && !allowedDifficulties.contains(difficulty)) {
      return fail(
        'Недопустимая сложность: $difficulty. Допустимые: easy, medium, hard.',
      );
    }
    if (strictSchema && difficulty == null) {
      return fail('Поле difficulty обязательно (easy, medium, hard).');
    }

    final cuisine = recipe['cuisine'];
    if (cuisine != null && (cuisine is! String || cuisine.length > 40)) {
      return fail('Поле cuisine должно быть строкой длиной до 40 символов.');
    }
    if (strictSchema && cuisine == null) {
      return fail('Поле cuisine обязательно.');
    }

    final totalMinutes = (recipe['total_minutes'] as num?)?.toInt() ?? 0;
    if (totalMinutes < 5 || totalMinutes > 600) {
      return fail('Время приготовления должно быть от 5 до 600 минут.');
    }

    final activeMinutes = (recipe['active_minutes'] as num?)?.toInt();
    if (activeMinutes != null) {
      if (activeMinutes < 1 || activeMinutes > 600) {
        return fail(
          'Активное время приготовления должно быть от 1 до 600 минут.',
        );
      }
      if (activeMinutes > totalMinutes) {
        return fail(
          'Активное время ($activeMinutes мин) не может превышать общее ($totalMinutes мин).',
        );
      }
    } else if (strictSchema) {
      return fail('Поле active_minutes обязательно.');
    }

    final servings = (recipe['servings'] as num?)?.toInt() ?? 2;
    if (servings < 1 || servings > 12) {
      return fail('Количество порций должно быть от 1 до 12.');
    }

    final description = recipe['description'];
    if (description != null &&
        (description is! String || description.length > 300)) {
      return fail('Описание блюда должно быть строкой до 300 символов.');
    }
    if (strictSchema && description == null) {
      return fail('Поле description обязательно.');
    }

    final rawIngredients = recipe['ingredients'];
    if (rawIngredients is! List ||
        rawIngredients.isEmpty ||
        rawIngredients.length > 25) {
      return fail('Рецепт должен содержать от 1 до 25 ингредиентов.');
    }

    final ingredientIds = <String>{};
    final ingredientEntries = <_IngredientEntry>[];
    final rawText = StringBuffer();
    rawText.write('$title ${description ?? ''} ');

    for (final ing in rawIngredients) {
      if (ing is! Map<String, dynamic>) {
        return fail('Каждый ингредиент должен быть объектом.');
      }
      final name = ing['name']?.toString() ?? '';
      var id = ing['ingredient_id']?.toString() ?? '';
      if (name.isEmpty && id.isEmpty) {
        return fail('У каждого ингредиента должно быть указано название.');
      }
      if (name.length > 80) {
        return fail(
          'Название ингредиента не должно превышать 80 символов: $name.',
        );
      }

      final amount = (ing['amount'] as num?)?.toDouble();
      if (amount != null && amount < 0) {
        return fail(
          'Количество ингредиента не может быть отрицательным: $name.',
        );
      }

      final unit = ing['unit']?.toString();
      if (unit == null || !allowedUnits.contains(unit)) {
        return fail(
          'Недопустимая единица измерения у ингредиента "$name": $unit. Допустимые: ${allowedUnits.join(', ')}.',
        );
      }

      final isOptional = ing['is_optional'];
      if (strictSchema && isOptional is! bool) {
        return fail('Поле is_optional обязательно для ингредиента "$name".');
      }

      final note = ing['note'];
      if (note != null && (note is! String || note.length > 80)) {
        return fail(
          'Примечание к ингредиенту не должно превышать 80 символов: $name.',
        );
      }

      if (id.isEmpty && name.isNotEmpty && resolveIngredientId != null) {
        id = resolveIngredientId(name) ?? '';
      }
      if (id.isNotEmpty) ingredientIds.add(id);

      ingredientEntries.add(
        _IngredientEntry(id: id, amount: amount, unit: unit),
      );
      rawText.write('$id $name ${ing['note'] ?? ''} ');
    }

    final steps = recipe['steps'];
    if (steps is! List || steps.length < 2 || steps.length > 20) {
      return fail('Рецепт должен содержать от 2 до 20 шагов.');
    }

    int sumTimersSeconds = 0;
    for (final s in steps) {
      if (s is! Map<String, dynamic>) {
        return fail('Каждый шаг должен быть объектом.');
      }
      final text = s['text'];
      if (text is! String ||
          text.trim().length < 3 ||
          text.trim().length > 240) {
        return fail(
          'Текст каждого шага должен быть строкой от 3 до 240 символов.',
        );
      }

      final timer = (s['timer_seconds'] as num?)?.toInt();
      if (timer != null) {
        if (timer < 0 || timer > 36000) {
          return fail('Время таймера шага должно быть от 0 до 36000 секунд.');
        }
        sumTimersSeconds += timer;
      }

      final tip = s['tip'];
      if (tip != null && (tip is! String || tip.length > 160)) {
        return fail('Совет к шагу не должен превышать 160 символов.');
      }

      rawText.write('$text ${tip ?? ''} ');
    }

    final maxAllowedTimerSeconds = (totalMinutes * 60 * 1.1).round();
    if (sumTimersSeconds > maxAllowedTimerSeconds) {
      return fail(
        'Сумма таймеров ($sumTimersSeconds с) превышает общее время с допуском 10% ($maxAllowedTimerSeconds с).',
      );
    }

    final fullTextLower = rawText.toString().toLowerCase();

    // 2. Stop-list check (inedible & dangerous items) -> always Rejected
    final stopList =
        (safetyMinimums['stop_list'] as List?)?.cast<String>() ?? const [];

    for (final stopItem in stopList) {
      final itemLower = stopItem.toLowerCase().trim();
      if (itemLower.isNotEmpty && fullTextLower.contains(itemLower)) {
        return Rejected(
          'Обнаружен опасный или запрещённый компонент: $stopItem',
        );
      }
    }

    // 3. Allergens and exclusions check -> always Rejected
    if (profile != null) {
      final allergies = (profile['allergies'] as List?)?.cast<String>() ?? [];
      final exclusions =
          (profile['excluded_ingredients'] as List?)?.cast<String>() ?? [];
      final forbidden = {...allergies, ...exclusions};

      for (final bad in forbidden) {
        final badLower = bad.toLowerCase().trim();
        // Check direct id match
        if (ingredientIds.contains(badLower)) {
          return Rejected('Рецепт содержит исключённый продукт: $bad');
        }

        // Check hierarchy (if an ingredient's parent is forbidden)
        if (ingredientHierarchy != null) {
          for (final ingId in ingredientIds) {
            final parents = ingredientHierarchy[ingId] ?? const [];
            if (parents.contains(badLower)) {
              return Rejected(
                'Рецепт содержит $ingId, относящийся к исключённой категории: $bad',
              );
            }
          }
        }

        // Check text: by the forbidden product's words (name, synonyms,
        // descendants), falling back to the raw value.
        final terms = forbiddenTerms?[badLower] ?? [badLower];
        for (final term in terms) {
          final t = term.toLowerCase().trim();
          if (t.isNotEmpty && fullTextLower.contains(t)) {
            return Rejected(
              'Текст рецепта упоминает исключённый продукт: $bad ($t)',
            );
          }
        }
      }
    }

    // 4. Heat treatment checks (poultry, minced meat, pork, beef, fish, eggs, dry beans, mushrooms)
    final heatRules =
        (safetyMinimums['heat_treatment'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const [];

    for (final rule in heatRules) {
      final exceptDishTypes =
          (rule['except_dish_types'] as List?)?.cast<String>() ?? const [];
      if (exceptDishTypes.contains(dishType)) {
        continue;
      }

      final targetIds =
          (rule['ingredient_ids'] as List?)?.cast<String>() ?? const [];
      final hasTargetIngredient = ingredientIds.any(
        (id) =>
            targetIds.contains(id) ||
            (ingredientHierarchy?[id] ?? const <String>[]).any(
              targetIds.contains,
            ),
      );

      if (hasTargetIngredient) {
        final category = rule['category'] ?? 'продукт';
        final minMinutes = (rule['min_minutes'] as num?)?.toInt() ?? 10;
        final keywords =
            (rule['keywords'] as List?)?.cast<String>() ?? const [];

        // Check if at least one step contains keyword with sufficient duration
        bool hasSufficientStep = false;

        for (final s in steps) {
          if (s is! Map<String, dynamic>) continue;
          final stepText = (s['text']?.toString() ?? '').toLowerCase();
          final containsKeyword = keywords.any((k) => stepText.contains(k));
          if (!containsKeyword) continue;

          // Check timer_seconds
          final stepTimerSec = (s['timer_seconds'] as num?)?.toInt() ?? 0;
          if (stepTimerSec >= minMinutes * 60) {
            hasSufficientStep = true;
            break;
          }

          // Check explicit minutes mention in text like "20 минут", "25 мин", "22 минуты"
          final minutesRegex = RegExp(r'(\d+)\s*(?:мин|минут|минуты)');
          final matches = minutesRegex.allMatches(stepText);
          for (final m in matches) {
            final mins = int.tryParse(m.group(1) ?? '0') ?? 0;
            if (mins >= minMinutes) {
              hasSufficientStep = true;
              break;
            }
          }
          if (hasSufficientStep) break;

          // Check explicit hours mention in text like "1 час", "1.5 часа", "2 часа"
          final hoursRegex = RegExp(
            r'(\d+(?:[.,]\d+)?)\s*(?:ч|час|часа|часов)',
          );
          final hourMatches = hoursRegex.allMatches(stepText);
          for (final m in hourMatches) {
            final hStr = (m.group(1) ?? '0').replaceAll(',', '.');
            final hours = double.tryParse(hStr) ?? 0.0;
            if (hours * 60 >= minMinutes) {
              hasSufficientStep = true;
              break;
            }
          }
          if (hasSufficientStep) break;
        }

        // A long total time does not prove the meat itself was cooked long
        // enough: require a cooking step with a sufficient duration.
        if (!hasSufficientStep) {
          return fail(
            'Для $category требуется тепловая обработка не менее $minMinutes минут.',
          );
        }
      }
    }

    // 5. Per-serving limits warnings (salt, sugar, oil, butter, vinegar, chili)
    final warnings = <String>[];
    final perServingLimits =
        (safetyMinimums['per_serving_limits'] as Map<String, dynamic>?) ??
        const {};

    for (final ing in ingredientEntries) {
      final ingId = ing.id;
      if (ingId.isEmpty) continue;
      final amount = ing.amount;
      if (amount == null || servings <= 0) continue;

      final baseAmount = _toBaseAmount(amount, ing.unit, ingId);
      if (baseAmount == null) continue;
      final perServing = baseAmount / servings;
      final ancestors = ingredientHierarchy?[ingId] ?? const <String>[];

      if (ingId == 'salt' || ancestors.contains('salt')) {
        final limit = (perServingLimits['salt_g'] as num?)?.toDouble() ?? 10.0;
        if (perServing > limit) {
          warnings.add(
            'Количество соли (${perServing.toStringAsFixed(1)} г на порцию) превышает рекомендуемый лимит ($limit г).',
          );
        }
      } else if (ingId == 'sugar' || ancestors.contains('sugar')) {
        final limit = (perServingLimits['sugar_g'] as num?)?.toDouble() ?? 80.0;
        if (perServing > limit) {
          warnings.add(
            'Количество сахара (${perServing.toStringAsFixed(1)} г на порцию) превышает рекомендуемый лимит ($limit г).',
          );
        }
      } else if (ingId == 'sunflower_oil' ||
          ingId == 'olive_oil' ||
          ingId == 'oil' ||
          ingId == 'vegetable_oil' ||
          ancestors.contains('sunflower_oil') ||
          ancestors.contains('olive_oil') ||
          ancestors.contains('oil')) {
        final limit = (perServingLimits['oil_ml'] as num?)?.toDouble() ?? 50.0;
        if (perServing > limit) {
          warnings.add(
            'Количество масла (${perServing.toStringAsFixed(1)} мл на порцию) превышает рекомендуемый лимит ($limit мл).',
          );
        }
      } else if (ingId == 'butter' || ancestors.contains('butter')) {
        final limit =
            (perServingLimits['butter_g'] as num?)?.toDouble() ?? 60.0;
        if (perServing > limit) {
          warnings.add(
            'Количество сливочного масла (${perServing.toStringAsFixed(1)} г на порцию) превышает рекомендуемый лимит ($limit г).',
          );
        }
      } else if (ingId == 'vinegar' ||
          ingId.endsWith('_vinegar') ||
          ancestors.contains('vinegar')) {
        final limit =
            (perServingLimits['vinegar_ml'] as num?)?.toDouble() ?? 30.0;
        if (perServing > limit) {
          warnings.add(
            'Количество уксуса (${perServing.toStringAsFixed(1)} мл на порцию) превышает рекомендуемый лимит ($limit мл).',
          );
        }
      } else if (ingId == 'chili' ||
          ingId == 'chili_pepper' ||
          ingId == 'hot_pepper' ||
          ancestors.contains('chili_pepper')) {
        final limit =
            (perServingLimits['chili_pcs'] as num?)?.toDouble() ?? 1.0;
        if (perServing > limit) {
          warnings.add(
            'Количество острого перца (${perServing.toStringAsFixed(1)} шт на порцию) превышает рекомендуемый лимит ($limit шт).',
          );
        }
      }
    }

    return Valid(warnings);
  }

  /// Validates the `suggest_dishes` response (`spec/ai/schemas/suggest_dishes.schema.json`).
  ValidationResult validateDishes(
    Map<String, dynamic> data, {
    Map<String, dynamic>? profile,
    Map<String, List<String>>? ingredientHierarchy,
    String? Function(String name)? resolveIngredientId,
    Map<String, List<String>>? forbiddenTerms,
    int attempt = 1,
  }) {
    ValidationResult fail(String reason) =>
        attempt >= 2 ? Rejected(reason) : Retryable(reason);

    final dishes = data['dishes'];
    if (dishes is! List || dishes.isEmpty || dishes.length > 8) {
      return fail('Список блюд должен содержать от 1 до 8 вариантов.');
    }

    final stopList =
        (safetyMinimums['stop_list'] as List?)?.cast<String>() ?? const [];

    final allergies =
        (profile?['allergies'] as List?)?.cast<String>() ?? const [];
    final exclusions =
        (profile?['excluded_ingredients'] as List?)?.cast<String>() ?? const [];
    final forbidden = {...allergies, ...exclusions};

    for (int i = 0; i < dishes.length; i++) {
      final dish = dishes[i];
      if (dish is! Map<String, dynamic>) {
        return fail('Элемент $i в списке блюд должен быть объектом.');
      }

      final title = dish['title'];
      if (title is! String ||
          title.trim().length < 2 ||
          title.trim().length > 80) {
        return fail(
          'Блюдо ${i + 1}: название должно быть от 2 до 80 символов.',
        );
      }

      final dishType = dish['dish_type']?.toString();
      if (dishType == null || !allowedDishTypes.contains(dishType)) {
        return fail(
          'Блюдо ${i + 1}: недопустимый тип $dishType. Допустимые: ${allowedDishTypes.join(', ')}.',
        );
      }

      final difficulty = dish['difficulty']?.toString();
      if (difficulty == null || !allowedDifficulties.contains(difficulty)) {
        return fail(
          'Блюдо ${i + 1}: недопустимая сложность $difficulty. Допустимые: easy, medium, hard.',
        );
      }

      final totalMinutes = (dish['total_minutes'] as num?)?.toInt() ?? 0;
      if (totalMinutes < 5 || totalMinutes > 600) {
        return fail(
          'Блюдо ${i + 1}: время приготовления должно быть от 5 до 600 минут.',
        );
      }

      final mainIngredients = dish['main_ingredients'];
      if (mainIngredients is! List ||
          mainIngredients.isEmpty ||
          mainIngredients.length > 6) {
        return fail(
          'Блюдо ${i + 1}: должно содержать от 1 до 6 основных ингредиентов.',
        );
      }

      final missing = dish['missing'];
      if (missing != null && (missing is! List || missing.length > 2)) {
        return fail(
          'Блюдо ${i + 1}: недостающих ингредиентов должно быть не более 2.',
        );
      }

      final why = dish['why'];
      if (why != null && (why is! String || why.length > 140)) {
        return fail(
          'Блюдо ${i + 1}: пояснение "why" не должно превышать 140 символов.',
        );
      }

      // Check stop-list & allergens for this dish
      final rawDishText = StringBuffer();
      rawDishText.write('$title ${why ?? ''} ');
      final dishIngredientIds = <String>{};

      for (final ing in mainIngredients) {
        final ingStr = ing.toString();
        rawDishText.write('$ingStr ');
        var id = ingStr;
        if (resolveIngredientId != null) {
          id = resolveIngredientId(ingStr) ?? ingStr;
        }
        dishIngredientIds.add(id);
      }

      if (missing is List) {
        for (final m in missing) {
          final mStr = m.toString();
          rawDishText.write('$mStr ');
          var id = mStr;
          if (resolveIngredientId != null) {
            id = resolveIngredientId(mStr) ?? mStr;
          }
          dishIngredientIds.add(id);
        }
      }

      final dishTextLower = rawDishText.toString().toLowerCase();

      for (final stopItem in stopList) {
        final itemLower = stopItem.toLowerCase().trim();
        if (itemLower.isNotEmpty && dishTextLower.contains(itemLower)) {
          return Rejected(
            'Обнаружен опасный или запрещённый компонент: $stopItem в блюде "$title"',
          );
        }
      }

      for (final bad in forbidden) {
        final badLower = bad.toLowerCase().trim();
        if (dishIngredientIds.contains(badLower)) {
          return Rejected('Блюдо "$title" содержит исключённый продукт: $bad');
        }

        if (ingredientHierarchy != null) {
          for (final ingId in dishIngredientIds) {
            final parents = ingredientHierarchy[ingId] ?? const [];
            if (parents.contains(badLower)) {
              return Rejected(
                'Блюдо "$title" содержит $ingId, относящийся к исключённой категории: $bad',
              );
            }
          }
        }

        final terms = forbiddenTerms?[badLower] ?? [badLower];
        for (final term in terms) {
          final t = term.toLowerCase().trim();
          if (t.isNotEmpty && dishTextLower.contains(t)) {
            return Rejected(
              'Блюдо "$title" упоминает исключённый продукт: $bad ($t)',
            );
          }
        }
      }
    }

    return const Valid();
  }

  /// Parses raw AI text (extracting JSON and stripping code fences), then validates as recipe.
  ValidationResult validateRawRecipeJson(
    String rawText, {
    Map<String, dynamic>? profile,
    Map<String, List<String>>? ingredientHierarchy,
    String? Function(String name)? resolveIngredientId,
    Map<String, List<String>>? forbiddenTerms,
    int attempt = 1,
    bool strictSchema = false,
  }) {
    final payload = extractJsonPayload(rawText);
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return attempt >= 2
            ? const Rejected('Ответ ИИ должен быть JSON-объектом.')
            : const Retryable('Ответ ИИ должен быть JSON-объектом.');
      }
      return validate(
        decoded,
        profile: profile,
        ingredientHierarchy: ingredientHierarchy,
        resolveIngredientId: resolveIngredientId,
        forbiddenTerms: forbiddenTerms,
        attempt: attempt,
        strictSchema: strictSchema,
      );
    } catch (e) {
      return attempt >= 2
          ? Rejected('Некорректный JSON в ответе ИИ: $e')
          : Retryable('Некорректный JSON в ответе ИИ: $e');
    }
  }

  /// Parses raw AI text (extracting JSON and stripping code fences), then validates as dishes suggestion.
  ValidationResult validateRawDishesJson(
    String rawText, {
    Map<String, dynamic>? profile,
    Map<String, List<String>>? ingredientHierarchy,
    String? Function(String name)? resolveIngredientId,
    Map<String, List<String>>? forbiddenTerms,
    int attempt = 1,
  }) {
    final payload = extractJsonPayload(rawText);
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return attempt >= 2
            ? const Rejected('Ответ ИИ должен содержать JSON-объект.')
            : const Retryable('Ответ ИИ должен содержать JSON-объект.');
      }
      return validateDishes(
        decoded,
        profile: profile,
        ingredientHierarchy: ingredientHierarchy,
        resolveIngredientId: resolveIngredientId,
        forbiddenTerms: forbiddenTerms,
        attempt: attempt,
      );
    } catch (e) {
      return attempt >= 2
          ? Rejected('Некорректный JSON в ответе ИИ: $e')
          : Retryable('Некорректный JSON в ответе ИИ: $e');
    }
  }

  /// Validates the `month_plan` response (`spec/ai/schemas/month_plan.schema.json`).
  ValidationResult validateMonthPlan(
    Map<String, dynamic> data, {
    Map<String, dynamic>? profile,
    Map<String, List<String>>? ingredientHierarchy,
    String? Function(String name)? resolveIngredientId,
    Map<String, List<String>>? forbiddenTerms,
    int attempt = 1,
  }) {
    ValidationResult fail(String reason) =>
        attempt >= 2 ? Rejected(reason) : Retryable(reason);

    final days = data['days'];
    if (days is! List || days.isEmpty || days.length > 7) {
      return fail('План должен содержать от 1 до 7 дней.');
    }

    final stopList =
        (safetyMinimums['stop_list'] as List?)?.cast<String>() ?? const [];

    final allergies =
        (profile?['allergies'] as List?)?.cast<String>() ?? const [];
    final exclusions =
        (profile?['excluded_ingredients'] as List?)?.cast<String>() ?? const [];
    final forbidden = {...allergies, ...exclusions};

    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      if (day is! Map<String, dynamic>) {
        return fail('Элемент $i в плане должен быть объектом.');
      }

      final date = day['date']?.toString();
      if (date == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
        return fail('День ${i + 1}: дата должна быть в формате YYYY-MM-DD.');
      }

      final title = day['title'];
      if (title is! String ||
          title.trim().length < 2 ||
          title.trim().length > 80) {
        return fail('День ${i + 1}: название должно быть от 2 до 80 символов.');
      }

      final dishType = day['dish_type']?.toString();
      if (dishType == null || !allowedDishTypes.contains(dishType)) {
        return fail(
          'День ${i + 1}: недопустимый тип $dishType. Допустимые: ${allowedDishTypes.join(', ')}.',
        );
      }

      final difficulty = day['difficulty']?.toString();
      if (difficulty == null || !allowedDifficulties.contains(difficulty)) {
        return fail(
          'День ${i + 1}: недопустимая сложность $difficulty. Допустимые: easy, medium, hard.',
        );
      }

      final mainIngredients = day['main_ingredients'];
      if (mainIngredients is! List ||
          mainIngredients.isEmpty ||
          mainIngredients.length > 4) {
        return fail(
          'День ${i + 1}: основных ингредиентов должно быть от 1 до 4.',
        );
      }

      // Check stop-list & allergens for this day
      final rawDayText = StringBuffer()..write('$title ');
      final dayIngredientIds = <String>{};

      for (final ing in mainIngredients) {
        final ingStr = ing.toString();
        rawDayText.write('$ingStr ');
        var id = ingStr;
        if (resolveIngredientId != null) {
          id = resolveIngredientId(ingStr) ?? ingStr;
        }
        dayIngredientIds.add(id);
      }

      final textLower = rawDayText.toString().toLowerCase();

      // Stop-list check
      for (final stopItem in stopList) {
        if (textLower.contains(stopItem.toLowerCase())) {
          return Rejected('Содержит опасные вещества: $stopItem');
        }
      }

      // Allergen & exclusion check
      for (final bad in forbidden) {
        final badLower = bad.toLowerCase().trim();
        if (dayIngredientIds.contains(badLower)) {
          return Rejected('Блюдо "$title" содержит исключённый продукт: $bad');
        }

        if (ingredientHierarchy != null) {
          for (final ingId in dayIngredientIds) {
            final ancestors = ingredientHierarchy[ingId] ?? const [];
            if (ancestors.contains(badLower)) {
              return Rejected('Блюдо "$title" содержит $ingId (потомок $bad)');
            }
          }
        }

        final terms = forbiddenTerms?[badLower] ?? [badLower];
        for (final term in terms) {
          final t = term.toLowerCase().trim();
          if (t.isNotEmpty && textLower.contains(t)) {
            return Rejected(
              'Блюдо "$title" упоминает исключённый продукт: $bad ($t)',
            );
          }
        }
      }
    }

    return const Valid();
  }

  /// Parses raw AI text (extracting JSON and stripping code fences), then validates as month plan.
  ValidationResult validateRawMonthPlanJson(
    String rawText, {
    Map<String, dynamic>? profile,
    Map<String, List<String>>? ingredientHierarchy,
    String? Function(String name)? resolveIngredientId,
    Map<String, List<String>>? forbiddenTerms,
    int attempt = 1,
  }) {
    final payload = extractJsonPayload(rawText);
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return attempt >= 2
            ? const Rejected('Ответ ИИ должен содержать JSON-объект.')
            : const Retryable('Ответ ИИ должен содержать JSON-объект.');
      }
      return validateMonthPlan(
        decoded,
        profile: profile,
        ingredientHierarchy: ingredientHierarchy,
        resolveIngredientId: resolveIngredientId,
        forbiddenTerms: forbiddenTerms,
        attempt: attempt,
      );
    } catch (e) {
      return attempt >= 2
          ? Rejected('Некорректный JSON в ответе ИИ: $e')
          : Retryable('Некорректный JSON в ответе ИИ: $e');
    }
  }

  /// Converts a household measure to grams/millilitres using
  /// `unit_to_base` from `safety_minimums.json`. Returns null when the unit
  /// cannot be converted, so the limit check is skipped instead of guessing.
  double? _toBaseAmount(double amount, String? unit, String ingredientId) {
    final u = unit?.toLowerCase().trim();
    if (u == null || u.isEmpty) return amount;

    const genericFactors = <String, double>{
      'g': 1,
      'ml': 1,
      'kg': 1000,
      'l': 1000,
      'pcs': 1,
    };
    final genericFactor = genericFactors[u];
    if (genericFactor != null) return amount * genericFactor;

    final unitMap = safetyMinimums['unit_to_base'];
    if (unitMap is Map) {
      final perIngredient = unitMap[ingredientId];
      if (perIngredient is Map) {
        final factor = (perIngredient[u] as num?)?.toDouble();
        if (factor != null) return amount * factor;
      }

      // Fallback for olive_oil using sunflower_oil
      if (ingredientId == 'olive_oil' || ingredientId.contains('oil')) {
        final oilMap = unitMap['sunflower_oil'];
        if (oilMap is Map) {
          final factor = (oilMap[u] as num?)?.toDouble();
          if (factor != null) return amount * factor;
        }
      }
    }

    // Household liquid measures fallback for vinegar or oils
    if (ingredientId.contains('vinegar') || ingredientId.contains('oil')) {
      if (u == 'tbsp') return amount * 15;
      if (u == 'tsp') return amount * 5;
      if (u == 'cup') return amount * 200;
    }

    return null;
  }
}

class _IngredientEntry {
  const _IngredientEntry({
    required this.id,
    required this.amount,
    required this.unit,
  });

  final String id;
  final double? amount;
  final String? unit;
}
