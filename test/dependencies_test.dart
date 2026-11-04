import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dependencies check (S0-02)', () {
    test('pubspec.yaml contains all required dependencies', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      final requiredDependencies = [
        'flutter_riverpod',
        'go_router',
        'drift',
        'drift_flutter',
        'sqlite3_flutter_libs',
        'path_provider',
        'freezed_annotation',
        'json_annotation',
        'dio',
        'connectivity_plus',
        'network_info_plus',
        'uuid',
        'table_calendar',
        'speech_to_text',
        'flutter_tts',
        'wakelock_plus',
        'flutter_local_notifications',
        'flutter_secure_storage',
        'intl',
        'flutter_localizations',
      ];

      for (final dep in requiredDependencies) {
        expect(
          pubspec.contains(dep),
          isTrue,
          reason: 'pubspec.yaml must contain dependency: $dep',
        );
      }

      final requiredDevDependencies = [
        'build_runner',
        'drift_dev',
        'freezed',
        'json_serializable',
        'mocktail',
        'flutter_lints',
      ];

      for (final devDep in requiredDevDependencies) {
        expect(
          pubspec.contains(devDep),
          isTrue,
          reason: 'pubspec.yaml must contain dev_dependency: $devDep',
        );
      }
    });
  });
}
