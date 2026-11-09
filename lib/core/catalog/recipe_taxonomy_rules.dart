import '../db/enums.dart';
import 'cuisine.dart';
import 'dish_group.dart';
import 'nutrition_reference.dart';
import 'recipe_tags.dart';

/// Concrete ingredient descriptor for taxonomy classification.
class TaxonomyIngredient {
  final String id;
  final double amount;
  final String unit;
  final String? category;

  const TaxonomyIngredient({
    required this.id,
    this.amount = 0,
    this.unit = 'g',
    this.category,
  });
}

/// Core rules engine for classifying dishes and deriving tags from recipe ingredients & metadata.
class RecipeTaxonomyRules {
  static const Set<String> _meatCategories = {'meat', 'poultry'};
  static const Set<String> _fishCategories = {'fish'};
  static const Set<String> _dairyCategories = {'dairy'};

  static const Set<String> _meatKeywords = {
    'meat',
    'beef',
    'pork',
    'chicken',
    'poultry',
    'turkey',
    'ham',
    'bacon',
    'sausage',
    'frankfurter',
    'mince',
    'minced',
    'lamb',
    'duck',
    'veal',
    'куриц',
    'курин',
    'мяс',
    'говяд',
    'свинин',
    'индейк',
    'фарш',
    'ветчин',
    'колбас',
    'сосиск',
    'бекон',
    'баранин',
    'утк',
    'телятин',
  };

  static const Set<String> _fishKeywords = {
    'fish',
    'salmon',
    'tuna',
    'cod',
    'shrimp',
    'crab',
    'seafood',
    'squid',
    'рыб',
    'лосос',
    'семг',
    'форел',
    'тунец',
    'треск',
    'креветк',
    'морепродукт',
    'кальмар',
    'миди',
    'сельдь',
    'селедк',
    'шпрот',
    'горбуш',
  };

  static const Set<String> _eggKeywords = {'egg', 'яйц', 'яич', 'яйцо'};

  static const Set<String> _dairyKeywords = {
    'milk',
    'cheese',
    'butter',
    'sour_cream',
    'cottage_cheese',
    'cream',
    'yogurt',
    'kefir',
    'condensed_milk',
    'молок',
    'сыр',
    'масло сливочн',
    'сметан',
    'творог',
    'сливк',
    'йогурт',
    'кефир',
    'сгущенк',
  };

  static const Set<String> _glutenKeywords = {
    'wheat_flour',
    'rye_flour',
    'bread',
    'white_bread',
    'black_bread',
    'pasta',
    'semolina',
    'barley',
    'spelt',
    'soy_sauce',
    'noodle',
    'мука',
    'мука пшеничн',
    'мука ржан',
    'хлеб',
    'батон',
    'макарон',
    'паста',
    'манка',
    'манная',
    'соевый соус',
    'сухар',
    'вермишель',
  };

  // --- 1. Dish Group Inference ---

  /// Determines the single canonical [DishGroup] for a recipe.
  static DishGroup inferDishGroup({
    String? explicitDishGroup,
    DishType? dishType,
    required List<TaxonomyIngredient> ingredients,
    String? title,
  }) {
    if (explicitDishGroup != null) {
      final parsed = DishGroup.tryFromId(explicitDishGroup);
      if (parsed != null) return parsed;
    }

    final lowerTitle = (title ?? '').toLowerCase();

    // Specific title-based overrides
    if (lowerTitle.contains('торт') ||
        lowerTitle.contains('пирожн') ||
        lowerTitle.contains('десерт') ||
        lowerTitle.contains('мусс') ||
        lowerTitle.contains('морожен')) {
      return DishGroup.dessert;
    }
    if (lowerTitle.contains('пирог') ||
        lowerTitle.contains('булочк') ||
        lowerTitle.contains('кекс') ||
        lowerTitle.contains('блин') ||
        lowerTitle.contains('оладь') ||
        lowerTitle.contains('сырник')) {
      return DishGroup.baking;
    }
    if (lowerTitle.contains('суп') ||
        lowerTitle.contains('борщ') ||
        lowerTitle.contains('щи') ||
        lowerTitle.contains('солянк') ||
        lowerTitle.contains('уха') ||
        lowerTitle.contains('бульон') ||
        lowerTitle.contains('рассольник')) {
      return DishGroup.soup;
    }
    if (lowerTitle.contains('морс') ||
        lowerTitle.contains('компот') ||
        lowerTitle.contains('кисель') ||
        lowerTitle.contains('чай') ||
        lowerTitle.contains('морс') ||
        lowerTitle.contains('напиток')) {
      return DishGroup.beverage;
    }
    if (lowerTitle.contains('варень') ||
        lowerTitle.contains('джем') ||
        lowerTitle.contains('солень') ||
        lowerTitle.contains('заготовк') ||
        lowerTitle.contains('лечо') ||
        lowerTitle.contains('маринад')) {
      return DishGroup.preserves;
    }

    if (dishType != null) {
      switch (dishType) {
        case DishType.soup:
          return DishGroup.soup;
        case DishType.baking:
          return DishGroup.baking;
        case DishType.dessert:
          return DishGroup.dessert;
        case DishType.drink:
          return DishGroup.beverage;
        case DishType.preserve:
          return DishGroup.preserves;
        case DishType.salad:
        case DishType.snack:
          return DishGroup.saladSnack;
        case DishType.side:
          if (_hasGrainsOrPasta(ingredients)) return DishGroup.porridgeSide;
          return DishGroup.vegetable;
        case DishType.breakfast:
          if (_hasEggsOrDairy(ingredients)) return DishGroup.eggDairy;
          if (_hasGrainsOrPasta(ingredients)) return DishGroup.porridgeSide;
          return DishGroup.eggDairy;
        case DishType.main:
          if (_hasMeat(ingredients)) return DishGroup.meat;
          if (_hasFish(ingredients)) return DishGroup.fishSeafood;
          if (_hasEggsOrDairy(ingredients)) return DishGroup.eggDairy;
          return DishGroup.vegetable;
      }
    }

    // Fallback by ingredients
    if (_hasMeat(ingredients)) return DishGroup.meat;
    if (_hasFish(ingredients)) return DishGroup.fishSeafood;
    if (_hasEggsOrDairy(ingredients)) return DishGroup.eggDairy;
    if (_hasGrainsOrPasta(ingredients)) return DishGroup.porridgeSide;
    return DishGroup.vegetable;
  }

  // --- 2. Dietary Tags Inference ---

  /// Infers all applicable dietary tags for a recipe.
  static Set<DietaryTag> inferDietaryTags({
    required List<TaxonomyIngredient> ingredients,
    int? kcalPerServing,
    double? proteinPerServing,
    int servings = 2,
  }) {
    final tags = <DietaryTag>{};

    final hasMeat = _hasMeat(ingredients);
    final hasFish = _hasFish(ingredients);
    final hasDairy = _hasDairy(ingredients);
    final hasEggs = _hasEggs(ingredients);
    final hasGluten = _hasGluten(ingredients);

    // Vegetarian: no meat, poultry, fish
    final isVegetarian = !hasMeat && !hasFish;
    if (isVegetarian) {
      tags.add(DietaryTag.vegetarian);
    }

    // Vegan: vegetarian AND no dairy, no eggs
    final isVegan = isVegetarian && !hasDairy && !hasEggs;
    if (isVegan) {
      tags.add(DietaryTag.vegan);
    }

    // Lenten (Orthodox fasting): no meat, poultry, fish, dairy, eggs
    // (Fish is permitted only on specific feast days, but canonical fasting baseline excludes it)
    final isLenten = isVegan;
    if (isLenten) {
      tags.add(DietaryTag.lenten);
    }

    // Gluten-free: no wheat, rye, barley, bread, flour, pasta
    if (!hasGluten) {
      tags.add(DietaryTag.glutenFree);
    }

    // Lactose-free: no dairy products
    if (!hasDairy) {
      tags.add(DietaryTag.lactoseFree);
    }

    // Low calorie check
    var kcal = kcalPerServing;
    var protein = proteinPerServing;

    if (kcal == null || kcal <= 0 || protein == null || protein <= 0) {
      final nutritionInputs = ingredients
          .map(
            (i) => (
              ingredientId: i.id,
              amount: i.amount,
              unit: i.unit,
              category: i.category,
            ),
          )
          .toList();
      final estimated = NutritionReference.estimatePerServing(
        ingredients: nutritionInputs,
        servings: servings,
      );
      kcal ??= estimated.$1;
      protein ??= estimated.$2;
    }

    if (kcal > 0 && kcal <= NutritionReference.kLowCalorieThresholdKcal) {
      tags.add(DietaryTag.lowCalorie);
    }

    if (protein >= NutritionReference.kHighProteinThresholdGrams) {
      tags.add(DietaryTag.highProtein);
    }

    return tags;
  }

  // --- 3. Occasion Tags Inference ---

  /// Infers occasion tags from cook minutes, servings and recipe attributes.
  static Set<OccasionTag> inferOccasionTags({
    required int totalMinutes,
    int servings = 2,
    DishGroup? dishGroup,
    Difficulty? difficulty,
    String? title,
  }) {
    final tags = <OccasionTag>{};

    // Quick
    if (totalMinutes > 0 && totalMinutes <= 30) {
      tags.add(OccasionTag.quick);
    }

    // For guests
    if (servings >= 5 || difficulty == Difficulty.hard) {
      tags.add(OccasionTag.forGuests);
    }

    // Festive
    final lowerTitle = (title ?? '').toLowerCase();
    if (lowerTitle.contains('праздничн') ||
        lowerTitle.contains('торт') ||
        lowerTitle.contains('новогод') ||
        servings >= 6) {
      tags.add(OccasionTag.festive);
    }

    // Picnic (sandwiches, finger food, portable baking)
    if (dishGroup == DishGroup.saladSnack ||
        (dishGroup == DishGroup.baking &&
            (lowerTitle.contains('пирожк') ||
                lowerTitle.contains('булочк') ||
                lowerTitle.contains('бутерброд')))) {
      tags.add(OccasionTag.picnic);
    }

    // Kids (mild porridges, pancakes, casseroles, desserts)
    if (dishGroup == DishGroup.dessert ||
        lowerTitle.contains('сырник') ||
        lowerTitle.contains('каша') ||
        lowerTitle.contains('блин') ||
        lowerTitle.contains('запеканк')) {
      tags.add(OccasionTag.kids);
    }

    // Everyday (if not strictly festive)
    if (!tags.contains(OccasionTag.festive)) {
      tags.add(OccasionTag.everyday);
    }

    return tags;
  }

  // --- 4. Mood Tags Inference ---

  /// Infers mood tags from metadata and recipe nature.
  static Set<MoodTag> inferMoodTags({
    required int totalMinutes,
    DishGroup? dishGroup,
    String? cuisine,
    Set<DietaryTag>? dietaryTags,
    int? kcalPerServing,
  }) {
    final tags = <MoodTag>{};

    // On the run
    if (totalMinutes > 0 && totalMinutes <= 20) {
      tags.add(MoodTag.onTheRun);
    }

    // Treat yourself
    if (dishGroup == DishGroup.dessert || dishGroup == DishGroup.baking) {
      tags.add(MoodTag.treatYourself);
    }

    // Cozy
    if (dishGroup == DishGroup.soup ||
        dishGroup == DishGroup.porridgeSide ||
        dishGroup == DishGroup.beverage) {
      tags.add(MoodTag.cozy);
    }

    // Light
    if (dietaryTags?.contains(DietaryTag.lowCalorie) == true ||
        dishGroup == DishGroup.saladSnack ||
        dishGroup == DishGroup.vegetable) {
      tags.add(MoodTag.light);
    }

    // Hearty
    if (dishGroup == DishGroup.meat ||
        (kcalPerServing != null && kcalPerServing >= 450)) {
      tags.add(MoodTag.hearty);
    }

    // Something new (international cuisine)
    final normCuisine = Cuisine.normalize(cuisine);
    if (normCuisine != 'home' && normCuisine != 'ru') {
      tags.add(MoodTag.somethingNew);
    }

    return tags;
  }

  // --- 5. All Inferred Tags ---

  /// Generates the complete set of unified [RecipeTag]s.
  static Set<RecipeTag> inferAllTags({
    required List<TaxonomyIngredient> ingredients,
    required int totalMinutes,
    int servings = 2,
    DishGroup? dishGroup,
    Difficulty? difficulty,
    String? cuisine,
    String? title,
    int? kcalPerServing,
    double? proteinPerServing,
  }) {
    final group =
        dishGroup ?? inferDishGroup(ingredients: ingredients, title: title);

    final dietary = inferDietaryTags(
      ingredients: ingredients,
      kcalPerServing: kcalPerServing,
      proteinPerServing: proteinPerServing,
      servings: servings,
    );

    final occasion = inferOccasionTags(
      totalMinutes: totalMinutes,
      servings: servings,
      dishGroup: group,
      difficulty: difficulty,
      title: title,
    );

    final mood = inferMoodTags(
      totalMinutes: totalMinutes,
      dishGroup: group,
      cuisine: cuisine,
      dietaryTags: dietary,
      kcalPerServing: kcalPerServing,
    );

    final result = <RecipeTag>{};
    for (final d in dietary) {
      result.add(RecipeTag.dietary(d));
    }
    for (final o in occasion) {
      result.add(RecipeTag.occasion(o));
    }
    for (final m in mood) {
      result.add(RecipeTag.mood(m));
    }
    return result;
  }

  // --- Helper Predicates ---

  static bool _hasMeat(List<TaxonomyIngredient> ingredients) {
    for (final ing in ingredients) {
      if (ing.category != null &&
          _meatCategories.contains(ing.category!.toLowerCase())) {
        return true;
      }
      final id = ing.id.toLowerCase();
      for (final kw in _meatKeywords) {
        if (id.contains(kw)) return true;
      }
    }
    return false;
  }

  static bool _hasFish(List<TaxonomyIngredient> ingredients) {
    for (final ing in ingredients) {
      if (ing.category != null &&
          _fishCategories.contains(ing.category!.toLowerCase())) {
        return true;
      }
      final id = ing.id.toLowerCase();
      for (final kw in _fishKeywords) {
        if (id.contains(kw)) return true;
      }
    }
    return false;
  }

  static bool _hasEggs(List<TaxonomyIngredient> ingredients) {
    for (final ing in ingredients) {
      final id = ing.id.toLowerCase();
      for (final kw in _eggKeywords) {
        if (id.contains(kw)) return true;
      }
    }
    return false;
  }

  static bool _hasDairy(List<TaxonomyIngredient> ingredients) {
    for (final ing in ingredients) {
      if (ing.category != null &&
          _dairyCategories.contains(ing.category!.toLowerCase())) {
        // If categorized as dairy, make sure it's not eggs alone
        if (!_isPureEgg(ing.id)) return true;
      }
      final id = ing.id.toLowerCase();
      for (final kw in _dairyKeywords) {
        if (id.contains(kw)) return true;
      }
    }
    return false;
  }

  static bool _isPureEgg(String id) {
    final lower = id.toLowerCase();
    return lower.contains('egg') &&
        !lower.contains('cheese') &&
        !lower.contains('milk');
  }

  static bool _hasEggsOrDairy(List<TaxonomyIngredient> ingredients) {
    return _hasEggs(ingredients) || _hasDairy(ingredients);
  }

  static bool _hasGluten(List<TaxonomyIngredient> ingredients) {
    for (final ing in ingredients) {
      final id = ing.id.toLowerCase();
      for (final kw in _glutenKeywords) {
        if (id.contains(kw)) return true;
      }
    }
    return false;
  }

  static bool _hasGrainsOrPasta(List<TaxonomyIngredient> ingredients) {
    for (final ing in ingredients) {
      final cat = ing.category?.toLowerCase() ?? '';
      if (cat == 'grains' || cat == 'bakery') return true;
      final id = ing.id.toLowerCase();
      if (id.contains('rice') ||
          id.contains('buckwheat') ||
          id.contains('pasta') ||
          id.contains('oat') ||
          id.contains('рис') ||
          id.contains('гречк') ||
          id.contains('макарон')) {
        return true;
      }
    }
    return false;
  }
}
