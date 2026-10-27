import 'package:flutter/material.dart';

abstract final class ShelfColors {
  static const background = Color(0xFFFAF8F3);
  static const green = Color(0xFF244C3B);
  static const ink = Color(0xFF252B25);
  static const muted = Color(0xFF71776D);
  static const orange = Color(0xFFB94D30);
  static const line = Color(0xFFE5E7DE);
}

ThemeData shelfTheme() => ThemeData(
  fontFamily: 'ShelfSans',
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ShelfColors.green,
    primary: ShelfColors.green,
    secondary: ShelfColors.orange,
    surface: ShelfColors.background,
    error: const Color(0xFFAA3124),
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
      borderSide: const BorderSide(color: ShelfColors.green, width: 2),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(44, 50),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
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
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);
