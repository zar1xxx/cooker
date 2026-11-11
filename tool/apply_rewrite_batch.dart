// R9-05: apply a hand-written batch to assets/seed/recipes.json.
// Usage: dart run tool/apply_rewrite_batch.dart tool/seed_data/rewrite/batch_001.json
// Refuses forbidden fields, unknown ids and steps shorter than 20 chars.
import 'dart:convert';
import 'dart:io';

import 'r9_lib.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: apply_rewrite_batch.dart BATCH.json');
    exit(64);
  }
  const path = 'assets/seed/recipes.json';
  final data = readJsonFile(path);
  final recipes = recipesOf(data);
  final batch = readJsonFile(args.first);

  final errors = checkBatch(batch, {
    for (final r in recipes) r['id'] as String,
  });
  if (errors.isNotEmpty) {
    stderr.writeln('REFUSED');
    for (final e in errors) {
      stderr.writeln(e);
    }
    exit(1);
  }

  final changed = applyBatch(recipes, batch);
  File(path)
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));

  const appliedPath = 'tool/seed_data/rewrite/applied_ids.txt';
  final applied = readAppliedIds(appliedPath)..addAll(changed);
  File(appliedPath)
      .writeAsStringSync((applied.toList()..sort()).map((i) => '$i\n').join());
  stdout.writeln('applied ${changed.length}');
}
