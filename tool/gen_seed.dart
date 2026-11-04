import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'seed_data/ingredient_data.dart';
import 'seed_data/recipe_data.dart';
import 'seed_data/seed_models.dart';

const _allowedCategories = {
  'vegetables',
  'fruits',
  'meat',
  'poultry',
  'fish',
  'dairy',
  'grains',
  'bakery',
  'legumes',
  'mushrooms',
  'canned',
  'spices',
  'nuts',
  'sweets',
  'greens',
};

const _heatKeywords = [
  'вар',
  'жар',
  'запек',
  'туш',
  'томит',
  'пассер',
  'гриль',
];

class _HeatRule {
  const _HeatRule(this.ids, this.minutes, this.category);

  final List<String> ids;
  final int minutes;
  final String category;
}

const _heatRules = [
  _HeatRule(
    [
      'chicken',
      'chicken_fillet',
      'chicken_thigh',
      'chicken_wings',
      'turkey',
      'turkey_fillet',
      'duck',
      'goose',
    ],
    20,
    'poultry',
  ),
  _HeatRule(
    ['minced_meat', 'minced_pork', 'minced_beef', 'minced_chicken'],
    15,
    'minced_meat',
  ),
  _HeatRule(['pork'], 20, 'pork'),
  _HeatRule(['beef', 'veal'], 10, 'beef'),
  _HeatRule(
    [
      'fish',
      'pollock',
      'cod',
      'hake',
      'salmon',
      'trout',
      'herring',
      'mackerel',
      'pike',
      'perch',
      'carp',
      'catfish',
    ],
    10,
    'fish',
  ),
  _HeatRule(['egg'], 3, 'eggs'),
  _HeatRule(
    ['beans_dry', 'beans_red', 'beans_white', 'chickpeas_dry'],
    40,
    'dry_beans',
  ),
  _HeatRule(
    ['forest_mushrooms', 'porcini', 'chanterelles', 'honey_mushrooms'],
    20,
    'mushrooms_wild',
  ),
];

void main() {
  final ingredients = _parseIngredients();
  _validateIngredients(ingredients);
  final byId = {
    for (final ingredient in ingredients) ingredient.id: ingredient,
  };

  final recipes = <Map<String, dynamic>>[];
  final recipeIds = <String>{};
  final titleKeys = <String>{};
  final ingredientSets = <String, Set<String>>{};
  final typeCounts = <String, int>{};
  final difficultyCounts = <String, int>{};

  for (final spec in allRecipeSpecs) {
    if (!recipeIds.add(spec.id)) {
      throw StateError('Duplicate recipe id: ${spec.id}');
    }
    final parsed = _parseRecipeIngredients(spec.ingredients);
    _validateRecipeIngredients(spec, parsed, byId);

    var steps = spec.customSteps ?? _templateSteps(spec, parsed, byId);
    steps = _injectHeatSteps(spec, parsed, steps, byId);
    if (steps.length < 2) {
      throw StateError('Recipe ${spec.id} has fewer than 2 steps');
    }

    final sumTimers = steps.fold<int>(
      0,
      (total, step) => total + (step.timerSeconds ?? 0),
    );
    final totalMinutes = max(
      max(spec.totalMinutes ?? 0, (sumTimers / 60).ceil() + 5),
      spec.activeMinutes + 5,
    );
    final difficulty = _difficulty(steps.length, spec.activeMinutes);
    final titleKey = _normalize(spec.title);
    if (!titleKeys.add(titleKey)) {
      throw StateError('Duplicate normalized title: ${spec.title}');
    }

    ingredientSets[spec.id] = parsed
        .where((ingredient) => !byId[ingredient.id]!.isStaple)
        .map((ingredient) => ingredient.id)
        .toSet();
    typeCounts.update(spec.dishType, (value) => value + 1, ifAbsent: () => 1);
    difficultyCounts.update(
      difficulty,
      (value) => value + 1,
      ifAbsent: () => 1,
    );

    recipes.add({
      'id': spec.id,
      'title': spec.title,
      'dish_type': spec.dishType,
      'difficulty': difficulty,
      'cuisine': spec.cuisine,
      'total_minutes': totalMinutes,
      'active_minutes': spec.activeMinutes,
      'servings': spec.servings,
      'description': spec.description,
      'ingredients': parsed
          .map(
            (ingredient) => {
              'ingredient_id': ingredient.id,
              'amount': ingredient.amount,
              'unit': ingredient.unit,
              'is_optional': ingredient.optional,
            },
          )
          .toList(),
      'steps': steps
          .map(
            (step) => {
              'text': step.text,
              'timer_seconds': step.timerSeconds,
              if (step.tip != null) 'tip': step.tip,
            },
          )
          .toList(),
    });
  }

  _validateDuplicates(ingredientSets);
  _validateCounts(ingredients, recipes, typeCounts, difficultyCounts);

  _writeJson('assets/seed/ingredients.json', {
    'version': 1,
    'ingredients': ingredients
        .map(
          (ingredient) => {
            'id': ingredient.id,
            'name': ingredient.name,
            'synonyms': ingredient.synonyms,
            'category': ingredient.category,
            'parent_id': ingredient.parentId,
            'is_staple': ingredient.isStaple,
          },
        )
        .toList(),
  });
  _writeJson('assets/seed/recipes.json', {'version': 1, 'recipes': recipes});

  stdout.writeln('Ingredients: ${ingredients.length}');
  stdout.writeln('Recipes: ${recipes.length}');
  stdout.writeln('By type: $typeCounts');
  stdout.writeln('By difficulty: $difficultyCounts');

  final sample = [...recipes]..shuffle(Random(42));
  stdout.writeln('Manual review sample (20):');
  for (final recipe in sample.take(20)) {
    stdout.writeln('- ${recipe['id']}: ${recipe['title']}');
  }
}

List<SeedIngredient> _parseIngredients() {
  final result = <SeedIngredient>[];
  for (final rawLine in ingredientLines.trim().split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split('|');
    if (parts.length != 6) {
      throw FormatException('Ingredient line must have 6 fields: $line');
    }
    final synonyms = parts[2].trim().isEmpty
        ? <String>[]
        : parts[2]
              .split(';')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList();
    result.add(
      SeedIngredient(
        id: parts[0].trim(),
        name: parts[1].trim(),
        synonyms: synonyms,
        category: parts[3].trim(),
        parentId: parts[4].trim().isEmpty ? null : parts[4].trim(),
        isStaple: parts[5].trim() == 'staple',
      ),
    );
  }
  return result;
}

void _validateIngredients(List<SeedIngredient> ingredients) {
  if (ingredients.length < 250) {
    throw StateError(
      'Expected at least 250 ingredients, got ${ingredients.length}',
    );
  }
  final ids = <String>{};
  for (final ingredient in ingredients) {
    if (!ids.add(ingredient.id)) {
      throw StateError('Duplicate ingredient id: ${ingredient.id}');
    }
    if (ingredient.name.isEmpty) {
      throw StateError('Ingredient ${ingredient.id} has an empty name');
    }
    if (!_allowedCategories.contains(ingredient.category)) {
      throw StateError(
        'Ingredient ${ingredient.id} has unknown category ${ingredient.category}',
      );
    }
  }
  for (final ingredient in ingredients) {
    final parentId = ingredient.parentId;
    if (parentId == null) continue;
    if (parentId == ingredient.id) {
      throw StateError('Ingredient ${ingredient.id} is its own parent');
    }
    if (!ids.contains(parentId)) {
      throw StateError(
        'Ingredient ${ingredient.id} refers to missing parent $parentId',
      );
    }
    final seen = <String>{ingredient.id};
    String? current = parentId;
    while (current != null) {
      if (!seen.add(current)) {
        throw StateError('Parent cycle around ingredient ${ingredient.id}');
      }
      current = ingredients.firstWhere((item) => item.id == current).parentId;
    }
  }
  final staples = ingredients
      .where((item) => item.isStaple)
      .map((item) => item.id)
      .toSet();
  const expectedStaples = {
    'salt',
    'water',
    'sugar',
    'black_pepper',
    'sunflower_oil',
  };
  if (!_setEquals(staples, expectedStaples)) {
    throw StateError('Staples must be exactly $expectedStaples, got $staples');
  }
}

List<RecipeIngredient> _parseRecipeIngredients(String raw) {
  final result = <RecipeIngredient>[];
  for (final rawPart in raw.split(';')) {
    final part = rawPart.trim();
    if (part.isEmpty) continue;
    final fields = part.split(':');
    final id = fields[0].trim();
    if (fields.length == 1) {
      result.add(
        RecipeIngredient(
          id: id,
          amount: null,
          unit: 'to_taste',
          optional: false,
        ),
      );
      continue;
    }
    final amountField = fields[1].trim();
    final amount = amountField == 'null' ? null : double.tryParse(amountField);
    if (amountField != 'null' && amount == null) {
      throw FormatException('Bad amount in recipe ingredient "$part"');
    }
    final unit = fields.length > 2 ? fields[2].trim() : 'g';
    final optional = fields.length > 3 && fields[3].trim() == 'opt';
    result.add(
      RecipeIngredient(id: id, amount: amount, unit: unit, optional: optional),
    );
  }
  return result;
}

void _validateRecipeIngredients(
  RecipeSpec spec,
  List<RecipeIngredient> ingredients,
  Map<String, SeedIngredient> byId,
) {
  if (ingredients.isEmpty) {
    throw StateError('Recipe ${spec.id} has no ingredients');
  }
  for (final ingredient in ingredients) {
    if (!byId.containsKey(ingredient.id)) {
      throw StateError(
        'Recipe ${spec.id} refers to missing ingredient ${ingredient.id}',
      );
    }
    if (ingredient.amount == null && ingredient.unit != 'to_taste') {
      throw StateError(
        'Recipe ${spec.id}: null amount is only allowed with to_taste',
      );
    }
    if (ingredient.amount != null && ingredient.unit == 'to_taste') {
      throw StateError('Recipe ${spec.id}: to_taste must have a null amount');
    }
  }
}

List<SeedStep> _templateSteps(
  RecipeSpec spec,
  List<RecipeIngredient> ingredients,
  Map<String, SeedIngredient> byId,
) {
  final main = byId[ingredients.first.id]!;
  final rest = ingredients
      .skip(1)
      .map((ingredient) => byId[ingredient.id]!)
      .where(
        (ingredient) =>
            !ingredient.isStaple &&
            ingredient.category != 'spices' &&
            ingredient.id != 'water',
      )
      .map((ingredient) => ingredient.name)
      .take(3)
      .toList();
  final restText = rest.isEmpty ? 'остальные продукты' : _join(rest);

  switch (spec.kind) {
    case 'soup':
      final grain = main.category == 'grains' || main.category == 'legumes';
      return [
        SeedStep(
          grain
              ? 'Промойте ${main.name} и нарежьте овощи.'
              : 'Нарежьте ${main.name} и $restText.',
        ),
        SeedStep('Залейте ${main.name} водой и доведите до кипения.', 600),
        const SeedStep(
          'Добавьте остальные продукты и варите до готовности.',
          1200,
        ),
        const SeedStep(
          'Посолите, поперчите и дайте настояться под крышкой.',
          300,
        ),
      ];
    case 'fry':
      return [
        SeedStep('Нарежьте ${main.name} и $restText.'),
        const SeedStep('Разогрейте масло на сковороде.', 60),
        const SeedStep(
          'Добавьте остальные продукты и готовьте до готовности.',
          600,
        ),
        const SeedStep('Посолите, поперчите и подавайте горячим.'),
      ];
    case 'stew':
      return [
        SeedStep('Нарежьте ${main.name} и $restText.'),
        SeedStep('Обжарьте ${main.name} на разогретом масле.', 300),
        const SeedStep(
          'Добавьте остальные продукты и тушите до готовности.',
          1200,
        ),
        const SeedStep('Посолите и оставьте под крышкой.', 300),
      ];
    case 'bake':
      return [
        SeedStep('Нарежьте ${main.name} и $restText.'),
        const SeedStep('Выложите продукты в форму, посолите и поперчите.'),
        SeedStep('Запекайте ${main.name} с остальными продуктами.', 2100),
        const SeedStep('Дайте блюду постоять перед подачей.', 600),
      ];
    case 'salad':
      return [
        SeedStep('Нарежьте ${main.name} и $restText.'),
        const SeedStep('Смешайте продукты в салатнике.'),
        const SeedStep('Заправьте по вкусу и перемешайте.'),
        const SeedStep('Дайте салату настояться.', 600),
      ];
    case 'boil':
      return [
        SeedStep('Промойте и подготовьте ${main.name}.'),
        SeedStep('Отварите ${main.name} до готовности.', 900),
        const SeedStep('Добавьте масло и перемешайте.'),
      ];
    case 'porridge':
      return [
        SeedStep('Промойте ${main.name}.'),
        const SeedStep('Вскипятите молоко или воду.', 300),
        SeedStep('Всыпьте ${main.name} и варите, помешивая.', 900),
        const SeedStep('Добавьте масло и дайте настояться.', 300),
      ];
    case 'egg':
      return [
        const SeedStep('Взбейте яйца с молоком и солью.'),
        const SeedStep('Разогрейте масло на сковороде.', 60),
        const SeedStep('Жарьте омлет под крышкой.', 300),
        const SeedStep('Подавайте горячим.'),
      ];
    case 'cold':
      return [
        SeedStep('Нарежьте ${main.name} и $restText.'),
        const SeedStep('Смешайте продукты.'),
        const SeedStep('Охладите перед подачей.', 1800),
      ];
    case 'bake_dough':
      return [
        const SeedStep('Замесите тесто из муки, яйца и жидкости.'),
        const SeedStep('Оставьте тесто под полотенцем.', 3600),
        const SeedStep('Раскатайте тесто и выложите начинку.'),
        const SeedStep('Запекайте пирог до золотистой корочки.', 2100),
        const SeedStep('Дайте выпечке остыть.', 600),
      ];
    default:
      throw StateError('Unknown recipe kind: ${spec.kind}');
  }
}

List<SeedStep> _injectHeatSteps(
  RecipeSpec spec,
  List<RecipeIngredient> ingredients,
  List<SeedStep> steps,
  Map<String, SeedIngredient> byId,
) {
  final result = List<SeedStep>.from(steps);
  final rules = [..._heatRules]
    ..sort((left, right) => right.minutes.compareTo(left.minutes));
  final requireName = {'salad', 'snack', 'drink', 'cold'}.contains(spec.kind);

  for (final rule in rules) {
    final matched = ingredients.where((ingredient) {
      final ids = [ingredient.id, ..._ancestors(ingredient.id, byId)];
      return ids.any(rule.ids.contains);
    }).toList();
    if (matched.isEmpty) continue;
    if (result.any(
      (step) => _stepCovers(step, rule, matched, byId, requireName),
    )) {
      continue;
    }
    final minutes = _heatMinutes(spec.kind, rule);
    final step = SeedStep(
      _heatText(spec.kind, rule, matched, byId, minutes),
      minutes * 60,
    );
    result.insert(_insertIndex(spec.kind, result.length), step);
  }
  return result;
}

int _heatMinutes(String kind, _HeatRule rule) {
  if (rule.category == 'eggs') {
    return kind == 'breakfast' || kind == 'fry' ? 5 : 10;
  }
  if (kind == 'bake' || kind == 'bake_dough' || kind == 'dessert') {
    return max(rule.minutes + 10, 25);
  }
  return rule.minutes + 5;
}

String _heatText(
  String kind,
  _HeatRule rule,
  List<RecipeIngredient> matched,
  Map<String, SeedIngredient> byId,
  int minutes,
) {
  final String verb;
  switch (kind) {
    case 'bake':
    case 'bake_dough':
    case 'dessert':
      verb = 'Запекайте в духовке';
    case 'fry':
    case 'side':
      verb = 'Жарьте на среднем огне';
    case 'breakfast':
      verb = rule.category == 'eggs'
          ? 'Жарьте на среднем огне'
          : 'Варите на слабом огне';
    case 'salad':
    case 'snack':
    case 'cold':
    case 'drink':
      verb = 'Варите на слабом огне';
    default:
      verb = 'Варите на слабом огне';
  }
  final names = matched
      .map((ingredient) => byId[ingredient.id]!.name)
      .join(', ');
  return '$verb $minutes минут: $names.';
}

int _insertIndex(String kind, int length) {
  switch (kind) {
    case 'salad':
    case 'snack':
    case 'drink':
    case 'cold':
      return 0;
    case 'soup':
    case 'boil':
    case 'porridge':
    case 'side':
      return min(1, length);
    case 'fry':
    case 'stew':
    case 'egg':
      return min(2, length);
    case 'bake':
    case 'bake_dough':
    case 'dessert':
      return max(0, length - 1);
    default:
      return min(1, length);
  }
}

bool _stepCovers(
  SeedStep step,
  _HeatRule rule,
  List<RecipeIngredient> matched,
  Map<String, SeedIngredient> byId,
  bool requireName,
) {
  final text = _normalize(step.text);
  if (!_heatKeywords.any(text.contains)) return false;

  var enough = (step.timerSeconds ?? 0) >= rule.minutes * 60;
  if (!enough) {
    for (final match in RegExp(r'(\d+)\s*(?:мин|минут)').allMatches(text)) {
      final minutes = int.tryParse(match.group(1) ?? '') ?? 0;
      if (minutes >= rule.minutes) {
        enough = true;
        break;
      }
    }
  }
  if (!enough) return false;
  if (!requireName) return true;

  return matched.any((ingredient) {
    final name = _normalize(byId[ingredient.id]!.name);
    final firstWord = name.split(' ').first;
    final stem = firstWord.length <= 4 ? firstWord : firstWord.substring(0, 4);
    return text.contains(stem);
  });
}

List<String> _ancestors(String id, Map<String, SeedIngredient> byId) {
  final result = <String>[];
  var current = byId[id]?.parentId;
  while (current != null && !result.contains(current)) {
    result.add(current);
    current = byId[current]?.parentId;
  }
  return result;
}

String _difficulty(int stepCount, int activeMinutes) {
  if (stepCount <= 5 && activeMinutes <= 30) return 'easy';
  if (stepCount <= 10 && activeMinutes <= 60) return 'medium';
  return 'hard';
}

void _validateDuplicates(Map<String, Set<String>> ingredientSets) {
  final ids = ingredientSets.keys.toList();
  for (var i = 0; i < ids.length; i++) {
    for (var j = i + 1; j < ids.length; j++) {
      final left = ingredientSets[ids[i]]!;
      final right = ingredientSets[ids[j]]!;
      final intersection = left.intersection(right).length;
      final union = left.union(right).length;
      final jaccard = union == 0 ? 1.0 : intersection / union;
      if (jaccard >= 0.8) {
        throw StateError(
          'Recipes ${ids[i]} and ${ids[j]} are too similar: '
          '${jaccard.toStringAsFixed(3)}',
        );
      }
    }
  }
}

void _validateCounts(
  List<SeedIngredient> ingredients,
  List<Map<String, dynamic>> recipes,
  Map<String, int> typeCounts,
  Map<String, int> difficultyCounts,
) {
  if (ingredients.length < 250) {
    throw StateError('Expected at least 250 ingredients');
  }
  if (recipes.length < 120) {
    throw StateError('Expected at least 120 recipes');
  }
  const dishTypes = {
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
  for (final dishType in dishTypes) {
    if ((typeCounts[dishType] ?? 0) == 0) {
      throw StateError('No recipes for dish type $dishType');
    }
  }
  for (final difficulty in ['easy', 'medium', 'hard']) {
    if ((difficultyCounts[difficulty] ?? 0) == 0) {
      throw StateError('No recipes with difficulty $difficulty');
    }
  }
}

void _writeJson(String path, Map<String, dynamic> data) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(data)}\n',
  );
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll('ё', 'е').trim();

String _join(List<String> values) {
  if (values.isEmpty) return '';
  if (values.length == 1) return values.first;
  return '${values.take(values.length - 1).join(', ')} и ${values.last}';
}

bool _setEquals(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);
