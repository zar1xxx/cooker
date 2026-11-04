import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Project structure and configuration (S0-01)', () {
    test('required lib directories exist according to TZ 3', () {
      final requiredDirs = [
        'lib/app',
        'lib/core/db',
        'lib/core/ai',
        'lib/core/matching',
        'lib/core/preferences',
        'lib/features/pantry',
        'lib/features/suggestions',
        'lib/features/recipe',
        'lib/features/calendar',
        'lib/features/history',
        'lib/features/settings',
      ];

      for (final dirPath in requiredDirs) {
        final dir = Directory(dirPath);
        expect(
          dir.existsSync(),
          isTrue,
          reason: 'Directory $dirPath should exist per TZ 3',
        );
      }
    });

    test('android/app/build.gradle.kts specifies minSdk 24', () {
      final gradleFile = File('android/app/build.gradle.kts');
      expect(
        gradleFile.existsSync(),
        isTrue,
        reason: 'build.gradle.kts should exist',
      );

      final content = gradleFile.readAsStringSync();
      expect(
        content.contains('minSdk = 24'),
        isTrue,
        reason: 'minSdk must be explicitly set to 24 per AGENTS.md',
      );
      expect(
        content.contains(
          'applicationId = "dev.chtoprigotovit.chto_prigotovit"',
        ),
        isTrue,
        reason: 'applicationId must match dev.chtoprigotovit.chto_prigotovit',
      );
    });
  });
}
