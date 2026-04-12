import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/game_cubit.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/shop_cubit.dart';
import '../bloc/shop_state.dart';
import '../models/bottle_model.dart';
import '../models/game_colors.dart';
import '../services/level_progress_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_config.dart';
import '../widgets/bottle_widget.dart';
import '../widgets/game_ui.dart';
import '../widgets/settings_dialog.dart';
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

  final List<BottleModel> _demoBottles = const [
    BottleModel(
      id: 0,
      colors: [
        GameColors.red,
        GameColors.blue,
        GameColors.red,
        GameColors.green,
      ],
    ),
    BottleModel(
      id: 1,
      colors: [
        GameColors.blue,
        GameColors.green,
        GameColors.yellow,
        GameColors.red,
      ],
    ),
    BottleModel(
      id: 2,
      colors: [
        GameColors.green,
        GameColors.yellow,
        GameColors.blue,
        GameColors.yellow,
      ],
    ),
    BottleModel(
      id: 3,
      colors: [
        GameColors.yellow,
        GameColors.red,
        GameColors.green,
        GameColors.blue,
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
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _ambientController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: theme.backgroundGradient),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (context, child) {
                  return _HomeAmbientBackground(
                    progress: _ambientController.value,
                    theme: theme,
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: AppTheme.screenPadding,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final metrics = _HomeViewportMetrics.resolve(constraints);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopBar(context),
                        SizedBox(height: metrics.topSpacing),
                        // The home screen now reads as one composed hero: a
                        // framed brand block, a showcased bottle stage, then a
                        // tight CTA cluster. That keeps the layout simple while
                        // giving each section a stronger sense of purpose.
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: Column(
                                children: [
                                  _buildHeroCopy(context, metrics),
                                  SizedBox(height: metrics.brandToStageSpacing),
                                  Expanded(
                                    child: Center(
                                      child: _buildBottleStage(metrics),
                                    ),
                                  ),
                                  SizedBox(
                                    height: metrics.stageToButtonSpacing,
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: _buildPlayButton(context, metrics),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = AppTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final iconSize = compact ? 18.0 : 19.0;
        final actionSpacing = compact ? 8.0 : 10.0;
        final actionPadding = compact ? 8.0 : 9.0;

        return Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BlocBuilder<ShopCubit, ShopState>(
                builder: (context, shop) {
                  return _HomeCoinChip(coins: shop.coins, compact: compact);
                },
              ),
              SizedBox(width: actionSpacing),
              _HeaderActionButton(
                icon: Icons.storefront_rounded,
                tint: theme.warmAccent,
                size: iconSize,
                padding: actionPadding,
                onTap: _openShop,
              ),
              SizedBox(width: actionSpacing),
              _HeaderActionButton(
                icon: Icons.tune_rounded,
                tint: theme.primaryAccent,
                size: iconSize,
                padding: actionPadding,
                onTap: _openSettings,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroCopy(BuildContext context, _HomeViewportMetrics metrics) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final logoHeight = (screenHeight * (metrics.isVeryShort ? 0.20 : 0.22))
        .clamp(146.0, 208.0)
        .toDouble();

    return _HeroBrandPanel(
      logoAsset: _homeLogoAsset,
      title: _gameName,
      logoHeight: logoHeight,
      titleFontSize: metrics.gameTitleFontSize,
      titleLetterSpacing: metrics.gameTitleLetterSpacing,
      titleSpacing: metrics.heroSpacing,
      compact: metrics.isVeryShort,
    );
  }

  Widget _buildBottleStage(_HomeViewportMetrics metrics) {
    return BlocBuilder<ShopCubit, ShopState>(
      builder: (context, shop) {
        final theme = AppTheme.of(context);
        return AnimatedBuilder(
          animation: Listenable.merge([_wobbleController, _ambientController]),
          builder: (context, child) {
            final wobblePhase = _wobbleController.value * 2 * pi;
            final ambientPhase = _ambientController.value * 2 * pi;

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: metrics.stageWidth,
                maxHeight: metrics.stageHeight,
              ),
              child: AspectRatio(
                aspectRatio: 332 / 286,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _BottleShowcaseBase(
                          progress: _ambientController.value,
                          theme: theme,
                          compact: metrics.isVeryShort,
                        ),
                      ),
                    ),
                    ...List.generate(_demoBottles.length, (index) {
                      final baseX = [-108.0, -34.0, 34.0, 108.0][index];
                      final baseY = [18.0, 0.0, 0.0, 18.0][index];
                      final scale = [0.9, 1.0, 1.0, 0.9][index];
                      final bob = sin(ambientPhase + index * 0.65) * 6;
                      final tilt = sin(ambientPhase + index * 0.75) * 0.04;

                      return Transform.translate(
                        offset: Offset(
                          baseX * metrics.stagePositionScale,
                          (baseY + bob) * metrics.stagePositionScale,
                        ),
                        child: Transform.rotate(
                          angle: tilt,
                          child: Transform.scale(
                            scale: scale,
                            child: SizedBox(
                              width: metrics.bottlePreviewWidth,
                              height: metrics.bottlePreviewHeight,
                              child: BottleWidget(
                                bottle: _demoBottles[index],
                                wobblePhase: wobblePhase,
                                bottleType: shop.selectedType,
                                fillType: shop.selectedFill,
                                size: Size(
                                  metrics.bottlePreviewWidth,
                                  metrics.bottlePreviewHeight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayButton(BuildContext context, _HomeViewportMetrics metrics) {
    final theme = AppTheme.of(context);
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        final pulse = (sin(_ambientController.value * 2 * pi) + 1) / 2;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HomeSupportChip(
              label: 'Relaxing Puzzle',
              icon: Icons.spa_rounded,
              compact: metrics.isVeryShort,
            ),
            SizedBox(height: metrics.ctaSpacing),
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: metrics.playButtonWidth,
                maxWidth: metrics.playButtonWidth,
              ),
              child: _PremiumHomePlayButton(
                onTap: _startGame,
                height: metrics.playButtonHeight,
                iconSize: metrics.isVeryShort ? 19 : 21,
                pulse: pulse,
                theme: theme,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HomeViewportMetrics {
  const _HomeViewportMetrics({
    required this.isVeryShort,
    required this.topSpacing,
    required this.brandToStageSpacing,
    required this.stageToButtonSpacing,
    required this.ctaSpacing,
    required this.gameTitleFontSize,
    required this.gameTitleLetterSpacing,
    required this.heroSpacing,
    required this.stageWidth,
    required this.stageHeight,
    required this.stagePositionScale,
    required this.bottlePreviewWidth,
    required this.bottlePreviewHeight,
    required this.playButtonHeight,
    required this.playButtonWidth,
  });

  final bool isVeryShort;
  final double topSpacing;
  final double brandToStageSpacing;
  final double stageToButtonSpacing;
  final double ctaSpacing;
  final double gameTitleFontSize;
  final double gameTitleLetterSpacing;
  final double heroSpacing;
  final double stageWidth;
  final double stageHeight;
  final double stagePositionScale;
  final double bottlePreviewWidth;
  final double bottlePreviewHeight;
  final double playButtonHeight;
  final double playButtonWidth;

  static _HomeViewportMetrics resolve(BoxConstraints constraints) {
    final maxWidth = constraints.maxWidth;
    final maxHeight = constraints.maxHeight;
    final isShort = maxHeight < 760;
    final isVeryShort = maxHeight < 690;

    final stageWidth = (maxWidth * (maxWidth < 390 ? 0.84 : 0.76))
        .clamp(260.0, 332.0)
        .toDouble();
    final stageScale = stageWidth / 332.0;

    return _HomeViewportMetrics(
      isVeryShort: isVeryShort,
      topSpacing: isVeryShort ? 8 : (isShort ? 10 : 12),
      brandToStageSpacing: isVeryShort ? 8 : (isShort ? 10 : 12),
      stageToButtonSpacing: isVeryShort ? 8 : (isShort ? 10 : 12),
      ctaSpacing: isVeryShort ? 8 : 10,
      gameTitleFontSize: maxWidth < 360 ? 29 : (maxWidth < 430 ? 32 : 35),
      gameTitleLetterSpacing: isVeryShort ? 0.5 : 0.9,
      heroSpacing: isVeryShort ? 10 : (isShort ? 12 : 14),
      stageWidth: stageWidth,
      stageHeight: (maxHeight * (isVeryShort ? 0.29 : (isShort ? 0.33 : 0.36)))
          .clamp(198.0, 282.0)
          .toDouble(),
      stagePositionScale: stageScale,
      bottlePreviewWidth: (64 * stageScale).clamp(50.0, 64.0).toDouble(),
      bottlePreviewHeight: (170 * stageScale).clamp(132.0, 170.0).toDouble(),
      playButtonHeight: isVeryShort ? 50 : 56,
      playButtonWidth: (maxWidth * 0.36).clamp(150.0, 188.0).toDouble(),
    );
  }
}

class _HeroBrandPanel extends StatelessWidget {
  const _HeroBrandPanel({
    required this.logoAsset,
    required this.title,
    required this.logoHeight,
    required this.titleFontSize,
    required this.titleLetterSpacing,
    required this.titleSpacing,
    required this.compact,
  });

  final String logoAsset;
  final String title;
  final double logoHeight;
  final double titleFontSize;
  final double titleLetterSpacing;
  final double titleSpacing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final panelRadius = compact ? 28.0 : 34.0;

    return GlassCard(
      tint: theme.secondaryAccent,
      radius: panelRadius,
      blurSigma: 24,
      muted: true,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(panelRadius),
        border: Border.all(color: theme.surfaceStroke.withValues(alpha: 0.18)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            theme.surfaceStrong.withValues(alpha: 0.3),
            theme.backgroundDeep.withValues(alpha: 0.18),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.ambientGlowSecondary.withValues(alpha: 0.08),
            blurRadius: 42,
            spreadRadius: -24,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: -16,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 22,
            right: 22,
            top: 0,
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(panelRadius),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -24,
            top: 26,
            child: IgnorePointer(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.ambientGlow.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 22,
              compact ? 18 : 22,
              compact ? 18 : 22,
              compact ? 16 : 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: theme.ambientGlow.withValues(alpha: 0.28),
                        blurRadius: 54,
                        spreadRadius: -18,
                        offset: const Offset(0, 18),
                      ),
                      BoxShadow(
                        color: theme.ambientGlowSecondary.withValues(
                          alpha: 0.18,
                        ),
                        blurRadius: 44,
                        spreadRadius: -22,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 24,
                        spreadRadius: -12,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Transform.scale(
                    scale: compact ? 1.0 : 1.03,
                    child: Image.asset(
                      logoAsset,
                      height: logoHeight,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                SizedBox(height: titleSpacing),
                _PremiumGameTitle(
                  title: title,
                  fontSize: titleFontSize,
                  letterSpacing: titleLetterSpacing,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCoinChip extends StatelessWidget {
  const _HomeCoinChip({required this.coins, required this.compact});

  final int coins;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GlassCard(
      tint: theme.goldAccent,
      radius: 18,
      highlighted: true,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 9,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on_rounded,
            color: theme.goldAccent,
            size: compact ? 16 : 17,
          ),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tint,
    required this.size,
    required this.padding,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final double size;
  final double padding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return tint.withValues(alpha: 0.08);
          }
          return Colors.transparent;
        }),
        child: GlassCard(
          tint: tint,
          radius: 16,
          muted: true,
          padding: EdgeInsets.all(padding),
          child: Icon(icon, color: theme.textPrimary, size: size),
        ),
      ),
    );
  }
}

class _PremiumGameTitle extends StatelessWidget {
  const _PremiumGameTitle({
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
    final words = title.split(' ');
    final leading = words.isNotEmpty ? '${words.first} ' : title;
    final middle = words.length > 1 ? '${words[1]} ' : '';
    final trailing = words.length > 2 ? words.sublist(2).join(' ') : '';
    final baseStyle = TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      height: 1.0,
      fontWeight: FontWeight.w900,
      letterSpacing: letterSpacing,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: leading,
                  style: baseStyle.copyWith(
                    color: Colors.black.withValues(alpha: 0.24),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: middle,
                  style: baseStyle.copyWith(
                    color: Colors.black.withValues(alpha: 0.26),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: trailing,
                  style: baseStyle.copyWith(
                    color: Colors.black.withValues(alpha: 0.22),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Transform.translate(
            offset: const Offset(0, 1),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) =>
                  theme.brandingGradient.createShader(bounds),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: leading,
                      style: baseStyle.copyWith(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: middle,
                      style: baseStyle.copyWith(fontWeight: FontWeight.w900),
                    ),
                    TextSpan(
                      text: trailing,
                      style: baseStyle.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IgnorePointer(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: leading,
                    style: baseStyle.copyWith(
                      color: theme.textPrimary.withValues(alpha: 0.18),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: middle,
                    style: baseStyle.copyWith(
                      color: theme.textPrimary.withValues(alpha: 0.12),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: trailing,
                    style: baseStyle.copyWith(
                      color: theme.textPrimary.withValues(alpha: 0.1),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSupportChip extends StatelessWidget {
  const _HomeSupportChip({
    required this.label,
    required this.icon,
    required this.compact,
  });

  final String label;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GlassCard(
      tint: theme.secondaryAccent,
      radius: 999,
      blurSigma: 18,
      muted: true,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.surfaceStroke.withValues(alpha: 0.16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            theme.surface.withValues(alpha: 0.4),
            theme.backgroundDeep.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 13 : 14,
            color: theme.secondaryAccent.withValues(alpha: 0.88),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.textPrimary.withValues(alpha: 0.88),
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.28,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumHomePlayButton extends StatelessWidget {
  const _PremiumHomePlayButton({
    required this.onTap,
    required this.height,
    required this.iconSize,
    required this.pulse,
    required this.theme,
  });

  final VoidCallback onTap;
  final double height;
  final double iconSize;
  final double pulse;
  final AppThemeConfig theme;

  @override
  Widget build(BuildContext context) {
    final glowStrength = 0.16 + (pulse * 0.08);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 12,
          right: 12,
          bottom: -12,
          child: IgnorePointer(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    theme.primaryAccent.withValues(alpha: glowStrength),
                    theme.secondaryAccent.withValues(alpha: glowStrength * 0.7),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.56, 1.0],
                ),
              ),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.white.withValues(alpha: 0.06);
              }
              return Colors.transparent;
            }),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: theme.primaryButtonGradient,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 26,
                    spreadRadius: -14,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: theme.primaryAccent.withValues(alpha: glowStrength),
                    blurRadius: 28,
                    spreadRadius: -10,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: theme.secondaryAccent.withValues(
                      alpha: glowStrength * 0.74,
                    ),
                    blurRadius: 24,
                    spreadRadius: -12,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 2,
                    right: 2,
                    top: 2,
                    child: Container(
                      height: height * 0.38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.22),
                            Colors.white.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 8,
                    child: Container(
                      height: 1.2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.24),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: iconSize,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Play',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: height < 54 ? 17 : 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.44,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeAmbientBackground extends StatelessWidget {
  const _HomeAmbientBackground({required this.progress, required this.theme});

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
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: theme.overlayGradient),
                ),
              ),
              Positioned(
                top: -height * 0.04,
                right: -width * 0.12,
                child: _AmbientGlowBlob(
                  width: width * 0.62,
                  height: height * 0.34,
                  color: theme.ambientGlowSecondary.withValues(alpha: 0.12),
                ),
              ),
              Positioned(
                left: -width * 0.16,
                top: height * 0.26,
                child: _AmbientGlowBlob(
                  width: width * 0.58,
                  height: height * 0.3,
                  color: theme.ambientGlow.withValues(alpha: 0.1),
                ),
              ),
              Positioned(
                right: -width * 0.04,
                bottom: height * 0.08,
                child: _AmbientGlowBlob(
                  width: width * 0.42,
                  height: height * 0.26,
                  color: theme.ambientGlowWarm.withValues(alpha: 0.08),
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

class _AmbientGlowBlob extends StatelessWidget {
  const _AmbientGlowBlob({
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

class _BottleShowcaseBase extends StatelessWidget {
  const _BottleShowcaseBase({
    required this.progress,
    required this.theme,
    required this.compact,
  });

  final double progress;
  final AppThemeConfig theme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final pulse = (sin(progress * 2 * pi) + 1) / 2;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: const Alignment(0, -0.08),
              child: Container(
                width: width * 0.92,
                height: height * 0.86,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      theme.boardAura.withValues(alpha: 0.18 + (pulse * 0.04)),
                      theme.boardHalo.withValues(alpha: 0.09),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.46, 1.0],
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.16),
              child: Container(
                width: width * 0.74,
                height: height * 0.46,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.82),
              child: SizedBox(
                width: width * 0.82,
                height: compact ? 74 : 82,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 0,
                      child: Container(
                        height: compact ? 24 : 28,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              theme.boardAura.withValues(
                                alpha: 0.18 + (pulse * 0.05),
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: compact ? 10 : 12,
                      child: Container(
                        width: width * 0.58,
                        height: compact ? 30 : 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.surfaceStrong.withValues(alpha: 0.74),
                              theme.surface.withValues(alpha: 0.92),
                              theme.backgroundDeep.withValues(alpha: 0.84),
                            ],
                          ),
                          border: Border.all(
                            color: theme.surfaceStroke.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 18,
                              spreadRadius: -10,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: theme.boardAura.withValues(alpha: 0.12),
                              blurRadius: 24,
                              spreadRadius: -14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 10,
                              right: 10,
                              top: 4,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.18),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              child: Container(
                                width: width * 0.26,
                                height: 2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      theme.secondaryAccent.withValues(
                                        alpha: 0.34,
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: compact ? 34 : 38,
                      child: Container(
                        width: width * 0.46,
                        height: compact ? 12 : 14,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HomeBackdropPainter extends CustomPainter {
  const _HomeBackdropPainter({required this.progress, required this.theme});

  final double progress;
  final AppThemeConfig theme;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * 2 * pi;
    final orbCenters = [
      Offset(size.width * 0.82 + sin(phase) * 12, size.height * 0.16),
      Offset(size.width * 0.14 + cos(phase * 0.7) * 14, size.height * 0.72),
      Offset(size.width * 0.52 + sin(phase * 0.9) * 16, size.height * 0.42),
    ];
    final orbColors = [
      theme.ambientGlow.withValues(alpha: 0.14),
      theme.ambientGlowSecondary.withValues(alpha: 0.1),
      theme.ambientGlowWarm.withValues(alpha: 0.08),
    ];
    final orbRadii = [160.0, 180.0, 120.0];

    for (int i = 0; i < orbCenters.length; i++) {
      final paint = Paint()
        ..shader =
            RadialGradient(
              colors: [orbColors[i], Colors.transparent],
              stops: const [0.0, 1.0],
            ).createShader(
              Rect.fromCircle(center: orbCenters[i], radius: orbRadii[i]),
            );
      canvas.drawCircle(orbCenters[i], orbRadii[i], paint);
    }

    final beamPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: 0.07), Colors.transparent],
          ).createShader(
            Rect.fromLTWH(
              size.width * 0.24,
              0,
              size.width * 0.52,
              size.height * 0.44,
            ),
          );
    final beamPath = Path()
      ..moveTo(size.width * 0.38, 0)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.26,
        size.width * 0.28,
        size.height * 0.5,
      )
      ..lineTo(size.width * 0.72, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.26,
        size.width * 0.62,
        0,
      )
      ..close();
    canvas.drawPath(beamPath, beamPaint);
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
      theme.ambientGlow.withValues(alpha: 0.1),
      theme.ambientGlowSecondary.withValues(alpha: 0.09),
      theme.goldAccent.withValues(alpha: 0.07),
    ];

    for (int i = 0; i < 18; i++) {
      final dx =
          size.width * (0.08 + (((i * 37) % 100) / 100) * 0.84) +
          sin(phase * (0.65 + (i % 5) * 0.08) + i) * 10;
      final dy =
          size.height * (0.1 + (((i * 23) % 100) / 100) * 0.74) +
          cos(phase * (0.54 + (i % 4) * 0.06) + i * 0.8) * 8;
      final radius = i % 4 == 0 ? 2.1 : 1.25;
      final paint = Paint()..color = colors[i % colors.length];
      canvas.drawCircle(Offset(dx, dy), radius, paint);

      if (i % 6 == 0) {
        final streakPaint = Paint()
          ..color = colors[(i + 1) % colors.length].withValues(alpha: 0.05)
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(dx - 4, dy + 6),
          Offset(dx + 4, dy - 6),
          streakPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientParticlePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.theme != theme;
  }
}
