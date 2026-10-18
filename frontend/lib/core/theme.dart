import 'package:flutter/material.dart';

class FarmColors {
  static const olive = Color(0xFF414D32);
  static const paper = Color(0xFFF7F4EB);
  static const wheat = Color(0xFFE8C777);
  static const soil = Color(0xFF8D573D);
}

ThemeData farmTheme([bool dark = false]) {
  final scheme = ColorScheme.fromSeed(
    seedColor: FarmColors.olive,
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: dark ? const Color(0xFFBDCE9C) : FarmColors.olive,
    secondary: FarmColors.soil,
    surface: dark ? const Color(0xFF20251E) : FarmColors.paper,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'DMSans',
  );
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontFamily: 'Lora',
        fontWeight: FontWeight.w400,
        letterSpacing: -1.2,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontFamily: 'Lora',
        fontWeight: FontWeight.w400,
        letterSpacing: -.6,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontFamily: 'Lora'),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .6)),
      ),
    ),
  );
}
