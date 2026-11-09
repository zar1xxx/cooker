/// Nutrition reference data and serving estimation algorithms.
class NutritionReference {
  /// Caloric ceiling for [DietaryTag.lowCalorie] (in kcal per serving).
  static const int kLowCalorieThresholdKcal = 350;

  /// Protein floor for [DietaryTag.highProtein] (in grams per serving).
  static const double kHighProteinThresholdGrams = 20.0;

  /// Nutrition per 100g: (kcal, protein_g, fat_g, carbs_g)
  static const Map<String, (double, double, double, double)>
  _ingredientNutrition = {
    // Meat & Poultry
    'chicken_breast': (165.0, 31.0, 3.6, 0.0),
    'chicken_thigh': (210.0, 24.0, 12.0, 0.0),
    'chicken': (190.0, 27.0, 9.0, 0.0),
    'turkey': (150.0, 29.0, 3.0, 0.0),
    'beef': (250.0, 26.0, 17.0, 0.0),
    'minced_beef': (240.0, 20.0, 18.0, 0.0),
    'minced_meat': (250.0, 18.0, 20.0, 0.0),
    'pork': (260.0, 20.0, 21.0, 0.0),
    'ham': (145.0, 21.0, 6.0, 1.5),

    // Fish & Seafood
    'salmon': (200.0, 20.0, 13.0, 0.0),
    'white_fish': (90.0, 19.0, 1.0, 0.0),
    'tuna_canned': (110.0, 25.0, 1.0, 0.0),
    'shrimp': (95.0, 20.0, 1.5, 0.0),

    // Eggs & Dairy
    'egg': (155.0, 13.0, 11.0, 1.1),
    'milk': (60.0, 3.2, 3.2, 4.7),
    'sour_cream': (206.0, 2.5, 20.0, 3.4),
    'cottage_cheese': (120.0, 16.0, 5.0, 3.0),
    'hard_cheese': (350.0, 25.0, 28.0, 0.5),
    'cheese': (330.0, 23.0, 26.0, 1.0),
    'butter': (748.0, 0.8, 82.5, 0.8),
    'cream': (200.0, 2.8, 20.0, 4.0),

    // Vegetables & Greens
    'potato': (77.0, 2.0, 0.1, 17.5),
    'onion': (40.0, 1.1, 0.1, 9.3),
    'carrot': (35.0, 0.9, 0.2, 8.2),
    'cabbage': (25.0, 1.3, 0.1, 5.8),
    'tomato': (18.0, 0.9, 0.2, 3.9),
    'cucumber': (15.0, 0.7, 0.1, 3.6),
    'garlic': (149.0, 6.4, 0.5, 33.0),
    'bell_pepper': (27.0, 1.0, 0.3, 5.3),
    'beetroot': (43.0, 1.6, 0.2, 9.6),
    'zucchini': (17.0, 1.2, 0.3, 3.1),
    'eggplant': (25.0, 1.0, 0.2, 5.9),
    'dill': (38.0, 2.5, 0.5, 6.3),
    'parsley': (36.0, 3.0, 0.8, 6.3),

    // Grains, Pasta, Bakery
    'rice': (130.0, 2.7, 0.3, 28.0),
    'buckwheat': (120.0, 4.2, 1.1, 25.0),
    'pasta': (140.0, 5.0, 0.6, 28.0),
    'oatmeal': (150.0, 5.0, 3.0, 27.0),
    'wheat_flour': (364.0, 10.3, 1.0, 76.0),
    'rye_flour': (325.0, 8.5, 1.7, 65.0),
    'bread': (240.0, 7.5, 1.5, 48.0),

    // Legumes & Mushrooms
    'beans': (120.0, 8.0, 0.5, 21.0),
    'peas': (118.0, 8.3, 0.5, 21.1),
    'lentils': (116.0, 9.0, 0.4, 20.0),
    'mushrooms': (22.0, 3.1, 0.3, 3.3),

    // Pantry, Oils, Sweets
    'vegetable_oil': (884.0, 0.0, 100.0, 0.0),
    'olive_oil': (884.0, 0.0, 100.0, 0.0),
    'sugar': (398.0, 0.0, 0.0, 99.8),
    'honey': (304.0, 0.3, 0.0, 82.4),
    'salt': (0.0, 0.0, 0.0, 0.0),
    'water': (0.0, 0.0, 0.0, 0.0),
  };

  /// Category defaults (kcal, protein_g) per 100g if ingredient id not found.
  static const Map<String, (double, double)> _categoryDefaults = {
    'meat': (240.0, 20.0),
    'poultry': (180.0, 25.0),
    'fish': (120.0, 18.0),
    'dairy': (120.0, 6.0),
    'vegetables': (30.0, 1.5),
    'fruits': (50.0, 0.8),
    'grains': (130.0, 3.5),
    'bakery': (320.0, 9.0),
    'legumes': (120.0, 8.0),
    'mushrooms': (25.0, 3.0),
    'canned': (120.0, 10.0),
    'spices': (50.0, 1.0),
    'nuts': (600.0, 18.0),
    'sweets': (400.0, 1.0),
    'greens': (30.0, 2.0),
  };

  /// Approximate unit weight in grams.
  static double unitToGrams(
    String unit,
    double amount, {
    String? ingredientId,
  }) {
    switch (unit.toLowerCase()) {
      case 'g':
        return amount;
      case 'kg':
        return amount * 1000.0;
      case 'ml':
        return amount; // ~1 g/ml for kitchen approximations
      case 'l':
        return amount * 1000.0;
      case 'tbsp':
        return amount * 18.0;
      case 'tsp':
        return amount * 5.0;
      case 'cup':
        return amount * 200.0;
      case 'pinch':
      case 'to_taste':
        return amount > 0 ? amount * 2.0 : 2.0;
      case 'pcs':
        return amount * _pieceWeightGrams(ingredientId);
      default:
        return amount;
    }
  }

  static double _pieceWeightGrams(String? ingredientId) {
    if (ingredientId == null) return 100.0;
    final id = ingredientId.toLowerCase();
    if (id.contains('egg')) return 55.0;
    if (id.contains('potato')) return 120.0;
    if (id.contains('onion')) return 100.0;
    if (id.contains('carrot')) return 100.0;
    if (id.contains('tomato')) return 110.0;
    if (id.contains('cucumber')) return 100.0;
    if (id.contains('apple')) return 150.0;
    if (id.contains('garlic')) return 5.0; // single clove / piece
    if (id.contains('breast') || id.contains('fillet')) return 200.0;
    return 100.0;
  }

  /// Calculates total (kcal, protein_g) for a recipe, given its ingredients.
  static (int kcalPerServing, double proteinPerServing) estimatePerServing({
    required List<
      ({String ingredientId, double amount, String unit, String? category})
    >
    ingredients,
    required int servings,
  }) {
    final validServings = servings > 0 ? servings : 2;
    double totalKcal = 0.0;
    double totalProtein = 0.0;

    for (final ing in ingredients) {
      final grams = unitToGrams(
        ing.unit,
        ing.amount,
        ingredientId: ing.ingredientId,
      );
      final (kcal100, protein100) = _getNutrition100g(
        ing.ingredientId,
        ing.category,
      );
      totalKcal += (grams * kcal100) / 100.0;
      totalProtein += (grams * protein100) / 100.0;
    }

    final kcalPerServing = (totalKcal / validServings).round();
    final proteinPerServing = totalProtein / validServings;

    return (kcalPerServing, proteinPerServing);
  }

  static (double kcal, double protein) _getNutrition100g(
    String id,
    String? category,
  ) {
    final key = id.toLowerCase();
    if (_ingredientNutrition.containsKey(key)) {
      final data = _ingredientNutrition[key]!;
      return (data.$1, data.$2);
    }
    // Try matching partial key
    for (final entry in _ingredientNutrition.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return (entry.value.$1, entry.value.$2);
      }
    }
    if (category != null &&
        _categoryDefaults.containsKey(category.toLowerCase())) {
      return _categoryDefaults[category.toLowerCase()]!;
    }
    return (100.0, 3.0); // Safe neutral default
  }
}
