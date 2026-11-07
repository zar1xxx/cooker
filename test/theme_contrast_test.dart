import 'package:chto_prigotovit/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// R2-01: colors added by the reviewer (secondary*, primaryContainer) must keep
// WCAG AA contrast and must not fall back to Flutter's default teal.

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

    test('${entry.key}: container and secondary pairs are >= 4.5:1', () {
      final pairs = {
        'primaryContainer': (cs.primaryContainer, cs.onPrimaryContainer),
        'secondary': (cs.secondary, cs.onSecondary),
        'secondaryContainer': (cs.secondaryContainer, cs.onSecondaryContainer),
      };
      for (final p in pairs.entries) {
        expect(
          _contrast(p.value.$1, p.value.$2),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key} ${p.key}',
        );
      }
    });

    test('${entry.key}: no default Material teal', () {
      const teal = Color(0xFF03DAC6);
      expect(cs.secondary, isNot(teal));
      expect(cs.secondaryContainer, isNot(teal));
      expect(cs.primaryContainer, isNot(cs.primary));
    });
  }
}
