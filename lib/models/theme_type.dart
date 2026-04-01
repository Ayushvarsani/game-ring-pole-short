import 'package:flutter/material.dart';

enum ThemeType {
  midnight(
    displayName: 'Midnight',
    coinPrice: 0,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0F1535),
        Color(0xFF0B0F2B),
        Color(0xFF090D24),
      ],
      stops: [0.0, 0.6, 1.0],
    ),
  ),
  sunset(
    displayName: 'Sunset',
    coinPrice: 150,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF2A0845),
        Color(0xFF6441A5),
        Color(0xFF8A2387),
      ],
      stops: [0.0, 0.5, 1.0],
    ),
  ),
  forest(
    displayName: 'Forest',
    coinPrice: 150,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0B2117),
        Color(0xFF143D2A),
        Color(0xFF0F1C1B),
      ],
      stops: [0.0, 0.6, 1.0],
    ),
  ),
  ocean(
    displayName: 'Ocean',
    coinPrice: 200,
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF012A4A),
        Color(0xFF01497C),
        Color(0xFF013A63),
      ],
      stops: [0.0, 0.6, 1.0],
    ),
  );

  final String displayName;
  final int coinPrice;
  final LinearGradient gradient;

  const ThemeType({
    required this.displayName,
    required this.coinPrice,
    required this.gradient,
  });
}
