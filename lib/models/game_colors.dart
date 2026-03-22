import 'package:flutter/material.dart';

/// Curated color palette for the Water Sort game.
/// Each color is vibrant, distinct, and visually appealing.
class GameColors {
  GameColors._();

  static const Color red = Color(0xFFE53935);
  static const Color blue = Color(0xFF1E88E5);
  static const Color green = Color(0xFF43A047);
  static const Color yellow = Color(0xFFFDD835);
  static const Color purple = Color(0xFF8E24AA);
  static const Color orange = Color(0xFFFB8C00);
  static const Color pink = Color(0xFFD81B60);
  static const Color cyan = Color(0xFF00ACC1);
  static const Color lime = Color(0xFFC0CA33);
  static const Color teal = Color(0xFF00897B);
  static const Color deepOrange = Color(0xFFE64A19);
  static const Color indigo = Color(0xFF3949AB);
  static const Color brown = Color(0xFF6D4C41);
  static const Color grey = Color(0xFF757575);

  /// Returns a list of [count] distinct game colors.
  static List<Color> getColors(int count) {
    const allColors = [
      red, blue, green, yellow, purple, orange,
      pink, cyan, lime, teal, deepOrange, indigo,
      brown, grey,
    ];
    assert(count <= allColors.length, 'Cannot request more than ${allColors.length} colors');
    return allColors.sublist(0, count);
  }

  /// Returns a slightly lighter version of the color (for liquid highlights).
  static Color lighten(Color color, [double amount = 0.15]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  /// Returns a slightly darker version of the color (for liquid shadows).
  static Color darken(Color color, [double amount = 0.15]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
