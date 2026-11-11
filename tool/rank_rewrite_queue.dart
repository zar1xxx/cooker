// R9-03: builds docs/reports/rewrite/queue.csv, the order of rewriting.
// Famous dishes first (tool/seed_data/priority_dishes.csv, round-robin, two
// recipes per keyword per round), then the rest by dish_type and id.
// Usage: dart run tool/rank_rewrite_queue.dart
import 'dart:io';

import 'r9_lib.dart';

const _typeOrder = [
  'main',
  'soup',
  'breakfast',
  'salad',
  'side',
  'baking',
  'dessert',
  'snack',
  'drink',
  'preserve',
];

List<List<String>> buildQueue(
  List<Map<String, dynamic>> recipes,
  List<(int, String)> keywords, {
  Set<String> skip = const {},
}) {
  final groups = <int, List<Map<String, dynamic>>>{};
  final rest = <Map<String, dynamic>>[];
  for (final r in recipes) {
    if (r['quality'] != 'template') continue;
    if (skip.contains(r['id'])) continue;
    final low = (r['title'] as String).toLowerCase();
    int? rank;
    for (final (k, kw) in keywords) {
      if (RegExp('(^|[^а-яё])${RegExp.escape(kw)}').hasMatch(low)) {
        rank = k;
        break;
      }
    }
    if (rank == null) {
      rest.add(r);
    } else {
      groups.putIfAbsent(rank, () => []).add(r);
    }
  }
  int byId(Map<String, dynamic> a, Map<String, dynamic> b) =>
      (a['id'] as String).compareTo(b['id'] as String);
  for (final g in groups.values) {
    g.sort(byId);
  }
  final ranks = groups.keys.toList()..sort();
  final rows = <List<String>>[];
  var rounds = 0;
  for (final g in groups.values) {
    rounds = rounds < (g.length + 1) ~/ 2 ? (g.length + 1) ~/ 2 : rounds;
  }
  void add(Map<String, dynamic> r, int? rank) => rows.add([
    '${rows.length + 1}',
    r['id'] as String,
    r['title'] as String,
    r['dish_type'] as String,
    rank == null ? '' : '$rank',
  ]);
  for (var round = 0; round < rounds; round++) {
    for (final rank in ranks) {
      final g = groups[rank]!;
      for (var i = round * 2; i < (round + 1) * 2 && i < g.length; i++) {
        add(g[i], rank);
      }
    }
  }
  rest.sort((a, b) {
    final ta = _typeOrder.indexOf(a['dish_type'] as String);
    final tb = _typeOrder.indexOf(b['dish_type'] as String);
    return ta != tb ? ta.compareTo(tb) : byId(a, b);
  });
  for (final r in rest) {
    add(r, null);
  }
  return rows;
}

String _csv(String v) =>
    v.contains(',') || v.contains('"') ? '"${v.replaceAll('"', '""')}"' : v;

void main() {
  final recipes = recipesOf(readJsonFile('assets/seed/recipes.json'));
  final keywords = <(int, String)>[];
  final lines = File('tool/seed_data/priority_dishes.csv').readAsLinesSync();
  for (final line in lines.skip(1)) {
    final i = line.indexOf(',');
    if (i < 0) continue;
    keywords.add((
      int.parse(line.substring(0, i)),
      line.substring(i + 1).trim(),
    ));
  }
  // Recipes skipped in R9 (see docs/reports/rewrite/needs_ingredients.md)
  // wait for an owner decision and stay out of the queue.
  final skippedFile = File('tool/seed_data/rewrite/skipped_ids.txt');
  final skip = skippedFile.existsSync()
      ? skippedFile
            .readAsLinesSync()
            .map((l) => l.split('|').first.trim())
            .where((l) => l.isNotEmpty)
            .toSet()
      : <String>{};
  final rows = buildQueue(recipes, keywords, skip: skip);
  final out = StringBuffer('position,id,title,dish_type,priority\n');
  for (final row in rows) {
    out.writeln(row.map(_csv).join(','));
  }
  Directory('docs/reports/rewrite').createSync(recursive: true);
  File('docs/reports/rewrite/queue.csv').writeAsStringSync(out.toString());
  stdout.writeln('queue ${rows.length}');
}
