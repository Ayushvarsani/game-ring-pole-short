import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _progressController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = AppTheme.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: theme.backgroundGradient),
        child: Stack(
          children: [
            // Decorative background orbs
            ...List.generate(6, (i) {
              final angle = _floatController.value * 2 * pi + (i * pi / 3);
              return Positioned(
                left: size.width * (0.1 + 0.15 * i) + sin(angle + i) * 20,
                top: size.height * (0.15 + 0.1 * (i % 3)) + cos(angle) * 15,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, _) {
                    return Container(
                      width: 60 + i * 15.0,
                      height: 60 + i * 15.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (i.isEven
                                    ? theme.primaryAccent
                                    : theme.secondaryAccent)
                                .withValues(
                                  alpha: 0.08 + _pulseController.value * 0.04,
                                ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated water drop icon with glow
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, child) {
                      final scale = 1.0 + _pulseController.value * 0.08;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                theme.secondaryAccent.withValues(alpha: 0.3),
                                theme.primaryAccent.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.secondaryAccent.withValues(
                                  alpha: 0.2 + _pulseController.value * 0.15,
                                ),
                                blurRadius: 30,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.water_drop_rounded,
                            color: theme.secondaryAccent,
                            size: 80,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 36),

                  // Title with gradient-like appearance
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        theme.brandingGradient.createShader(bounds),
                    child: Text(
                      'WATER SORT',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PUZZLE',
                    style: TextStyle(
                      color: theme.textSecondary.withValues(alpha: 0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 8,
                    ),
                  ),

                  const SizedBox(height: 54),

                  // Progress Bar with glow
                  SizedBox(
                    width: size.width * 0.55,
                    child: Column(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryAccent.withValues(
                                  alpha: 0.3 * _progressController.value,
                                ),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progressController.value,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.primaryAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Loading... ${(_progressController.value * 100).toInt()}%',
                          style: TextStyle(
                            color: theme.textMuted,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
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
}
