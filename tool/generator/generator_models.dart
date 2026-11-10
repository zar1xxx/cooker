class RawRecipe {
  final String id;
  final String title;
  final String dishType;
  final String dishGroup;
  final String cuisine;
  final int servings;
  final int totalMinutes;
  final int activeMinutes;
  final String description;
  final List<RawIngredient> ingredients;
  final List<RawStep> steps;

  const RawRecipe({
    required this.id,
    required this.title,
    required this.dishType,
    required this.dishGroup,
    required this.cuisine,
    required this.servings,
    required this.totalMinutes,
    required this.activeMinutes,
    required this.description,
    required this.ingredients,
    required this.steps,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dish_type': dishType,
      'dish_group': dishGroup,
      'cuisine': cuisine,
      'total_minutes': totalMinutes,
      'active_minutes': activeMinutes,
      'servings': servings,
      'description': description,
      'ingredients': ingredients.map((ing) => ing.toJson()).toList(),
      'steps': steps.map((st) => st.toJson()).toList(),
    };
  }
}

class RawIngredient {
  final String id;
  final double? amount;
  final String unit;
  final bool isOptional;

  const RawIngredient(
    this.id,
    this.amount,
    this.unit, [
    this.isOptional = false,
  ]);

  Map<String, dynamic> toJson() {
    return {
      'ingredient_id': id,
      'amount': amount,
      'unit': unit,
      'is_optional': isOptional,
    };
  }
}

class RawStep {
  final String text;
  final int? timerSeconds;
  final String? tip;

  const RawStep(this.text, [this.timerSeconds, this.tip]);

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'text': text};
    if (timerSeconds != null) map['timer_seconds'] = timerSeconds;
    if (tip != null && tip!.isNotEmpty) map['tip'] = tip;
    return map;
  }
}

RawIngredient ing(String id, double? amount, String unit, [bool opt = false]) =>
    RawIngredient(id, amount, unit, opt);

RawStep step(String text, [int? timerSeconds, String? tip]) =>
    RawStep(text, timerSeconds, tip);
