// R10-05: adds hand-written recipes from assets/seed/recipes/r10_new.json to
// assets/seed/recipes.json without recompiling the whole catalog (a full
// compile would drop the R9 `quality` marks kept only in recipes.json).
// Derived fields are computed with the same rules as compile_catalog.dart.
// Run: dart run tool/add_r10_recipes.dart
import 'dart:convert';
import 'dart:io';

import 'package:chto_prigotovit/core/catalog/catalog_taxonomy.dart';
import 'package:chto_prigotovit/core/catalog/difficulty_calculator.dart';

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final ingList =
      (_loadJson('assets/seed/ingredients.json')['ingredients'] as List)
          .cast<Map<String, dynamic>>();
  final categoryOf = {
    for (final i in ingList) i['id'] as String: i['category'] as String?,
  };

  final catalog = _loadJson('assets/seed/recipes.json');
  final recipes = (catalog['recipes'] as List).cast<Map<String, dynamic>>();
  final added =
      (_loadJson('assets/seed/recipes/r10_new.json')['recipes'] as List)
          .cast<Map<String, dynamic>>();
  final addedIds = {for (final r in added) r['id'] as String};
  recipes.removeWhere((r) => addedIds.contains(r['id']));

  for (final source in added) {
    final rec = Map<String, dynamic>.from(source);
    final title = rec['title'] as String;
    final totalMinutes = rec['total_minutes'] as int;
    final servings = rec['servings'] as int;
    final ingredients = (rec['ingredients'] as List)
        .cast<Map<String, dynamic>>()
        .map(
          (ing) => TaxonomyIngredient(
            id: ing['ingredient_id'] as String,
            amount: (ing['amount'] as num?)?.toDouble() ?? 0.0,
            unit: ing['unit'] as String? ?? 'g',
            category: categoryOf[ing['ingredient_id']],
          ),
        )
        .toList();

    final dishGroup = RecipeTaxonomyRules.inferDishGroup(
      explicitDishGroup: rec['dish_group'] as String?,
      ingredients: ingredients,
      title: title,
    );
    rec['dish_group'] = dishGroup.id;
    final cuisine = Cuisine.normalize(rec['cuisine'] as String? ?? 'home');
    rec['cuisine'] = cuisine;

    final (kcal, protein) = NutritionReference.estimatePerServing(
      ingredients: [
        for (final i in ingredients)
          (
            ingredientId: i.id,
            amount: i.amount,
            unit: i.unit,
            category: i.category,
          ),
      ],
      servings: servings,
    );
    rec['kcal_per_serving'] = kcal;
    final tags = RecipeTaxonomyRules.inferAllTags(
      ingredients: ingredients,
      totalMinutes: totalMinutes,
      servings: servings,
      dishGroup: dishGroup,
      cuisine: cuisine,
      title: title,
      kcalPerServing: kcal,
      proteinPerServing: protein,
    );
    rec['tags'] = tags.map((t) => {'kind': t.kind.id, 'tag': t.tag}).toList()
      ..sort(
        (a, b) =>
            '${a['kind']}:${a['tag']}'.compareTo('${b['kind']}:${b['tag']}'),
      );
    rec['difficulty'] = DifficultyCalculator.calculateFromJson(rec)
        .difficulty
        .name;
    rec['quality'] = 'curated';
    recipes.add(rec);
  }

  catalog['recipes'] = recipes;
  File('assets/seed/recipes.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(catalog));
  stdout.writeln('R10: ${added.length} recipes added, total ${recipes.length}');
}
