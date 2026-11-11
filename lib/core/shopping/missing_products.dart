/// One product the user does not have at home for a recipe (R7-09).
class MissingProduct {
  const MissingProduct({
    required this.ingredientId,
    required this.name,
    this.amount,
    this.unit,
  });

  final String ingredientId;
  final String name;

  /// Amount for the chosen number of servings, null for «по вкусу».
  final double? amount;
  final String? unit;
}

/// Plain view of a recipe ingredient line, so the logic needs no database.
class MissingProductInput {
  const MissingProductInput({
    required this.ingredientId,
    required this.name,
    this.amount,
    this.unit,
    this.isOptional = false,
    this.isStaple = false,
  });

  final String ingredientId;
  final String name;
  final double? amount;
  final String? unit;
  final bool isOptional;
  final bool isStaple;
}

/// Builds the «Чего не хватает» list: recipe minus products at home.
///
/// Optional ingredients and staples (salt, water, oil) are never counted as
/// missing, the same rule as the dish of the day (R8-04). A product counts as
/// available when the pantry has it or one of its child products
/// ([hierarchy] maps a product id to its ancestors).
List<MissingProduct> missingProducts({
  required List<MissingProductInput> lines,
  required Set<String> pantryIds,
  Map<String, List<String>> hierarchy = const {},
  double scale = 1,
}) {
  final available = <String>{...pantryIds};
  for (final id in pantryIds) {
    available.addAll(hierarchy[id] ?? const <String>[]);
  }
  final result = <MissingProduct>[];
  final seen = <String>{};
  for (final line in lines) {
    if (line.isOptional || line.isStaple) continue;
    if (available.contains(line.ingredientId)) continue;
    if (!seen.add(line.ingredientId)) continue;
    result.add(
      MissingProduct(
        ingredientId: line.ingredientId,
        name: line.name,
        amount: line.amount == null ? null : line.amount! * scale,
        unit: line.unit,
      ),
    );
  }
  return result;
}

/// Formats an amount without trailing zeros: 2.0 → "2", 1.5 → "1,5".
String formatAmount(double amount) {
  if (amount == amount.roundToDouble()) return amount.toInt().toString();
  final text = amount.toStringAsFixed(1);
  final trimmed = text.endsWith('.0')
      ? text.substring(0, text.length - 2)
      : text;
  return trimmed.replaceAll('.', ',');
}

/// Text for «Поделиться списком»: a title line and one line per product.
///
/// [unitLabel] turns a unit code (`g`, `pcs`) into Russian text.
String shoppingListText({
  required String title,
  required List<MissingProduct> products,
  required String Function(String? unit) unitLabel,
}) {
  final buffer = StringBuffer(title);
  for (final product in products) {
    buffer.write('\n- ${product.name}');
    final amount = product.amount;
    if (amount != null && amount > 0) {
      final unit = unitLabel(product.unit).trim();
      buffer.write(
        unit.isEmpty
            ? ': ${formatAmount(amount)}'
            : ': ${formatAmount(amount)} $unit',
      );
    }
  }
  return buffer.toString();
}

/// Official Kuper web search for one product (R7-00: no API, no app links
/// confirmed). Only the product name leaves the phone.
Uri kuperSearchUri(String productName) => Uri.parse(
  'https://kuper.ru/search?query=${Uri.encodeComponent(productName)}',
);

/// «Что докупить»: products missing most often for the given dishes.
///
/// [recipeIngredients] maps a recipe id to its non-optional, non-staple
/// ingredient ids. Ties are broken by id, so the result is stable.
List<MapEntry<String, int>> mostMissing({
  required Map<String, Set<String>> recipeIngredients,
  required Set<String> pantryIds,
  int limit = 5,
}) {
  final counts = <String, int>{};
  for (final ids in recipeIngredients.values) {
    for (final id in ids) {
      if (pantryIds.contains(id)) continue;
      counts.update(id, (value) => value + 1, ifAbsent: () => 1);
    }
  }
  final entries = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return entries.take(limit).toList();
}
