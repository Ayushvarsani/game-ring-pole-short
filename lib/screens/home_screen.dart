import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/game_cubit.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/shop_cubit.dart';
import '../bloc/shop_state.dart';
import '../models/bottle_model.dart';
import '../models/game_colors.dart';
import '../painters/liquid_painter.dart';
import '../services/level_progress_service.dart';
import '../theme/app_theme.dart';
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
  late final AnimationController _wobbleController;
  late final AnimationController _glowController;
  late final AnimationController _ambientController;
  late Future<int> _nextLevelFuture;

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
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _nextLevelFuture = LevelProgressService.getNextLevelToPlay();
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _glowController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _refreshNextLevel() {
    setState(() {
      _nextLevelFuture = LevelProgressService.getNextLevelToPlay();
    });
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
    if (mounted) _refreshNextLevel();
  }

  Future<void> _openShop() async {
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerLightHaptic();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ShopScreen()));
    if (mounted) _refreshNextLevel();
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
                    final compact = constraints.maxHeight < 760;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopBar(context),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - 76,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: compact ? 16 : 26),
                                  _buildHeroCopy(compact),
                                  SizedBox(height: compact ? 24 : 34),
                                  _buildBottleStage(compact),
                                  SizedBox(height: compact ? 22 : 30),
                                  _buildSupportRow(),
                                  SizedBox(height: compact ? 26 : 34),
                                  FutureBuilder<int>(
                                    future: _nextLevelFuture,
                                    builder: (context, snapshot) {
                                      final nextLevel = snapshot.data ?? 1;
                                      return AnimatedBuilder(
                                        animation: _glowController,
                                        builder: (context, child) {
                                          final glow =
                                              0.22 +
                                              (_glowController.value * 0.18);
                                          final floatOffset =
                                              sin(
                                                _glowController.value * pi * 2,
                                              ) *
                                              2.5;
                                          return Transform.translate(
                                            offset: Offset(0, -floatOffset),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(28),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme
                                                        .accentPrimary
                                                        .withValues(
                                                          alpha: glow,
                                                        ),
                                                    blurRadius: 32,
                                                    spreadRadius: -10,
                                                    offset: const Offset(0, 18),
                                                  ),
                                                ],
                                              ),
                                              child: GamePrimaryButton(
                                                label: 'Play Level $nextLevel',
                                                subtitle:
                                                    'Continue your puzzle run',
                                                icon: Icons.play_arrow_rounded,
                                                onTap: _startGame,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 28,
                                                      vertical: 20,
                                                    ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 14),
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: AppTheme.surfaceDecoration(
            tint: AppTheme.accentSecondary,
            radius: 22,
            muted: true,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentSecondary, AppTheme.accentPrimary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Color Sort',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Puzzle Studio',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        BlocBuilder<ShopCubit, ShopState>(
          builder: (context, shop) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: AppTheme.chipDecoration(
                tint: AppTheme.accentGold,
                emphasized: true,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: AppTheme.accentGold,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${shop.coins}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        GameIconButton(
          icon: Icons.storefront_rounded,
          tint: AppTheme.accentWarm,
          onTap: _openShop,
        ),
        const SizedBox(width: 10),
        GameIconButton(
          icon: Icons.tune_rounded,
          tint: AppTheme.accentPrimary,
          onTap: _openSettings,
        ),
      ],
    );
  }

  Widget _buildHeroCopy(bool compact) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: AppTheme.chipDecoration(
            tint: AppTheme.accentSecondary,
            emphasized: true,
          ),
          child: const Text(
            'PREMIUM CASUAL PUZZLE',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
        ),
        SizedBox(height: compact ? 16 : 20),
        Text(
          'Sort every drop\ninto its perfect bottle',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: compact ? 34 : 40,
            height: 0.98,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
          ),
        ),
        SizedBox(height: compact ? 12 : 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: const Text(
            'A clean strategy puzzle with smooth pours, subtle feedback, and enough depth to keep every level satisfying.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottleStage(bool compact) {
    return BlocBuilder<ShopCubit, ShopState>(
      builder: (context, shop) {
        return AnimatedBuilder(
          animation: Listenable.merge([_wobbleController, _ambientController]),
          builder: (context, child) {
            final wobblePhase = _wobbleController.value * 2 * pi;
            final ambientPhase = _ambientController.value * 2 * pi;
            final stageHeight = compact ? 248.0 : 286.0;
            final stageWidth = compact ? 308.0 : 332.0;

            return SizedBox(
              width: stageWidth,
              height: stageHeight,
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
                      offset: Offset(baseX, baseY + bob),
                      child: Transform.rotate(
                        angle: tilt,
                        child: Transform.scale(
                          scale: scale,
                          child: SizedBox(
                            width: compact ? 60 : 64,
                            height: compact ? 160 : 170,
                            child: CustomPaint(
                              painter: LiquidPainter(
                                bottle: _demoBottles[index],
                                wobblePhase: wobblePhase,
                                bottleType: shop.selectedType,
                                fillType: shop.selectedFill,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSupportRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: const [
        GameStatChip(
          label: 'Collection',
          value: '200 Levels',
          icon: Icons.auto_awesome_rounded,
          tint: AppTheme.accentSecondary,
          compact: true,
        ),
        GameStatChip(
          label: 'Tools',
          value: 'Hints + Undo',
          icon: Icons.psychology_alt_rounded,
          tint: AppTheme.accentWarm,
          compact: true,
        ),
        GameStatChip(
          label: 'Style',
          value: 'Custom Bottles',
          icon: Icons.inventory_2_rounded,
          tint: AppTheme.accentPrimary,
          compact: true,
        ),
      ],
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
