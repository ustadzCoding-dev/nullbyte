import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Color Tokens (dari neural_override DESIGN.md) ──────────────────────────
  static const Color primary = Color(0xFFEBFFE2);
  static const Color primaryFixed = Color(0xFF72FF70);
  static const Color primaryContainer = Color(0xFF00FF41); // Neon Green
  static const Color onPrimary = Color(0xFF003907);
  static const Color onPrimaryContainer = Color(0xFF007117);

  static const Color secondary = Color(0xFFFFD393);
  static const Color secondaryContainer = Color(0xFFFDAF00); // Amber
  static const Color onSecondary = Color(0xFF422C00);
  static const Color onSecondaryContainer = Color(0xFF5C3D00);

  static const Color tertiary = Color(0xFFE6FDFF);
  static const Color tertiaryContainer = Color(0xFF1DF3FF); // Cyan
  static const Color onTertiary = Color(0xFF003739);
  static const Color onTertiaryContainer = Color(0xFF004F52);

  static const Color surface = Color(0xFF131313); // Deep Black
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow = Color(0xFF1C1B1B);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);

  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFB9CCB2);
  static const Color outline = Color(0xFF84967E);
  static const Color outlineVariant = Color(0xFF3B4B37);

  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFF690005);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // ── ThemeData ───────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryContainer,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondaryContainer,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiaryContainer,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
    ),
    scaffoldBackgroundColor: surface,
    textTheme: _buildTextTheme(),
    // 0px border radius — Terminal Brutalism rule
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(),
      color: surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: surfaceContainerLowest,
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: primaryContainer, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: outlineVariant, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: primaryContainer, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: error, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelStyle: TextStyle(color: onSurfaceVariant),
      hintStyle: TextStyle(color: outlineVariant),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryContainer,
        foregroundColor: onPrimary,
        shape: const RoundedRectangleBorder(),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontWeight: FontWeight.w700,
          letterSpacing: 0.05,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryContainer,
        side: const BorderSide(color: primaryContainer, width: 1),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryContainer,
        shape: const RoundedRectangleBorder(),
        textStyle: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontWeight: FontWeight.w400,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceContainerHigh,
      indicatorColor: primaryContainer.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primaryContainer);
        }
        return const IconThemeData(color: onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 10,
            color: primaryContainer,
            letterSpacing: 0.1,
          );
        }
        return const TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 10,
          color: onSurfaceVariant,
          letterSpacing: 0.1,
        );
      }),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceContainerHigh,
      foregroundColor: onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: onSurface,
        letterSpacing: 0.05,
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: surfaceContainerHigh,
      selectedColor: primaryContainer,
      labelStyle: TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: 10,
        letterSpacing: 0.05,
      ),
      shape: RoundedRectangleBorder(),
      side: BorderSide.none,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    dividerTheme: const DividerThemeData(
      color: outlineVariant,
      thickness: 1,
      space: 0,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: surfaceContainerHigh,
      contentTextStyle: TextStyle(
        fontFamily: 'JetBrainsMono',
        color: onSurface,
      ),
      shape: RoundedRectangleBorder(),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: surfaceContainer,
      shape: RoundedRectangleBorder(),
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: onSurface,
      ),
      contentTextStyle: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 14,
        color: onSurfaceVariant,
      ),
    ),
  );

  // ── TextTheme ───────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme() => const TextTheme(
    // Space Grotesk — Display & Headlines (Commanding Voices)
    displayLarge: TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w900,
      fontSize: 56,
      letterSpacing: -0.02,
      color: onSurface,
    ),
    displayMedium: TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w800,
      fontSize: 45,
      letterSpacing: -0.01,
      color: onSurface,
    ),
    displaySmall: TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w700,
      fontSize: 36,
      color: onSurface,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w800,
      fontSize: 32,
      letterSpacing: -0.01,
      color: onSurface,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w700,
      fontSize: 28,
      color: onSurface,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w700,
      fontSize: 24,
      color: onSurface,
    ),
    titleLarge: TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w700,
      fontSize: 22,
      color: onSurface,
    ),
    titleMedium: TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w600,
      fontSize: 16,
      letterSpacing: 0.01,
      color: onSurface,
    ),
    titleSmall: TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w600,
      fontSize: 14,
      letterSpacing: 0.01,
      color: onSurface,
    ),
    // JetBrains Mono — Body & Data Layer
    bodyLarge: TextStyle(
      fontFamily: 'JetBrainsMono',
      fontWeight: FontWeight.w400,
      fontSize: 16,
      color: onSurface,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'JetBrainsMono',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: onSurface,
    ),
    bodySmall: TextStyle(
      fontFamily: 'JetBrainsMono',
      fontWeight: FontWeight.w400,
      fontSize: 12,
      color: onSurfaceVariant,
    ),
    // Space Mono — Labels & Metadata
    labelLarge: TextStyle(
      fontFamily: 'SpaceMono',
      fontWeight: FontWeight.w700,
      fontSize: 14,
      letterSpacing: 0.05,
      color: onSurface,
    ),
    labelMedium: TextStyle(
      fontFamily: 'SpaceMono',
      fontWeight: FontWeight.w400,
      fontSize: 12,
      letterSpacing: 0.05,
      color: onSurfaceVariant,
    ),
    labelSmall: TextStyle(
      fontFamily: 'SpaceMono',
      fontWeight: FontWeight.w400,
      fontSize: 10,
      letterSpacing: 0.1,
      color: onSurfaceVariant,
    ),
  );
}
