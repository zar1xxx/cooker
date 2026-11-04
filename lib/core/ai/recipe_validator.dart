import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

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

class RecipeValidator {
  final Map<String, dynamic> safetyMinimums;

  const RecipeValidator({required this.safetyMinimums});

  static Future<RecipeValidator> fromAsset({String? jsonString}) async {
    final content =
        jsonString ??
        await rootBundle.loadString('assets/ai/safety_minimums.json');
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    return RecipeValidator(safetyMinimums: decoded);
  }

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
  }) {
    // 1. Structure checks
    final servings = (recipe['servings'] as num?)?.toInt() ?? 2;
    if (servings < 1 || servings > 12) {
      return const Retryable('Количество порций должно быть от 1 до 12.');
    }

    final steps = (recipe['steps'] as List?) ?? const [];
    if (steps.length < 2) {
      return const Retryable('Рецепт должен содержать не менее 2 шагов.');
    }

    final totalMinutes = (recipe['total_minutes'] as num?)?.toInt() ?? 0;
    if (totalMinutes <= 0) {
      return const Retryable('Время приготовления должно быть больше 0 минут.');
    }

    int sumTimersSeconds = 0;
    for (final s in steps) {
      if (s is Map<String, dynamic>) {
        final timer = (s['timer_seconds'] as num?)?.toInt() ?? 0;
        sumTimersSeconds += timer;
      }
    }

    final maxAllowedTimerSeconds = (totalMinutes * 60 * 1.1).round();
    if (sumTimersSeconds > maxAllowedTimerSeconds) {
      return Retryable(
        'Сумма таймеров ($sumTimersSeconds с) превышает общее время с допуском 10% ($maxAllowedTimerSeconds с).',
      );
    }

    // 2. Stop-list check
    final stopList =
        (safetyMinimums['stop_list'] as List?)?.cast<String>() ?? const [];
    final rawText = StringBuffer();
    rawText.write('${recipe['title']} ${recipe['description']} ');

    final rawIngredients = (recipe['ingredients'] as List?) ?? const [];
    final ingredientIds = <String>{};
    final ingredientEntries = <_IngredientEntry>[];

    for (final ing in rawIngredients) {
      if (ing is Map<String, dynamic>) {
        final name = ing['name']?.toString() ?? '';
        var id = ing['ingredient_id']?.toString() ?? '';
        if (id.isEmpty && name.isNotEmpty && resolveIngredientId != null) {
          id = resolveIngredientId(name) ?? '';
        }
        if (id.isNotEmpty) ingredientIds.add(id);
        ingredientEntries.add(
          _IngredientEntry(
            id: id,
            amount: (ing['amount'] as num?)?.toDouble(),
            unit: ing['unit']?.toString(),
          ),
        );
        rawText.write('$id $name ${ing['note'] ?? ''} ');
      }
    }

    for (final s in steps) {
      if (s is Map<String, dynamic>) {
        rawText.write('${s['text']} ${s['tip'] ?? ''} ');
      }
    }

    final fullTextLower = rawText.toString().toLowerCase();

    for (final stopItem in stopList) {
      final itemLower = stopItem.toLowerCase().trim();
      if (fullTextLower.contains(itemLower)) {
        return Rejected(
          'Обнаружен опасный или запрещённый компонент: $stopItem',
        );
      }
    }

    // 3. Allergens and exclusions check
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

    // 4. Heat treatment checks
    final dishType = recipe['dish_type']?.toString();
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

          // Also check explicit minutes mention in text like "20 минут", "25 мин"
          final minutesRegex = RegExp(r'(\d+)\s*(?:мин|минут)');
          final matches = minutesRegex.allMatches(stepText);
          for (final m in matches) {
            final mins = int.tryParse(m.group(1) ?? '0') ?? 0;
            if (mins >= minMinutes) {
              hasSufficientStep = true;
              break;
            }
          }
          if (hasSufficientStep) break;
        }

        // A long total time does not prove the meat itself was cooked long
        // enough: require a cooking step with a sufficient duration.
        if (!hasSufficientStep) {
          return Retryable(
            'Для $category требуется тепловая обработка не менее $minMinutes минут.',
          );
        }
      }
    }

    // 5. Per-serving limits warnings
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

      if (ingId == 'salt') {
        final limit = (perServingLimits['salt_g'] as num?)?.toDouble() ?? 10.0;
        if (perServing > limit) {
          warnings.add(
            'Количество соли (${perServing.toStringAsFixed(1)} г на порцию) превышает рекомендуемый лимит ($limit г).',
          );
        }
      } else if (ingId == 'sugar') {
        final limit = (perServingLimits['sugar_g'] as num?)?.toDouble() ?? 80.0;
        if (perServing > limit) {
          warnings.add(
            'Количество сахара (${perServing.toStringAsFixed(1)} г на порцию) превышает рекомендуемый лимит ($limit г).',
          );
        }
      } else if (ingId == 'sunflower_oil' || ingId == 'olive_oil') {
        final limit = (perServingLimits['oil_ml'] as num?)?.toDouble() ?? 50.0;
        if (perServing > limit) {
          warnings.add(
            'Количество масла (${perServing.toStringAsFixed(1)} мл на порцию) превышает рекомендуемый лимит ($limit мл).',
          );
        }
      } else if (ingId == 'butter') {
        final limit =
            (perServingLimits['butter_g'] as num?)?.toDouble() ?? 60.0;
        if (perServing > limit) {
          warnings.add(
            'Количество сливочного масла (${perServing.toStringAsFixed(1)} г на порцию) превышает рекомендуемый лимит ($limit г).',
          );
        }
      }
    }

    return Valid(warnings);
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
