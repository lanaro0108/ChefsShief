import 'package:flutter/material.dart';

abstract final class ShelfColors {
  static const primary = Color(0xFFFF3030);
  static const darkRed = Color(0xFFD92525);
  static const ink = Color(0xFF15191F);
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFFAFAFA);
  static const subtle = Color(0xFFF3F4F6);
  static const muted = Color(0xFF757575);
  static const line = Color(0xFFE5E7EB);
}

ThemeData shelfTheme() => ThemeData(
  fontFamily: 'Poppins',
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: ShelfColors.primary,
    onPrimary: ShelfColors.ink,
    primaryContainer: ShelfColors.subtle,
    onPrimaryContainer: ShelfColors.darkRed,
    secondary: ShelfColors.darkRed,
    onSecondary: ShelfColors.white,
    secondaryContainer: ShelfColors.subtle,
    onSecondaryContainer: ShelfColors.darkRed,
    surface: ShelfColors.white,
    onSurface: ShelfColors.ink,
    onSurfaceVariant: ShelfColors.muted,
    surfaceContainerLowest: ShelfColors.white,
    surfaceContainerLow: ShelfColors.background,
    surfaceContainer: ShelfColors.subtle,
    surfaceContainerHigh: ShelfColors.subtle,
    surfaceContainerHighest: ShelfColors.subtle,
    outline: ShelfColors.muted,
    outlineVariant: ShelfColors.line,
    error: ShelfColors.darkRed,
    onError: ShelfColors.white,
    surfaceTint: Colors.transparent,
  ),
  scaffoldBackgroundColor: ShelfColors.background,
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 38,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -1.4,
      color: ShelfColors.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -.7,
      color: ShelfColors.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: ShelfColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: ShelfColors.ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: ShelfColors.ink),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: ShelfColors.ink),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: ShelfColors.background,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ShelfColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ShelfColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ShelfColors.primary, width: 2),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: ShelfColors.darkRed,
      foregroundColor: ShelfColors.white,
      minimumSize: const Size(44, 50),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: ShelfColors.darkRed),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: ShelfColors.white,
    indicatorColor: ShelfColors.subtle,
    surfaceTintColor: Colors.transparent,
  ),
  dividerColor: ShelfColors.line,
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ShelfColors.darkRed,
      minimumSize: const Size(44, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: ShelfColors.line),
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: ShelfColors.line),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: ShelfColors.ink,
    contentTextStyle: const TextStyle(
      fontFamily: 'Poppins',
      color: ShelfColors.white,
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);
