import 'dart:convert';
import 'dart:io';

import 'package:chto_prigotovit/core/catalog/catalog_taxonomy.dart';

void main() async {
  final recipesFile = File('assets/seed/recipes.json');
  final ingredientsFile = File('assets/seed/ingredients.json');

  if (!recipesFile.existsSync() || !ingredientsFile.existsSync()) {
    stderr.writeln('Seed files not found!');
    exit(1);
  }

  // 1. Load ingredient categories
  final ingData = jsonDecode(
    ingredientsFile.readAsStringSync(),
  ) as Map<String, dynamic>;
  final ingList = (ingData['ingredients'] as List).cast<Map<String, dynamic>>();
  final ingredientCategoryMap = <String, String>{};
  for (final ing in ingList) {
    ingredientCategoryMap[ing['id'] as String] =
        ing['category'] as String? ?? 'other';
  }

  // 2. Load recipes
  final recData =
      jsonDecode(recipesFile.readAsStringSync()) as Map<String, dynamic>;
  final recipesList = (recData['recipes'] as List).cast<Map<String, dynamic>>();

  final groupStats = <String, int>{};
  final cuisineStats = <String, int>{};
  final tagStats = <String, int>{};

  for (final rec in recipesList) {
    final title = rec['title'] as String;
    final totalMinutes = rec['total_minutes'] as int? ?? 30;
    final servings = rec['servings'] as int? ?? 2;
    final rawIngredients =
        (rec['ingredients'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final taxonomyIngredients = rawIngredients.map((ing) {
      final id = ing['ingredient_id'] as String? ?? '';
      return TaxonomyIngredient(
        id: id,
        amount: (ing['amount'] as num?)?.toDouble() ?? 0.0,
        unit: ing['unit'] as String? ?? 'g',
        category: ingredientCategoryMap[id],
      );
    }).toList();

    // Dish group
    final dishGroup = RecipeTaxonomyRules.inferDishGroup(
      explicitDishGroup: rec['dish_group'] as String?,
      ingredients: taxonomyIngredients,
      title: title,
    );
    rec['dish_group'] = dishGroup.id;
    groupStats[dishGroup.id] = (groupStats[dishGroup.id] ?? 0) + 1;

    // Cuisine normalization
    final rawCuisine = rec['cuisine'] as String? ?? 'домашняя';
    final normalizedCuisine = _mapCuisineToCode(rawCuisine);
    rec['cuisine'] = normalizedCuisine;
    cuisineStats[normalizedCuisine] =
        (cuisineStats[normalizedCuisine] ?? 0) + 1;

    // Cook minutes
    final cookMinutes = (rec['cook_minutes'] as int?) ?? totalMinutes;
    rec['cook_minutes'] = cookMinutes;

    // Nutrition estimation
    final nutritionInputs = taxonomyIngredients
        .map(
          (i) => (
            ingredientId: i.id,
            amount: i.amount,
            unit: i.unit,
            category: i.category,
          ),
        )
        .toList();
    final (
      estimatedKcal,
      estimatedProtein,
    ) = NutritionReference.estimatePerServing(
      ingredients: nutritionInputs,
      servings: servings,
    );
    final kcal = (rec['kcal_per_serving'] as int?) ?? estimatedKcal;
    rec['kcal_per_serving'] = kcal;

    // Tags inference
    final allTags = RecipeTaxonomyRules.inferAllTags(
      ingredients: taxonomyIngredients,
      totalMinutes: totalMinutes,
      servings: servings,
      dishGroup: dishGroup,
      cuisine: normalizedCuisine,
      title: title,
      kcalPerServing: kcal,
      proteinPerServing: estimatedProtein,
    );

    final tagsJson =
        allTags.map((t) => {'kind': t.kind.id, 'tag': t.tag}).toList()..sort(
          (a, b) =>
              '${a['kind']}:${a['tag']}'.compareTo('${b['kind']}:${b['tag']}'),
        );
    rec['tags'] = tagsJson;

    for (final t in allTags) {
      final key = '${t.kind.id}:${t.tag}';
      tagStats[key] = (tagStats[key] ?? 0) + 1;
    }
  }

  // 3. Verification: every recipe MUST have a dish_group and cuisine
  for (final rec in recipesList) {
    final title = rec['title'];
    final group = rec['dish_group'] as String?;
    final cuisine = rec['cuisine'] as String?;
    if (group == null || group.isEmpty || DishGroup.tryFromId(group) == null) {
      stderr.writeln('ERROR: Recipe "$title" has invalid dish_group: "$group"');
      exit(1);
    }
    if (cuisine == null || cuisine.isEmpty) {
      stderr.writeln('ERROR: Recipe "$title" has invalid cuisine: "$cuisine"');
      exit(1);
    }
  }

  // 4. Save back formatted
  final encoder = const JsonEncoder.withIndent('  ');
  await recipesFile.writeAsString('${encoder.convert(recData)}\n');

  stdout.writeln(
    'SUCCESS: Tagged and verified ${recipesList.length} seed recipes.',
  );
  stdout.writeln('\nDish Groups distribution:');
  for (final entry in groupStats.entries) {
    stdout.writeln('  ${entry.key.padRight(16)}: ${entry.value}');
  }
  stdout.writeln('\nCuisine distribution:');
  for (final entry in cuisineStats.entries) {
    stdout.writeln('  ${entry.key.padRight(16)}: ${entry.value}');
  }
}

String _mapCuisineToCode(String raw) {
  final lower = raw.trim().toLowerCase();
  if (lower.contains('русск') || lower == 'ru') return 'ru';
  if (lower.contains('итальян') || lower == 'it') return 'it';
  if (lower.contains('грузин') || lower == 'ge') return 'ge';
  if (lower.contains('узбек') || lower == 'uz') return 'uz';
  if (lower.contains('француз') || lower == 'fr') return 'fr';
  if (lower.contains('китай') || lower == 'cn') return 'cn';
  if (lower.contains('япон') || lower == 'jp') return 'jp';
  if (lower.contains('турец') || lower == 'tr') return 'tr';
  if (lower.contains('домашн') || lower == 'home') return 'home';
  if (lower.contains('греческ') || lower == 'gr') return 'gr';
  if (lower.contains('мексикан') || lower == 'mx') return 'mx';
  if (lower.contains('ближневост')) return 'tr';
  if (lower.contains('кавказ') || lower.contains('азиат')) return 'home';
  return Cuisine.normalize(lower);
}
