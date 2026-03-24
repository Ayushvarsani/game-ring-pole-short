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
import 'game_screen.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/shop_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _wobbleController;

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
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Settings
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Color Sort',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BlocBuilder<ShopCubit, ShopState>(
                        builder: (context, shop) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.monetization_on_rounded,
                                  color: const Color(0xFFFFD700)
                                      .withValues(alpha: 0.95),
                                  size: 22,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${shop.coins}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.store_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          context.read<SettingsCubit>().playClickSound();
                          context.read<SettingsCubit>().triggerLightHaptic();
                          showDialog(
                            context: context,
                            builder: (context) => const ShopDialog(),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.settings_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          context.read<SettingsCubit>().playClickSound();
                          context.read<SettingsCubit>().triggerLightHaptic();
                          showDialog(
                            context: context,
                            builder: (context) => const SettingsDialog(),
                          );
                        },
                      ),
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
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),

                  const SizedBox(height: 44),

                  // Play Button
                  GestureDetector(
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF4FC3F7)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF)
                                .withValues(alpha: 0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
