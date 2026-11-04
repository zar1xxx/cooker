/// Data model shared by the seed generator and its data files.
library;

class SeedIngredient {
  const SeedIngredient({
    required this.id,
    required this.name,
    required this.synonyms,
    required this.category,
    required this.parentId,
    required this.isStaple,
  });

  final String id;
  final String name;
  final List<String> synonyms;
  final String category;
  final String? parentId;
  final bool isStaple;
}

class SeedStep {
  const SeedStep(this.text, [this.timerSeconds, this.tip]);

  final String text;
  final int? timerSeconds;
  final String? tip;
}

class RecipeIngredient {
  const RecipeIngredient({
    required this.id,
    required this.amount,
    required this.unit,
    required this.optional,
  });

  final String id;
  final double? amount;
  final String unit;
  final bool optional;
}

class RecipeSpec {
  const RecipeSpec({
    required this.id,
    required this.title,
    required this.dishType,
    required this.kind,
    required this.servings,
    required this.activeMinutes,
    required this.ingredients,
    required this.description,
    this.cuisine = 'домашняя',
    this.customSteps,
    this.totalMinutes,
  });

  final String id;
  final String title;
  final String dishType;
  final String kind;
  final int servings;
  final int activeMinutes;
  final String ingredients;
  final String description;
  final String cuisine;
  final List<SeedStep>? customSteps;
  final int? totalMinutes;
}

RecipeSpec r(
  String id,
  String title,
  String dishType,
  String kind,
  int servings,
  int activeMinutes,
  String ingredients, {
  required String description,
  String cuisine = 'домашняя',
  List<SeedStep>? steps,
  int? totalMinutes,
}) {
  return RecipeSpec(
    id: id,
    title: title,
    dishType: dishType,
    kind: kind,
    servings: servings,
    activeMinutes: activeMinutes,
    ingredients: ingredients,
    description: description,
    cuisine: cuisine,
    customSteps: steps,
    totalMinutes: totalMinutes,
  );
}

SeedStep s(String text, [int? timerSeconds]) => SeedStep(text, timerSeconds);
