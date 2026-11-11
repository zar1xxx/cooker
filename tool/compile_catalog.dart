import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:chto_prigotovit/core/catalog/catalog_taxonomy.dart';
import 'package:chto_prigotovit/core/catalog/difficulty_calculator.dart';

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() async {
  final recipesDir = Directory('assets/seed/recipes');
  final mainRecipesFile = File('assets/seed/recipes.json');
  final ingredientsFile = File('assets/seed/ingredients.json');

  if (!ingredientsFile.existsSync()) {
    stderr.writeln('Ingredients file not found!');
    exit(1);
  }

  // 1. Load ingredients
  final ingData = _loadJson('assets/seed/ingredients.json');
  final ingList = (ingData['ingredients'] as List).cast<Map<String, dynamic>>();
  final ingredientCategoryMap = <String, String>{};
  for (final ing in ingList) {
    ingredientCategoryMap[ing['id'] as String] =
        ing['category'] as String? ?? 'other';
  }

  // 2. Load existing 125 baseline recipes
  final existingMap = <String, Map<String, dynamic>>{};
  final baselineFile = File('tool/generator/baseline_125.json');
  final sourceBaseline = baselineFile.existsSync()
      ? baselineFile
      : mainRecipesFile;
  if (sourceBaseline.existsSync()) {
    final existingData = _loadJson(sourceBaseline.path);
    final existingList = (existingData['recipes'] as List)
        .cast<Map<String, dynamic>>();
    for (final r in existingList) {
      existingMap[r['id'] as String] = r;
    }
  }

  stdout.writeln('Loaded ${existingMap.length} baseline seed recipes.');

  // 3. Load all recipes from assets/seed/recipes/*.json
  int batchFilesCount = 0;
  if (recipesDir.existsSync()) {
    for (final file in recipesDir.listSync().whereType<File>()) {
      if (file.path.endsWith('.json')) {
        batchFilesCount++;
        final data =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final recs = (data['recipes'] as List).cast<Map<String, dynamic>>();
        for (final r in recs) {
          final id = r['id'] as String;
          existingMap[id] = r; // updates or adds
        }
      }
    }
  }

  stdout.writeln(
    'Processed $batchFilesCount batch files. Total unique recipes: ${existingMap.length}',
  );

  // 3b. Overlay hand-rewritten recipes (R9): tool/seed_data/rewrite/batch_*.json,
  // only for ids listed in applied_ids.txt. Keeps rewrites durable across recompiles.
  final rewriteDir = Directory('tool/seed_data/rewrite');
  final appliedFile = File('tool/seed_data/rewrite/applied_ids.txt');
  if (rewriteDir.existsSync() && appliedFile.existsSync()) {
    final applied = appliedFile
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toSet();
    final batchFiles =
        rewriteDir
            .listSync()
            .whereType<File>()
            .where((f) => RegExp(r'batch_\d+\.json$').hasMatch(f.path))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    var overlaid = 0;
    for (final f in batchFiles) {
      final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      for (final r in (data['recipes'] as List).cast<Map<String, dynamic>>()) {
        final id = r['id'] as String;
        final target = existingMap[id];
        if (!applied.contains(id) || target == null) continue;
        for (final key in const [
          'description',
          'steps',
          'total_minutes',
          'active_minutes',
          'cook_minutes',
          'kcal_per_serving',
        ]) {
          if (r.containsKey(key)) target[key] = r[key];
        }
        target['quality'] = 'curated';
        overlaid++;
      }
    }
    stdout.writeln('Overlaid $overlaid rewritten recipes (quality=curated).');
  }

  final allRecipes = existingMap.values.toList();

  // 4. Enrich every recipe with DifficultyCalculator, NutritionReference, and Taxonomy
  for (final rec in allRecipes) {
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

    // Inferred dish group
    final dishGroup = RecipeTaxonomyRules.inferDishGroup(
      explicitDishGroup: rec['dish_group'] as String?,
      ingredients: taxonomyIngredients,
      title: title,
    );
    rec['dish_group'] = dishGroup.id;

    // Normalized cuisine
    final rawCuisine = rec['cuisine'] as String? ?? 'home';
    final normalizedCuisine = Cuisine.normalize(rawCuisine);
    rec['cuisine'] = normalizedCuisine;

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

    rec['tags'] = allTags.map((t) => {'kind': t.kind.id, 'tag': t.tag}).toList()
      ..sort(
        (a, b) =>
            '${a['kind']}:${a['tag']}'.compareTo('${b['kind']}:${b['tag']}'),
      );

    // Difficulty calculation
    final diffResult = DifficultyCalculator.calculateFromJson(rec);
    rec['difficulty'] = diffResult.difficulty.name;
  }

  // Sort recipes deterministically by dish_group then title
  allRecipes.sort((a, b) {
    final gComp = (a['dish_group'] as String).compareTo(
      b['dish_group'] as String,
    );
    if (gComp != 0) return gComp;
    return (a['title'] as String).compareTo(b['title'] as String);
  });

  // 5. Save compiled assets/seed/recipes.json
  final outputJson = {'version': 1, 'recipes': allRecipes};
  const encoder = JsonEncoder.withIndent('  ');
  mainRecipesFile.writeAsStringSync(encoder.convert(outputJson));
  stdout.writeln(
    'Written ${allRecipes.length} recipes to assets/seed/recipes.json',
  );

  // 6. Generate tool/seed_data/dish_list.csv
  final csvFile = File('tool/seed_data/dish_list.csv');
  final csvBuf = StringBuffer();
  csvBuf.writeln(
    'id,title,dish_group,dish_type,cuisine,total_minutes,difficulty',
  );
  for (final r in allRecipes) {
    final id = r['id'];
    final title = (r['title'] as String).replaceAll(',', ';');
    final group = r['dish_group'];
    final type = r['dish_type'];
    final cuisine = r['cuisine'];
    final time = r['total_minutes'];
    final diff = r['difficulty'];
    csvBuf.writeln('$id,$title,$group,$type,$cuisine,$time,$diff');
  }
  csvFile.writeAsStringSync(csvBuf.toString());
  stdout.writeln('Written dish list to tool/seed_data/dish_list.csv');

  // 7. Generate random samples for review: sample_1..sample_4 (50 recipes each)
  final random = Random(42);
  final shuffled = List<Map<String, dynamic>>.from(allRecipes)..shuffle(random);

  final sampleBreakpoints = [500, 1000, 1500, 2000];
  for (int sIdx = 0; sIdx < sampleBreakpoints.length; sIdx++) {
    final targetNum = sampleBreakpoints[sIdx];
    if (allRecipes.length < targetNum && allRecipes.length < 500) continue;

    final sampleFile = File('docs/reports/gen/sample_${sIdx + 1}.md');
    final sampleRecipes = shuffled.skip(sIdx * 50).take(50).toList();
    if (sampleRecipes.isEmpty) continue;

    final buf = StringBuffer();
    buf.writeln(
      '# Выборка рецептов для проверки (Выборка №${sIdx + 1}, рецепты 1–50 из ${allRecipes.length})',
    );
    buf.writeln();
    buf.writeln('Дата генерации: 2026-11-10');
    buf.writeln('Всего рецептов в каталоге: ${allRecipes.length}');
    buf.writeln();

    for (int i = 0; i < sampleRecipes.length; i++) {
      final r = sampleRecipes[i];
      buf.writeln('## ${i + 1}. ${r['title']} (`${r['id']}`)');
      buf.writeln(
        '- **Раздел**: ${r['dish_group']} | **Тип**: ${r['dish_type']} | **Кухня**: ${r['cuisine']}',
      );
      buf.writeln(
        '- **Время**: ${r['total_minutes']} мин (активное: ${r['active_minutes']} мин) | **Сложность**: ${r['difficulty']} | **Порции**: ${r['servings']}',
      );
      buf.writeln('- **Описание**: ${r['description']}');
      buf.writeln();
      buf.writeln('### Ингредиенты:');
      final ings = (r['ingredients'] as List).cast<Map<String, dynamic>>();
      for (final ing in ings) {
        final opt = ing['is_optional'] == true ? ' (по желанию)' : '';
        final amt = ing['amount'] != null
            ? '${ing['amount']} ${ing['unit']}'
            : ing['unit'];
        buf.writeln('- `${ing['ingredient_id']}`: $amt$opt');
      }
      buf.writeln();
      buf.writeln('### Шаги приготовления:');
      final steps = (r['steps'] as List).cast<Map<String, dynamic>>();
      for (int stepIdx = 0; stepIdx < steps.length; stepIdx++) {
        final st = steps[stepIdx];
        final timer = st['timer_seconds'] != null
            ? ' ⏱️ ${(st['timer_seconds'] as int) ~/ 60} мин'
            : '';
        final tip = st['tip'] != null && (st['tip'] as String).isNotEmpty
            ? '\n  💡 *Совет: ${st['tip']}*'
            : '';
        buf.writeln('${stepIdx + 1}. ${st['text']}$timer$tip');
      }
      buf.writeln();
      buf.writeln('---');
      buf.writeln();
    }

    sampleFile.writeAsStringSync(buf.toString());
    stdout.writeln(
      'Written sample file: docs/reports/gen/sample_${sIdx + 1}.md (50 recipes)',
    );
  }
}
