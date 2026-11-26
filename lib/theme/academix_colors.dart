import 'package:flutter/material.dart';

/// Tokens de CursosWeb (src/index.css), también para los widgets del catálogo.
abstract final class AcademixColors {
  static const purple = Color(0xFF7C3AED);
  static const rose = Color(0xFFE23B56);

  static LinearGradient heroGradient(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(
          purple.withValues(alpha: dark ? .35 : .16),
          background,
        ),
        Color.alphaBlend(const Color(0x332563EB), background),
        background,
      ],
    );
  }

  static LinearGradient softGradient(BuildContext context) {
    final theme = Theme.of(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0, .45, 1],
      colors:
          theme.brightness == Brightness.dark
              ? [
                Color.alphaBlend(
                  const Color(0x596D28D9),
                  theme.colorScheme.surface,
                ),
                Color.alphaBlend(
                  const Color(0x29334155),
                  theme.colorScheme.surface,
                ),
                theme.colorScheme.surface,
              ]
              : const [Color(0xFFEDE9FE), Color(0xFFDDD6FE), Color(0xFFC7D2FE)],
    );
  }
}
