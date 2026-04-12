import 'package:flutter/material.dart';

import '../theme/app_theme_config.dart';

enum ThemeType {
  auroraFlux(
    displayName: 'Aurora Flux',
    coinPrice: 0,
    config: AppThemeCatalog.auroraFlux,
  ),
  neonEmber(
    displayName: 'Neon Ember',
    coinPrice: 180,
    config: AppThemeCatalog.neonEmber,
  ),
  lunarBloom(
    displayName: 'Lunar Bloom',
    coinPrice: 220,
    config: AppThemeCatalog.lunarBloom,
  ),
  deepCurrent(
    displayName: 'Deep Current',
    coinPrice: 200,
    config: AppThemeCatalog.deepCurrent,
  ),
  velvetPrism(
    displayName: 'Velvet Prism',
    coinPrice: 260,
    config: AppThemeCatalog.velvetPrism,
  ),
  solarMist(
    displayName: 'Solar Mist',
    coinPrice: 240,
    config: AppThemeCatalog.solarMist,
  );

  final String displayName;
  final int coinPrice;
  final AppThemeConfig config;

  const ThemeType({
    required this.displayName,
    required this.coinPrice,
    required this.config,
  });

  LinearGradient get gradient => config.backgroundGradient;
}
