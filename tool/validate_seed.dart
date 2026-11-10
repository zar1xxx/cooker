import 'dart:convert';
import 'dart:io';

import 'package:chto_prigotovit/core/ai/recipe_validator.dart';
import 'package:chto_prigotovit/core/catalog/catalog_taxonomy.dart';
import 'package:chto_prigotovit/core/catalog/difficulty_calculator.dart';

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll('ё', 'е')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

int _countSentences(String text) {
  final cleaned = text.trim();
  if (cleaned.isEmpty) return 0;
  final parts = cleaned.split(RegExp(r'[.!?]+(?:\s+|$)'));
  return parts.where((p) => p.trim().isNotEmpty).length;
}

void main(List<String> args) {
  final targetPath = args.isNotEmpty ? args[0] : 'assets/seed/recipes.json';
  final ingredientsPath = args.length > 1
      ? args[1]
      : 'assets/seed/ingredients.json';
  final safetyPath = args.length > 2 ? args[2] : 'spec/ai/safety_minimums.json';

  final ingredientsData = (_loadJson(ingredientsPath)['ingredients'] as List)
      .cast<Map<String, dynamic>>();
  final ingredientById = {
    for (final ing in ingredientsData) ing['id'] as String: ing,
  };

  final stapleIds = ingredientsData
      .where((i) => i['is_staple'] == true)
      .map((i) => i['id'] as String)
      .toSet();

  final hierarchy = <String, List<String>>{};
  for (final ing in ingredientsData) {
    final parents = <String>[];
    var parent = ing['parent_id'] as String?;
    while (parent != null && !parents.contains(parent)) {
      parents.add(parent);
      parent = ingredientById[parent]?['parent_id'] as String?;
    }
    hierarchy[ing['id'] as String] = parents;
  }

  final validator = RecipeValidator(safetyMinimums: _loadJson(safetyPath));

  List<Map<String, dynamic>> recipes = [];
  final targetFile = File(targetPath);
  final targetDir = Directory(targetPath);

  if (targetFile.existsSync()) {
    final data = _loadJson(targetPath);
    recipes = (data['recipes'] as List).cast<Map<String, dynamic>>();
  } else if (targetDir.existsSync()) {
    for (final f in targetDir.listSync().whereType<File>()) {
      if (f.path.endsWith('.json')) {
        final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        recipes.addAll((data['recipes'] as List).cast<Map<String, dynamic>>());
      }
    }
  } else {
    stderr.writeln('Target path not found: $targetPath');
    exit(1);
  }

  stdout.writeln('Validating ${recipes.length} recipes from $targetPath...');

  final errors = <String>[];
  final seenTitles = <String, String>{};
  final stepMap = <String, Set<String>>{};
  final ingredientSets = <String, Set<String>>{};

  int validCount = 0;

  for (final r in recipes) {
    final id = r['id'] as String;
    final title = r['title'] as String;
    final normTitle = _normalize(title);

    // 1. Unique title
    if (seenTitles.containsKey(normTitle)) {
      errors.add(
        '$id: duplicate title with ${seenTitles[normTitle]} ("$title")',
      );
    }
    seenTitles[normTitle] = id;

    // 2. Ingredients exist in ingredients.json
    final ings = (r['ingredients'] as List).cast<Map<String, dynamic>>();
    final recipeNonStaples = <String>{};

    for (final ing in ings) {
      final ingId = ing['ingredient_id'] as String;
      if (!ingredientById.containsKey(ingId)) {
        errors.add('$id: unknown ingredient "$ingId"');
      }
      if (!stapleIds.contains(ingId)) {
        recipeNonStaples.add(ingId);
      }
    }
    ingredientSets[id] = recipeNonStaples;

    // 3. RecipeValidator
    final valResult = validator.validate(r, ingredientHierarchy: hierarchy);
    if (valResult is! Valid) {
      errors.add('$id: RecipeValidator failure: $valResult');
    }

    // 4. Garbage text check
    final titleGarbage = RecipeValidator.checkGarbageText(title, 'title');
    if (titleGarbage != null) {
      errors.add('$id: title has garbage text: $titleGarbage');
    }

    final desc = r['description'] as String? ?? '';
    final descGarbage = RecipeValidator.checkGarbageText(desc, 'description');
    if (descGarbage != null) {
      errors.add('$id: description has garbage text: $descGarbage');
    }

    // 5. Difficulty calculation check
    final calculatedDiff = DifficultyCalculator.calculateFromJson(r)
        .difficulty
        .name;
    if (r['difficulty'] != calculatedDiff) {
      errors.add(
        '$id: difficulty mismatch: stored="${r['difficulty']}", calculated="$calculatedDiff"',
      );
    }

    // 6. Steps checks
    final steps = (r['steps'] as List).cast<Map<String, dynamic>>();
    final dishType = r['dish_type'] as String;

    if (dishType == 'soup' && steps.length < 5) {
      errors.add('$id: soup has ${steps.length} steps (minimum 5)');
    }

    for (int i = 0; i < steps.length; i++) {
      final stepText = steps[i]['text'] as String;
      final stepGarbage = RecipeValidator.checkGarbageText(
        stepText,
        'step ${i + 1}',
      );
      if (stepGarbage != null) {
        errors.add('$id: step ${i + 1} has garbage text: $stepGarbage');
      }

      final sentences = _countSentences(stepText);
      if (sentences > 2) {
        errors.add('$id: step ${i + 1} has $sentences sentences (maximum 2)');
      }

      final normStep = stepText.trim().toLowerCase();
      stepMap.putIfAbsent(normStep, () => <String>{}).add(id);
    }

    // 7. Taxonomy fields
    final group = r['dish_group'] as String?;
    if (group == null || DishGroup.tryFromId(group) == null) {
      errors.add('$id: invalid or missing dish_group "$group"');
    }

    final cuisine = r['cuisine'] as String?;
    if (cuisine == null || !Cuisine.isKnown(cuisine)) {
      errors.add('$id: invalid or missing cuisine "$cuisine"');
    }

    validCount++;
  }

  // 8. Over-repeated steps (> 3 recipes)
  for (final entry in stepMap.entries) {
    if (entry.value.length > 3) {
      errors.add(
        'Step phrasing appears in ${entry.value.length} recipes: "${entry.key}" (recipes: ${entry.value.take(4).join(', ')})',
      );
    }
  }

  // 9. Pairwise Jaccard >= 0.85
  final ids = ingredientSets.keys.toList();
  for (int i = 0; i < ids.length; i++) {
    for (int j = i + 1; j < ids.length; j++) {
      final s1 = ingredientSets[ids[i]]!;
      final s2 = ingredientSets[ids[j]]!;
      final intersection = s1.intersection(s2).length;
      final union = s1.union(s2).length;
      final jaccard = union == 0 ? 1.0 : intersection / union;
      if (jaccard >= 0.85) {
        errors.add(
          'High similarity (Jaccard ${(jaccard * 100).toStringAsFixed(1)}%) between ${ids[i]} and ${ids[j]}',
        );
      }
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('VALIDATION FAILED with ${errors.length} errors:');
    for (final err in errors.take(30)) {
      stderr.writeln(' - $err');
    }
    if (errors.length > 30) {
      stderr.writeln(' ... and ${errors.length - 30} more errors.');
    }
    exit(1);
  }

  stdout.writeln('ALL $validCount RECIPES VALID! (0 errors)');
  exit(0);
}
