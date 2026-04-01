import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/game_cubit.dart';
import '../bloc/settings_cubit.dart';
import '../services/level_progress_service.dart';
import '../bloc/shop_cubit.dart';
import '../bloc/shop_state.dart';
import '../models/bottle_model.dart';
import '../models/game_colors.dart';
import '../painters/liquid_painter.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';
import 'shop_screen.dart';
import '../widgets/settings_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _wobbleController;
  late AnimationController _glowController;

  // Demo bottles showing a mixed puzzle state
  final List<BottleModel> _demoBottles = const [
    BottleModel(id: 0, colors: [
      GameColors.red,
      GameColors.blue,
      GameColors.red,
      GameColors.green,
    ]),
    BottleModel(id: 1, colors: [
      GameColors.blue,
      GameColors.green,
      GameColors.yellow,
      GameColors.red,
    ]),
    BottleModel(id: 2, colors: [
      GameColors.green,
      GameColors.yellow,
      GameColors.blue,
      GameColors.yellow,
    ]),
    BottleModel(id: 3, colors: [
      GameColors.yellow,
      GameColors.red,
      GameColors.green,
      GameColors.blue,
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: context.watch<ShopCubit>().state.selectedTheme.gradient,
        ),
        child: Stack(
          children: [
            // Background decorative orbs
            Positioned(
              top: -80,
              right: -60,
              child: _buildBgOrb(200, AppTheme.accentPrimary.withValues(alpha: 0.08)),
            ),
            Positioned(
              bottom: -100,
              left: -50,
              child: _buildBgOrb(250, AppTheme.accentSecondary.withValues(alpha: 0.06)),
            ),
            Positioned(
              top: size.height * 0.4,
              left: -30,
              child: _buildBgOrb(120, AppTheme.accentWarm.withValues(alpha: 0.05)),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Top Bar with Settings
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title with subtle gradient
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppTheme.textPrimary, AppTheme.accentSecondary],
                          ).createShader(bounds),
                          child: const Text(
                            'Color Sort',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Coin display
                            BlocBuilder<ShopCubit, ShopState>(
                              builder: (context, shop) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.accentGold.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.monetization_on_rounded,
                                        color: AppTheme.accentGold.withValues(alpha: 0.95),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${shop.coins}',
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            _buildIconBtn(Icons.store_rounded, () {
                              context.read<SettingsCubit>().playClickSound();
                              context.read<SettingsCubit>().triggerLightHaptic();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ShopScreen(),
                                ),
                              );
                            }),
                            _buildIconBtn(Icons.settings_rounded, () {
                              context.read<SettingsCubit>().playClickSound();
                              context.read<SettingsCubit>().triggerLightHaptic();
                              showDialog(
                                context: context,
                                builder: (context) => const SettingsDialog(),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated demo bottles using real LiquidPainter
                        BlocBuilder<ShopCubit, ShopState>(
                          builder: (context, shop) {
                            final selectedBottleType = shop.selectedType;
                            final selectedFillType = shop.selectedFill;
                            return AnimatedBuilder(
                              animation: _wobbleController,
                              builder: (context, child) {
                                final wobblePhase =
                                    _wobbleController.value * 2 * pi;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _demoBottles.map((bottle) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 5),
                                      child: SizedBox(
                                        width: 50,
                                        height: 130,
                                        child: CustomPaint(
                                          painter: LiquidPainter(
                                            bottle: bottle,
                                            wobblePhase: wobblePhase,
                                            bottleType: selectedBottleType,
                                            fillType: selectedFillType,
                                          ),
                                          size: const Size(50, 130),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Tagline
                        Text(
                          'Sort the colors to win!',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                            letterSpacing: 0.8,
                          ),
                        ),

                        const SizedBox(height: 44),

                        // Play Button with animated glow
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            return GestureDetector(
                              onTap: () async {
                                context.read<SettingsCubit>().playClickSound();
                                context.read<SettingsCubit>().triggerHeavyHaptic();
                                final level =
                                    await LevelProgressService.getNextLevelToPlay();
                                if (!context.mounted) return;
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider(
                                      create: (_) => GameCubit(initialLevel: level),
                                      child: const GameScreen(),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 200,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.buttonGradient,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accentPrimary.withValues(
                                        alpha: 0.3 + _glowController.value * 0.2,
                                      ),
                                      blurRadius: 20 + _glowController.value * 10,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 5),
                                    ),
                                    BoxShadow(
                                      color: AppTheme.accentSecondary.withValues(
                                        alpha: 0.15 + _glowController.value * 0.1,
                                      ),
                                      blurRadius: 25,
                                      spreadRadius: -2,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow_rounded,
                                        color: Colors.white, size: 32),
                                    SizedBox(width: 10),
                                    Text(
                                      'PLAY',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: 22),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildBgOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}
