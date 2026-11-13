import 'package:flutter/material.dart';
import 'academix_colors.dart';

class AcademixTheme {
  AcademixTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AcademixColors.purple,
      brightness: Brightness.light,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AcademixColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AcademixColors.purple,
      brightness: Brightness.dark,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AcademixColors.card,
      hintStyle: const TextStyle(color: AcademixColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AcademixColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AcademixColors.border),
      ),
    ),
  );
}
