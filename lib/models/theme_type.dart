import 'package:flutter/material.dart';

enum ThemeType {
  midnight(
    displayName: 'Midnight',
    coinPrice: 0,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF16233D), Color(0xFF0D1830), Color(0xFF070D18)],
      stops: [0.0, 0.5, 1.0],
    ),
  ),
  sunset(
    displayName: 'Sunset',
    coinPrice: 150,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF341321), Color(0xFF58253A), Color(0xFF241435)],
      stops: [0.0, 0.56, 1.0],
    ),
  ),
  forest(
    displayName: 'Forest',
    coinPrice: 150,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF112A24), Color(0xFF1A4337), Color(0xFF091614)],
      stops: [0.0, 0.5, 1.0],
    ),
  ),
  ocean(
    displayName: 'Ocean',
    coinPrice: 200,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0B2B44), Color(0xFF0F4D65), Color(0xFF071722)],
      stops: [0.0, 0.52, 1.0],
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
