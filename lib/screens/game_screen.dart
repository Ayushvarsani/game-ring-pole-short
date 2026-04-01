import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_cubit.dart';
import '../bloc/game_state.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/shop_cubit.dart';
import '../models/bottle_type.dart';
import '../models/fill_type.dart';
import '../services/coin_service.dart';
import '../painters/liquid_painter.dart';
import '../painters/pouring_stream_painter.dart';
import '../theme/app_theme.dart';

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

  // ── Celebration animation for solved bottles ──
  late AnimationController _celebrationController;

  // ── Track if pour animation is active ──
  bool _isAnimating = false;

  // ── Track which bottles are newly solved (for cap drop + celebration) ──
  Set<int> _newlySolvedBottles = {};

  // ── Track previously solved bottles (cap stays, no celebration) ──
  Set<int> _previouslySolvedBottles = {};

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
        // Capture which bottles were solved BEFORE completing pour
        final preState = context.read<GameCubit>().state;
        final preSolved = <int>{};
        for (int i = 0; i < preState.bottles.length; i++) {
          if (preState.bottles[i].isSolved) preSolved.add(i);
        }

        setState(() => _isAnimating = false);
        context.read<GameCubit>().completePour();

        // Check which bottles became newly solved AFTER pour
        final postState = context.read<GameCubit>().state;
        final newSolved = <int>{};
        for (int i = 0; i < postState.bottles.length; i++) {
          if (postState.bottles[i].isSolved && !preSolved.contains(i) && !_previouslySolvedBottles.contains(i)) {
            newSolved.add(i);
          }
        }

        if (newSolved.isNotEmpty) {
          setState(() {
            _newlySolvedBottles = newSolved;
          });
          _celebrationController.forward(from: 0.0);
        }
      }
    });

    // Wobble animation: continuous sine wave phase
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Celebration animation: cap drop + sparkles (~800ms)
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _celebrationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          // Move newly solved to previously solved (cap stays, particles stop)
          _previouslySolvedBottles.addAll(_newlySolvedBottles);
          _newlySolvedBottles = {};
        });
      }
    });
  }

  @override
  void dispose() {
    _pourController.dispose();
    _wobbleController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  /// Start the coordinated pour animation.
  void _startPourAnimation() {
    setState(() {
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
          prev.status != curr.status || prev.level != curr.level,
      listener: (context, state) {
        if (state.status == GameStatus.animating && !_isAnimating) {
          _startPourAnimation();
        }
        if (state.status == GameStatus.won) {
          final reward = CoinService.rewardForLevel(state.level);
          context.read<ShopCubit>().addCoinsFromLevelReward(state.level);
          _showWinDialog(context, reward);
        }
        if (state.status == GameStatus.gameOver) {
          _showGameOverDialog(context, state);
        }
        // Reset solved tracking on new level or restart
        if (state.moveCount == 0) {
          _previouslySolvedBottles = {};
          _newlySolvedBottles = {};
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: context.watch<ShopCubit>().state.selectedTheme.gradient),
            child: SafeArea(
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
            AppTheme.bgDark.withValues(alpha: 0.9),
            AppTheme.bgLight.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                context.read<SettingsCubit>().playClickSound();
                context.read<SettingsCubit>().triggerLightHaptic();
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Level ${state.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_vert_rounded,
                    color: Colors.white.withValues(alpha: 0.75),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${max(0, state.moveLimit - state.moveCount)} moves',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
      animation: Listenable.merge([_pourController, _wobbleController, _celebrationController]),
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
                            return _buildBottleWidget(context, state, idx, bottleType: context.read<ShopCubit>().state.selectedType, fillType: context.read<ShopCubit>().state.selectedFill);
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
                      fillType: context.read<ShopCubit>().state.selectedFill,
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
  Widget _buildBottleWidget(BuildContext context, GameState state, int index, {BottleType bottleType = BottleType.classic, FillType fillType = FillType.liquid}) {
    // Ensure we have a GlobalKey for position tracking
    _bottleKeys.putIfAbsent(index, () => GlobalKey());

    final bottle = state.bottles[index];
    final isSelected = state.selectedBottleIndex == index;
    final isSource = _isAnimating && state.animSourceIndex == index;
    final isDest = _isAnimating && state.animDestIndex == index;
    final isHint = state.hintSourceIndex == index || state.hintDestIndex == index;
    final isHighlighted = isSelected;

    // ── Calculate tilt angle and translation ──
    double tiltAngle = 0.0;
    double translateX = 0.0;
    double translateY = (isHighlighted || isHint) ? -12.0 : 0.0;

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

    // ── Calculate level progress ──
    double levelProgress = 0.0;
    if ((isSource || isDest) && _isAnimating) {
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
              isDest: isDest,
              pourCount: (isSource || isDest) ? state.animColorCount : 0,
              pourColor: isDest ? state.animColor : null,
              isSelected: isHighlighted,
              isHint: isHint,
              wobblePhase: wobblePhase,
              isSolved: bottle.isSolved,
              capProgress: _newlySolvedBottles.contains(index)
                  ? _celebrationController.value
                  : (_previouslySolvedBottles.contains(index) || bottle.isSolved ? 1.0 : 0.0),
              celebrationProgress: _newlySolvedBottles.contains(index)
                  ? _celebrationController.value
                  : 0.0,
              bottleType: bottleType,
              fillType: fillType,
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
      
      final destPos = _getBottleBasePosition(state.animDestIndex);
      if (_sourcePos != Offset.zero && destPos != Offset.zero) {
        final targetX = (destPos.dx - _sourcePos.dx) - (direction * 15);
        final targetY = (destPos.dy - _sourcePos.dy) - 45;
        final translateX = targetX * _tiltAnimation.value;
        final translateY = targetY * _tiltAnimation.value;
        return Offset(pos.dx + xOffset + translateX, pos.dy + 15.0 + translateY);
      }
      return Offset(pos.dx + xOffset, pos.dy + 15.0);
    } else {
      return Offset(
        pos.dx + box.size.width / 2,
        pos.dy + 15,
      );
    }
  }

  /// Builds the bottom action bar with Undo and Restart.
  Widget _buildBottomBar(BuildContext context, GameState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppTheme.bgDark.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: _buildActionButton(
              icon: Icons.undo_rounded,
              label: 'Undo',
              onTap: state.moveHistory.isNotEmpty
                  ? () {
                      context.read<SettingsCubit>().playClickSound();
                      context.read<SettingsCubit>().triggerLightHaptic();
                      context.read<GameCubit>().undo();
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            height: 96,
            child: _buildActionButton(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Hint',
              badgeCount: state.hintsRemaining,
              onTap: state.status == GameStatus.playing &&
                      state.hintsRemaining > 0
                  ? () {
                      context.read<SettingsCubit>().playClickSound();
                      context.read<SettingsCubit>().triggerLightHaptic();
                      context.read<GameCubit>().getHint();
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            height: 96,
            child: _buildActionButton(
              icon: Icons.refresh_rounded,
              label: 'Restart',
              onTap: () {
                context.read<SettingsCubit>().playClickSound();
                context.read<SettingsCubit>().triggerLightHaptic();
                context.read<GameCubit>().restartLevel();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a styled action button with optional badge count on the icon.
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    int? badgeCount,
  }) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isEnabled ? 1.0 : 0.35,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: isEnabled ? 0.15 : 0.05),
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (badgeCount != null)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: Colors.white, size: 22),
                    Positioned(
                      top: -8,
                      right: -12,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: badgeCount > 0
                              ? const Color(0xFFE53935)
                              : Colors.grey,
                          shape: BoxShape.circle,
                          boxShadow: badgeCount > 0
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFE53935)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 6),
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
  void _showWinDialog(BuildContext context, int coinsEarned) {
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
            decoration: AppTheme.dialogDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy icon with glow
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.accentGold, Color(0xFFFFA000)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentGold.withValues(alpha: 0.4),
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
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      color: AppTheme.accentGold.withValues(alpha: 0.95),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+$coinsEarned coins',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
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
                      gradient: AppTheme.buttonGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentPrimary.withValues(alpha: 0.4),
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

  /// Shows a game-over dialog when move limit is reached.
  void _showGameOverDialog(BuildContext context, GameState state) {
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerHeavyHaptic();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.dialogDecoration(
              borderColor: const Color(0xFFFF5252),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF5252).withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.sentiment_dissatisfied_rounded,
                    color: Color(0xFFFF6E6E),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Game Over',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Move limit reached.\n${state.moveCount}/${state.moveLimit} moves used.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Text(
                            'Home',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          context.read<GameCubit>().restartLevel();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: AppTheme.buttonGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Restart',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Background painter with subtle radial glow effects.
class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Primary radial glow
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.3),
        radius: 1.2,
        colors: [
          AppTheme.accentPrimary.withValues(alpha: 0.06),
          AppTheme.bgMedium.withValues(alpha: 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Secondary teal accent glow at bottom
    final accentPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, 0.8),
        radius: 0.8,
        colors: [
          AppTheme.accentSecondary.withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
