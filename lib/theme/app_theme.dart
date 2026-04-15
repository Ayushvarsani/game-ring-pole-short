import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme_config.dart';

/// Shared visual system for the game's premium puzzle presentation.
class AppTheme {
  AppTheme._();

  static const AppThemeConfig fallbackConfig = AppThemeCatalog.auroraFlux;

  static const Color bgBase = Color(0xFF06131B);
  static const Color bgDark = Color(0xFF10222C);
  static const Color bgMedium = Color(0xFF18293A);
  static const Color bgLight = Color(0xFF203548);
  static const Color bgCard = Color(0xFF2A4560);

  static const Color accentPrimary = Color(0xFF72F5E8);
  static const Color accentSecondary = Color(0xFF9B8FFF);
  static const Color accentWarm = Color(0xFFFF9271);
  static const Color accentGold = Color(0xFFF5D48F);
  static const Color accentSuccess = Color(0xFF8BE6B4);
  static const Color accentDanger = Color(0xFFFF7197);

  static const Color textPrimary = Color(0xFFF6FAFF);
  static const Color textSecondary = Color(0xFFC6D4E6);
  static const Color textMuted = Color(0xFF8EA0B5);

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
    colors: [Color(0xFF11222B), Color(0xFF14313A), Color(0xFF231645)],
    stops: [0.0, 0.48, 1.0],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF93FFF0), Color(0xFF74E7EB), Color(0xFF8F8BFF)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient dialogGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22364C), Color(0xFF182637), Color(0xFF12152A)],
    stops: [0.0, 0.46, 1.0],
  );

  static const LinearGradient overlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x73050E15), Color(0x260A1320), Color(0x9D060913)],
    stops: [0.0, 0.35, 1.0],
  );

  static ThemeData materialTheme([AppThemeConfig? theme]) {
    final active = theme ?? fallbackConfig;
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: active.backgroundBase,
      fontFamily: 'Roboto',
      extensions: <ThemeExtension<dynamic>>[active],
      colorScheme: ColorScheme.dark(
        primary: active.primaryAccent,
        secondary: active.secondaryAccent,
        surface: active.surface,
        error: active.dangerAccent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      splashColor: active.secondaryAccent.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: active.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.04,
          letterSpacing: -0.45,
        ),
        headlineMedium: TextStyle(
          color: active.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          color: active.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        titleMedium: TextStyle(
          color: active.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.24,
        ),
        bodyLarge: TextStyle(
          color: active.textSecondary,
          fontSize: 17,
          fontWeight: FontWeight.w500,
          height: 1.45,
          letterSpacing: 0.14,
        ),
        bodyMedium: TextStyle(
          color: active.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
          letterSpacing: 0.18,
        ),
        labelLarge: TextStyle(
          color: active.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static SystemUiOverlayStyle overlayStyle([AppThemeConfig? theme]) {
    final active = theme ?? fallbackConfig;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: active.backgroundBase,
      systemNavigationBarIconBrightness: Brightness.light,
    );
  }

  static AppThemeConfig of(BuildContext context) {
    return Theme.of(context).extension<AppThemeConfig>() ?? fallbackConfig;
  }

  static LinearGradient accentGradient(
    Color accent, {
    double intensity = 1.0,
    AppThemeConfig? theme,
  }) {
    final active = theme ?? fallbackConfig;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(accent, Colors.white, 0.22 * intensity)!,
        accent,
        Color.lerp(accent, active.backgroundDeep, 0.38)!,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  static List<BoxShadow> premiumShadows(
    Color tint, {
    bool emphasized = false,
    bool muted = false,
    AppThemeConfig? theme,
  }) {
    final active = theme ?? fallbackConfig;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: muted ? 0.18 : 0.32),
        blurRadius: emphasized ? 34 : 24,
        spreadRadius: emphasized ? -12 : -10,
        offset: const Offset(0, 16),
      ),
      BoxShadow(
        color: active.backgroundDeep.withValues(alpha: muted ? 0.0 : 0.18),
        blurRadius: emphasized ? 24 : 18,
        spreadRadius: -10,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: tint.withValues(alpha: emphasized ? 0.24 : 0.1),
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
    AppThemeConfig? theme,
  }) {
    final active = theme ?? fallbackConfig;
    final accent = tint ?? active.primaryAccent;
    final surface = muted ? active.surfaceMuted : active.surface;
    final blend = highlighted ? 0.22 : 0.12;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _blend(surface, Colors.white, 0.18),
          _blend(surface, accent, blend),
          _blend(surface, active.backgroundDeep, 0.16),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color:
            borderColor ??
            active.surfaceStroke.withValues(alpha: highlighted ? 0.36 : 0.14),
        width: highlighted ? 1.2 : 1.0,
      ),
      boxShadow: premiumShadows(
        accent,
        emphasized: highlighted,
        muted: muted,
        theme: active,
      ),
    );
  }

  static BoxDecoration surfaceDecoration({
    Color? tint,
    Color? borderColor,
    double radius = radiusMedium,
    bool highlighted = false,
    bool muted = false,
    AppThemeConfig? theme,
  }) {
    return glassDecoration(
      tint: tint,
      borderColor: borderColor,
      radius: radius,
      highlighted: highlighted,
      muted: muted,
      theme: theme,
    );
  }

  static BoxDecoration dialogDecoration({
    Color? borderColor,
    Color? tint,
    AppThemeConfig? theme,
  }) {
    final active = theme ?? fallbackConfig;
    final accent = borderColor ?? tint ?? active.primaryAccent;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _blend(active.surfaceStrong, Colors.white, 0.12),
          _blend(active.surface, accent, 0.12),
          _blend(active.surfaceMuted, active.secondaryAccent, 0.08),
          _blend(active.backgroundDeep, Colors.black, 0.08),
        ],
        stops: const [0.0, 0.34, 0.68, 1.0],
      ),
      borderRadius: BorderRadius.circular(radiusLarge),
      border: Border.all(color: accent.withValues(alpha: 0.24), width: 1.1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.42),
          blurRadius: 42,
          spreadRadius: -14,
          offset: const Offset(0, 24),
        ),
        BoxShadow(
          color: accent.withValues(alpha: 0.18),
          blurRadius: 34,
          spreadRadius: -10,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: active.secondaryAccent.withValues(alpha: 0.08),
          blurRadius: 30,
          spreadRadius: -18,
          offset: const Offset(-10, -8),
        ),
      ],
    );
  }

  static BoxDecoration cardDecoration({
    bool isSelected = false,
    bool isLocked = false,
    Color? glowColor,
    AppThemeConfig? theme,
  }) {
    final active = theme ?? fallbackConfig;
    final tint = isSelected
        ? (glowColor ?? active.secondaryAccent)
        : isLocked
        ? active.textMuted
        : active.primaryAccent;
    return surfaceDecoration(
      tint: tint,
      radius: 22,
      muted: !isSelected,
      highlighted: isSelected,
      borderColor: isLocked ? Colors.white.withValues(alpha: 0.08) : null,
      theme: active,
    );
  }

  static BoxDecoration actionButtonDecoration({
    bool isEnabled = true,
    bool isActive = false,
    Color? accentColor,
    AppThemeConfig? theme,
  }) {
    final active = theme ?? fallbackConfig;
    final tint =
        accentColor ??
        (isActive ? active.secondaryAccent : active.primaryAccent);
    return surfaceDecoration(
      tint: tint,
      radius: 24,
      muted: !isEnabled,
      highlighted: isEnabled && isActive,
      borderColor: Colors.white.withValues(alpha: isEnabled ? 0.12 : 0.06),
      theme: active,
    );
  }

  static BoxDecoration gradientButtonDecoration({
    required Color accentColor,
    bool isEnabled = true,
    bool emphasized = false,
    double radius = 24,
    AppThemeConfig? theme,
  }) {
    final active = theme ?? fallbackConfig;
    final alpha = isEnabled ? 1.0 : 0.42;
    return BoxDecoration(
      gradient: accentGradient(
        accentColor,
        intensity: emphasized ? 1.0 : 0.82,
        theme: active,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16 * alpha)),
      boxShadow: premiumShadows(
        accentColor.withValues(alpha: alpha),
        emphasized: emphasized || isEnabled,
        muted: !isEnabled,
        theme: active,
      ),
    );
  }

  static BoxDecoration primaryButtonDecoration({
    double glowStrength = 0.3,
    AppThemeConfig? theme,
  }) {
    final active = theme ?? fallbackConfig;
    return BoxDecoration(
      gradient: active.primaryButtonGradient,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      boxShadow: [
        BoxShadow(
          color: active.primaryAccent.withValues(alpha: glowStrength),
          blurRadius: 28,
          spreadRadius: -8,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: active.secondaryAccent.withValues(alpha: glowStrength * 0.72),
          blurRadius: 24,
          spreadRadius: -10,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration chipDecoration({
    Color? tint,
    bool emphasized = false,
    AppThemeConfig? theme,
  }) {
    final active = theme ?? fallbackConfig;
    return surfaceDecoration(
      tint: tint ?? active.primaryAccent,
      radius: 999,
      muted: !emphasized,
      highlighted: emphasized,
      theme: active,
    );
  }

  static const Color systemNavColor = bgBase;

  static Color _blend(Color base, Color tint, double amount) {
    return Color.lerp(base, tint, amount) ?? base;
  }
}
