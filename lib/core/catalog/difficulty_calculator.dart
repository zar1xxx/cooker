import '../db/enums.dart';

/// Points and detailed reasons explaining a recipe's calculated difficulty.
class DifficultyScore {
  const DifficultyScore({
    required this.difficulty,
    required this.points,
    required this.reasons,
    required this.detectedTechniques,
  });

  final Difficulty difficulty;
  final int points;
  final List<String> reasons;
  final Set<String> detectedTechniques;

  @override
  String toString() =>
      'DifficultyScore(${difficulty.name}, points: $points, reasons: $reasons)';
}

/// Rule-based difficulty calculator per R8-10.
/// Calculates difficulty from active minutes, steps, ingredients, and culinary techniques.
class DifficultyCalculator {
  const DifficultyCalculator._();

  // Threshold constants
  static const int easyMaxPoints = 3;
  static const int mediumMaxPoints = 7;
  // hard >= 8

  /// Evaluates difficulty score from recipe attributes and step texts.
  static DifficultyScore calculate({
    required String title,
    required int activeMinutes,
    required int stepCount,
    required int ingredientCount,
    List<String>? stepTexts,
    String? description,
  }) {
    int totalPoints = 0;
    final reasons = <String>[];
    final detectedTechniques = <String>{};

    // 1. Active minutes points
    if (activeMinutes > 50) {
      totalPoints += 3;
      reasons.add('Длительное активное время (> 50 мин)');
    } else if (activeMinutes >= 31) {
      totalPoints += 2;
      reasons.add('Активное время 31–50 мин');
    } else if (activeMinutes >= 16) {
      totalPoints += 1;
      reasons.add('Активное время 16–30 мин');
    }

    // 2. Step count points
    if (stepCount >= 11) {
      totalPoints += 3;
      reasons.add('Много шагов (11+)');
    } else if (stepCount >= 8) {
      totalPoints += 2;
      reasons.add('8–10 шагов приготовления');
    } else if (stepCount >= 5) {
      totalPoints += 1;
      reasons.add('5–7 шагов приготовления');
    }

    // 3. Ingredient count points
    if (ingredientCount >= 13) {
      totalPoints += 3;
      reasons.add('Много ингредиентов (13+)');
    } else if (ingredientCount >= 9) {
      totalPoints += 2;
      reasons.add('9–12 ингредиентов');
    } else if (ingredientCount >= 6) {
      totalPoints += 1;
      reasons.add('6–8 ингредиентов');
    }

    // 4. Techniques detected from text (title, description, and steps)
    final combinedText = [
      title,
      description ?? '',
      ...(stepTexts ?? const <String>[]),
    ].join(' ').toLowerCase();

    // Multi-layer baking / pastry sheets (+3 pts)
    if (_matchesAny(combinedText, [
      'слоен',
      'корж',
      'слоев',
      'пропитк',
      'выпекать корж',
      'наполеон',
      'медовик',
      'пахлав',
      'круассан',
    ])) {
      totalPoints += 3;
      detectedTechniques.add('multi_layer_baking');
      reasons.add('Многослойная выпечка / коржи (+3)');
    }

    // Proofing / yeast dough (+2 pts)
    if (_matchesAny(combinedText, [
      'расстойк',
      'опар',
      'дрожжев',
      'дать подняться тест',
      'поднимется тест',
      'в теплое место для подъем',
      'в тёплое место для подъем',
      'кулебяк',
      'хачапури',
    ])) {
      totalPoints += 2;
      detectedTechniques.add('proofing');
      reasons.add('Расстойка дрожжевого теста (+2)');
    }

    // Dough rolling with rolling pin (+2 pts)
    if (_matchesAny(combinedText, [
      'раскатать',
      'раскатыва',
      'скалк',
      'раскатк',
      'раскатай',
    ])) {
      totalPoints += 2;
      detectedTechniques.add('dough_rolling');
      reasons.add('Раскатка теста (+2)');
    }

    // Caramel / confectionery temperature control (+2 pts)
    if (_matchesAny(combinedText, [
      'карамел',
      'темперир',
      'до янтарного цвет',
      'макарон',
      'глазирование',
      'эклеры',
    ])) {
      totalPoints += 2;
      detectedTechniques.add('caramel');
      reasons.add('Карамелизация / глазирование (+2)');
    }

    // Complex molding: dumplings / varenyky / khinkali (+1 pt)
    if (_matchesAny(combinedText, [
      'пельмен',
      'вареник',
      'хинкал',
      'лепить пельмени',
      'лепим пельмени',
      'лепим вареники',
      'защипну',
    ])) {
      totalPoints += 1;
      detectedTechniques.add('molding_complex');
      reasons.add('Лепка пельменей/вареников (+1)');
    } else if (_matchesAny(combinedText, [
      // Simple molding: patties / syrniki (+1 pt)
      'котлет',
      'сырник',
      'сформировать',
      'сформовать',
      'формуем',
      'слепи',
      'голубц',
      'оладь',
    ])) {
      totalPoints += 1;
      detectedTechniques.add('molding_simple');
      reasons.add('Формование (+1)');
    }

    // Baking / roasting in oven (+1 pt)
    if (_matchesAny(combinedText, [
      'выпек',
      'выпекать',
      'духовк',
      'запекани',
      'запечь',
      'шарлотк',
      'бисквит',
    ])) {
      totalPoints += 1;
      detectedTechniques.add('baking_oven');
      reasons.add('Выпекание в духовке (+1)');
    }

    // Pancake frying / batter preparation (+1 pt)
    if (_matchesAny(combinedText, ['блин', 'блинчик', 'оладь', 'панкейк'])) {
      totalPoints += 1;
      detectedTechniques.add('pancake_batter');
      reasons.add('Приготовление блинов/оладий (+1)');
    }

    // Water bath / delicate emulsion (+1 pt)
    if (_matchesAny(combinedText, [
      'водян баня',
      'водяной бан',
      'на пару',
      'суфле',
    ])) {
      totalPoints += 1;
      detectedTechniques.add('water_bath');
      reasons.add('Водяная баня (+1)');
    }

    // Deep frying (+1 pt)
    if (_matchesAny(combinedText, [
      'фритюр',
      'в большом количестве масла',
      'фритюрниц',
    ])) {
      totalPoints += 1;
      detectedTechniques.add('deep_frying');
      reasons.add('Жарка во фритюре (+1)');
    }

    // Simultaneous processes (+1 pt)
    if (_matchesAny(combinedText, [
      'пока варится',
      'пока закипает',
      'пока запекается',
      'пока тушится',
      'параллельно',
      'одновременно',
      'тем временем',
      'солянк',
      'лазань',
      'борщ',
      'холодец',
      'оливье',
    ])) {
      totalPoints += 1;
      detectedTechniques.add('simultaneous_processes');
      reasons.add('Параллельные процессы (+1)');
    }

    Difficulty difficulty;
    if (totalPoints <= easyMaxPoints) {
      difficulty = Difficulty.easy;
    } else if (totalPoints <= mediumMaxPoints) {
      difficulty = Difficulty.medium;
    } else {
      difficulty = Difficulty.hard;
    }

    return DifficultyScore(
      difficulty: difficulty,
      points: totalPoints,
      reasons: reasons,
      detectedTechniques: detectedTechniques,
    );
  }

  /// Calculates difficulty score from a raw JSON map (as in seed files or AI payloads).
  static DifficultyScore calculateFromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? '';
    final totalMinutes = json['total_minutes'] as int? ?? 30;
    var activeMinutes = json['active_minutes'] as int?;
    if (activeMinutes == null || activeMinutes <= 0) {
      activeMinutes = totalMinutes <= 20
          ? totalMinutes
          : (totalMinutes * 0.5).round();
    }

    final rawIngredients = json['ingredients'] as List?;
    final ingredientCount = rawIngredients?.length ?? 0;

    final rawSteps = json['steps'] as List?;
    final stepTexts = <String>[];
    if (rawSteps != null) {
      for (final s in rawSteps) {
        if (s is String) {
          stepTexts.add(s);
        } else if (s is Map<String, dynamic>) {
          stepTexts.add(
            s['text']?.toString() ?? s['description']?.toString() ?? '',
          );
        }
      }
    }
    final stepCount = stepTexts.isNotEmpty
        ? stepTexts.length
        : (rawSteps?.length ?? 0);
    final description = json['description'] as String?;

    return calculate(
      title: title,
      activeMinutes: activeMinutes,
      stepCount: stepCount,
      ingredientCount: ingredientCount,
      stepTexts: stepTexts,
      description: description,
    );
  }

  static bool _matchesAny(String text, List<String> patterns) {
    for (final p in patterns) {
      if (text.contains(p)) return true;
    }
    return false;
  }
}
