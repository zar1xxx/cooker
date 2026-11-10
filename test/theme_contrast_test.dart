import 'dart:io';
import 'dart:ui' as ui;

import 'package:chto_prigotovit/app/theme.dart';
import 'package:chto_prigotovit/core/db/app_database.dart';
import 'package:chto_prigotovit/core/db/daos/history_dao.dart';
import 'package:chto_prigotovit/core/preferences/preference_service.dart';
import 'package:chto_prigotovit/core/providers.dart';
import 'package:chto_prigotovit/features/settings/taste_preferences_screen.dart';
import 'package:chto_prigotovit/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// R2-01, R4-04 & R8-01: Color contrast must satisfy WCAG AA >= 4.5:1 across all ColorScheme pairs.

/// Public helper calculating WCAG contrast ratio between two colors.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in {
    'light': AppTheme.light,
    'dark': AppTheme.dark,
  }.entries) {
    final cs = entry.value.colorScheme;

    test(
      '${entry.key}: all ColorScheme primary/secondary/tertiary/error and container pairs are >= 4.5:1',
      () {
        final pairs = <String, (Color, Color)>{
          'primary': (cs.primary, cs.onPrimary),
          'primaryContainer': (cs.primaryContainer, cs.onPrimaryContainer),
          'secondary': (cs.secondary, cs.onSecondary),
          'secondaryContainer': (
            cs.secondaryContainer,
            cs.onSecondaryContainer,
          ),
          'tertiary': (cs.tertiary, cs.onTertiary),
          'tertiaryContainer': (cs.tertiaryContainer, cs.onTertiaryContainer),
          'error': (cs.error, cs.onError),
          'errorContainer': (cs.errorContainer, cs.onErrorContainer),
        };

        for (final p in pairs.entries) {
          final contrast = contrastRatio(p.value.$1, p.value.$2);
          expect(
            contrast,
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key} ${p.key}: contrast was $contrast < 4.5',
          );
        }
      },
    );

    test(
      '${entry.key}: UI component roles (chips, banners, buttons) satisfy WCAG AA >= 4.5:1',
      () {
        // Liked chip: primaryContainer + onPrimaryContainer
        final likedChipContrast = contrastRatio(
          cs.primaryContainer,
          cs.onPrimaryContainer,
        );
        expect(
          likedChipContrast,
          greaterThanOrEqualTo(4.5),
          reason: 'Liked chip contrast must be >= 4.5:1',
        );

        // Disliked chip: errorContainer + onErrorContainer
        final dislikedChipContrast = contrastRatio(
          cs.errorContainer,
          cs.onErrorContainer,
        );
        expect(
          dislikedChipContrast,
          greaterThanOrEqualTo(4.5),
          reason: 'Disliked chip contrast must be >= 4.5:1',
        );

        // Tip banner: tertiaryContainer + onTertiaryContainer
        final tipBannerContrast = contrastRatio(
          cs.tertiaryContainer,
          cs.onTertiaryContainer,
        );
        expect(
          tipBannerContrast,
          greaterThanOrEqualTo(4.5),
          reason: 'Tip banner contrast must be >= 4.5:1',
        );

        // Missing ingredients banner: secondaryContainer + onSecondaryContainer
        final missingBannerContrast = contrastRatio(
          cs.secondaryContainer,
          cs.onSecondaryContainer,
        );
        expect(
          missingBannerContrast,
          greaterThanOrEqualTo(4.5),
          reason: 'Missing ingredients banner contrast must be >= 4.5:1',
        );

        // Primary action button: primary + onPrimary
        final buttonContrast = contrastRatio(cs.primary, cs.onPrimary);
        expect(
          buttonContrast,
          greaterThanOrEqualTo(4.5),
          reason: 'Primary button contrast must be >= 4.5:1',
        );
      },
    );

    test(
      '${entry.key}: surface and all surfaceContainer* pairs with onSurface and onSurfaceVariant are >= 4.5:1',
      () {
        final surfaces = <String, Color>{
          'surface': cs.surface,
          'surfaceContainerLowest': cs.surfaceContainerLowest,
          'surfaceContainerLow': cs.surfaceContainerLow,
          'surfaceContainer': cs.surfaceContainer,
          'surfaceContainerHigh': cs.surfaceContainerHigh,
          'surfaceContainerHighest': cs.surfaceContainerHighest,
        };

        for (final s in surfaces.entries) {
          final onSurfaceContrast = contrastRatio(s.value, cs.onSurface);
          expect(
            onSurfaceContrast,
            greaterThanOrEqualTo(4.5),
            reason:
                '${entry.key} ${s.key} with onSurface: contrast was $onSurfaceContrast < 4.5',
          );

          final onSurfaceVariantContrast = contrastRatio(
            s.value,
            cs.onSurfaceVariant,
          );
          expect(
            onSurfaceVariantContrast,
            greaterThanOrEqualTo(4.5),
            reason:
                '${entry.key} ${s.key} with onSurfaceVariant: contrast was $onSurfaceVariantContrast < 4.5',
          );
        }
      },
    );

    test(
      '${entry.key}: no default Material teal and errorContainer matches R4-04 spec',
      () {
        const teal = Color(0xFF03DAC6);
        expect(cs.secondary, isNot(teal));
        expect(cs.secondaryContainer, isNot(teal));
        expect(cs.primaryContainer, isNot(cs.primary));

        if (entry.key == 'light') {
          expect(cs.errorContainer, const Color(0xFFFFDAD6));
          expect(cs.onErrorContainer, const Color(0xFF410002));
        } else {
          expect(cs.errorContainer, const Color(0xFF93000A));
          expect(cs.onErrorContainer, const Color(0xFFFFDAD6));
        }
      },
    );
  }

  test('Static audit (R8-01): No hardcoded raw colors in lib/features for semantic styling', () {
    final featuresDir = Directory('lib/features');
    final dartFiles = featuresDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    final forbiddenPatterns = [
      RegExp(r'Colors\.(green|orange|deepOrange|redAccent|amber)\b'),
      RegExp(r'Colors\.grey\[[0-9]+\]'),
      RegExp(r'Color\(0xFF(2E7D32|F9A825|D84315|E65100|C0392B)\)'),
    ];

    final violations = <String>[];
    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        for (final pat in forbiddenPatterns) {
          if (pat.hasMatch(line)) {
            violations.add('${file.path}:${i + 1}: $line');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Hardcoded colors found instead of theme colorScheme:\n${violations.join('\n')}',
    );
  });

  group('Golden / screenshot tests for TastePreferencesScreen (R8-01)', () {
    late AppDatabase db;
    late PreferenceService prefService;
    late HistoryDao historyDao;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory(), seed: true);
      await db.customSelect('SELECT 1').get();
      prefService = PreferenceService(db);
      historyDao = HistoryDao(db, preferenceService: prefService);

      // Populate liked, disliked, and top rated dishes for realistic rendering (>= 2 events per R8-02)
      await historyDao.recordCooked(recipeId: 'chicken_soup_potato', rating: 5);
      await historyDao.recordCooked(recipeId: 'chicken_soup_potato', rating: 5);
      await historyDao.recordCooked(recipeId: 'apple_bake', rating: 1);
      await historyDao.recordCooked(recipeId: 'apple_bake', rating: 1);
    });

    tearDown(() async {
      await db.close();
    });

    for (final isDark in [false, true]) {
      final modeName = isDark ? 'dark' : 'light';
      testWidgets(
        'TastePreferencesScreen visual rendering in $modeName theme',
        (tester) async {
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          const key = ValueKey('taste_preferences_view');
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                databaseProvider.overrideWithValue(db),
                preferenceServiceProvider.overrideWithValue(prefService),
                historyDaoProvider.overrideWithValue(historyDao),
              ],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('ru'),
                home: const RepaintBoundary(
                  key: key,
                  child: TastePreferencesScreen(),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pumpAndSettle();

          // Verify chips and items exist
          expect(find.textContaining('Супы'), findsOneWidget);
          expect(find.textContaining('Десерты'), findsOneWidget);

          // Capture screenshot
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(key),
            );
            final image = await boundary.toImage(pixelRatio: 1.0);
            final byteData = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            if (byteData != null) {
              final file = File(
                'docs/reports/img/taste_preferences_$modeName.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(byteData.buffer.asUint8List());
            }
          });

          expect(
            File('docs/reports/img/taste_preferences_$modeName.png')
                .existsSync(),
            isTrue,
          );
        },
      );
    }
  });
}
