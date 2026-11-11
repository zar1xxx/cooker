// R9-01: Template-recipe detector for the seed catalog.
//
// Reads assets/seed/recipes.json and flags a recipe as templated if ANY of:
//   (a) at least 2 of its steps (by first 40 chars) occur in 10+ other
//       recipes;
//   (b) its description occurs in 10+ recipes;
//   (c) none of its steps has a unique text (every step appears elsewhere too).
//
// Outputs:
//   - docs/reports/rewrite/templated.csv        (id, title, dish_type, reasons)
//   - docs/reports/rewrite/detected_template_ids.json  (machine-readable list)
//   - a summary by dish_type on stdout.
//
// Only reads JSON; no text is generated here. See R9-05 for writers.
import 'dart:convert';
import 'dart:io';

const _prefixLen = 40;
const _sharedThreshold = 10;

/// One templated recipe found by [detectTemplated].
class DetectedTemplate {
  const DetectedTemplate({
    required this.id,
    required this.title,
    required this.dishType,
    required this.reasons,
  });

  final String id;
  final String title;
  final String dishType;
  final String reasons;
}

Map<String, dynamic> _loadJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> _recipes(String path) {
  final data = _loadJson(path);
  return (data['recipes'] as List).cast<Map<String, dynamic>>();
}

/// Replaces the dish title and digits with placeholders, so generator text
/// like «Запекайте блюдо «<title>» 20 минут» matches across recipes.
String _normalize(String text, String title) {
  var t = text.trim();
  if (title.isNotEmpty) {
    t = t.replaceAll(title, '{T}').replaceAll(title.toLowerCase(), '{T}');
  }
  return t.replaceAll(RegExp(r'\d+'), 'N');
}

String _prefix(String text) {
  final t = text.trim();
  return t.substring(0, t.length < _prefixLen ? t.length : _prefixLen);
}

/// Core detection (R9-01). Pure: given the recipe list it returns every
/// templated recipe with the reason(s) that triggered. Exposed so tests can
/// drive it directly without touching disk.
List<DetectedTemplate> detectTemplated(List<Map<String, dynamic>> recipes) {
  final prefixToIds = <String, Set<String>>{};
  final descToIds = <String, Set<String>>{};
  final stepTextToIds = <String, Set<String>>{};

  for (final r in recipes) {
    final id = r['id'] as String;
    final recipeTitle = (r['title'] as String?) ?? '';
    final desc = _normalize((r['description'] as String?) ?? '', recipeTitle);
    if (desc.isNotEmpty) {
      descToIds.putIfAbsent(desc, () => <String>{}).add(id);
    }
    final steps =
        (r['steps'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    for (final s in steps) {
      final text = _normalize((s['text'] as String?) ?? '', recipeTitle);
      if (text.isEmpty) continue;
      prefixToIds.putIfAbsent(_prefix(text), () => <String>{}).add(id);
      stepTextToIds.putIfAbsent(text, () => <String>{}).add(id);
    }
  }

  final detected = <DetectedTemplate>[];
  for (final r in recipes) {
    final id = r['id'] as String;
    final title = r['title'] as String;
    final dishType = r['dish_type'] as String;
    final reasons = <String>[];

    final desc = _normalize((r['description'] as String?) ?? '', title);
    if (desc.isNotEmpty && (descToIds[desc]?.length ?? 0) >= _sharedThreshold) {
      reasons.add('description-shared');
    }

    final steps =
        (r['steps'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    var sharedStepCount = 0;
    var uniqueStepCount = 0;
    for (final s in steps) {
      final text = _normalize((s['text'] as String?) ?? '', title);
      if (text.isEmpty) continue;
      final prefixIds = prefixToIds[_prefix(text)] ?? const <String>{};
      // "other" recipes exclude this one.
      final others = prefixIds.length - (prefixIds.contains(id) ? 1 : 0);
      if (others >= _sharedThreshold) sharedStepCount++;
      if ((stepTextToIds[text]?.length ?? 1) == 1) uniqueStepCount++;
    }
    if (sharedStepCount >= 2) {
      reasons.add('steps-shared($sharedStepCount)');
    }
    if (steps.isNotEmpty && uniqueStepCount == 0) {
      reasons.add('no-unique-step');
    }

    if (reasons.isNotEmpty) {
      detected.add(
        DetectedTemplate(
          id: id,
          title: title,
          dishType: dishType,
          reasons: reasons.join('; '),
        ),
      );
    }
  }
  return detected;
}

/// Writes the CSV, machine-readable id list and prints the per-dish_type
/// summary. Shared by [main] and the tests so both stay in sync.
void writeDetectionReport(List<DetectedTemplate> detected, String outDir) {
  final dishTypeCounts = <String, int>{};
  for (final d in detected) {
    dishTypeCounts[d.dishType] = (dishTypeCounts[d.dishType] ?? 0) + 1;
  }

  final dir = Directory(outDir);
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // CSV report.
  final csv = StringBuffer('id,title,dish_type,reasons\n');
  for (final d in detected) {
    csv.write(
      '${_csvField(d.id)},${_csvField(d.title)},${d.dishType},${_csvField(d.reasons)}\n',
    );
  }
  File('$outDir/templated.csv').writeAsStringSync(csv.toString());

  // Machine-readable id list for R9-02 / R9-03.
  final ids = detected.map((d) => d.id).toList()..sort();
  File('$outDir/detected_template_ids.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(ids));

  // Summary by dish_type on stdout.
  final total = dishTypeCounts.values.fold<int>(0, (a, b) => a + b);
  stdout.writeln(
    'Detected ${detected.length} templated recipes out of '
    '$total.',
  );
  stdout.writeln('\nTemplated per dish_type:');
  final sorted = dishTypeCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final e in sorted) {
    stdout.writeln('  ${e.key}: ${e.value}');
  }
}

void main(List<String> args) {
  final recipesPath = args.isNotEmpty ? args[0] : 'assets/seed/recipes.json';
  final outDir = args.length > 1 ? args[1] : 'docs/reports/rewrite';

  final recipes = _recipes(recipesPath);
  final detected = detectTemplated(recipes);
  writeDetectionReport(detected, outDir);
}

String _csvField(String value) => '"${value.replaceAll('"', '""')}"';
