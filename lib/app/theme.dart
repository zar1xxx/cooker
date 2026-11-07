import 'package:flutter/material.dart';

/// Application theme definitions conforming to TZ 7.1 senior accessibility rules:
/// - Base body font >= 18 sp
/// - Titles >= 24 sp
/// - Interactive buttons min touch target >= 56 dp
/// - Contrast ratio >= 4.5:1 in both light and dark themes
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

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: primaryLight,
      onPrimary: onPrimaryLight,
      // Without these Flutter falls back to its default teal (#03DAC6) for
      // selected chips, switches and FABs, and primaryContainer equals
      // primary (dark text on dark green in selected pantry tiles).
      primaryContainer: Color(0xFFCDEBD6),
      onPrimaryContainer: Color(0xFF00210E),
      secondary: Color(0xFF8A4B2A),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF5DCCB),
      onSecondaryContainer: Color(0xFF3A1A08),
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      surfaceContainerHighest: Color(0xFFE2E4DE),
      outline: Color(0xFF727972),
    );

    return _buildTheme(colorScheme: colorScheme, isDark: false);
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: primaryDark,
      onPrimary: onPrimaryDark,
      primaryContainer: Color(0xFF00522D),
      onPrimaryContainer: Color(0xFF85F5B2),
      secondary: Color(0xFFFFB590),
      onSecondary: Color(0xFF552100),
      secondaryContainer: Color(0xFF6F3A1E),
      onSecondaryContainer: Color(0xFFFFDBCB),
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      surfaceContainerHighest: Color(0xFF333834),
      outline: Color(0xFF8C938C),
    );

    return _buildTheme(colorScheme: colorScheme, isDark: true);
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final textTheme = _buildTextTheme(colorScheme.onSurface);

    final buttonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size(minTouchTarget, minTouchTarget),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: baseFontSize,
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
      scaffoldBackgroundColor: isDark ? backgroundDark : backgroundLight,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: titleFontSize,
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
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
            Size(minTouchTarget, minTouchTarget),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        sizeConstraints: const BoxConstraints(
          minWidth: minTouchTarget,
          minHeight: minTouchTarget,
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        indicatorColor: colorScheme.primary.withAlpha(isDark ? 80 : 40),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color onSurface) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: onSurface,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: onSurface,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: titleFontSize,
        fontWeight: FontWeight.bold,
        color: onSurface,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontSize: titleFontSize,
        fontWeight: FontWeight.w700,
        color: onSurface,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
        height: 1.35,
      ),
      titleSmall: TextStyle(
        fontSize: baseFontSize,
        fontWeight: FontWeight.w600,
        color: onSurface,
        height: 1.35,
      ),
      bodyLarge: TextStyle(
        fontSize: baseFontSize,
        fontWeight: FontWeight.normal,
        color: onSurface,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontSize: baseFontSize,
        fontWeight: FontWeight.normal,
        color: onSurface,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: onSurface.withAlpha(200),
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: baseFontSize,
        fontWeight: FontWeight.w600,
        color: onSurface,
        height: 1.3,
      ),
      labelMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
        height: 1.3,
      ),
    );
  }
}
