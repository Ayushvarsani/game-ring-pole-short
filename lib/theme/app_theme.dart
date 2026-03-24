import 'package:flutter/material.dart';

/// Centralized app theme with a premium, vibrant color palette.
/// 
/// Gradient backgrounds: Deep ocean blue → midnight purple
/// Accents: Teal-cyan glow + soft violet highlights
class AppTheme {
  AppTheme._();

  // ── Primary Background Colors ──
  static const Color bgDark = Color(0xFF0B0F2B);         // Deep midnight base
  static const Color bgMedium = Color(0xFF131842);        // Card/surface dark
  static const Color bgLight = Color(0xFF1B2254);         // Elevated surface
  static const Color bgCard = Color(0xFF1E2561);          // Cards & dialogs

  // ── Accent Colors ──
  static const Color accentPrimary = Color(0xFF7B6CF6);   // Vibrant violet
  static const Color accentSecondary = Color(0xFF42D9C8);  // Teal-cyan glow
  static const Color accentWarm = Color(0xFFFF6B9D);       // Warm pink
  static const Color accentGold = Color(0xFFFFD93D);       // Gold/coins

  // ── Text Colors ──
  static const Color textPrimary = Color(0xFFF0F0FF);     // Near-white
  static const Color textSecondary = Color(0xFFB0B4D6);   // Muted lavender
  static const Color textMuted = Color(0xFF7B80A8);       // Subtle hints

  // ── Gradients ──
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F1535),  // Deep blue-purple top
      Color(0xFF0B0F2B),  // Midnight bottom
      Color(0xFF090D24),  // Deeper bottom fade
    ],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentPrimary, accentSecondary],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF7B6CF6), Color(0xFF42D9C8)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient dialogGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E2561), Color(0xFF131842)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF131842),
      Color(0x00131842),
    ],
  );

  // ── Decorations ──
  static BoxDecoration dialogDecoration({Color? borderColor}) {
    final bColor = borderColor ?? accentPrimary;
    return BoxDecoration(
      gradient: dialogGradient,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: bColor.withValues(alpha: 0.35),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: bColor.withValues(alpha: 0.25),
          blurRadius: 30,
          spreadRadius: 5,
        ),
      ],
    );
  }

  static BoxDecoration cardDecoration({
    bool isSelected = false,
    Color? glowColor,
  }) {
    final glow = glowColor ?? accentSecondary;
    return BoxDecoration(
      color: isSelected
          ? accentPrimary.withValues(alpha: 0.2)
          : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isSelected
            ? glow
            : Colors.white.withValues(alpha: 0.1),
        width: isSelected ? 2 : 1,
      ),
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: glow.withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ]
          : null,
    );
  }

  static BoxDecoration actionButtonDecoration({bool isEnabled = true}) {
    return BoxDecoration(
      color: isEnabled 
          ? Colors.white.withValues(alpha: 0.08) 
          : Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withValues(alpha: isEnabled ? 0.15 : 0.05),
      ),
      boxShadow: isEnabled
          ? [
              BoxShadow(
                color: accentPrimary.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  /// System navigation bar color
  static const Color systemNavColor = bgDark;
}
