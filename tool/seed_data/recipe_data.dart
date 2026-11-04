import 'recipes_baking_desserts.dart';
import 'recipes_breakfast_snacks.dart';
import 'recipes_drinks_preserves.dart';
import 'recipes_mains.dart';
import 'recipes_sides_salads.dart';
import 'recipes_soups.dart';
import 'seed_models.dart';

final List<RecipeSpec> allRecipeSpecs = [
  ...soupRecipes,
  ...mainRecipes,
  ...sideRecipes,
  ...saladRecipes,
  ...breakfastRecipes,
  ...snackRecipes,
  ...bakingRecipes,
  ...dessertRecipes,
  ...drinkRecipes,
  ...preserveRecipes,
];
