import 'dart:io';

import 'package:chto_prigotovit/core/catalog/difficulty_calculator.dart';
import 'package:chto_prigotovit/core/db/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DifficultyCalculator (R8-10)', () {
    test('1. Reference benchmark test: 40 dishes from difficulty_reference.csv', () {
      final file = File('test/fixtures/difficulty_reference.csv');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Reference CSV fixture must exist',
      );

      final lines = file
          .readAsLinesSync()
          .where((l) => l.trim().isNotEmpty)
          .toList();
      // Skip header
      final dataRows = lines.skip(1).toList();
      expect(
        dataRows.length,
        equals(40),
        reason: 'Must contain exactly 40 reference dishes',
      );

      int matches = 0;
      int crossLevelMismatches = 0;
      final discrepancies = <String>[];

      for (final row in dataRows) {
        final parts = row.split(',');
        final title = parts[0].trim();
        final expectedDiffStr = parts[1].trim();
        final activeMinutes = int.parse(parts[2].trim());
        final stepCount = int.parse(parts[3].trim());
        final ingredientCount = int.parse(parts[4].trim());
        final notes = parts.length > 5 ? parts.sublist(5).join(',').trim() : '';

        final score = DifficultyCalculator.calculate(
          title: title,
          activeMinutes: activeMinutes,
          stepCount: stepCount,
          ingredientCount: ingredientCount,
          stepTexts: notes.isNotEmpty ? [notes] : [],
        );

        final expectedDiff = Difficulty.values.firstWhere(
          (d) => d.name == expectedDiffStr,
        );
        final isMatch = score.difficulty == expectedDiff;

        if (isMatch) {
          matches++;
        } else {
          discrepancies.add(
            '$title: expected=$expectedDiffStr, actual=${score.difficulty.name} (points=${score.points}, reasons=${score.reasons})',
          );
          // Check if cross-level mismatch (easy <-> hard)
          if ((expectedDiff == Difficulty.easy &&
                  score.difficulty == Difficulty.hard) ||
              (expectedDiff == Difficulty.hard &&
                  score.difficulty == Difficulty.easy)) {
            crossLevelMismatches++;
          }
        }
      }

      final matchRate = matches / dataRows.length;
      // Requirements from R8-10:
      // >= 90% match
      // 0 cross-level discrepancies
      expect(
        crossLevelMismatches,
        equals(0),
        reason:
            'Zero cross-level (easy <-> hard) discrepancies allowed: $discrepancies',
      );
      expect(
        matchRate,
        greaterThanOrEqualTo(0.90),
        reason:
            'Match rate must be >= 90% (actual: ${(matchRate * 100).toStringAsFixed(1)}%). Discrepancies: $discrepancies',
      );
    });

    test('2. Thresholds: easy <= 3, medium 4..7, hard >= 8', () {
      final easy = DifficultyCalculator.calculate(
        title: 'Яичница',
        activeMinutes: 5,
        stepCount: 2,
        ingredientCount: 2,
      );
      expect(easy.difficulty, equals(Difficulty.easy));
      expect(
        easy.points,
        lessThanOrEqualTo(DifficultyCalculator.easyMaxPoints),
      );

      final medium = DifficultyCalculator.calculate(
        title: 'Сырники',
        activeMinutes: 25,
        stepCount: 5,
        ingredientCount: 6,
        stepTexts: ['формуем сырники и обжариваем'],
      );
      expect(medium.difficulty, equals(Difficulty.medium));
      expect(
        medium.points,
        inInclusiveRange(4, DifficultyCalculator.mediumMaxPoints),
      );

      final hard = DifficultyCalculator.calculate(
        title: 'Торт Наполеон',
        activeMinutes: 75,
        stepCount: 11,
        ingredientCount: 9,
        stepTexts: [
          'раскатать коржи слоеное тесто',
          'выпекать коржи и пропитать',
        ],
      );
      expect(hard.difficulty, equals(Difficulty.hard));
      expect(hard.points, greaterThanOrEqualTo(8));
    });

    test(
      '3. Explanations/reasons are populated for UI (R8-13 requirement)',
      () {
        final score = DifficultyCalculator.calculate(
          title: 'Пельмени сибирские',
          activeMinutes: 50,
          stepCount: 7,
          ingredientCount: 7,
          stepTexts: ['раскатать тесто скалкой', 'лепить пельмени'],
        );

        expect(score.reasons, isNotEmpty);
        expect(score.reasons.any((r) => r.contains('Раскатка')), isTrue);
        expect(score.reasons.any((r) => r.contains('Лепка')), isTrue);
      },
    );

    test('4. calculateFromJson parses seed or AI format correctly', () {
      final json = {
        'title': 'Гречка с маслом',
        'total_minutes': 20,
        'active_minutes': 5,
        'ingredients': [
          {'name': 'Гречка'},
          {'name': 'Вода'},
          {'name': 'Масло'},
        ],
        'steps': ['Промыть гречку', 'Сварить до готовности'],
      };

      final score = DifficultyCalculator.calculateFromJson(json);
      expect(score.difficulty, equals(Difficulty.easy));
      expect(score.points, equals(0));
    });
  });
}
