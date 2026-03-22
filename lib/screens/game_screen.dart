import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_cubit.dart';
import '../bloc/game_state.dart';
import '../bloc/settings_cubit.dart';
import '../painters/liquid_painter.dart';
import '../painters/pouring_stream_painter.dart';

/// The main game screen displaying all bottles and handling animations.
///
/// Animation Phases (coordinated via a single AnimationController):
///   Phase 1 (0.0 – 0.25): Source bottle tilts toward destination
///   Phase 2 (0.15 – 0.55): Liquid stream appears from mouth to destination
///   Phase 3 (0.3 – 0.9):  Synchronized level decrease (source) / increase (dest)
///   Phase 4 (0.85 – 1.0): Source bottle tilts back to upright
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  // ── Pour animation controller ──
  late AnimationController _pourController;

  // ── Wobble animation for idle liquid surface ──
  late AnimationController _wobbleController;

  // ── Animation curves for each phase ──
  late Animation<double> _tiltAnimation;      // Phase 1 & 4
  late Animation<double> _streamAnimation;    // Phase 2
  late Animation<double> _levelAnimation;     // Phase 3

  // ── Bottle position keys for calculating stream path ──
  final Map<int, GlobalKey> _bottleKeys = {};

  // ── Track if pour animation is active ──
  bool _isAnimating = false;

  /// Briefly highlights all non-empty bottles (Shuffle hint).
  bool _highlightNonEmpty = false;
  Timer? _shuffleHighlightTimer;

  // ── Base positions for animation ──
  Offset _sourcePos = Offset.zero;
  Offset _destPos = Offset.zero;

  @override
  void initState() {
    super.initState();

    // Pour animation: ~1 second total duration
    _pourController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Define animation phases with curves
    _tiltAnimation = TweenSequence<double>([
      // Phase 1: Tilt to pour position (0.0 → 0.25)
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      // Hold tilt during pour (0.25 → 0.85)
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 60,
      ),
      // Phase 4: Return to upright (0.85 → 1.0)
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
    ]).animate(_pourController);

    _streamAnimation = TweenSequence<double>([
      // Wait before stream appears
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 15,
      ),
      // Stream grows (0.15 → 0.55)
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      // Stream holds
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 30,
      ),
      // Stream retracts (0.85 → 1.0)
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
    ]).animate(_pourController);

    _levelAnimation = TweenSequence<double>([
      // Wait before level change
      TweenSequenceItem(
        tween: ConstantTween(0.0),
        weight: 30,
      ),
      // Level change (0.3 → 0.9)
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
      // Hold at end
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 10,
      ),
    ]).animate(_pourController);

    _pourController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isAnimating = false);
        context.read<GameCubit>().completePour();
      }
    });

    // Wobble animation: continuous sine wave phase
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shuffleHighlightTimer?.cancel();
    _pourController.dispose();
    _wobbleController.dispose();
    super.dispose();
  }

  static const _shuffleHighlightDuration = Duration(milliseconds: 2000);

  void _onShuffleTap() {
    if (_isAnimating) return;
    final state = context.read<GameCubit>().state;
    if (state.status == GameStatus.won) return;

    context.read<GameCubit>().shuffleLevel();

    _shuffleHighlightTimer?.cancel();
    setState(() => _highlightNonEmpty = true);
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerLightHaptic();

    _shuffleHighlightTimer = Timer(_shuffleHighlightDuration, () {
      if (mounted) setState(() => _highlightNonEmpty = false);
    });
  }

  /// Start the coordinated pour animation.
  void _startPourAnimation() {
    setState(() {
      _highlightNonEmpty = false;
      _shuffleHighlightTimer?.cancel();
      _isAnimating = true;
      final state = context.read<GameCubit>().state;
      _sourcePos = _getBottleBasePosition(state.animSourceIndex);
      _destPos = _getBottleBasePosition(state.animDestIndex);
    });
    _pourController.forward(from: 0.0);
    // Haptic feedback
    context.read<SettingsCubit>().triggerLightHaptic();
  }

  Offset _getBottleBasePosition(int index) {
    final key = _bottleKeys[index];
    if (key == null || key.currentContext == null) return Offset.zero;
    final box = key.currentContext!.findRenderObject() as RenderBox;
    return box.localToGlobal(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameCubit, GameState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status,
      listener: (context, state) {
        if (state.status == GameStatus.animating && !_isAnimating) {
          _startPourAnimation();
        }
        if (state.status == GameStatus.won) {
          _showWinDialog(context, state);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A0E21),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, state),
                Expanded(
                  child: _buildBottleGrid(context, state),
                ),
                _buildBottomBar(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the top header with level info and move counter.
  Widget _buildHeader(BuildContext context, GameState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A0E21),
            const Color(0xFF1A1F3A).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4FC3F7)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'Level ${state.level}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          // Move counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_vert_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${state.moveCount} moves',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the grid of bottles.
  Widget _buildBottleGrid(BuildContext context, GameState state) {
    final bottles = state.bottles;
    final count = bottles.length;

    // Determine grid layout based on bottle count
    int crossAxisCount;
    if (count <= 6) {
      crossAxisCount = count;
    } else if (count <= 8) {
      crossAxisCount = 4;
    } else {
      crossAxisCount = 5;
    }

    // Split bottles into rows
    final rows = <List<int>>[];
    for (int i = 0; i < count; i += crossAxisCount) {
      final end = (i + crossAxisCount).clamp(0, count);
      rows.add(List.generate(end - i, (j) => i + j));
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_pourController, _wobbleController]),
      builder: (context, child) {
        return Stack(
          children: [
            // Background subtle gradient
            Positioned.fill(
              child: CustomPaint(
                painter: _BackgroundPainter(),
              ),
            ),
            // Bottles layout
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: rows.map((row) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: row.map((idx) {
                            return _buildBottleWidget(context, state, idx);
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            // Pour stream overlay
            if (_isAnimating &&
                state.animSourceIndex >= 0 &&
                state.animDestIndex >= 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: PouringStreamPainter(
                      start: _getBottleMouthPosition(state.animSourceIndex),
                      end: _getBottleMouthPosition(state.animDestIndex),
                      color: state.animColor,
                      progress: _streamAnimation.value,
                      flowPhase: _wobbleController.value * 2 * pi,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Builds a single bottle widget with its CustomPainter.
  Widget _buildBottleWidget(BuildContext context, GameState state, int index) {
    // Ensure we have a GlobalKey for position tracking
    _bottleKeys.putIfAbsent(index, () => GlobalKey());

    final bottle = state.bottles[index];
    final isSelected = state.selectedBottleIndex == index;
    final isSource = _isAnimating && state.animSourceIndex == index;
    final highlightAsNonEmpty =
        _highlightNonEmpty && bottle.isNotEmpty;
    final isHighlighted = isSelected || highlightAsNonEmpty;

    // ── Calculate tilt angle and translation ──
    double tiltAngle = 0.0;
    double translateX = 0.0;
    double translateY = isHighlighted ? -12.0 : 0.0;

    if (isSource && _isAnimating && _sourcePos != Offset.zero && _destPos != Offset.zero) {
      final destIdx = state.animDestIndex;
      final direction = destIdx > index ? 1.0 : -1.0;
      
      // Increased tilt for more realistic pour (approx 85 degrees)
      tiltAngle = direction * _tiltAnimation.value * 1.48;

      // Translate source bottle near destination bottle mouth
      final targetX = (_destPos.dx - _sourcePos.dx) - (direction * 15);
      final targetY = (_destPos.dy - _sourcePos.dy) - 45;

      translateX = targetX * _tiltAnimation.value;
      translateY = targetY * _tiltAnimation.value;
    }

    // ── Calculate level progress for source bottle ──
    double levelProgress = 0.0;
    if (isSource && _isAnimating) {
      levelProgress = _levelAnimation.value;
    }

    // ── Wobble phase ──
    final wobblePhase = _wobbleController.value * 2 * pi;

    return GestureDetector(
      onTap: () {
        if (!_isAnimating) {
          context.read<SettingsCubit>().playClickSound();
          context.read<SettingsCubit>().triggerSelectionHaptic();
          context.read<GameCubit>().onBottleTap(index);
        }
      },
      child: AnimatedContainer(
        key: _bottleKeys[index],
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        // Lift or translate bottle
        transform: Matrix4.translationValues(
          translateX,
          translateY,
          0,
        ),
        child: SizedBox(
          width: 56,
          height: 150,
          child: CustomPaint(
            painter: LiquidPainter(
              bottle: bottle,
              tiltAngle: tiltAngle,
              levelProgress: levelProgress,
              isSource: isSource,
              pourCount: isSource ? state.animColorCount : 0,
              isSelected: isHighlighted,
              wobblePhase: wobblePhase,
              isSolved: bottle.isSolved,
            ),
            size: const Size(56, 150),
          ),
        ),
      ),
    );
  }

  /// Gets the screen position of a bottle's mouth for stream rendering.
  Offset _getBottleMouthPosition(int index) {
    final key = _bottleKeys[index];
    if (key == null || key.currentContext == null) {
      return Offset.zero;
    }

    final box = key.currentContext!.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);

    bool isSource = _isAnimating && context.read<GameCubit>().state.animSourceIndex == index;

    if (isSource) {
      final state = context.read<GameCubit>().state;
      final direction = state.animDestIndex > index ? 1.0 : -1.0;
      final xOffset = direction > 0 ? 37.0 : 19.0; // matching neckRight and neckLeft roughly
      return Offset(pos.dx + xOffset, pos.dy + 15.0);
    } else {
      return Offset(
        pos.dx + box.size.width / 2,
        pos.dy + 15,
      );
    }
  }

  /// Builds the bottom action bar with Undo, Shuffle hint, and Restart.
  Widget _buildBottomBar(BuildContext context, GameState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF0A0E21).withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.undo_rounded,
              label: 'Undo',
              compact: true,
              onTap: state.moveHistory.isNotEmpty
                  ? () {
                      context.read<SettingsCubit>().playClickSound();
                      context.read<SettingsCubit>().triggerLightHaptic();
                      context.read<GameCubit>().undo();
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              icon: Icons.shuffle_rounded,
              label: 'Shuffle',
              compact: true,
              onTap: () {
                _onShuffleTap();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              icon: Icons.refresh_rounded,
              label: 'Restart',
              onTap: () {
                _shuffleHighlightTimer?.cancel();
                setState(() => _highlightNonEmpty = false);
                context.read<SettingsCubit>().playClickSound();
                context.read<SettingsCubit>().triggerLightHaptic();
                context.read<GameCubit>().restartLevel();
              },
              compact: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a styled action button.
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool compact = false,
  }) {
    final isEnabled = onTap != null;
    final hPad = compact ? 10.0 : 24.0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isEnabled ? 1.0 : 0.35,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: isEnabled ? 0.15 : 0.05),
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the win dialog with next level option.
  void _showWinDialog(BuildContext context, GameState state) {
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerHeavyHaptic();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1F3A), Color(0xFF0A0E21)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy icon with glow
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Level Complete!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${state.moveCount} moves  •  ${state.undoCount} undos',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                // Next Level Button
                GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.read<GameCubit>().nextLevel();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4FC3F7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Next Level →',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Simple background painter with subtle radial gradient.
class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(0, -0.2),
        radius: 1.2,
        colors: [
          const Color(0xFF1A1F3A).withValues(alpha: 0.5),
          const Color(0xFF0A0E21),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
