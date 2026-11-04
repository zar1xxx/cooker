enum DishType {
  soup,
  main,
  side,
  salad,
  breakfast,
  snack,
  baking,
  dessert,
  drink,
  preserve,
}

enum Difficulty { easy, medium, hard }

enum RecipeSource { seed, ai, user }

enum MealPlanStatus { planned, cooked, skipped }

enum FeedbackKind {
  liked,
  disliked,
  skipped,
  cooked,
  opened,
  // ignore: constant_identifier_names
  rejected_suggestion,
}
