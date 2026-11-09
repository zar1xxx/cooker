import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/adaptive/adaptive_spec.dart';
import 'package:chto_prigotovit/core/adaptive/ui_profile.dart';
import 'package:chto_prigotovit/core/adaptive/ui_profile_service.dart';

void main() {
  group('UiProfile (R8-16 / D-057)', () {
    test('defaultSimple has expected fields', () {
      final p = UiProfile.defaultSimple();
      expect(p.mode, UiMode.simple);
      expect(p.fontScale, 1.0);
      expect(p.density, UiDensity.spacious);
      expect(p.hapticFeedback, isTrue);
      expect(p.cardGestures, isFalse);
      expect(p.showAiDetails, isFalse);
      expect(p.showStatistics, isFalse);
      expect(p.hasCompletedOnboarding, isFalse);
      expect(p.visibleTabs, ['today', 'pantry', 'calendar', 'history']);
    });

    test('defaultFull has expected fields', () {
      final p = UiProfile.defaultFull();
      expect(p.mode, UiMode.full);
      expect(p.fontScale, 1.0);
      expect(p.density, UiDensity.compact);
      expect(p.hapticFeedback, isTrue);
      expect(p.cardGestures, isTrue);
      expect(p.showAiDetails, isTrue);
      expect(p.showStatistics, isTrue);
      expect(p.hasCompletedOnboarding, isTrue);
      expect(p.visibleTabs, [
        'today',
        'pantry',
        'calendar',
        'history',
        'stats',
      ]);
    });

    test('font scale is clamped to 0.9 .. 1.6', () {
      final pLow = const UiProfile().copyWith(fontScale: 0.5);
      expect(pLow.fontScale, 0.9);

      final pHigh = const UiProfile().copyWith(fontScale: 2.5);
      expect(pHigh.fontScale, 1.6);
    });

    test('toJson and fromJson preserve all fields', () {
      final now = DateTime(2026, 11, 9, 12, 0);
      final original = UiProfile(
        mode: UiMode.full,
        fontScale: 1.25,
        density: UiDensity.compact,
        hapticFeedback: false,
        cardGestures: true,
        visibleTabs: const ['today', 'pantry', 'stats'],
        showAiDetails: true,
        showStatistics: true,
        hasCompletedOnboarding: true,
        lastModePromptDate: now,
        suppressModePrompt: true,
      );

      final json = original.toJson();
      final restored = UiProfile.fromJson(json);

      expect(restored.mode, original.mode);
      expect(restored.fontScale, original.fontScale);
      expect(restored.density, original.density);
      expect(restored.hapticFeedback, original.hapticFeedback);
      expect(restored.cardGestures, original.cardGestures);
      expect(restored.visibleTabs, original.visibleTabs);
      expect(restored.showAiDetails, original.showAiDetails);
      expect(restored.showStatistics, original.showStatistics);
      expect(restored.hasCompletedOnboarding, original.hasCompletedOnboarding);
      expect(restored.lastModePromptDate, original.lastModePromptDate);
      expect(restored.suppressModePrompt, original.suppressModePrompt);
    });
  });

  group('AdaptiveSpec (R8-16 / D-057)', () {
    test('simple mode derived properties meet senior-ux rules', () {
      const spec = AdaptiveSpec.defaultSimple;

      expect(spec.isSimple, isTrue);
      expect(spec.isFull, isFalse);
      expect(spec.minTouchTarget, 56.0);
      expect(spec.baseFontSize, 18.0);
      expect(spec.titleFontSize, 24.0);
      expect(spec.cookingStepFontSize, 28.0);
      expect(spec.captionFontSize, 16.0);
      expect(spec.visualDensity, VisualDensity.standard);
      expect(spec.showMultiFilters, isFalse);
      expect(spec.showSortOptions, isFalse);
      expect(spec.maxFilterRows, 1);
      expect(spec.columnsForWidth(800), 1);
      expect(spec.adaptive(simple: 'A', full: 'B'), 'A');
    });

    test('full mode derived properties meet full-featured rules', () {
      const spec = AdaptiveSpec.defaultFull;

      expect(spec.isSimple, isFalse);
      expect(spec.isFull, isTrue);
      expect(spec.minTouchTarget, 48.0);
      expect(spec.baseFontSize, 16.0);
      expect(spec.titleFontSize, 20.0);
      expect(spec.cookingStepFontSize, 28.0);
      expect(spec.captionFontSize, 14.0);
      expect(spec.visualDensity, VisualDensity.compact);
      expect(spec.showMultiFilters, isTrue);
      expect(spec.showSortOptions, isTrue);
      expect(spec.maxFilterRows, 4);
      expect(spec.columnsForWidth(800), 2);
      expect(spec.adaptive(simple: 'A', full: 'B'), 'B');
    });

    test('font scaling scales font sizes proportionally', () {
      final profile = UiProfile.defaultSimple().copyWith(fontScale: 1.5);
      final spec = AdaptiveSpec(profile: profile);

      expect(spec.baseFontSize, 27.0);
      expect(spec.titleFontSize, 36.0);
      expect(spec.cookingStepFontSize, 42.0);
    });

    testWidgets(
      'context.adaptive retrieves spec via AdaptiveScope and ThemeExtension',
      (tester) async {
        AdaptiveSpec? capturedSimple;
        AdaptiveSpec? capturedFull;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightFor(AdaptiveSpec.defaultSimple),
            home: Builder(
              builder: (ctx) {
                capturedSimple = ctx.adaptive;
                return const SizedBox();
              },
            ),
          ),
        );

        expect(capturedSimple, isNotNull);
        expect(capturedSimple!.isSimple, isTrue);

        await tester.pumpWidget(
          AdaptiveScope(
            spec: AdaptiveSpec.defaultFull,
            child: MaterialApp(
              home: Builder(
                builder: (ctx) {
                  capturedFull = ctx.adaptive;
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        expect(capturedFull, isNotNull);
        expect(capturedFull!.isFull, isTrue);
      },
    );

    testWidgets('FullOnly and SimpleOnly conditionally render content', (
      tester,
    ) async {
      await tester.pumpWidget(
        const AdaptiveScope(
          spec: AdaptiveSpec.defaultSimple,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SimpleOnly(child: Text('Only In Simple')),
                  FullOnly(child: Text('Only In Full')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Only In Simple'), findsOneWidget);
      expect(find.text('Only In Full'), findsNothing);

      await tester.pumpWidget(
        const AdaptiveScope(
          spec: AdaptiveSpec.defaultFull,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SimpleOnly(child: Text('Only In Simple')),
                  FullOnly(child: Text('Only In Full')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Only In Simple'), findsNothing);
      expect(find.text('Only In Full'), findsOneWidget);
    });
  });

  group('UiProfileService logic and persistence (R8-16 / R8-17)', () {
    test('prompts full mode only after 10 searches and 30-day throttle', () async {
      final tempFile = File(
        '${Directory.systemTemp.path}/test_ui_profile_${DateTime.now().microsecondsSinceEpoch}.json',
      );
      addTearDown(() async {
        if (await tempFile.exists()) await tempFile.delete();
      });

      final service = UiProfileService(tempFile);
      final now = DateTime(2026, 11, 9, 12, 0);

      // Low filter count -> false
      expect(
        service.shouldPromptFullMode(searchAndFilterCount: 5, now: now),
        isFalse,
      );

      // High filter count -> true
      expect(
        service.shouldPromptFullMode(searchAndFilterCount: 12, now: now),
        isTrue,
      );

      // Record prompt shown
      await service.recordModePromptPresented(now: now);

      // Prompted 5 days later -> false (throttled)
      expect(
        service.shouldPromptFullMode(
          searchAndFilterCount: 15,
          now: now.add(const Duration(days: 5)),
        ),
        isFalse,
      );

      // Prompted 35 days later -> true
      expect(
        service.shouldPromptFullMode(
          searchAndFilterCount: 15,
          now: now.add(const Duration(days: 35)),
        ),
        isTrue,
      );
    });

    test('prompts simple mode when system font scale >= 1.3', () async {
      final service = UiProfileService();
      await service.saveProfile(UiProfile.defaultFull());
      final now = DateTime(2026, 11, 9, 12, 0);

      expect(
        service.shouldPromptSimpleMode(systemFontScale: 1.0, now: now),
        isFalse,
      );
      expect(
        service.shouldPromptSimpleMode(systemFontScale: 1.4, now: now),
        isTrue,
      );
    });

    test('exportData and importData work correctly', () async {
      final service = UiProfileService();
      final full = UiProfile.defaultFull();
      await service.saveProfile(full);

      final exported = service.exportData();
      final service2 = UiProfileService();
      await service2.importData(exported);

      expect(service2.current.mode, UiMode.full);
      expect(service2.current.density, UiDensity.compact);
    });
  });

  group('Codebase audit (R8-16 requirement)', () {
    test('no fontSize: or SizedBox(height: 56 found outside theme and adaptive_spec', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where(
            (f) =>
                !f.path.contains('theme.dart') &&
                !f.path.contains('adaptive_spec.dart') &&
                !f.path.contains('.freezed.dart') &&
                !f.path.contains('.g.dart'),
          )
          .toList();

      final forbiddenFontSize = RegExp(r'fontSize:\s*\d+');
      final forbiddenSizedBox56 = RegExp(r'SizedBox\s*\(\s*height:\s*56');

      final violations = <String>[];

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (forbiddenFontSize.hasMatch(line)) {
            violations.add('${file.path}:${i + 1}: $line');
          }
          if (forbiddenSizedBox56.hasMatch(line)) {
            violations.add('${file.path}:${i + 1}: $line');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Hardcoded fontSize or SizedBox(height: 56) found outside theme and adaptive_spec:\n${violations.join('\n')}',
      );
    });
  });
}
