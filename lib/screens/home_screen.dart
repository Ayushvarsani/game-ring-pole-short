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
  static const LinearGradient _brandingTitleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8F7FF), Color(0xFF7AD6FF), Color(0xFF4DA3FF)],
  );

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
    final themeGradient = context
        .watch<ShopCubit>()
        .state
        .selectedTheme
        .gradient;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: themeGradient),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppTheme.overlayGradient,
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _HomeBackdropPainter(
                      progress: _ambientController.value,
                    ),
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
                        SizedBox(height: metrics.sectionSpacing),
                        // The logo now sizes against screen height instead of a
                        // narrow hero flex slice, so the brand can lead the
                        // screen while the bottle preview simply fills the
                        // remaining Expanded space underneath.
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: Column(
                                children: [
                                  _buildHeroCopy(context, metrics),
                                  SizedBox(height: metrics.sectionSpacing),
                                  Expanded(
                                    child: Center(
                                      child: _buildBottleStage(metrics),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: metrics.sectionSpacing),
                        Align(
                          alignment: Alignment.center,
                          child: _buildPlayButton(context, metrics),
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
                tint: AppTheme.accentWarm,
                size: iconSize,
                padding: actionPadding,
                onTap: _openShop,
              ),
              SizedBox(width: actionSpacing),
              _HeaderActionButton(
                icon: Icons.tune_rounded,
                tint: AppTheme.accentPrimary,
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
        .clamp(150.0, 210.0)
        .toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentPrimary.withValues(alpha: 0.28),
                blurRadius: 56,
                spreadRadius: -16,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: AppTheme.accentSecondary.withValues(alpha: 0.16),
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
            scale: metrics.isVeryShort ? 1.0 : 1.04,
            child: Image.asset(
              _homeLogoAsset,
              height: logoHeight,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        SizedBox(height: metrics.heroSpacing),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                _gameName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.22),
                  fontSize: metrics.gameTitleFontSize,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: metrics.gameTitleLetterSpacing,
                  shadows: [
                    Shadow(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.26),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
              ),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => _brandingTitleGradient.createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
                child: Text(
                  _gameName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: metrics.gameTitleFontSize,
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: metrics.gameTitleLetterSpacing,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottleStage(_HomeViewportMetrics metrics) {
    return BlocBuilder<ShopCubit, ShopState>(
      builder: (context, shop) {
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
                      child: CustomPaint(
                        painter: _HeroStagePainter(
                          progress: _ambientController.value,
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
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: metrics.playButtonWidth,
        maxWidth: metrics.playButtonWidth,
      ),
      child: _HomePlayButton(
        onTap: _startGame,
        height: metrics.playButtonHeight,
        iconSize: metrics.isVeryShort ? 18 : 20,
      ),
    );
  }
}

class _HomeViewportMetrics {
  const _HomeViewportMetrics({
    required this.isVeryShort,
    required this.sectionSpacing,
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
  final double sectionSpacing;
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
    final stageHeight =
        (maxHeight * (isVeryShort ? 0.31 : (isShort ? 0.35 : 0.39)))
            .clamp(208.0, 296.0)
            .toDouble();
    final stageScale = stageWidth / 332.0;

    return _HomeViewportMetrics(
      isVeryShort: isVeryShort,
      sectionSpacing: isVeryShort ? 10 : (isShort ? 14 : 18),
      gameTitleFontSize: maxWidth < 360 ? 30 : (maxWidth < 430 ? 33 : 36),
      gameTitleLetterSpacing: isVeryShort ? 0.5 : 0.8,
      heroSpacing: isVeryShort ? 12 : (isShort ? 14 : 16),
      stageWidth: stageWidth,
      stageHeight: stageHeight,
      stagePositionScale: stageScale,
      bottlePreviewWidth: (64 * stageScale).clamp(50.0, 64.0).toDouble(),
      bottlePreviewHeight: (170 * stageScale).clamp(132.0, 170.0).toDouble(),
      playButtonHeight: isVeryShort ? 54 : 58,
      playButtonWidth: (maxWidth * 0.44).clamp(164.0, 208.0).toDouble(),
    );
  }
}

class _HomeCoinChip extends StatelessWidget {
  const _HomeCoinChip({required this.coins, required this.compact});

  final int coins;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: AppTheme.accentGold,
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
            color: AppTheme.accentGold,
            size: compact ? 16 : 17,
          ),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: TextStyle(
              color: AppTheme.textPrimary,
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
          child: Icon(icon, color: AppTheme.textPrimary, size: size),
        ),
      ),
    );
  }
}

class _HomePlayButton extends StatelessWidget {
  const _HomePlayButton({
    required this.onTap,
    required this.height,
    required this.iconSize,
  });

  final VoidCallback onTap;
  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
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
            gradient: AppTheme.buttonGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentPrimary.withValues(alpha: 0.22),
                blurRadius: 24,
                spreadRadius: -10,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: iconSize,
              ),
              const SizedBox(width: 8),
              const Text(
                'Play',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBackdropPainter extends CustomPainter {
  const _HomeBackdropPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * 2 * pi;
    final orbCenters = [
      Offset(size.width * 0.82 + sin(phase) * 12, size.height * 0.16),
      Offset(size.width * 0.14 + cos(phase * 0.7) * 14, size.height * 0.72),
      Offset(size.width * 0.52 + sin(phase * 0.9) * 16, size.height * 0.42),
    ];
    final orbColors = [
      AppTheme.accentPrimary.withValues(alpha: 0.14),
      AppTheme.accentSecondary.withValues(alpha: 0.1),
      AppTheme.accentWarm.withValues(alpha: 0.08),
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
            colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
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
    return oldDelegate.progress != progress;
  }
}

class _HeroStagePainter extends CustomPainter {
  const _HeroStagePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.58);
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accentSecondary.withValues(alpha: 0.2),
          AppTheme.accentPrimary.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.5));
    canvas.drawCircle(center, size.width * 0.54, haloPaint);

    final shelfRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.86),
      width: size.width * 0.76,
      height: 28,
    );
    final shelfPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.02),
        ],
      ).createShader(shelfRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shelfRect, const Radius.circular(18)),
      shelfPaint,
    );

    final glowRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.88),
      width: size.width * 0.6,
      height: 38,
    );
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accentPrimary.withValues(
            alpha: 0.12 + (sin(progress * 2 * pi) * 0.02),
          ),
          Colors.transparent,
        ],
      ).createShader(glowRect);
    canvas.drawOval(glowRect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _HeroStagePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
