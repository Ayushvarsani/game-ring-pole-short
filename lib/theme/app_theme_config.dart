import 'dart:ui';

import 'package:flutter/material.dart';

/// Centralized visual tokens for a premium puzzle-game theme.
class AppThemeConfig extends ThemeExtension<AppThemeConfig> {
  const AppThemeConfig({
    required this.name,
    required this.backgroundBase,
    required this.backgroundDark,
    required this.backgroundDeep,
    required this.backgroundGradient,
    required this.overlayGradient,
    required this.dialogGradient,
    required this.primaryButtonGradient,
    required this.brandingGradient,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceStrong,
    required this.surfaceStroke,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.warmAccent,
    required this.goldAccent,
    required this.successAccent,
    required this.dangerAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.ambientGlow,
    required this.ambientGlowSecondary,
    required this.ambientGlowWarm,
    required this.boardAura,
    required this.boardHalo,
  });

  final String name;
  final Color backgroundBase;
  final Color backgroundDark;
  final Color backgroundDeep;
  final LinearGradient backgroundGradient;
  final LinearGradient overlayGradient;
  final LinearGradient dialogGradient;
  final LinearGradient primaryButtonGradient;
  final LinearGradient brandingGradient;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceStrong;
  final Color surfaceStroke;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color warmAccent;
  final Color goldAccent;
  final Color successAccent;
  final Color dangerAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color ambientGlow;
  final Color ambientGlowSecondary;
  final Color ambientGlowWarm;
  final Color boardAura;
  final Color boardHalo;

  @override
  AppThemeConfig copyWith({
    String? name,
    Color? backgroundBase,
    Color? backgroundDark,
    Color? backgroundDeep,
    LinearGradient? backgroundGradient,
    LinearGradient? overlayGradient,
    LinearGradient? dialogGradient,
    LinearGradient? primaryButtonGradient,
    LinearGradient? brandingGradient,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceStrong,
    Color? surfaceStroke,
    Color? primaryAccent,
    Color? secondaryAccent,
    Color? warmAccent,
    Color? goldAccent,
    Color? successAccent,
    Color? dangerAccent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? ambientGlow,
    Color? ambientGlowSecondary,
    Color? ambientGlowWarm,
    Color? boardAura,
    Color? boardHalo,
  }) {
    return AppThemeConfig(
      name: name ?? this.name,
      backgroundBase: backgroundBase ?? this.backgroundBase,
      backgroundDark: backgroundDark ?? this.backgroundDark,
      backgroundDeep: backgroundDeep ?? this.backgroundDeep,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      overlayGradient: overlayGradient ?? this.overlayGradient,
      dialogGradient: dialogGradient ?? this.dialogGradient,
      primaryButtonGradient:
          primaryButtonGradient ?? this.primaryButtonGradient,
      brandingGradient: brandingGradient ?? this.brandingGradient,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceStrong: surfaceStrong ?? this.surfaceStrong,
      surfaceStroke: surfaceStroke ?? this.surfaceStroke,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      warmAccent: warmAccent ?? this.warmAccent,
      goldAccent: goldAccent ?? this.goldAccent,
      successAccent: successAccent ?? this.successAccent,
      dangerAccent: dangerAccent ?? this.dangerAccent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      ambientGlow: ambientGlow ?? this.ambientGlow,
      ambientGlowSecondary: ambientGlowSecondary ?? this.ambientGlowSecondary,
      ambientGlowWarm: ambientGlowWarm ?? this.ambientGlowWarm,
      boardAura: boardAura ?? this.boardAura,
      boardHalo: boardHalo ?? this.boardHalo,
    );
  }

  @override
  AppThemeConfig lerp(ThemeExtension<AppThemeConfig>? other, double t) {
    if (other is! AppThemeConfig) return this;

    return AppThemeConfig(
      name: t < 0.5 ? name : other.name,
      backgroundBase: Color.lerp(backgroundBase, other.backgroundBase, t)!,
      backgroundDark: Color.lerp(backgroundDark, other.backgroundDark, t)!,
      backgroundDeep: Color.lerp(backgroundDeep, other.backgroundDeep, t)!,
      backgroundGradient: _lerpGradient(
        backgroundGradient,
        other.backgroundGradient,
        t,
      ),
      overlayGradient: _lerpGradient(overlayGradient, other.overlayGradient, t),
      dialogGradient: _lerpGradient(dialogGradient, other.dialogGradient, t),
      primaryButtonGradient: _lerpGradient(
        primaryButtonGradient,
        other.primaryButtonGradient,
        t,
      ),
      brandingGradient: _lerpGradient(
        brandingGradient,
        other.brandingGradient,
        t,
      ),
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceStrong: Color.lerp(surfaceStrong, other.surfaceStrong, t)!,
      surfaceStroke: Color.lerp(surfaceStroke, other.surfaceStroke, t)!,
      primaryAccent: Color.lerp(primaryAccent, other.primaryAccent, t)!,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      warmAccent: Color.lerp(warmAccent, other.warmAccent, t)!,
      goldAccent: Color.lerp(goldAccent, other.goldAccent, t)!,
      successAccent: Color.lerp(successAccent, other.successAccent, t)!,
      dangerAccent: Color.lerp(dangerAccent, other.dangerAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      ambientGlow: Color.lerp(ambientGlow, other.ambientGlow, t)!,
      ambientGlowSecondary: Color.lerp(
        ambientGlowSecondary,
        other.ambientGlowSecondary,
        t,
      )!,
      ambientGlowWarm: Color.lerp(ambientGlowWarm, other.ambientGlowWarm, t)!,
      boardAura: Color.lerp(boardAura, other.boardAura, t)!,
      boardHalo: Color.lerp(boardHalo, other.boardHalo, t)!,
    );
  }

  static LinearGradient _lerpGradient(
    LinearGradient a,
    LinearGradient b,
    double t,
  ) {
    return LinearGradient(
      begin: AlignmentGeometry.lerp(a.begin, b.begin, t)!,
      end: AlignmentGeometry.lerp(a.end, b.end, t)!,
      colors: List<Color>.generate(
        a.colors.length,
        (index) => Color.lerp(a.colors[index], b.colors[index], t)!,
      ),
      stops: a.stops == null || b.stops == null
          ? null
          : List<double>.generate(
              a.stops!.length,
              (index) => lerpDouble(a.stops![index], b.stops![index], t)!,
            ),
    );
  }
}

class AppThemeCatalog {
  AppThemeCatalog._();

  static const AppThemeConfig auroraFlux = AppThemeConfig(
    name: 'Aurora Flux',
    backgroundBase: Color(0xFF06131B),
    backgroundDark: Color(0xFF10222C),
    backgroundDeep: Color(0xFF231645),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF11222B), Color(0xFF14313A), Color(0xFF231645)],
      stops: [0.0, 0.48, 1.0],
    ),
    overlayGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x73050E15), Color(0x260A1320), Color(0x9D060913)],
      stops: [0.0, 0.35, 1.0],
    ),
    dialogGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF22364C), Color(0xFF182637), Color(0xFF12152A)],
      stops: [0.0, 0.46, 1.0],
    ),
    primaryButtonGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF93FFF0), Color(0xFF74E7EB), Color(0xFF8F8BFF)],
      stops: [0.0, 0.5, 1.0],
    ),
    brandingGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF4FDFF), Color(0xFF8AF8EE), Color(0xFF9B90FF)],
    ),
    surface: Color(0xFF203548),
    surfaceMuted: Color(0xFF18293A),
    surfaceStrong: Color(0xFF2A4560),
    surfaceStroke: Color(0xFF8AB9D7),
    primaryAccent: Color(0xFF72F5E8),
    secondaryAccent: Color(0xFF9B8FFF),
    warmAccent: Color(0xFFFF9271),
    goldAccent: Color(0xFFF5D48F),
    successAccent: Color(0xFF8BE6B4),
    dangerAccent: Color(0xFFFF7197),
    textPrimary: Color(0xFFF6FAFF),
    textSecondary: Color(0xFFC6D4E6),
    textMuted: Color(0xFF8EA0B5),
    ambientGlow: Color(0xFF62F9E9),
    ambientGlowSecondary: Color(0xFF9A8EFF),
    ambientGlowWarm: Color(0xFFFF9A7B),
    boardAura: Color(0xFF6BF2E5),
    boardHalo: Color(0xFF9793FF),
  );

  static const AppThemeConfig neonEmber = AppThemeConfig(
    name: 'Neon Ember',
    backgroundBase: Color(0xFF120B14),
    backgroundDark: Color(0xFF26131D),
    backgroundDeep: Color(0xFF132531),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1D0F18), Color(0xFF3A1420), Color(0xFF11232E)],
      stops: [0.0, 0.46, 1.0],
    ),
    overlayGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x730C050A), Color(0x240E1016), Color(0xA0070A10)],
      stops: [0.0, 0.34, 1.0],
    ),
    dialogGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3A232C), Color(0xFF221827), Color(0xFF141B26)],
      stops: [0.0, 0.48, 1.0],
    ),
    primaryButtonGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFA17A), Color(0xFFFF7A60), Color(0xFF66D4FF)],
      stops: [0.0, 0.5, 1.0],
    ),
    brandingGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF5F1), Color(0xFFFF9C7A), Color(0xFF6ED5FF)],
    ),
    surface: Color(0xFF31202D),
    surfaceMuted: Color(0xFF231825),
    surfaceStrong: Color(0xFF3E2A39),
    surfaceStroke: Color(0xFFDB9B87),
    primaryAccent: Color(0xFFFF7A5C),
    secondaryAccent: Color(0xFF66D4FF),
    warmAccent: Color(0xFFFFB368),
    goldAccent: Color(0xFFFFD27B),
    successAccent: Color(0xFF91E5AD),
    dangerAccent: Color(0xFFFF607D),
    textPrimary: Color(0xFFFFF8FA),
    textSecondary: Color(0xFFD7C6CF),
    textMuted: Color(0xFFA8949E),
    ambientGlow: Color(0xFFFF7E6B),
    ambientGlowSecondary: Color(0xFF61D2FF),
    ambientGlowWarm: Color(0xFFFFBF75),
    boardAura: Color(0xFFFF835F),
    boardHalo: Color(0xFF6AD5FF),
  );

  static const AppThemeConfig lunarBloom = AppThemeConfig(
    name: 'Lunar Bloom',
    backgroundBase: Color(0xFF0E121A),
    backgroundDark: Color(0xFF1A2430),
    backgroundDeep: Color(0xFF2A1A31),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF151D26), Color(0xFF202B39), Color(0xFF2A1A31)],
      stops: [0.0, 0.5, 1.0],
    ),
    overlayGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x6E080A10), Color(0x220D141A), Color(0x990B0B12)],
      stops: [0.0, 0.36, 1.0],
    ),
    dialogGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2C3645), Color(0xFF202737), Color(0xFF1A1728)],
      stops: [0.0, 0.44, 1.0],
    ),
    primaryButtonGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD0C0FF), Color(0xFFB6A2FF), Color(0xFF8FE5D1)],
      stops: [0.0, 0.54, 1.0],
    ),
    brandingGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFAFAFF), Color(0xFFC7B8FF), Color(0xFFA0F0DA)],
    ),
    surface: Color(0xFF293444),
    surfaceMuted: Color(0xFF1E2735),
    surfaceStrong: Color(0xFF334355),
    surfaceStroke: Color(0xFFB7A5D8),
    primaryAccent: Color(0xFFB9A4FF),
    secondaryAccent: Color(0xFF8FE7D0),
    warmAccent: Color(0xFFFFA8B5),
    goldAccent: Color(0xFFF4DE99),
    successAccent: Color(0xFF95E5BF),
    dangerAccent: Color(0xFFFF7DA2),
    textPrimary: Color(0xFFF6F8FF),
    textSecondary: Color(0xFFCED7E2),
    textMuted: Color(0xFF97A2B3),
    ambientGlow: Color(0xFFB9A3FF),
    ambientGlowSecondary: Color(0xFF8EE7CF),
    ambientGlowWarm: Color(0xFFFFAFBC),
    boardAura: Color(0xFFA9DDFF),
    boardHalo: Color(0xFFC0ABFF),
  );

  static const AppThemeConfig deepCurrent = AppThemeConfig(
    name: 'Deep Current',
    backgroundBase: Color(0xFF071318),
    backgroundDark: Color(0xFF0D252C),
    backgroundDeep: Color(0xFF10283A),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0C1C23), Color(0xFF0E2B33), Color(0xFF112939)],
      stops: [0.0, 0.5, 1.0],
    ),
    overlayGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x70040B0F), Color(0x1F09161D), Color(0x96060E15)],
      stops: [0.0, 0.35, 1.0],
    ),
    dialogGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1E3840), Color(0xFF162A34), Color(0xFF122030)],
      stops: [0.0, 0.44, 1.0],
    ),
    primaryButtonGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF86FFE8), Color(0xFF63E4D7), Color(0xFF4FB8FF)],
      stops: [0.0, 0.5, 1.0],
    ),
    brandingGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFEFFEFF), Color(0xFF79F0E2), Color(0xFF74C7FF)],
    ),
    surface: Color(0xFF1E3746),
    surfaceMuted: Color(0xFF162A36),
    surfaceStrong: Color(0xFF28475A),
    surfaceStroke: Color(0xFF77B7C8),
    primaryAccent: Color(0xFF66E6D8),
    secondaryAccent: Color(0xFF4FB8FF),
    warmAccent: Color(0xFFFFA27B),
    goldAccent: Color(0xFFEAD491),
    successAccent: Color(0xFF84E0B0),
    dangerAccent: Color(0xFFFF7B86),
    textPrimary: Color(0xFFF3FAFF),
    textSecondary: Color(0xFFC1D4DF),
    textMuted: Color(0xFF8FA5B4),
    ambientGlow: Color(0xFF65E8D8),
    ambientGlowSecondary: Color(0xFF56B8FF),
    ambientGlowWarm: Color(0xFFFFA77F),
    boardAura: Color(0xFF5EE7D9),
    boardHalo: Color(0xFF66BDFF),
  );

  static const AppThemeConfig velvetPrism = AppThemeConfig(
    name: 'Velvet Prism',
    backgroundBase: Color(0xFF140E1E),
    backgroundDark: Color(0xFF25162F),
    backgroundDeep: Color(0xFF171F35),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1B1126), Color(0xFF33193A), Color(0xFF182238)],
      stops: [0.0, 0.48, 1.0],
    ),
    overlayGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x72090611), Color(0x240B101A), Color(0x9A080810)],
      stops: [0.0, 0.34, 1.0],
    ),
    dialogGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF342341), Color(0xFF251D32), Color(0xFF1A1E31)],
      stops: [0.0, 0.46, 1.0],
    ),
    primaryButtonGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF1B5FF), Color(0xFFE58DFF), Color(0xFF78B8FF)],
      stops: [0.0, 0.5, 1.0],
    ),
    brandingGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF5FF), Color(0xFFE6A8FF), Color(0xFF8DC4FF)],
    ),
    surface: Color(0xFF33253F),
    surfaceMuted: Color(0xFF251D32),
    surfaceStrong: Color(0xFF433252),
    surfaceStroke: Color(0xFFD0A8E8),
    primaryAccent: Color(0xFFE58CFF),
    secondaryAccent: Color(0xFF78B8FF),
    warmAccent: Color(0xFFFF948D),
    goldAccent: Color(0xFFFFD28E),
    successAccent: Color(0xFF9DE3C6),
    dangerAccent: Color(0xFFFF729A),
    textPrimary: Color(0xFFFCF7FF),
    textSecondary: Color(0xFFD7CAE5),
    textMuted: Color(0xFFAA97BC),
    ambientGlow: Color(0xFFE38EFF),
    ambientGlowSecondary: Color(0xFF7BB8FF),
    ambientGlowWarm: Color(0xFFFF938E),
    boardAura: Color(0xFFCF8EFF),
    boardHalo: Color(0xFF85BCFF),
  );

  static const AppThemeConfig solarMist = AppThemeConfig(
    name: 'Solar Mist',
    backgroundBase: Color(0xFF15120F),
    backgroundDark: Color(0xFF2C2316),
    backgroundDeep: Color(0xFF12272C),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1E1813), Color(0xFF332919), Color(0xFF13292E)],
      stops: [0.0, 0.47, 1.0],
    ),
    overlayGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x70090604), Color(0x240E130D), Color(0x9808090C)],
      stops: [0.0, 0.35, 1.0],
    ),
    dialogGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3A2D1E), Color(0xFF2C2318), Color(0xFF182A2F)],
      stops: [0.0, 0.46, 1.0],
    ),
    primaryButtonGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFE09C), Color(0xFFFFD07A), Color(0xFF7EE4E8)],
      stops: [0.0, 0.52, 1.0],
    ),
    brandingGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFBF1), Color(0xFFFFD98B), Color(0xFFA2EEF1)],
    ),
    surface: Color(0xFF372C1F),
    surfaceMuted: Color(0xFF291F16),
    surfaceStrong: Color(0xFF44392A),
    surfaceStroke: Color(0xFFE0C69A),
    primaryAccent: Color(0xFFFFD27C),
    secondaryAccent: Color(0xFF7EE4E8),
    warmAccent: Color(0xFFFFA07E),
    goldAccent: Color(0xFFFFE39A),
    successAccent: Color(0xFFA5E2BC),
    dangerAccent: Color(0xFFFF7D71),
    textPrimary: Color(0xFFFFFBF4),
    textSecondary: Color(0xFFE1D3C0),
    textMuted: Color(0xFFB7A590),
    ambientGlow: Color(0xFFFFD27E),
    ambientGlowSecondary: Color(0xFF83E5E9),
    ambientGlowWarm: Color(0xFFFFA17E),
    boardAura: Color(0xFFFFD88E),
    boardHalo: Color(0xFF87E7E9),
  );
}
