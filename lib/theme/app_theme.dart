import 'package:flutter/material.dart';

/// Shared visual system for the game's premium puzzle presentation.
class AppTheme {
  AppTheme._();

  static const Color bgBase = Color(0xFF070E1A);
  static const Color bgDark = Color(0xFF0B1527);
  static const Color bgMedium = Color(0xFF122036);
  static const Color bgLight = Color(0xFF1A2B45);
  static const Color bgCard = Color(0xFF223553);

  static const Color accentPrimary = Color(0xFF5CA8FF);
  static const Color accentSecondary = Color(0xFF79E2D7);
  static const Color accentWarm = Color(0xFFFF916C);
  static const Color accentGold = Color(0xFFF2C35A);
  static const Color accentSuccess = Color(0xFF84DF9A);
  static const Color accentDanger = Color(0xFFFF7771);

  static const Color textPrimary = Color(0xFFF4F7FF);
  static const Color textSecondary = Color(0xFFB8C6DF);
  static const Color textMuted = Color(0xFF7D8EA9);

  static const double radiusSmall = 18;
  static const double radiusMedium = 24;
  static const double radiusLarge = 30;

  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF12223C), Color(0xFF0C1830), Color(0xFF070E1A)],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5CA8FF), Color(0xFF77D9F0), Color(0xFF79E2D7)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient dialogGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF243654), Color(0xFF19283F), Color(0xFF101A2D)],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient overlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x660A1220), Color(0x220A1220), Color(0x88060C15)],
    stops: [0.0, 0.35, 1.0],
  );

  static const LinearGradient glassBaseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x66FFFFFF), Color(0x2BFFFFFF), Color(0x180B1527)],
    stops: [0.0, 0.28, 1.0],
  );

  static ThemeData get materialTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: bgBase,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentSecondary,
        surface: bgLight,
        error: accentDanger,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      splashColor: accentSecondary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.04,
          letterSpacing: -0.45,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.24,
        ),
        bodyLarge: TextStyle(
          color: textSecondary,
          fontSize: 17,
          fontWeight: FontWeight.w500,
          height: 1.45,
          letterSpacing: 0.14,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
          letterSpacing: 0.18,
        ),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static LinearGradient accentGradient(Color accent, {double intensity = 1.0}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(accent, Colors.white, 0.22 * intensity)!,
        accent,
        Color.lerp(accent, bgDark, 0.36)!,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  static List<BoxShadow> premiumShadows(
    Color tint, {
    bool emphasized = false,
    bool muted = false,
  }) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: muted ? 0.16 : 0.3),
        blurRadius: emphasized ? 34 : 24,
        spreadRadius: emphasized ? -12 : -10,
        offset: const Offset(0, 16),
      ),
      BoxShadow(
        color: tint.withValues(alpha: emphasized ? 0.22 : 0.1),
        blurRadius: emphasized ? 30 : 18,
        spreadRadius: emphasized ? -10 : -12,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static BoxDecoration glassDecoration({
    Color? tint,
    Color? borderColor,
    double radius = radiusMedium,
    bool highlighted = false,
    bool muted = false,
  }) {
    final accent = tint ?? accentPrimary;
    final surface = muted ? bgMedium : bgCard;
    final blend = highlighted ? 0.2 : 0.12;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _blend(surface, Colors.white, 0.18),
          _blend(surface, accent, blend),
          _blend(surface, bgDark, 0.14),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color:
            borderColor ??
            Colors.white.withValues(alpha: highlighted ? 0.22 : 0.12),
        width: highlighted ? 1.2 : 1.0,
      ),
      boxShadow: premiumShadows(accent, emphasized: highlighted, muted: muted),
    );
  }

  static BoxDecoration surfaceDecoration({
    Color? tint,
    Color? borderColor,
    double radius = radiusMedium,
    bool highlighted = false,
    bool muted = false,
  }) {
    return glassDecoration(
      tint: tint,
      borderColor: borderColor,
      radius: radius,
      highlighted: highlighted,
      muted: muted,
    );
  }

  static BoxDecoration dialogDecoration({Color? borderColor, Color? tint}) {
    final accent = borderColor ?? tint ?? accentPrimary;
    return BoxDecoration(
      gradient: dialogGradient,
      borderRadius: BorderRadius.circular(radiusLarge),
      border: Border.all(color: accent.withValues(alpha: 0.28), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.38),
          blurRadius: 36,
          offset: const Offset(0, 20),
        ),
        BoxShadow(
          color: accent.withValues(alpha: 0.14),
          blurRadius: 28,
          spreadRadius: -6,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration cardDecoration({
    bool isSelected = false,
    bool isLocked = false,
    Color? glowColor,
  }) {
    final tint = isSelected
        ? (glowColor ?? accentSecondary)
        : isLocked
        ? textMuted
        : accentPrimary;
    return surfaceDecoration(
      tint: tint,
      radius: 22,
      muted: !isSelected,
      highlighted: isSelected,
      borderColor: isLocked ? Colors.white.withValues(alpha: 0.08) : null,
    );
  }

  static BoxDecoration actionButtonDecoration({
    bool isEnabled = true,
    bool isActive = false,
    Color? accentColor,
  }) {
    final tint = accentColor ?? (isActive ? accentSecondary : accentPrimary);
    return surfaceDecoration(
      tint: tint,
      radius: 24,
      muted: !isEnabled,
      highlighted: isEnabled && isActive,
      borderColor: Colors.white.withValues(alpha: isEnabled ? 0.12 : 0.06),
    );
  }

  static BoxDecoration gradientButtonDecoration({
    required Color accentColor,
    bool isEnabled = true,
    bool emphasized = false,
    double radius = 24,
  }) {
    final alpha = isEnabled ? 1.0 : 0.42;
    return BoxDecoration(
      gradient: accentGradient(accentColor, intensity: emphasized ? 1.0 : 0.82),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16 * alpha)),
      boxShadow: premiumShadows(
        accentColor.withValues(alpha: alpha),
        emphasized: emphasized || isEnabled,
        muted: !isEnabled,
      ),
    );
  }

  static BoxDecoration primaryButtonDecoration({double glowStrength = 0.3}) {
    return BoxDecoration(
      gradient: buttonGradient,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      boxShadow: [
        BoxShadow(
          color: accentPrimary.withValues(alpha: glowStrength),
          blurRadius: 28,
          spreadRadius: -8,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: accentSecondary.withValues(alpha: glowStrength * 0.72),
          blurRadius: 24,
          spreadRadius: -10,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration chipDecoration({Color? tint, bool emphasized = false}) {
    return surfaceDecoration(
      tint: tint ?? accentPrimary,
      radius: 999,
      muted: !emphasized,
      highlighted: emphasized,
    );
  }

  static const Color systemNavColor = bgBase;

  static Color _blend(Color base, Color tint, double amount) {
    return Color.lerp(base, tint, amount) ?? base;
  }
}
