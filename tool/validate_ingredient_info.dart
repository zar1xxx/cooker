// Проверка assets/seed/ingredient_info.json (задача A4).
// Запуск: dart run tool/validate_ingredient_info.dart
import 'dart:convert';
import 'dart:io';

const _storages = {'fridge', 'freezer', 'pantry'};

void main() {
  final ingredientsRaw = jsonDecode(
    File('assets/seed/ingredients.json').readAsStringSync(),
  );
  final ingredientList = ingredientsRaw is Map
      ? ingredientsRaw['ingredients'] as List<dynamic>
      : ingredientsRaw as List<dynamic>;
  final ids = <String>{
    for (final i in ingredientList) (i as Map<String, dynamic>)['id'] as String,
  };

  final info = jsonDecode(
    File('assets/seed/ingredient_info.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final items = info['items'] as Map<String, dynamic>;

  final errors = <String>[];
  for (final id in ids) {
    if (!items.containsKey(id)) errors.add('нет записи для $id');
  }
  items.forEach((id, value) {
    if (!ids.contains(id)) {
      errors.add('лишний id: $id');
      return;
    }
    final e = value as Map<String, dynamic>;
    if (!_storages.contains(e['storage'])) {
      errors.add('$id: неверное storage ${e['storage']}');
    }
    final days = e['shelf_days'];
    if (days is! int || days <= 0) errors.add('$id: неверное shelf_days');
    final tip = e['tip'];
    if (tip is! String || tip.trim().isEmpty) errors.add('$id: пустой tip');
    final subs = e['substitutes'];
    if (subs is! List) {
      errors.add('$id: substitutes не список');
    } else {
      for (final s in subs) {
        if (s == id) errors.add('$id: замена на себя');
        if (!ids.contains(s)) errors.add('$id: нет замены $s');
      }
    }
  });

  if (errors.isEmpty) {
    stdout.writeln('OK: ${items.length} ингредиентов');
  } else {
    errors.forEach(stderr.writeln);
    exit(1);
  }
}
