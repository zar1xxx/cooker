import 'package:flutter/material.dart';

import '../core/db/enums.dart';

/// Centralized registry for all graphic assets in the app (A-01 / R1-04).
///
/// Icons are 180x180 px pre-rendered tiles on warm cream background with rounded corners.
/// Placeholders are ~528 px wide WebP illustrations.
abstract final class AppImages {
  // Category Icons (15 categories from spec/data/ingredient_categories.json)
  static const String categoryVegetables =
      'assets/icons/categories/vegetables.png';
  static const String categoryFruits = 'assets/icons/categories/fruits.png';
  static const String categoryMeat = 'assets/icons/categories/meat.png';
  static const String categoryPoultry = 'assets/icons/categories/poultry.png';
  static const String categoryFish = 'assets/icons/categories/fish.png';
  static const String categoryDairy = 'assets/icons/categories/dairy.png';
  static const String categoryGrains = 'assets/icons/categories/grains.png';
  static const String categoryBakery = 'assets/icons/categories/bakery.png';
  static const String categoryLegumes = 'assets/icons/categories/legumes.png';
  static const String categoryMushrooms =
      'assets/icons/categories/mushrooms.png';
  static const String categoryCanned = 'assets/icons/categories/canned.png';
  static const String categorySpices = 'assets/icons/categories/spices.png';
  static const String categoryNuts = 'assets/icons/categories/nuts.png';
  static const String categorySweets = 'assets/icons/categories/sweets.png';
  static const String categoryGreens = 'assets/icons/categories/greens.png';

  // Dish Type Icons (10 DishType enum values)
  static const String dishSoup = 'assets/icons/dish_types/soup.png';
  static const String dishMain = 'assets/icons/dish_types/main.png';
  static const String dishSide = 'assets/icons/dish_types/side.png';
  static const String dishSalad = 'assets/icons/dish_types/salad.png';
  static const String dishBreakfast = 'assets/icons/dish_types/breakfast.png';
  static const String dishSnack = 'assets/icons/dish_types/snack.png';
  static const String dishBaking = 'assets/icons/dish_types/baking.png';
  static const String dishDessert = 'assets/icons/dish_types/dessert.png';
  static const String dishDrink = 'assets/icons/dish_types/drink.png';
  static const String dishPreserve = 'assets/icons/dish_types/preserve.png';

  // Recipe Placeholders (WebP)
  static const String placeholderSoup = 'assets/images/placeholders/soup.webp';
  static const String placeholderMain = 'assets/images/placeholders/main.webp';
  static const String placeholderSide = 'assets/images/placeholders/side.webp';
  static const String placeholderSalad =
      'assets/images/placeholders/salad.webp';

  // State Illustrations (WebP)
  static const String stateNoDishes = 'assets/images/states/no_dishes.webp';
  static const String stateErrorGeneric =
      'assets/images/states/error_generic.webp';

  // Cooking Illustrations (WebP)
  static const String cookingStepStart =
      'assets/images/cooking/step_start.webp';
  static const String cookingTimerRing =
      'assets/images/cooking/timer_ring.webp';

  /// Maps ingredient category id to asset path.
  static const Map<String, String> categoryIcons = {
    'vegetables': categoryVegetables,
    'fruits': categoryFruits,
    'meat': categoryMeat,
    'poultry': categoryPoultry,
    'fish': categoryFish,
    'dairy': categoryDairy,
    'grains': categoryGrains,
    'bakery': categoryBakery,
    'legumes': categoryLegumes,
    'mushrooms': categoryMushrooms,
    'canned': categoryCanned,
    'spices': categorySpices,
    'nuts': categoryNuts,
    'sweets': categorySweets,
    'greens': categoryGreens,
  };

  /// Maps DishType enum to asset path.
  static const Map<DishType, String> dishTypeIcons = {
    DishType.soup: dishSoup,
    DishType.main: dishMain,
    DishType.side: dishSide,
    DishType.salad: dishSalad,
    DishType.breakfast: dishBreakfast,
    DishType.snack: dishSnack,
    DishType.baking: dishBaking,
    DishType.dessert: dishDessert,
    DishType.drink: dishDrink,
    DishType.preserve: dishPreserve,
  };

  /// Maps DishType enum to placeholder illustration path (if available).
  static const Map<DishType, String> recipePlaceholders = {
    DishType.soup: placeholderSoup,
    DishType.main: placeholderMain,
    DishType.side: placeholderSide,
    DishType.salad: placeholderSalad,
  };

  /// Resolves category icon asset path by category id with fallback.
  static String? categoryIconPath(String categoryId) {
    return categoryIcons[categoryId];
  }

  /// Resolves DishType icon asset path by DishType enum.
  static String dishTypeIconPath(DishType dishType) {
    return dishTypeIcons[dishType] ?? dishMain;
  }

  /// Resolves recipe placeholder asset path by DishType, or null if no dedicated placeholder.
  static String? recipePlaceholderPath(DishType dishType) {
    return recipePlaceholders[dishType];
  }

  /// Fallback Material Icon for a category.
  static IconData fallbackCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'vegetables':
      case 'carrot':
        return Icons.eco;
      case 'fruits':
      case 'apple':
        return Icons.apple;
      case 'meat':
        return Icons.kebab_dining;
      case 'poultry':
      case 'chicken':
        return Icons.egg;
      case 'fish':
        return Icons.set_meal;
      case 'dairy':
      case 'milk':
        return Icons.local_drink;
      case 'grains':
      case 'grain':
        return Icons.grain;
      case 'bakery':
      case 'bread':
        return Icons.bakery_dining;
      case 'legumes':
      case 'bean':
        return Icons.circle;
      case 'mushrooms':
      case 'mushroom':
        return Icons.forest;
      case 'canned':
        return Icons.inventory_2_outlined;
      case 'spices':
        return Icons.flare;
      case 'nuts':
        return Icons.yard_outlined;
      case 'sweets':
        return Icons.cake_outlined;
      case 'greens':
        return Icons.grass;
      default:
        return Icons.category_outlined;
    }
  }

  /// Fallback Material Icon for DishType.
  static IconData fallbackDishTypeIcon(DishType dishType) {
    switch (dishType) {
      case DishType.soup:
        return Icons.soup_kitchen;
      case DishType.main:
        return Icons.dinner_dining;
      case DishType.side:
        return Icons.rice_bowl;
      case DishType.salad:
        return Icons.eco;
      case DishType.breakfast:
        return Icons.free_breakfast;
      case DishType.snack:
        return Icons.fastfood;
      case DishType.baking:
        return Icons.bakery_dining;
      case DishType.dessert:
        return Icons.icecream;
      case DishType.drink:
        return Icons.local_cafe;
      case DishType.preserve:
        return Icons.takeout_dining;
    }
  }
}

/// Widget for displaying a category tile icon in ClipRRect with ~10% radius,
/// accessible semantics, and Material icon fallback.
class AppCategoryIcon extends StatelessWidget {
  const AppCategoryIcon({
    super.key,
    required this.categoryId,
    this.size = 48,
    this.semanticLabel,
  });

  final String categoryId;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final assetPath = AppImages.categoryIconPath(categoryId);
    final fallbackIcon = AppImages.fallbackCategoryIcon(categoryId);

    Widget imageWidget;
    if (assetPath != null) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.1),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Icon(fallbackIcon, size: size * 0.7),
        ),
      );
    } else {
      imageWidget = Icon(fallbackIcon, size: size * 0.7);
    }

    if (semanticLabel != null && semanticLabel!.isNotEmpty) {
      return Semantics(label: semanticLabel, image: true, child: imageWidget);
    }
    return imageWidget;
  }
}

/// Widget for displaying a DishType icon tile in ClipRRect with ~10% radius.
class AppDishTypeIcon extends StatelessWidget {
  const AppDishTypeIcon({
    super.key,
    required this.dishType,
    this.size = 32,
    this.semanticLabel,
  });

  final DishType dishType;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final assetPath = AppImages.dishTypeIconPath(dishType);
    final fallbackIcon = AppImages.fallbackDishTypeIcon(dishType);

    final imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.1),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(fallbackIcon, size: size * 0.7),
      ),
    );

    if (semanticLabel != null && semanticLabel!.isNotEmpty) {
      return Semantics(label: semanticLabel, image: true, child: imageWidget);
    }
    return imageWidget;
  }
}

/// Header placeholder illustration for recipe cards and recipe detail screen.
/// Uses high-res WebP placeholder when available, or dishes tile on warm cream background.
class AppRecipePlaceholder extends StatelessWidget {
  const AppRecipePlaceholder({
    super.key,
    required this.dishType,
    this.height = 140,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(16)),
  });

  final DishType dishType;
  final double height;
  final BoxFit fit;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final path = AppImages.recipePlaceholderPath(dishType);

    if (path != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Image.asset(
            path,
            fit: fit,
            errorBuilder: (_, _, _) => _fallbackBox(context),
          ),
        ),
      );
    }

    return ClipRRect(borderRadius: borderRadius, child: _fallbackBox(context));
  }

  Widget _fallbackBox(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFF2E6D0),
      alignment: Alignment.center,
      child: AppDishTypeIcon(dishType: dishType, size: 72),
    );
  }
}

/// State illustration widget (empty dishes, generic error)
class AppStateIllustration extends StatelessWidget {
  const AppStateIllustration({
    super.key,
    required this.assetPath,
    this.height = 160,
    this.semanticLabel,
  });

  final String assetPath;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(assetPath, height: height, fit: BoxFit.contain),
    );

    if (semanticLabel != null) {
      return Semantics(label: semanticLabel, image: true, child: image);
    }
    return image;
  }
}
