import 'package:flutter/material.dart';

/// Soft-blue look from the signed-off prototype (screenshots/).
class PvColors {
  static const background = Color(0xFFF6F8FD);
  static const primary = Color(0xFF6B8DFD);
  static const ink = Color(0xFF232B45);
  static const muted = Color(0xFF8A93A8);
  static const dotBorder = Color(0xFFCBD5EC);
  static const error = Color(0xFFD64545);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: PvColors.primary,
    surface: PvColors.background,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: PvColors.background,
    textTheme: Typography.blackMountainView.apply(
      bodyColor: PvColors.ink,
      displayColor: PvColors.ink,
    ),
  );
}
