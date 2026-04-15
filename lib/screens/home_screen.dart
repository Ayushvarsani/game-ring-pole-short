import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/game_cubit.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/shop_cubit.dart';
import '../bloc/shop_state.dart';
import '../models/bottle_model.dart';
import '../models/bottle_type.dart';
import '../models/fill_type.dart';
import '../models/game_colors.dart';
import '../services/level_progress_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_config.dart';
import '../widgets/bottle_widget.dart';
import '../widgets/game_ui.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/our_games_dialog.dart';
import 'game_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const String _homeLogoAsset = 'assets/images/logo.png';
  static const String _gameName = 'Mind Color Pour';

  late final AnimationController _wobbleController;
  late final AnimationController _ambientController;
  late final AnimationController _floatController;
  late final AnimationController _pulseController;

  final List<BottleModel> _heroBottles = const [
    BottleModel(
      id: 0,
      colors: [
        GameColors.cyan,
        GameColors.teal,
        GameColors.cyan,
        GameColors.cyan,
      ],
    ),
    BottleModel(
      id: 1,
      colors: [
        GameColors.pink,
        GameColors.purple,
        GameColors.pink,
        GameColors.pink,
      ],
    ),
    BottleModel(
      id: 2,
      colors: [
        GameColors.yellow,
        GameColors.orange,
        GameColors.yellow,
        GameColors.yellow,
      ],
    ),
    BottleModel(
      id: 3,
      colors: [
        GameColors.cyan,
        GameColors.purple,
        GameColors.blue,
        GameColors.purple,
      ],
    ),
    BottleModel(
      id: 4,
      colors: [
        GameColors.lime,
        GameColors.green,
        GameColors.lime,
        GameColors.green,
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    // Dedicated smooth float for bottles (slower, independent of wobble)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat();
    // Slow breathing pulse for the Play orb scale
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _ambientController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerHeavyHaptic();

    final level = await LevelProgressService.getNextLevelToPlay();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => GameCubit(initialLevel: level),
          child: const GameScreen(),
        ),
      ),
    );
  }

  Future<void> _openShop() async {
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerLightHaptic();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ShopScreen()));
  }

  void _openSettings() {
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerLightHaptic();
    showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Settings',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.56),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SettingsDialog(),
        ),
      ),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _openOurGames() {
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerLightHaptic();
    showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Our Games',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.56),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: OurGamesDialog(),
        ),
      ),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(theme.backgroundDark, theme.backgroundBase, 0.3)!,
              theme.backgroundBase,
              Color.lerp(theme.backgroundDeep, Colors.black, 0.26)!,
            ],
            stops: const [0.0, 0.44, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (context, child) {
                  return _HomeAtmosphere(
                    progress: _ambientController.value,
                    theme: theme,
                  );
                },
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final metrics = _HomeViewportMetrics.resolve(constraints);

                  return BlocBuilder<ShopCubit, ShopState>(
                    builder: (context, shop) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          metrics.outerPadding,
                          metrics.topInset,
                          metrics.outerPadding,
                          metrics.bottomInset,
                        ),
                        child: Column(
                          children: [
                            _HomeUtilityRow(
                              coins: shop.coins,
                              metrics: metrics,
                              onOpenShop: _openShop,
                              onOpenSettings: _openSettings,
                              onOpenOurGames: _openOurGames,
                            ),
                            SizedBox(height: metrics.brandGap),
                            AnimatedBuilder(
                              animation: _ambientController,
                              builder: (context, child) {
                                return _HomeBrandBlock(
                                  logoAsset: _homeLogoAsset,
                                  title: _gameName,
                                  metrics: metrics,
                                  ambientProgress: _ambientController.value,
                                );
                              },
                            ),
                            SizedBox(height: metrics.brandToHeroGap),
                            Expanded(
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: Listenable.merge([
                                    _ambientController,
                                    _wobbleController,
                                    _floatController,
                                    _pulseController,
                                  ]),
                                  builder: (context, child) {
                                    return _BottleHeroShowcase(
                                      bottles: _heroBottles,
                                      bottleType: shop.selectedType,
                                      fillType: shop.selectedFill,
                                      metrics: metrics,
                                      progress: _ambientController.value,
                                      wobblePhase:
                                          _wobbleController.value * 2 * pi,
                                      floatPhase:
                                          _floatController.value * 2 * pi,
                                      pulseValue: _pulseController.value,
                                      onPlay: _startGame,
                                      theme: theme,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeViewportMetrics {
  const _HomeViewportMetrics({
    required this.compact,
    required this.veryShort,
    required this.outerPadding,
    required this.topInset,
    required this.bottomInset,
    required this.utilityGap,
    required this.utilityIconSize,
    required this.utilityPadding,
    required this.brandGap,
    required this.logoHeight,
    required this.brandTitleGap,
    required this.titleFontSize,
    required this.titleLetterSpacing,
    required this.brandMaxWidth,
    required this.brandToHeroGap,
    required this.heroWidth,
    required this.heroHeight,
    required this.ringWidth,
    required this.ringHeight,
    required this.bottleWidth,
    required this.bottleHeight,
    required this.playOrbSize,
    required this.playOrbBottomInset,
  });

  final bool compact;
  final bool veryShort;
  final double outerPadding;
  final double topInset;
  final double bottomInset;
  final double utilityGap;
  final double utilityIconSize;
  final double utilityPadding;
  final double brandGap;
  final double logoHeight;
  final double brandTitleGap;
  final double titleFontSize;
  final double titleLetterSpacing;
  final double brandMaxWidth;
  final double brandToHeroGap;
  final double heroWidth;
  final double heroHeight;
  final double ringWidth;
  final double ringHeight;
  final double bottleWidth;
  final double bottleHeight;
  final double playOrbSize;
  final double playOrbBottomInset;

  static _HomeViewportMetrics resolve(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final compact = width < 390 || height < 780;
    final veryShort = height < 690;

    final heroWidth = (width * (width < 390 ? 0.9 : 0.82))
        .clamp(290.0, 400.0)
        .toDouble();
    final heroHeight = (height * (veryShort ? 0.42 : (compact ? 0.47 : 0.5)))
        .clamp(300.0, 420.0)
        .toDouble();
    final ringWidth = heroWidth * 0.72;

    return _HomeViewportMetrics(
      compact: compact,
      veryShort: veryShort,
      outerPadding: width < 360 ? 12 : 16,
      topInset: compact ? 8 : 12,
      bottomInset: veryShort ? 10 : 14,
      utilityGap: compact ? 10 : 12,
      utilityIconSize: compact ? 17 : 19,
      utilityPadding: compact ? 8 : 9,
      brandGap: compact ? 18 : 24,
      logoHeight: (height * (veryShort ? 0.25 : (compact ? 0.27 : 0.29)))
          .clamp(160.0, 250.0)
          .toDouble(),
      brandTitleGap: compact ? 10 : 14,
      titleFontSize: width < 360 ? 27 : (compact ? 30 : 34),
      titleLetterSpacing: compact ? 1.0 : 1.2,
      brandMaxWidth: (width * 0.86).clamp(280.0, 430.0).toDouble(),
      brandToHeroGap: veryShort ? 14 : (compact ? 18 : 24),
      heroWidth: heroWidth,
      heroHeight: heroHeight,
      ringWidth: ringWidth,
      ringHeight: ringWidth * 0.28,
      bottleWidth: (heroWidth * 0.11).clamp(38.0, 50.0).toDouble(),
      bottleHeight: (heroWidth * 0.315).clamp(120.0, 156.0).toDouble(),
      playOrbSize: (heroWidth * 0.215).clamp(76.0, 90.0).toDouble(),
      playOrbBottomInset: veryShort ? 0 : 6,
    );
  }
}

class _HomeUtilityRow extends StatelessWidget {
  const _HomeUtilityRow({
    required this.coins,
    required this.metrics,
    required this.onOpenShop,
    required this.onOpenSettings,
    required this.onOpenOurGames,
  });

  final int coins;
  final _HomeViewportMetrics metrics;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenOurGames;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Row(
      children: [
        GameIconButton(
          icon: Icons.videogame_asset_rounded,
          tint: theme.secondaryAccent,
          size: metrics.utilityIconSize,
          padding: EdgeInsets.all(metrics.utilityPadding),
          onTap: onOpenOurGames,
        ),
        SizedBox(width: metrics.utilityGap),
        GameIconButton(
          icon: Icons.storefront_rounded,
          tint: theme.warmAccent,
          size: metrics.utilityIconSize,
          padding: EdgeInsets.all(metrics.utilityPadding),
          onTap: onOpenShop,
        ),
        SizedBox(width: metrics.utilityGap),
        GameIconButton(
          icon: Icons.settings_rounded,
          tint: theme.primaryAccent,
          size: metrics.utilityIconSize,
          padding: EdgeInsets.all(metrics.utilityPadding),
          onTap: onOpenSettings,
        ),
        const Spacer(),
        _UtilityCoinChip(coins: coins, compact: metrics.compact),
      ],
    );
  }
}

class _HomeBrandBlock extends StatelessWidget {
  const _HomeBrandBlock({
    required this.logoAsset,
    required this.title,
    required this.metrics,
    required this.ambientProgress,
  });

  final String logoAsset;
  final String title;
  final _HomeViewportMetrics metrics;
  final double ambientProgress;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final logoGlow = theme.brandGlowColor;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: metrics.brandMaxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: metrics.logoHeight * 1.08,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated glowing color ring simulating liquid energy
                  IgnorePointer(
                    child: Transform.rotate(
                      angle: ambientProgress * 2 * pi,
                      child: Container(
                        width: metrics.logoHeight * 1.15,
                        height: metrics.logoHeight * 1.15,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Colors.transparent,
                              theme.primaryAccent.withValues(alpha: 0.1),
                              theme.secondaryAccent.withValues(alpha: 0.45),
                              theme.goldAccent.withValues(alpha: 0.55),
                              theme.primaryAccent.withValues(alpha: 0.45),
                              theme.secondaryAccent.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.2, 0.4, 0.5, 0.6, 0.8, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryAccent.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 40,
                              spreadRadius: -5,
                            ),
                            BoxShadow(
                              color: theme.secondaryAccent.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 60,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Floating droplets/bubbles around logo
                  IgnorePointer(
                    child: SizedBox(
                      width: metrics.logoHeight * 1.6,
                      height: metrics.logoHeight * 1.6,
                      child: CustomPaint(
                        painter: _LogoBubblePainter(
                          progress: ambientProgress,
                          colors: [
                            theme.primaryAccent,
                            theme.secondaryAccent,
                            theme.goldAccent,
                            Colors.cyanAccent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // The actual logo
                  Transform.translate(
                    offset: Offset(0, sin(ambientProgress * 4 * pi) * 5.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: theme.brandShadowColor.withValues(
                              alpha: 0.2,
                            ),
                            blurRadius: 28,
                            spreadRadius: -18,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: logoGlow.withValues(alpha: 0.26),
                            blurRadius: 42,
                            spreadRadius: -22,
                          ),
                          BoxShadow(
                            color: logoGlow.withValues(alpha: 0.14),
                            blurRadius: 64,
                            spreadRadius: -34,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        logoAsset,
                        height: metrics.logoHeight,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: metrics.brandTitleGap),
            _BrandNameText(
              title: title,
              fontSize: metrics.titleFontSize,
              letterSpacing: metrics.titleLetterSpacing,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandNameText extends StatelessWidget {
  const _BrandNameText({
    required this.title,
    required this.fontSize,
    required this.letterSpacing,
  });

  final String title;
  final double fontSize;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final brandGradient = theme.brandTextGradient;
    final baseStyle = TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: letterSpacing + 0.1,
      height: 1,
    );

    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: baseStyle.copyWith(
                color: theme.brandGlowColor.withValues(alpha: 0.16),
                shadows: [
                  Shadow(
                    color: theme.brandShadowColor.withValues(alpha: 0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                  Shadow(
                    color: theme.brandGlowColor.withValues(alpha: 0.22),
                    blurRadius: 18,
                  ),
                ],
              ),
            ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => brandGradient.createShader(bounds),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: baseStyle.copyWith(
                  shadows: [
                    Shadow(
                      color: theme.brandShadowColor.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                    Shadow(
                      color: theme.brandGlowColor.withValues(alpha: 0.16),
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UtilityCoinChip extends StatelessWidget {
  const _UtilityCoinChip({required this.coins, required this.compact});

  final int coins;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return GlassCard(
      tint: theme.goldAccent,
      radius: 999,
      blurSigma: 14,
      highlighted: true,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 8 : 9,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            theme.goldAccent.withValues(alpha: 0.18),
            theme.backgroundDeep.withValues(alpha: 0.18),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            spreadRadius: -12,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: theme.goldAccent.withValues(alpha: 0.14),
            blurRadius: 20,
            spreadRadius: -14,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on_rounded,
            size: compact ? 15 : 16,
            color: theme.goldAccent,
          ),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.96),
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottleHeroShowcase extends StatelessWidget {
  const _BottleHeroShowcase({
    required this.bottles,
    required this.bottleType,
    required this.fillType,
    required this.metrics,
    required this.progress,
    required this.wobblePhase,
    required this.floatPhase,
    required this.pulseValue,
    required this.onPlay,
    required this.theme,
  });

  static const List<_HeroBottleSpec> _specs = [
    _HeroBottleSpec(xFactor: -0.25, scale: 0.86, lift: 0, tilt: 0.018),
    _HeroBottleSpec(xFactor: -0.12, scale: 0.94, lift: 10, tilt: 0.014),
    _HeroBottleSpec(xFactor: 0, scale: 1.02, lift: 18, tilt: 0.012),
    _HeroBottleSpec(xFactor: 0.12, scale: 0.94, lift: 10, tilt: -0.014),
    _HeroBottleSpec(xFactor: 0.25, scale: 0.86, lift: 0, tilt: -0.018),
  ];

  final List<BottleModel> bottles;
  final BottleType bottleType;
  final FillType fillType;
  final _HomeViewportMetrics metrics;
  final double progress;
  final double wobblePhase;
  final double floatPhase;
  final double pulseValue;
  final VoidCallback onPlay;
  final AppThemeConfig theme;

  @override
  Widget build(BuildContext context) {
    final pulse = (sin(progress * 2 * pi) + 1) / 2;
    final ringBottom = metrics.playOrbSize * 0.46 + metrics.bottleHeight * 0.02;
    final bottleBaseBottom = ringBottom + (metrics.ringHeight * 0.18);
    final showcaseCount = min(bottles.length, _specs.length);

    return SizedBox(
      width: metrics.heroWidth,
      height: metrics.heroHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HeroGeometryPainter(progress: progress, theme: theme),
              ),
            ),
          ),
          // Stronger center radial glow — pulses more visibly
          Positioned(
            top: metrics.heroHeight * 0.12,
            left: metrics.heroWidth * 0.15,
            right: metrics.heroWidth * 0.15,
            child: IgnorePointer(
              child: _HeroGroundGlow(
                width: metrics.heroWidth * 0.7,
                height: metrics.heroHeight * 0.42,
                color: theme.boardHalo.withValues(alpha: 0.12 + (pulse * 0.06)),
              ),
            ),
          ),
          Positioned(
            bottom: ringBottom - (metrics.ringHeight * 0.2),
            child: IgnorePointer(
              child: _HeroGroundGlow(
                width: metrics.ringWidth * 0.94,
                height: metrics.heroHeight * 0.18,
                color: theme.boardAura.withValues(alpha: 0.14 + (pulse * 0.04)),
              ),
            ),
          ),
          Positioned(
            left: (metrics.heroWidth - metrics.ringWidth) / 2,
            bottom: ringBottom,
            child: _GlowingRing(
              width: metrics.ringWidth,
              height: metrics.ringHeight,
              progress: progress,
              theme: theme,
            ),
          ),
          ...List.generate(showcaseCount, (index) {
            final spec = _specs[index];
            final bottle = bottles[index];
            // Independent float per bottle using the dedicated float phase
            final bob =
                sin(floatPhase + (index * 1.1)) * (metrics.compact ? 3.5 : 5.0);
            final tilt = sin(wobblePhase + (index * 0.7)) * spec.tilt;
            final scaledWidth = metrics.bottleWidth * spec.scale;
            final scaledHeight = metrics.bottleHeight * spec.scale;
            final left =
                (metrics.heroWidth / 2) +
                (spec.xFactor * metrics.heroWidth) -
                (scaledWidth / 2);

            return Positioned(
              left: left,
              bottom: bottleBaseBottom + spec.lift + bob,
              child: Transform.rotate(
                angle: tilt,
                child: SizedBox(
                  width: scaledWidth,
                  height: scaledHeight,
                  child: BottleWidget(
                    bottle: bottle,
                    bottleType: bottleType,
                    fillType: fillType,
                    wobblePhase: wobblePhase,
                    size: Size(scaledWidth, scaledHeight),
                  ),
                ),
              ),
            );
          }),
          Positioned(
            bottom: metrics.playOrbBottomInset,
            child: _IntegratedPlayOrb(
              size: metrics.playOrbSize,
              progress: progress,
              pulseValue: pulseValue,
              onTap: onPlay,
              theme: theme,
            ),
          ),
          // ── Sparkle ring around platform ─────────────────────────
          Positioned(
            left: (metrics.heroWidth - metrics.ringWidth) / 2,
            bottom:
                metrics.playOrbSize * 0.46 +
                metrics.bottleHeight * 0.02 -
                (metrics.ringHeight * 0.02),
            child: IgnorePointer(
              child: SizedBox(
                width: metrics.ringWidth,
                height: metrics.ringHeight,
                child: CustomPaint(
                  painter: _SparkleRingPainter(
                    progress: progress,
                    theme: theme,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBottleSpec {
  const _HeroBottleSpec({
    required this.xFactor,
    required this.scale,
    required this.lift,
    required this.tilt,
  });

  final double xFactor;
  final double scale;
  final double lift;
  final double tilt;
}

class _HeroGroundGlow extends StatelessWidget {
  const _HeroGroundGlow({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class _GlowingRing extends StatelessWidget {
  const _GlowingRing({
    required this.width,
    required this.height,
    required this.progress,
    required this.theme,
  });

  final double width;
  final double height;
  final double progress;
  final AppThemeConfig theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _GlowingRingPainter(progress: progress, theme: theme),
      ),
    );
  }
}

class _GlowingRingPainter extends CustomPainter {
  const _GlowingRingPainter({required this.progress, required this.theme});

  final double progress;
  final AppThemeConfig theme;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = (sin(progress * 2 * pi) + 1) / 2;
    final rect = Rect.fromLTWH(
      size.width * 0.05,
      size.height * 0.18,
      size.width * 0.9,
      size.height * 0.62,
    );

    final haloPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.17
      ..color = theme.boardHalo.withValues(alpha: 0.08 + (pulse * 0.03))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(rect, haloPaint);

    final coreStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, size.height * 0.048)
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.54),
          theme.boardAura.withValues(alpha: 0.82),
          theme.boardHalo.withValues(alpha: 0.78),
          Colors.white.withValues(alpha: 0.48),
        ],
      ).createShader(rect);
    canvas.drawOval(rect, coreStroke);

    final innerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, size.height * 0.018)
      ..color = Colors.white.withValues(alpha: 0.18);
    canvas.drawOval(rect.deflate(size.height * 0.12), innerStroke);

    final topArc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.4, size.height * 0.03)
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          theme.boardHalo.withValues(alpha: 0.42),
          Colors.transparent,
        ],
      ).createShader(rect.inflate(size.height * 0.18));
    canvas.drawArc(
      rect.inflate(size.height * 0.12),
      -pi * 0.08,
      pi * 0.34,
      false,
      topArc,
    );

    final lowerArc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, size.height * 0.028)
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          theme.boardAura.withValues(alpha: 0.34),
          Colors.transparent,
        ],
      ).createShader(rect.inflate(size.height * 0.08));
    canvas.drawArc(
      rect.inflate(size.height * 0.06),
      pi * 0.74,
      pi * 0.18,
      false,
      lowerArc,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowingRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}

class _IntegratedPlayOrb extends StatelessWidget {
  const _IntegratedPlayOrb({
    required this.size,
    required this.progress,
    required this.pulseValue,
    required this.onTap,
    required this.theme,
  });

  final double size;
  final double progress;
  final double pulseValue;
  final VoidCallback onTap;
  final AppThemeConfig theme;

  @override
  Widget build(BuildContext context) {
    final pulse = (sin(progress * 2 * pi) + 1) / 2;
    final glowStrength = 0.09 + (pulse * 0.03);
    // Breathing scale: 1.0 → 1.035 → 1.0
    final breathScale = 1.0 + (pulseValue * 0.035);

    return GamePressable(
      onTap: onTap,
      pressedScale: 0.97,
      hoverScale: 1.015,
      child: Transform.scale(
        scale: breathScale,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              child: Container(
                width: size * 1.04,
                height: size * 1.04,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.boardHalo.withValues(alpha: glowStrength),
                      blurRadius: size * 0.21,
                      spreadRadius: -(size * 0.1),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: size * 0.16,
                      spreadRadius: -(size * 0.1),
                      offset: Offset(0, size * 0.12),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _PlayOrbFramePainter(progress: progress, theme: theme),
                child: GlassCard(
                  tint: theme.secondaryAccent,
                  radius: size / 2,
                  blurSigma: 16,
                  muted: true,
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size / 2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        theme.surface.withValues(alpha: 0.5),
                        theme.backgroundDeep.withValues(alpha: 0.72),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.boardAura.withValues(alpha: glowStrength),
                        blurRadius: size * 0.18,
                        spreadRadius: -(size * 0.16),
                        offset: Offset(0, size * 0.08),
                      ),
                    ],
                  ),
                  child: SizedBox.expand(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: size * 0.13),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white.withValues(alpha: 0.96),
                            size: size * 0.27,
                          ),
                          SizedBox(height: size * 0.008),
                          Text(
                            'Play',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.94),
                              fontSize: size * 0.155,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayOrbFramePainter extends CustomPainter {
  const _PlayOrbFramePainter({required this.progress, required this.theme});

  final double progress;
  final AppThemeConfig theme;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = (sin(progress * 2 * pi) + 1) / 2;
    final center = size.center(Offset.zero);
    final radius = size.width * 0.46;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.036
      ..color = theme.boardAura.withValues(alpha: 0.06 + (pulse * 0.02))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, radius, glowPaint);

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.011
      ..color = Colors.white.withValues(alpha: 0.14);
    canvas.drawCircle(center, radius - (size.width * 0.03), edgePaint);

    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.017
      ..shader = SweepGradient(
        startAngle: -pi * 0.5,
        endAngle: pi * 1.5,
        colors: [
          Colors.transparent,
          theme.boardHalo.withValues(alpha: 0.36),
          Colors.transparent,
          theme.boardAura.withValues(alpha: 0.32),
          Colors.transparent,
        ],
        stops: const [0.0, 0.18, 0.42, 0.72, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - (size.width * 0.02)),
      -pi * 0.28,
      pi * 0.92,
      false,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PlayOrbFramePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}

class _HomeAtmosphere extends StatelessWidget {
  const _HomeAtmosphere({required this.progress, required this.theme});

  final double progress;
  final AppThemeConfig theme;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            children: [
              Positioned(
                top: -height * 0.06,
                right: -width * 0.12,
                child: _AtmosphereBloom(
                  width: width * 0.62,
                  height: height * 0.3,
                  color: theme.ambientGlowSecondary.withValues(alpha: 0.08),
                ),
              ),
              Positioned(
                left: -width * 0.14,
                top: height * 0.26,
                child: _AtmosphereBloom(
                  width: width * 0.52,
                  height: height * 0.24,
                  color: theme.ambientGlow.withValues(alpha: 0.08),
                ),
              ),
              Positioned(
                left: width * 0.22,
                right: width * 0.22,
                bottom: -height * 0.08,
                child: _AtmosphereBloom(
                  width: width * 0.4,
                  height: height * 0.2,
                  color: theme.boardAura.withValues(alpha: 0.06),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _HomeBackdropPainter(
                    progress: progress,
                    theme: theme,
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _AmbientParticlePainter(
                    progress: progress,
                    theme: theme,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AtmosphereBloom extends StatelessWidget {
  const _AtmosphereBloom({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class _HeroGeometryPainter extends CustomPainter {
  const _HeroGeometryPainter({required this.progress, required this.theme});

  final double progress;
  final AppThemeConfig theme;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = (sin(progress * 2 * pi) + 1) / 2;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8)
      ..color = theme.surfaceStroke.withValues(alpha: 0.20);

    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = theme.boardHalo.withValues(alpha: 0.18 + (pulse * 0.04));

    final frame = Path()
      ..moveTo(size.width * 0.24, size.height * 0.14)
      ..lineTo(size.width * 0.5, size.height * 0.08)
      ..lineTo(size.width * 0.76, size.height * 0.14)
      ..lineTo(size.width * 0.84, size.height * 0.54)
      ..lineTo(size.width * 0.7, size.height * 0.86)
      ..lineTo(size.width * 0.3, size.height * 0.86)
      ..lineTo(size.width * 0.16, size.height * 0.54)
      ..close();
    canvas.drawPath(frame, linePaint);
    canvas.drawLine(
      Offset(size.width * 0.32, size.height * 0.22),
      Offset(size.width * 0.68, size.height * 0.22),
      accentPaint,
    );

    final orbitRect = Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.6),
      radius: size.width * 0.36,
    );
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          theme.boardAura.withValues(alpha: 0.20),
          Colors.transparent,
        ],
      ).createShader(orbitRect);
    canvas.drawArc(orbitRect, pi * 0.92, pi * 0.8, false, orbitPaint);
  }

  @override
  bool shouldRepaint(covariant _HeroGeometryPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}

class _HomeBackdropPainter extends CustomPainter {
  const _HomeBackdropPainter({required this.progress, required this.theme});

  final double progress;
  final AppThemeConfig theme;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * 2 * pi;
    final center = Offset(size.width * 0.5, size.height * 0.62);

    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8)
      ..color = theme.surfaceStroke.withValues(alpha: 0.18);

    final frame = Path()
      ..moveTo(size.width * 0.24, size.height * 0.08)
      ..lineTo(size.width * 0.5, size.height * 0.03)
      ..lineTo(size.width * 0.76, size.height * 0.08)
      ..lineTo(size.width * 0.88, size.height * 0.34)
      ..lineTo(size.width * 0.74, size.height * 0.9)
      ..lineTo(size.width * 0.26, size.height * 0.9)
      ..lineTo(size.width * 0.12, size.height * 0.34)
      ..close();
    canvas.drawPath(frame, framePaint);

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.03),
      Offset(size.width * 0.5, size.height * 0.28),
      framePaint,
    );

    final orbitRect = Rect.fromCircle(
      center: center,
      radius: size.width * 0.44,
    );
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          theme.boardAura.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(orbitRect);
    canvas.drawArc(
      orbitRect,
      pi * (0.84 + (sin(phase * 0.5) * 0.02)),
      pi * 0.92,
      false,
      orbitPaint,
    );

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              theme.boardAura.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.width * 0.28),
          );
    canvas.drawCircle(center, size.width * 0.28, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _HomeBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}

class _AmbientParticlePainter extends CustomPainter {
  const _AmbientParticlePainter({required this.progress, required this.theme});

  final double progress;
  final AppThemeConfig theme;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * 2 * pi;
    final colors = [
      theme.textPrimary.withValues(alpha: 0.08),
      theme.ambientGlow.withValues(alpha: 0.09),
      theme.ambientGlowSecondary.withValues(alpha: 0.09),
      theme.boardHalo.withValues(alpha: 0.07),
    ];

    for (int i = 0; i < 22; i++) {
      final dx =
          size.width * (0.06 + ((((i * 37) % 100) / 100) * 0.88)) +
          sin((phase * (0.52 + ((i % 5) * 0.06))) + i) * 8;
      final dy =
          size.height * (0.06 + ((((i * 23) % 100) / 100) * 0.80)) +
          cos((phase * (0.44 + ((i % 4) * 0.04))) + (i * 0.8)) * 8;
      // Vary sizes: tiny sparkles and slightly larger glows
      final radius = i % 5 == 0 ? 2.0 : (i % 3 == 0 ? 1.4 : 0.9);
      final paint = Paint()..color = colors[i % colors.length];
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientParticlePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}

class _SparkleRingPainter extends CustomPainter {
  const _SparkleRingPainter({required this.progress, required this.theme});

  final double progress;
  final AppThemeConfig theme;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * 2 * pi;
    final cx = size.width / 2;
    final cy = size.height * 0.5;
    final rx = size.width * 0.46;
    final ry = size.height * 0.31;

    // Draw 6 tiny sparkle dots that orbit around the ring ellipse
    const sparkleCount = 6;
    for (int i = 0; i < sparkleCount; i++) {
      final angle = (i / sparkleCount) * 2 * pi + phase * 0.6;
      final x = cx + rx * cos(angle);
      final y = cy + ry * sin(angle);
      // Brightness varies per dot
      final alpha = 0.08 + ((sin(angle + phase * 1.2) + 1) / 2) * 0.12;
      final colors = [theme.boardHalo, theme.boardAura, theme.ambientGlow];
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      final r = i % 2 == 0 ? 2.2 : 1.4;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.theme != oldDelegate.theme;
  }
}

class _LogoBubblePainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  _LogoBubblePainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(42);
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    for (int i = 0; i < 18; i++) {
      final color = colors[i % colors.length];

      final startX = rand.nextDouble() * size.width;
      final speed = rand.nextDouble() * 1.0 + 0.5; // Upward travel speed factor
      final phase = rand.nextDouble() * 2 * pi;
      final baseSize = rand.nextDouble() * 5.0 + 2.0;

      // Map progress to a continuous upward wrap
      // progress goes from 0..1 (12 sec). Multiply to make it travel faster
      final rawY = size.height - (progress * size.height * 2.5 * speed);
      // Because we modulo size.height, bubbles wrap bottom-to-top infinitely
      final y = (rawY % size.height + size.height) % size.height;

      // Sine wave drift left and right
      final x = startX + sin(progress * 2 * pi * speed + phase) * 12.0;

      // Soft glow opacity pulse
      final opacity = (sin(progress * 4 * pi + phase) + 1) / 2 * 0.35 + 0.15;

      paint.color = color.withValues(alpha: opacity);

      if (rand.nextBool()) {
        paint.maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          5.0,
        ); // Deeper focus
      } else {
        paint.maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          2.0,
        ); // Sharper
      }

      canvas.drawCircle(Offset(x, y), baseSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LogoBubblePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
