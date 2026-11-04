import 'package:drift/drift.dart';

import '../../matching/ingredient_normalizer.dart';
import '../app_database.dart';

/// Read access to the ingredient catalog, including full-text search.
class IngredientDao {
  IngredientDao(this._db);

  final AppDatabase _db;

  Future<List<Ingredient>> all() {
    return (_db.select(
      _db.ingredients,
    )..where((tbl) => tbl.deletedAt.isNull())).get();
  }

  Future<Ingredient?> byId(String id) {
    return (_db.select(_db.ingredients)
          ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<List<Ingredient>> byIds(Iterable<String> ids) async {
    final idList = ids.toList();
    if (idList.isEmpty) return const [];
    return (_db.select(
      _db.ingredients,
    )..where((tbl) => tbl.id.isIn(idList) & tbl.deletedAt.isNull())).get();
  }

  Future<List<Ingredient>> byCategory(String category) {
    return (_db.select(_db.ingredients)..where(
          (tbl) => tbl.category.equals(category) & tbl.deletedAt.isNull(),
        ))
        .get();
  }

  /// Searches `name` and `synonyms` through the FTS5 table. Falls back to a
  /// LIKE scan for queries FTS cannot tokenize.
  Future<List<Ingredient>> search(String query) async {
    final match = _toMatchQuery(query);
    if (match.isEmpty) return const [];

    final ftsRows = await _db.searchIngredientsFts(match).get();
    if (ftsRows.isEmpty) return _searchLike(query);

    final ids = ftsRows.map((row) => row.ingredientId).toList();
    final rows = await byIds(ids);
    final byId = {for (final row in rows) row.id: row};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  /// Builds a normalizer over the current catalog for synonym/typo/hierarchy
  /// resolution. The normalizer itself is pure Dart and has no DB access.
  Future<IngredientNormalizer> createNormalizer() async {
    final rows = await all();
    return IngredientNormalizer(
      rows.map(
        (row) => IngredientTerm(
          id: row.id,
          name: row.name,
          synonyms: row.synonyms,
          parentId: row.parentId,
        ),
      ),
    );
  }

  /// Resolves free text through the normalizer first, then falls back to FTS.
  Future<List<Ingredient>> searchWithNormalizer(String query) async {
    final normalizer = await createNormalizer();
    final ids = normalizer.resolveMany(query);
    if (ids.isNotEmpty) return byIds(ids);
    return search(query);
  }

  /// Returns `childId -> [direct parent, grandparent, ...]` so callers can
  /// check allergies and exclusions through the whole hierarchy.
  Future<Map<String, List<String>>> hierarchy() async {
    final allIngredients = await all();
    final parentOf = {
      for (final ingredient in allIngredients)
        ingredient.id: ingredient.parentId,
    };
    final result = <String, List<String>>{};

    for (final ingredient in allIngredients) {
      final ancestors = <String>[];
      final seen = <String>{ingredient.id};
      var current = parentOf[ingredient.id];
      while (current != null && current.isNotEmpty && seen.add(current)) {
        ancestors.add(current);
        current = parentOf[current];
      }
      if (ancestors.isNotEmpty) result[ingredient.id] = ancestors;
    }
    return result;
  }

  Future<List<Ingredient>> _searchLike(String query) {
    final pattern = '%${query.trim().toLowerCase()}%';
    return (_db.select(_db.ingredients)..where(
          (tbl) =>
              tbl.deletedAt.isNull() &
              (tbl.name.lower().like(pattern) | tbl.synonyms.like(pattern)),
        ))
        .get();
  }

  String _toMatchQuery(String input) {
    final tokens = RegExp(r'[\p{L}\p{N}]+', unicode: true)
        .allMatches(input.toLowerCase())
        .map((match) => match.group(0)!)
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return '';
    return tokens.map((token) => '"$token"*').join(' ');
  }
}
