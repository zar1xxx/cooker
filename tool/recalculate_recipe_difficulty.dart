// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:chto_prigotovit/core/catalog/difficulty_calculator.dart';

void main() {
  final recipesFile = File('assets/seed/recipes.json');
  if (!recipesFile.existsSync()) {
    stderr.writeln('assets/seed/recipes.json not found!');
    exit(1);
  }

  final data =
      jsonDecode(recipesFile.readAsStringSync()) as Map<String, dynamic>;
  final recipesList = (data['recipes'] as List).cast<Map<String, dynamic>>();

  print('Loaded ${recipesList.length} seed recipes.');

  int changedCount = 0;
  final diffReport = StringBuffer();
  diffReport.writeln(
    '| № | Название | Старая сложность | Новая сложность | Очки | Причины |',
  );
  diffReport.writeln('|---|---|---|---|---|---|');

  for (int i = 0; i < recipesList.length; i++) {
    final rec = recipesList[i];
    final title = rec['title'] as String;
    final oldDiff = rec['difficulty'] as String? ?? 'easy';

    final score = DifficultyCalculator.calculateFromJson(rec);
    final newDiff = score.difficulty.name;

    if (oldDiff != newDiff) {
      changedCount++;
      rec['difficulty'] = newDiff;
      diffReport.writeln(
        '| $changedCount | $title | $oldDiff | **$newDiff** | ${score.points} | ${score.reasons.join(", ")} |',
      );
    }
  }

  // Save updated file
  final encoder = const JsonEncoder.withIndent('  ');
  recipesFile.writeAsStringSync('${encoder.convert(data)}\n');

  print('Recalculation finished.');
  print('Total changed: $changedCount / ${recipesList.length}');
  final diffCounts = <String, int>{};
  for (final r in recipesList) {
    final d = r['difficulty'] as String;
    diffCounts[d] = (diffCounts[d] ?? 0) + 1;
  }
  print('Counts: $diffCounts');
  print('\nDiscrepancy table:\n');
  print(diffReport.toString());
}
