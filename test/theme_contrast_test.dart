import 'package:chto_prigotovit/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// R2-01 & R4-04: Color contrast must satisfy WCAG AA >= 4.5:1 across all ColorScheme pairs.

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
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
          final contrast = _contrast(p.value.$1, p.value.$2);
          expect(
            contrast,
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key} ${p.key}: contrast was $contrast < 4.5',
          );
        }
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
          final onSurfaceContrast = _contrast(s.value, cs.onSurface);
          expect(
            onSurfaceContrast,
            greaterThanOrEqualTo(4.5),
            reason:
                '${entry.key} ${s.key} with onSurface: contrast was $onSurfaceContrast < 4.5',
          );

          final onSurfaceVariantContrast = _contrast(
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
}
