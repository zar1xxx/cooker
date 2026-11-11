// R9 pipeline logic shared by the tools and the tests (no text generation).
import 'dart:convert';
import 'dart:io';

const rewriteAllowedFields = {
  'id',
  'description',
  'steps',
  'total_minutes',
  'active_minutes',
  'cook_minutes',
  'kcal_per_serving',
};

const maxSameStepAcrossCatalog = 3;
const minStepLength = 20;

/// Cured or canned animal products that need no cooking step.
const _readyToEat = {
  'ham',
  'beef_stew',
  'tuna_canned',
  'saury_canned',
  'sardines_canned',
  'lard',
  'bacon',
  'sausage',
  'frankfurters',
  'crab_sticks',
  'herring',
};

const _rawCategories = {'meat', 'poultry', 'fish'};

/// Replaces the dish title and digits, so generator text matches across
/// recipes (same rule as tool/detect_templated_recipes.dart).
String normalizeStep(String text, String title) {
  var t = text.trim();
  if (title.isNotEmpty) {
    t = t.replaceAll(title, '{T}').replaceAll(title.toLowerCase(), '{T}');
  }
  return t.replaceAll(RegExp(r'\d+'), 'N');
}

Map<String, dynamic> readJsonFile(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> recipesOf(Map<String, dynamic> data) =>
    (data['recipes'] as List).cast<Map<String, dynamic>>();

Map<String, String> ingredientCategories(Map<String, dynamic> ingredients) => {
  for (final i
      in (ingredients['ingredients'] as List).cast<Map<String, dynamic>>())
    i['id'] as String: (i['category'] as String?) ?? '',
};

Set<String> readAppliedIds(String path) {
  final file = File(path);
  if (!file.existsSync()) return <String>{};
  return file
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toSet();
}

/// Checks one hand-written batch before it is applied. Returns the problems;
/// an empty list means the batch may be applied.
List<String> checkBatch(Map<String, dynamic> batch, Set<String> knownIds) {
  final errors = <String>[];
  final seen = <String>{};
  final items = (batch['recipes'] as List?)?.cast<Map<String, dynamic>>();
  if (items == null) return ['batch has no "recipes" list'];
  for (final item in items) {
    final id = item['id'] as String?;
    if (id == null || !knownIds.contains(id)) {
      errors.add('$id: unknown id');
      continue;
    }
    if (!seen.add(id)) errors.add('$id: duplicate in batch');
    final forbidden = item.keys.where((k) => !rewriteAllowedFields.contains(k));
    if (forbidden.isNotEmpty) {
      errors.add('$id: forbidden fields ${forbidden.toList()..sort()}');
    }
    if (item['description'] == null || item['steps'] == null) {
      errors.add('$id: description and steps are required');
      continue;
    }
    final steps = (item['steps'] as List).cast<Map<String, dynamic>>();
    for (var k = 0; k < steps.length; k++) {
      final text = (steps[k]['text'] as String?) ?? '';
      if (text.length < minStepLength) {
        errors.add('$id: step ${k + 1} shorter than $minStepLength chars');
      }
    }
  }
  return errors;
}

/// Applies a checked batch to the recipe list in place and marks the recipes
/// as curated. Returns the ids that were changed.
List<String> applyBatch(
  List<Map<String, dynamic>> recipes,
  Map<String, dynamic> batch,
) {
  final byId = {for (final r in recipes) r['id'] as String: r};
  final changed = <String>[];
  for (final item in (batch['recipes'] as List).cast<Map<String, dynamic>>()) {
    final recipe = byId[item['id']]!;
    for (final key in rewriteAllowedFields) {
      if (key != 'id' && item.containsKey(key)) recipe[key] = item[key];
    }
    recipe['quality'] = 'curated';
    changed.add(item['id'] as String);
  }
  return changed;
}

/// Lints the recipes listed in [appliedIds] (the ones rewritten in R9)
/// against the whole catalog. Returns human readable problems.
List<String> lintCurated(
  List<Map<String, dynamic>> recipes,
  Map<String, String> categories,
  Set<String> appliedIds,
) {
  final errors = <String>[];
  final stepCount = <String, int>{};
  final descCount = <String, int>{};
  for (final r in recipes) {
    final title = (r['title'] as String?) ?? '';
    final steps = (r['steps'] as List).cast<Map<String, dynamic>>();
    for (final text in {
      for (final s in steps) normalizeStep(s['text'] as String, title),
    }) {
      stepCount[text] = (stepCount[text] ?? 0) + 1;
    }
    final d = normalizeStep((r['description'] as String?) ?? '', title);
    descCount[d] = (descCount[d] ?? 0) + 1;
  }

  for (final r in recipes) {
    final id = r['id'] as String;
    if (!appliedIds.contains(id)) continue;
    final title = (r['title'] as String?) ?? '';
    final steps = (r['steps'] as List).cast<Map<String, dynamic>>();
    final texts = [
      for (final s in steps) normalizeStep(s['text'] as String, title),
    ];

    for (var k = 0; k < steps.length; k++) {
      if ((steps[k]['text'] as String).length < minStepLength) {
        errors.add('$id: step ${k + 1} shorter than $minStepLength chars');
      }
    }
    if (texts.toSet().length != texts.length) {
      errors.add('$id: repeated step inside the recipe');
    }
    for (final t in texts) {
      final n = stepCount[t] ?? 0;
      if (n > maxSameStepAcrossCatalog) {
        errors.add('$id: step appears in $n recipes');
      }
    }
    final desc = normalizeStep((r['description'] as String?) ?? '', title);
    if ((descCount[desc] ?? 0) > 1) {
      errors.add('$id: description is not unique');
    }

    var timerSeconds = 0;
    for (final s in steps) {
      timerSeconds += (s['timer_seconds'] as int?) ?? 0;
    }
    final total = r['total_minutes'] as int;
    if (timerSeconds / 60 > total) {
      errors.add('$id: timers ${timerSeconds ~/ 60} min > total $total min');
    }

    final ingredients = (r['ingredients'] as List).cast<Map<String, dynamic>>();
    final ids = {for (final i in ingredients) i['ingredient_id'] as String};
    final dishType = r['dish_type'] as String;
    final raw = ids.where((i) {
      if (_readyToEat.contains(i)) return false;
      if (i == 'egg') return dishType != 'drink';
      return _rawCategories.contains(categories[i]);
    }).toList();
    final hasTimer = steps.any((s) => ((s['timer_seconds'] as int?) ?? 0) > 0);
    if (raw.isNotEmpty && !hasTimer) {
      errors.add('$id: raw $raw but no step with timer_seconds');
    }

    final body = steps.map((s) => s['text'] as String).join(' ').toLowerCase();
    final eggAmount = ingredients
        .where((i) => i['ingredient_id'] == 'egg')
        .map((i) => (i['amount'] as num).toDouble())
        .fold<double>(0, (a, b) => a + b);
    for (final m in RegExp(r'(\d+)\s*(?:яйц|яиц)').allMatches(body)) {
      if (int.parse(m.group(1)!) > eggAmount) {
        errors.add('$id: a step mentions more eggs than the ingredients');
        break;
      }
    }
  }
  return errors;
}
