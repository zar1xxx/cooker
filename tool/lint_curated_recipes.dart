// R9-05: lint of the recipes rewritten by hand.
// Usage: dart run tool/lint_curated_recipes.dart
import 'dart:io';

import 'r9_lib.dart';

void main() {
  final recipes = recipesOf(readJsonFile('assets/seed/recipes.json'));
  final categories = ingredientCategories(
    readJsonFile('assets/seed/ingredients.json'),
  );
  final applied = readAppliedIds('tool/seed_data/rewrite/applied_ids.txt');
  final errors = lintCurated(recipes, categories, applied);
  for (final e in errors) {
    stdout.writeln('ERROR $e');
  }
  stdout.writeln('rewritten ${applied.length}, errors ${errors.length}');
  exit(errors.isEmpty ? 0 : 1);
}
