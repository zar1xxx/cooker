import 'package:drift/drift.dart';

import '../../catalog/recipe_tags.dart';
import 'recipes.dart';

/// Tag join table associating recipes with multiple dietary, occasion and mood tags.
@DataClassName('RecipeTagEntry')
class RecipeTags extends Table {
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagKind => textEnum<TagKind>()();
  TextColumn get tag => text()();

  @override
  Set<Column> get primaryKey => {recipeId, tagKind, tag};
}
