import 'package:chto_prigotovit/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Accessibility Theme (S0-03 / TZ 7.1)', () {
    test('font sizes conform to accessibility standards', () {
      final lightText = AppTheme.light.textTheme;
      final darkText = AppTheme.dark.textTheme;

      expect(lightText.bodyLarge?.fontSize, greaterThanOrEqualTo(18.0));
      expect(lightText.bodyMedium?.fontSize, greaterThanOrEqualTo(18.0));
      expect(lightText.titleLarge?.fontSize, greaterThanOrEqualTo(24.0));
      expect(lightText.headlineSmall?.fontSize, greaterThanOrEqualTo(24.0));

      expect(darkText.bodyLarge?.fontSize, greaterThanOrEqualTo(18.0));
      expect(darkText.bodyMedium?.fontSize, greaterThanOrEqualTo(18.0));
      expect(darkText.titleLarge?.fontSize, greaterThanOrEqualTo(24.0));
      expect(darkText.headlineSmall?.fontSize, greaterThanOrEqualTo(24.0));
    });

    test('buttons have minimum touch target >= 56 dp', () {
      final lightTheme = AppTheme.light;
      final darkTheme = AppTheme.dark;

      final lightFilledMinSize = lightTheme.filledButtonTheme.style?.minimumSize
          ?.resolve({});
      final darkFilledMinSize = darkTheme.filledButtonTheme.style?.minimumSize
          ?.resolve({});

      expect(lightFilledMinSize?.width, greaterThanOrEqualTo(56.0));
      expect(lightFilledMinSize?.height, greaterThanOrEqualTo(56.0));

      expect(darkFilledMinSize?.width, greaterThanOrEqualTo(56.0));
      expect(darkFilledMinSize?.height, greaterThanOrEqualTo(56.0));
    });

    test('both light and dark themes are properly configured', () {
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
    });
  });
}
