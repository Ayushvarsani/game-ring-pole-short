import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../bloc/game_cubit.dart';
import '../bloc/settings_cubit.dart';
import 'game_screen.dart';
import '../widgets/settings_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            ),
            
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Game Graphic Representation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMiniBottle([const Color(0xFF6C63FF), const Color(0xFF4FC3F7)]),
                      const SizedBox(width: 15),
                      _buildMiniBottle([const Color(0xFFFF5252), const Color(0xFFFFD700)]),
                      const SizedBox(width: 15),
                      _buildMiniBottle([const Color(0xFF4CAF50), const Color(0xFF9C27B0)]),
                    ],
                  ),
                  const SizedBox(height: 50),
                  
                  // Play Button
                  GestureDetector(
                    onTap: () {
                      context.read<SettingsCubit>().playClickSound();
                      context.read<SettingsCubit>().triggerHeavyHaptic();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (_) => GameCubit(),
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
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
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

  // Helper widget to draw mini bottles for visual appeal
  Widget _buildMiniBottle(List<Color> colors) {
    return Container(
      width: 40,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: colors.map((color) {
          return Container(
            height: 35,
            width: double.infinity,
            color: color,
          );
        }).toList(),
      ),
    );
  }
}
