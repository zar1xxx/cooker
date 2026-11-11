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

    // R10: new products (explicit values; partial id matching would
    // mislead, e.g. butter_mushroom -> butter, herring_salted -> salt)
    'butternut_squash': (45.0, 1.0, 0.1, 11.7),
    'eggplant_white': (24.0, 1.0, 0.2, 5.7),
    'eggplant_caviar': (148.0, 1.7, 13.3, 5.1),
    'squash_caviar': (97.0, 1.2, 7.0, 7.4),
    'watercress': (11.0, 2.3, 0.1, 1.3),
    'water_chestnut': (97.0, 1.4, 0.1, 23.9),
    'butter_mushroom': (19.0, 2.4, 0.7, 1.7),
    'milk_mushroom': (16.0, 1.8, 0.8, 1.1),
    'saffron_milk_cap': (17.0, 1.9, 0.8, 0.5),
    'brown_champignon': (27.0, 4.3, 1.0, 0.1),
    'honeysuckle': (30.0, 0.0, 0.0, 8.0),
    'herring_salted': (217.0, 19.8, 15.4, 0.0),
    'salted_trout': (186.0, 20.6, 11.4, 0.0),
    'salted_salmon': (202.0, 22.5, 12.5, 0.0),
    'peanut_butter': (588.0, 25.0, 50.0, 20.0),
    'cocoa_butter': (899.0, 0.0, 99.8, 0.0),
    'milk_chocolate': (535.0, 7.6, 29.7, 59.4),
    'dark_chocolate': (546.0, 4.9, 31.3, 61.2),
    'white_chocolate': (539.0, 5.9, 32.1, 59.2),
    'gingerbread_tula': (364.0, 4.8, 3.2, 76.0),
    'rice_flour': (366.0, 6.0, 1.4, 80.1),
    'buckwheat_flour': (335.0, 13.6, 1.3, 70.6),
    'corn_flour': (331.0, 7.2, 1.5, 72.0),
    'oat_flour': (369.0, 13.0, 6.8, 64.9),
    'almond_flour': (571.0, 21.0, 50.0, 21.0),
    'rice_noodles': (364.0, 6.0, 0.6, 80.0),
    'glass_noodles': (320.0, 0.7, 0.5, 84.0),
    'rice_flakes': (360.0, 7.0, 1.0, 79.0),
    'puffed_rice': (382.0, 6.3, 1.1, 86.0),
    'rice_vinegar': (18.0, 0.3, 0.0, 0.0),
    'egg_white': (52.0, 10.9, 0.2, 0.7),
    'egg_yolk': (322.0, 15.9, 26.5, 3.6),
    'quail_egg': (168.0, 11.9, 13.1, 0.6),
    'almond_milk': (24.0, 0.4, 1.1, 3.0),
    'oat_milk': (46.0, 1.0, 1.5, 6.7),
    'soy_milk': (54.0, 3.3, 1.8, 6.0),
    'baked_milk': (67.0, 3.0, 4.0, 4.7),
    'evaporated_milk': (131.0, 7.0, 7.5, 9.5),
    'boiled_condensed_milk': (315.0, 7.2, 8.5, 55.0),
    'coconut_cream': (330.0, 3.6, 34.7, 6.7),
    'cream_33': (322.0, 2.2, 33.0, 3.0),
    'cream_10': (118.0, 3.0, 10.0, 4.0),
    'ghee': (892.0, 0.3, 99.0, 0.0),
    'greek_yogurt': (97.0, 9.0, 5.0, 4.0),
    'ricotta': (174.0, 11.3, 13.0, 3.0),
    'mascarpone': (412.0, 4.6, 42.0, 3.6),
    'brynza': (260.0, 17.9, 20.1, 0.0),
    'suluguni': (290.0, 20.0, 24.0, 0.0),
    'adyghe_cheese': (240.0, 18.5, 14.0, 1.5),
    'blue_cheese': (354.0, 21.0, 29.0, 2.3),
    'brie': (334.0, 20.8, 27.7, 0.5),
    'cheddar': (403.0, 24.9, 33.1, 1.3),
    'goat_cheese': (364.0, 21.6, 29.8, 0.1),
    'cottage_cheese_grainy': (98.0, 11.0, 4.3, 1.0),
    'curd_mass': (340.0, 7.1, 23.0, 27.5),
    'ayran': (24.0, 1.1, 1.5, 1.4),
    'varenets': (53.0, 2.9, 2.5, 4.1),
    'pork_neck': (267.0, 13.0, 24.0, 0.0),
    'pork_loin': (181.0, 21.0, 10.0, 0.0),
    'pork_shoulder': (248.0, 16.9, 20.0, 0.0),
    'pork_belly': (518.0, 9.3, 53.0, 0.0),
    'pork_knuckle': (293.0, 15.0, 26.0, 0.0),
    'pork_liver': (109.0, 18.8, 3.8, 4.7),
    'pork_skin': (330.0, 30.0, 23.0, 0.0),
    'beef_tenderloin': (158.0, 20.2, 8.5, 0.0),
    'beef_brisket': (217.0, 18.6, 16.0, 0.0),
    'beef_liver': (127.0, 17.9, 3.7, 5.3),
    'beef_kidney': (86.0, 15.2, 2.8, 0.0),
    'beef_bones': (150.0, 15.0, 9.0, 0.0),
    'lamb_leg': (230.0, 18.0, 17.0, 0.0),
    'lamb_ribs': (300.0, 16.0, 26.0, 0.0),
    'goat': (143.0, 27.0, 3.0, 0.0),
    'horse_meat': (167.0, 20.2, 7.0, 0.0),
    'venison': (155.0, 19.5, 8.5, 0.0),
    'minced_lamb': (280.0, 17.0, 23.0, 0.0),
    'minced_turkey': (160.0, 19.7, 8.4, 0.0),
    'smoked_sausage': (450.0, 24.0, 38.0, 0.2),
    'salami': (430.0, 22.0, 37.0, 1.0),
    'boiled_sausage': (257.0, 12.8, 22.2, 1.5),
    'prosciutto': (250.0, 26.0, 16.0, 0.0),
    'smoked_chicken': (184.0, 27.5, 8.2, 0.0),
    'chicken_drumstick': (172.0, 18.2, 10.2, 0.0),
    'chicken_gizzards': (94.0, 17.7, 2.7, 0.0),
    'chicken_hearts': (159.0, 15.8, 10.3, 0.8),
    'quail': (230.0, 18.2, 17.3, 0.4),
    'duck_breast': (200.0, 19.0, 13.0, 0.0),
    'pink_salmon': (140.0, 20.5, 6.5, 0.0),
    'chum_salmon': (127.0, 19.0, 5.6, 0.0),
    'sea_bass': (97.0, 18.4, 2.0, 0.0),
    'dorado': (96.0, 18.0, 3.0, 0.0),
    'flounder': (83.0, 16.5, 1.8, 0.0),
    'halibut': (102.0, 18.9, 3.0, 0.0),
    'tilapia': (96.0, 20.1, 1.7, 0.0),
    'zander': (84.0, 18.4, 1.1, 0.0),
    'capelin': (116.0, 13.4, 7.0, 0.0),
    'sprat': (137.0, 14.1, 9.0, 0.0),
    'tuna_fresh': (108.0, 23.0, 1.0, 0.0),
    'smoked_mackerel': (221.0, 23.4, 13.4, 0.0),
    'red_caviar': (263.0, 31.6, 13.8, 0.0),
    'cod_liver': (613.0, 4.2, 65.7, 1.2),
    'sprats_canned': (363.0, 17.4, 32.4, 0.4),
    'salmon_canned': (136.0, 20.9, 5.0, 0.0),
    'octopus': (82.0, 14.9, 1.0, 2.2),
    'scallops': (88.0, 16.8, 0.8, 3.0),
    'crab_meat': (87.0, 18.0, 1.1, 0.0),
    'king_prawns': (95.0, 20.0, 1.5, 0.0),
    'seafood_mix': (95.0, 17.0, 2.0, 1.0),
    'stewed_pork': (349.0, 14.9, 32.2, 0.0),
    'chicken_canned': (200.0, 18.0, 14.0, 0.0),
    'pate_liver': (301.0, 11.0, 28.0, 2.0),
    'long_rice': (350.0, 7.0, 0.8, 77.0),
    'jasmine_rice': (350.0, 7.0, 0.6, 78.0),
    'brown_rice': (337.0, 7.4, 1.8, 72.9),
    'wild_rice': (357.0, 14.7, 1.1, 74.9),
    'arborio_rice': (350.0, 7.0, 0.6, 79.0),
    'sushi_rice': (350.0, 7.0, 0.6, 77.0),
    'buckwheat_kernel': (313.0, 12.6, 3.3, 62.1),
    'buckwheat_green': (310.0, 12.6, 3.3, 57.0),
    'buckwheat_flakes': (330.0, 12.0, 3.0, 64.0),
    'spelt': (338.0, 14.6, 2.4, 70.2),
    'wheat_groats': (316.0, 11.5, 1.3, 62.0),
    'granola': (471.0, 10.0, 20.0, 64.0),
    'muesli': (352.0, 10.0, 6.0, 66.0),
    'penne': (350.0, 12.0, 1.5, 71.0),
    'fusilli': (350.0, 12.0, 1.5, 71.0),
    'farfalle': (350.0, 12.0, 1.5, 71.0),
    'shells_pasta': (350.0, 12.0, 1.5, 71.0),
    'horns_pasta': (350.0, 12.0, 1.5, 71.0),
    'wholegrain_pasta': (348.0, 13.0, 2.5, 68.0),
    'tagliatelle': (350.0, 12.0, 1.5, 71.0),
    'orzo': (350.0, 12.0, 1.5, 71.0),
    'dumplings_frozen': (275.0, 12.0, 14.0, 26.0),
    'vareniki_frozen': (200.0, 6.0, 3.0, 37.0),
    'puff_pastry': (377.0, 6.0, 23.0, 37.0),
    'yeast_dough': (280.0, 8.0, 5.0, 51.0),
    'wholegrain_bread': (245.0, 13.0, 3.4, 41.0),
    'toast_bread': (266.0, 8.0, 4.0, 49.0),
    'crispbread': (360.0, 10.0, 2.5, 72.0),
    'beans_black': (341.0, 21.6, 1.4, 62.4),
    'beans_pinto': (347.0, 21.4, 1.2, 62.6),
    'lima_beans': (338.0, 21.5, 0.7, 63.4),
    'lentils_black': (352.0, 25.0, 1.0, 60.0),
    'lentils_yellow': (352.0, 24.6, 1.1, 63.4),
    'peas_split': (298.0, 20.5, 2.0, 53.3),
    'peas_whole': (298.0, 20.5, 2.0, 53.3),
    'beans_red_canned': (99.0, 6.7, 0.3, 17.4),
    'lentils_canned': (99.0, 7.0, 0.4, 17.0),
    'broad_beans': (88.0, 7.9, 0.7, 17.6),
    'dried_porcini': (286.0, 30.3, 3.3, 25.0),
    'dried_mushrooms': (286.0, 30.3, 3.3, 25.0),
    'salted_mushrooms': (25.0, 2.0, 1.0, 1.5),
    'pickled_mushrooms': (25.0, 2.0, 1.0, 2.0),
    'brown_sugar': (380.0, 0.1, 0.0, 98.0),
    'powdered_sugar': (399.0, 0.0, 0.0, 99.8),
    'gelatin_sugar': (390.0, 0.0, 0.0, 97.0),
    'salt_sea': (0.0, 0.0, 0.0, 0.0),
    'salt_iodized': (0.0, 0.0, 0.0, 0.0),
    'salt_coarse': (0.0, 0.0, 0.0, 0.0),
    'mineral_water': (0.0, 0.0, 0.0, 0.0),
    'juice_tomato': (21.0, 1.1, 0.2, 3.8),
    'juice_apple': (46.0, 0.1, 0.1, 11.0),
    'juice_orange': (45.0, 0.7, 0.2, 10.4),
    'tomato_puree': (38.0, 1.6, 0.3, 7.0),
    'sun_dried_tomato': (258.0, 14.1, 3.0, 55.8),
    'garlic_sauce': (330.0, 1.0, 33.0, 6.0),
    'tomato_ketchup_spicy': (110.0, 1.5, 0.2, 25.0),
    'dried_garlic': (331.0, 16.6, 0.7, 72.7),
    'dried_onion': (349.0, 10.4, 1.0, 79.0),
    'dried_dill': (253.0, 20.0, 4.4, 55.8),
    'dried_parsley': (292.0, 26.6, 5.5, 50.6),
    'chicken_spices': (250.0, 10.0, 6.0, 40.0),
    'young_potato': (61.0, 2.4, 0.4, 12.4),
    'young_garlic': (149.0, 6.4, 0.5, 33.0),
    'wild_garlic': (35.0, 2.4, 0.1, 6.5),
    'cucumber_salted': (13.0, 0.8, 0.1, 1.7),
    'frozen_peas_carrot': (60.0, 3.0, 0.3, 11.0),
    'linseed_oil': (898.0, 0.0, 99.8, 0.0),
    'corn_oil': (899.0, 0.0, 99.9, 0.0),
    'coconut_oil': (899.0, 0.0, 99.9, 0.0),
    'pumpkin_oil': (896.0, 0.0, 99.6, 0.0),
    'refined_oil': (899.0, 0.0, 99.9, 0.0),
    'unrefined_oil': (899.0, 0.0, 99.9, 0.0),
    'truffle_oil': (884.0, 0.0, 100.0, 0.0),
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
