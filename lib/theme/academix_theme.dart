import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'academix_colors.dart';

abstract final class AcademixTheme {
  static final light = _theme(Brightness.light);
  static final dark = _theme(Brightness.dark);

  static SystemUiOverlayStyle systemOverlay(ThemeData theme) {
    final dark = theme.brightness == Brightness.dark;
    final icons = dark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      statusBarBrightness: theme.brightness,
      systemNavigationBarColor: theme.colorScheme.surface,
      systemNavigationBarIconBrightness: icons,
    );
  }

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF020617) : const Color(0xFFF8FAFC);
    final surface = dark ? const Color(0xFF0F172A) : Colors.white;
    final foreground = dark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final muted = dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final border = dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final accent = dark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9);
    final tinted = dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final scheme = ColorScheme.fromSeed(
      seedColor: AcademixColors.purple,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: dark ? const Color(0xFF2E1065) : Colors.white,
      primaryContainer:
          dark ? const Color(0xFF2E1065) : const Color(0xFFEDE9FE),
      onPrimaryContainer: accent,
      surface: surface,
      onSurface: foreground,
      onSurfaceVariant: muted,
      outline: muted,
      outlineVariant: border,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: tinted,
      surfaceContainerHigh: tinted,
      surfaceContainerHighest: tinted,
      error: dark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
    );

    OutlineInputBorder inputBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(color: surface),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AcademixColors.purple,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(accent),
      ),
    );
  }
}
