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
  late Animation<double> _progressCurve;

  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _entranceController;
  late AnimationController _sweepController;

  late Animation<double> _entranceScale;
  late Animation<double> _entranceFade;

  // For simulated parallax
  double _pseudoParallaxX = 0;
  double _pseudoParallaxY = 0;

  @override
  void initState() {
    super.initState();

    // 1. App loading simulation with natural easing
    _progressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));

    _progressCurve = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.addListener(() {
      setState(() {});
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });

    // 2. Continuous pulse for background/glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    // 3. Floating background orbs and logo bobbing
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // 4. Shimmer/Sweep rotation behind logo
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 5. Entrance animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _entranceScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _floatController.addListener(() {
      // Simulate very subtle continuous parallax
      setState(() {
        _pseudoParallaxX = sin(_floatController.value * 2 * pi) * 6.0;
        _pseudoParallaxY = cos(_floatController.value * 2 * pi * 1.5) * 4.0;
      });
    });

    // Start entrance and progress simultaneously
    _entranceController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _entranceController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = AppTheme.of(context);

    // High-end multi-layer gradient background with vignette
    final bgGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Color.lerp(
            theme.primaryAccent, theme.backgroundGradient.colors.first, 0.8)!,
        theme.backgroundGradient.colors.last,
        const Color(0xFF03010B), // Hard vignette edge
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    return Scaffold(
      backgroundColor: Colors.black, // fallback
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: bgGradient),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 1: Simulated Parallax Background Particles
            Transform.translate(
              offset: Offset(_pseudoParallaxX * 1.5, _pseudoParallaxY * 1.5),
              child: CustomPaint(
                size: Size(size.width, size.height),
                painter: _StarfieldPainter(
                  animation: _floatController.value,
                  pulse: _pulseController.value,
                  color: theme.goldAccent,
                ),
              ),
            ),

            // Layer 2: Main Logo Assembly with entrance animation
            AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                return Opacity(
                  opacity: _entranceFade.value,
                  child: Transform.scale(
                    scale: _entranceScale.value,
                    child: Transform.translate(
                      // Subtle continuous float up/down (3px) + slight parallax offset
                      offset: Offset(
                        _pseudoParallaxX * -0.5, // Counter-move for depth
                        sin(_floatController.value * 4 * pi) * 4.0,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow layer
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) {
                              return Container(
                                width: 260,
                                height: 260,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryAccent.withValues(
                                        alpha: 0.15 +
                                            (_pulseController.value * 0.15),
                                      ),
                                      blurRadius: 80,
                                      spreadRadius: 20,
                                    ),
                                    BoxShadow(
                                      color: theme.secondaryAccent.withValues(
                                        alpha: 0.08 +
                                            (_pulseController.value * 0.05),
                                      ),
                                      blurRadius: 100,
                                      spreadRadius: 40,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Rotating magical shimmer ring behind the logo
                          AnimatedBuilder(
                            animation: _sweepController,
                            builder: (context, _) {
                              return Transform.rotate(
                                angle: _sweepController.value * 2 * pi,
                                child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      colors: [
                                        Colors.transparent,
                                        theme.goldAccent
                                            .withValues(alpha: 0.0),
                                        theme.goldAccent
                                            .withValues(alpha: 0.3),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.4, 0.5, 0.6],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // The actual logo
                          Image.asset(
                            'assets/images/logo.png',
                            width: 240,
                            height: 240,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Layer 3: Premium Animated Bottom Loader
            Positioned(
              bottom: size.height * 0.10,
              child: AnimatedBuilder(
                animation: _entranceController,
                builder: (context, child) {
                  // Eased fade-in for loader
                  final loaderOpacity = Curves.easeIn.transform(
                    (_entranceController.value - 0.4).clamp(0.0, 1.0) / 0.6,
                  );
                  return Opacity(
                    opacity: loaderOpacity,
                    child: SizedBox(
                      width: size.width * 0.68,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Dynamic glowing progress bar
                          AnimatedBuilder(
                            animation: Listenable.merge(
                                [_progressController, _sweepController]),
                            builder: (context, _) {
                              final progress = _progressCurve.value;
                              return Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white.withValues(alpha: 0.06),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryAccent.withValues(
                                        alpha: 0.3 * progress,
                                      ),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final fillWidth =
                                          constraints.maxWidth * progress;
                                      return Stack(
                                        children: [
                                          // Animated liquid gradient fill
                                          Positioned(
                                            left: 0,
                                            width: fillWidth,
                                            top: 0,
                                            bottom: 0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    theme.primaryAccent,
                                                    theme.secondaryAccent,
                                                    theme.goldAccent,
                                                    theme.primaryAccent,
                                                  ],
                                                  stops: const [
                                                    0.0,
                                                    0.4,
                                                    0.7,
                                                    1.0
                                                  ],
                                                  // Animate the gradient laterally
                                                  transform: GradientRotation(
                                                      _sweepController.value *
                                                          2 *
                                                          pi),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Shimmer highlight sweeping across the filled portion
                                          Positioned(
                                            left: -constraints.maxWidth +
                                                (fillWidth +
                                                        constraints.maxWidth) *
                                                    _sweepController.value,
                                            width: 100,
                                            top: 0,
                                            bottom: 0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white
                                                        .withValues(alpha: 0.0),
                                                    Colors.white
                                                        .withValues(alpha: 0.5),
                                                    Colors.white
                                                        .withValues(alpha: 0.0),
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
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          // Premium typography for percentage
                          Text(
                            '${(_progressCurve.value * 100).toInt()}%',
                            style: TextStyle(
                              color: Color.lerp(theme.textMuted,
                                  theme.textPrimary, _progressCurve.value),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                              shadows: [
                                Shadow(
                                  color: theme.primaryAccent.withValues(
                                      alpha: 0.4 * _progressCurve.value),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

// A highly optimized particle starfield for the background depth
class _StarfieldPainter extends CustomPainter {
  final double animation;
  final double pulse;
  final Color color;

  _StarfieldPainter({
    required this.animation,
    required this.pulse,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(42); // fixed seed for stable layout
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    for (int i = 0; i < 35; i++) {
      // Randomize positions, phases, sizes
      final baseX = rand.nextDouble() * size.width;
      final baseY = rand.nextDouble() * size.height;
      final baseSize = rand.nextDouble() * 3.0 + 1.0;
      final speedFactor = rand.nextDouble() * 1.5 + 0.5;
      final phase = rand.nextDouble() * 2 * pi;

      // Slow vertical drift mapped to the 0->1 animation float value
      final yOffset = baseY - (animation * 100 * speedFactor);
      final wrappedY = yOffset % size.height;

      // Gentle lateral drift using sine
      final xOffset =
          baseX + sin(animation * 2 * pi * speedFactor + phase) * 15;

      // Twinkle mapped to pulse controller and unique phase
      final opacity =
          (sin(pulse * pi + phase) + 1) / 2 * 0.4 + 0.1; // 0.1 - 0.5 opacity

      paint.color = color.withValues(alpha: opacity);

      // Some particles are blurred heavily (out of focus) to simulate depth
      if (rand.nextBool()) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      } else {
        paint.maskFilter = null;
      }

      canvas.drawCircle(Offset(xOffset, wrappedY), baseSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.pulse != pulse;
  }
}
