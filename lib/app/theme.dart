import 'package:flutter/material.dart';

import '../core/adaptive/adaptive_spec.dart';

/// Application theme definitions conforming to TZ 7.1 senior accessibility rules
/// and D-057 adaptive interface modes (simple / full via [AdaptiveSpec]).
class AppTheme {
  AppTheme._();

  static const double baseFontSize = 18.0;
  static const double titleFontSize = 24.0;
  static const double cookingStepFontSize = 28.0;
  static const double minTouchTarget = 56.0;

  static const Color primaryLight = Color(0xFF1E5B3A); // Deep forest green
  static const Color onPrimaryLight = Colors.white;
  static const Color primaryDark = Color(0xFF69D898);
  static const Color onPrimaryDark = Color(0xFF00391D);

  static const Color backgroundLight = Color(0xFFF9F9F6);
  static const Color surfaceLight = Colors.white;
  static const Color onSurfaceLight = Color(0xFF191C1A);

  static const Color backgroundDark = Color(0xFF121413);
  static const Color surfaceDark = Color(0xFF1C1F1D);
  static const Color onSurfaceDark = Color(0xFFE1E3DF);

  static const ColorScheme lightColorScheme = ColorScheme.light(
    primary: primaryLight,
    onPrimary: onPrimaryLight,
    primaryContainer: Color(0xFFCDEBD6),
    onPrimaryContainer: Color(0xFF00210E),
    secondary: Color(0xFF8A4B2A),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFF5DCCB),
    onSecondaryContainer: Color(0xFF3A1A08),
    tertiary: Color(0xFF3E6373),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFC2E8FB),
    onTertiaryContainer: Color(0xFF001F2A),
    error: Color(0xFFBA1A1A),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: surfaceLight,
    onSurface: onSurfaceLight,
    onSurfaceVariant: Color(0xFF424940),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF3F5EF),
    surfaceContainer: Color(0xFFEDF0E9),
    surfaceContainerHigh: Color(0xFFE7EAE3),
    surfaceContainerHighest: Color(0xFFE2E4DE),
    outline: Color(0xFF727972),
    outlineVariant: Color(0xFFC2C9BD),
  );

  static const ColorScheme darkColorScheme = ColorScheme.dark(
    primary: primaryDark,
    onPrimary: onPrimaryDark,
    primaryContainer: Color(0xFF00522D),
    onPrimaryContainer: Color(0xFF85F5B2),
    secondary: Color(0xFFFFB590),
    onSecondary: Color(0xFF552100),
    secondaryContainer: Color(0xFF6F3A1E),
    onSecondaryContainer: Color(0xFFFFDBCB),
    tertiary: Color(0xFFA6CCDE),
    onTertiary: Color(0xFF073543),
    tertiaryContainer: Color(0xFF254B5B),
    onTertiaryContainer: Color(0xFFC2E8FB),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: surfaceDark,
    onSurface: onSurfaceDark,
    onSurfaceVariant: Color(0xFFC2C9BD),
    surfaceContainerLowest: Color(0xFF0D0F0E),
    surfaceContainerLow: Color(0xFF191C1A),
    surfaceContainer: Color(0xFF1D201E),
    surfaceContainerHigh: Color(0xFF282B28),
    surfaceContainerHighest: Color(0xFF333834),
    outline: Color(0xFF8C938C),
    outlineVariant: Color(0xFF424940),
  );

  static ThemeData get light => lightFor(AdaptiveSpec.defaultSimple);

  static ThemeData get dark => darkFor(AdaptiveSpec.defaultSimple);

  static ThemeData lightFor([AdaptiveSpec? spec]) {
    return _buildTheme(
      colorScheme: lightColorScheme,
      isDark: false,
      spec: spec ?? AdaptiveSpec.defaultSimple,
    );
  }

  static ThemeData darkFor([AdaptiveSpec? spec]) {
    return _buildTheme(
      colorScheme: darkColorScheme,
      isDark: true,
      spec: spec ?? AdaptiveSpec.defaultSimple,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required bool isDark,
    required AdaptiveSpec spec,
  }) {
    final textTheme = _buildTextTheme(colorScheme.onSurface, spec);

    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(spec.minTouchTarget, spec.minTouchTarget),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: spec.isFull ? 16 : 24,
          vertical: spec.isFull ? 12 : 16,
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: spec.baseFontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      visualDensity: spec.visualDensity,
      extensions: [spec],
      scaffoldBackgroundColor: isDark ? backgroundDark : backgroundLight,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: spec.titleFontSize,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: buttonStyle.copyWith(
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: buttonStyle),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
            Size(spec.minTouchTarget, spec.minTouchTarget),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        sizeConstraints: BoxConstraints(
          minWidth: spec.minTouchTarget,
          minHeight: spec.minTouchTarget,
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: spec.isFull ? 64 : 72,
        indicatorColor: colorScheme.primary.withAlpha(isDark ? 80 : 40),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: spec.captionFontSize,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color onSurface, AdaptiveSpec spec) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: spec.headlineLargeFontSize,
        fontWeight: FontWeight.bold,
        color: onSurface,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize: spec.headlineMediumFontSize,
        fontWeight: FontWeight.bold,
        color: onSurface,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: spec.headlineSmallFontSize,
        fontWeight: FontWeight.bold,
        color: onSurface,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontSize: spec.titleFontSize,
        fontWeight: FontWeight.w700,
        color: onSurface,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        fontSize: spec.isSimple ? 20 * spec.fontScale : 18 * spec.fontScale,
        fontWeight: FontWeight.w600,
        color: onSurface,
        height: 1.35,
      ),
      titleSmall: TextStyle(
        fontSize: spec.baseFontSize,
        fontWeight: FontWeight.w600,
        color: onSurface,
        height: 1.35,
      ),
      bodyLarge: TextStyle(
        fontSize: spec.baseFontSize,
        fontWeight: FontWeight.normal,
        color: onSurface,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontSize: spec.baseFontSize,
        fontWeight: FontWeight.normal,
        color: onSurface,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontSize: spec.captionFontSize,
        fontWeight: FontWeight.normal,
        color: onSurface.withAlpha(200),
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: spec.baseFontSize,
        fontWeight: FontWeight.w600,
        color: onSurface,
        height: 1.3,
      ),
      labelMedium: TextStyle(
        fontSize: spec.captionFontSize,
        fontWeight: FontWeight.w600,
        color: onSurface,
        height: 1.3,
      ),
    );
  }
}
