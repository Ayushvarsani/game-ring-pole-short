import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/game_cubit.dart';
import '../bloc/game_state.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/shop_cubit.dart';
import '../models/bottle_model.dart';
import '../models/bottle_type.dart';
import '../models/fill_type.dart';
import '../painters/liquid_painter.dart';
import '../painters/pouring_stream_painter.dart';
import '../services/coin_service.dart';
import '../services/level_generator.dart';
import '../theme/app_theme.dart';
import '../widgets/game_ui.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final GlobalKey _stackKey = GlobalKey();
  
  late final AnimationController _pourController;
  late final AnimationController _wobbleController;
  late final AnimationController _celebrationController;

  late final Animation<double> _tiltAnimation;
  late final Animation<double> _streamAnimation;
  late final Animation<double> _levelAnimation;

  final Map<int, GlobalKey> _bottleKeys = {};

  bool _isAnimating = false;
  Set<int> _newlySolvedBottles = {};
  Set<int> _previouslySolvedBottles = {};

  Offset _sourcePos = Offset.zero;
  Offset _destPos = Offset.zero;

  @override
  void initState() {
    super.initState();

    _pourController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );

    _tiltAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 22,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 58),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 20,
      ),
    ]).animate(_pourController);

    _streamAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 12),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 28,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 20,
      ),
    ]).animate(_pourController);

    _levelAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 22),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 58,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
    ]).animate(_pourController);

    _pourController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final preState = context.read<GameCubit>().state;
        final preSolved = <int>{};
        for (int i = 0; i < preState.bottles.length; i++) {
          if (preState.bottles[i].isSolved) preSolved.add(i);
        }

        setState(() => _isAnimating = false);
        context.read<GameCubit>().completePour();

        final postState = context.read<GameCubit>().state;
        final newSolved = <int>{};
        for (int i = 0; i < postState.bottles.length; i++) {
          if (postState.bottles[i].isSolved &&
              !preSolved.contains(i) &&
              !_previouslySolvedBottles.contains(i)) {
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

    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _celebrationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
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

  void _startPourAnimation() {
    setState(() {
      _isAnimating = true;
      final state = context.read<GameCubit>().state;
      _sourcePos = _getBottleBasePosition(state.animSourceIndex);
      _destPos = _getBottleBasePosition(state.animDestIndex);
    });
    _pourController.forward(from: 0.0);
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
        if (state.moveCount == 0) {
          _previouslySolvedBottles = {};
          _newlySolvedBottles = {};
        }
      },
      builder: (context, state) {
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
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _buildHeader(context, state),
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: _buildBottleGrid(context, state)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _buildBottomBar(context, state),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, GameState state) {
    final movesLeft = max(0, state.moveLimit - state.moveCount);
    final isLowMoves = movesLeft <= 3;
    final difficulty = LevelGenerator.difficultyLabelForLevel(state.level);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.surfaceDecoration(
        tint: isLowMoves ? AppTheme.accentWarm : AppTheme.accentPrimary,
        radius: 30,
        muted: true,
      ),
      child: Column(
        children: [
          Row(
            children: [
              GameIconButton(
                icon: Icons.arrow_back_rounded,
                tint: AppTheme.accentPrimary,
                onTap: () {
                  context.read<SettingsCubit>().playClickSound();
                  context.read<SettingsCubit>().triggerLightHaptic();
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Puzzle Board',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Smooth pours. Clear reads.',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              GameStatChip(
                label: 'Board',
                value: '${state.bottles.length} Bottles',
                icon: Icons.grid_view_rounded,
                tint: AppTheme.accentSecondary,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GameStatChip(
                  label: 'Level',
                  value: '${state.level}',
                  icon: Icons.auto_awesome_rounded,
                  tint: AppTheme.accentPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameStatChip(
                  label: 'Difficulty',
                  value: difficulty,
                  icon: Icons.insights_rounded,
                  tint: AppTheme.accentSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameStatChip(
                  label: 'Moves Left',
                  value: '$movesLeft',
                  icon: Icons.swap_vert_rounded,
                  tint: isLowMoves ? AppTheme.accentWarm : AppTheme.accentGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottleGrid(BuildContext context, GameState state) {
    final count = state.bottles.length;
    final shopState = context.watch<ShopCubit>().state;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pourController,
        _wobbleController,
        _celebrationController,
      ]),
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _BottleGridMetrics.resolve(
              constraints.maxWidth,
              count,
            );
            Offset? localSourcePos;
            if (_isAnimating && state.animSourceIndex >= 0 && _sourcePos != Offset.zero) {
              try {
                final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
                if (box != null && box.hasSize) {
                  localSourcePos = box.globalToLocal(_sourcePos);
                }
              } catch (_) {}
            }

            return Stack(
              key: _stackKey,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BoardPainter(
                      progress: _wobbleController.value,
                      isAnimating: _isAnimating,
                    ),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    physics: _isAnimating
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: metrics.horizontalSpacing,
                          runSpacing: metrics.verticalSpacing,
                          children: List.generate(count, (idx) {
                            return SizedBox(
                              width: metrics.bottleSize.width,
                              child: _buildBottleWidget(
                                context,
                                state,
                                idx,
                                bottleType: shopState.selectedType,
                                fillType: shopState.selectedFill,
                                bottleSize: metrics.bottleSize,
                                asPlaceholder: _isAnimating && state.animSourceIndex == idx,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isAnimating && state.animSourceIndex >= 0 && localSourcePos != null)
                  Positioned(
                    left: localSourcePos.dx,
                    top: localSourcePos.dy,
                    width: metrics.bottleSize.width,
                    height: metrics.bottleSize.height,
                    child: IgnorePointer(
                      child: _buildBottleWidget(
                        context,
                        state,
                        state.animSourceIndex,
                        bottleType: shopState.selectedType,
                        fillType: shopState.selectedFill,
                        bottleSize: metrics.bottleSize,
                        asPlaceholder: false,
                      ),
                    ),
                  ),
                if (_isAnimating &&
                    state.animSourceIndex >= 0 &&
                    state.animDestIndex >= 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: PouringStreamPainter(
                          start: _getBottleMouthPosition(
                            state.animSourceIndex,
                            bottleType: shopState.selectedType,
                            bottleSize: metrics.bottleSize,
                          ),
                          end: _getBottleMouthPosition(
                            state.animDestIndex,
                            bottleType: shopState.selectedType,
                            bottleSize: metrics.bottleSize,
                          ),
                          color: state.animColor,
                          progress: _streamAnimation.value,
                          flowPhase: _wobbleController.value * 2 * pi,
                          fillType: shopState.selectedFill,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBottleWidget(
    BuildContext context,
    GameState state,
    int index, {
    required BottleType bottleType,
    required FillType fillType,
    required Size bottleSize,
    bool asPlaceholder = false,
  }) {
    _bottleKeys.putIfAbsent(index, () => GlobalKey());

    final bottle = state.bottles[index];
    final isSelected = state.selectedBottleIndex == index;
    final isSource = _isAnimating && state.animSourceIndex == index;
    final isDest = _isAnimating && state.animDestIndex == index;
    final isHint =
        state.hintSourceIndex == index || state.hintDestIndex == index;

    double tiltAngle = 0.0;
    double translateX = 0.0;
    double translateY = isSelected ? -16.0 : (isHint ? -10.0 : 0.0);

    if (isSource &&
        _isAnimating &&
        _sourcePos != Offset.zero &&
        _destPos != Offset.zero) {
      final direction = state.animDestIndex > index ? 1.0 : -1.0;
      tiltAngle = direction * _tiltAnimation.value * 1.46;

      final mouthOffset = bottleSize.width * 0.26;
      final liftHeight = bottleSize.height * 0.3;
      final targetX = (_destPos.dx - _sourcePos.dx) - (direction * mouthOffset);
      final targetY = (_destPos.dy - _sourcePos.dy) - liftHeight;

      translateX = targetX * _tiltAnimation.value;
      translateY = targetY * _tiltAnimation.value;
    } else if (isDest && _isAnimating) {
      translateY -= sin(_levelAnimation.value * pi) * 6;
    }

    double levelProgress = 0.0;
    if ((isSource || isDest) && _isAnimating) {
      levelProgress = _levelAnimation.value;
    }

    final wobblePhase = _wobbleController.value * 2 * pi;
    final scale = isSource
        ? 1.05
        : isDest
        ? 1.0 + (sin(_levelAnimation.value * pi) * 0.035)
        : isSelected
        ? 1.04
        : isHint
        ? 1.02
        : bottle.isSolved
        ? 0.99
        : 1.0;

    Widget content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: asPlaceholder ? null : () {
        if (_isAnimating) return;
        context.read<SettingsCubit>().playClickSound();
        context.read<SettingsCubit>().triggerSelectionHaptic();
        context.read<GameCubit>().onBottleTap(index);
      },
      child: AnimatedContainer(
        key: _bottleKeys[index],
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(translateX, translateY, 0),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          scale: scale,
          child: SizedBox(
            width: bottleSize.width,
            height: bottleSize.height,
            child: CustomPaint(
              painter: LiquidPainter(
                bottle: bottle,
                tiltAngle: tiltAngle,
                levelProgress: levelProgress,
                isSource: isSource,
                isDest: isDest,
                pourCount: (isSource || isDest) ? state.animColorCount : 0,
                pourColor: isDest ? state.animColor : null,
                isSelected: isSelected,
                isHint: isHint,
                wobblePhase: wobblePhase,
                isSolved: bottle.isSolved,
                capProgress: _newlySolvedBottles.contains(index)
                    ? _celebrationController.value
                    : (_previouslySolvedBottles.contains(index) ||
                              bottle.isSolved
                          ? 1.0
                          : 0.0),
                celebrationProgress: _newlySolvedBottles.contains(index)
                    ? _celebrationController.value
                    : 0.0,
                bottleType: bottleType,
                fillType: fillType,
              ),
              size: bottleSize,
            ),
          ),
        ),
      ),
    );

    if (asPlaceholder) {
      return Opacity(opacity: 0.0, child: content);
    }
    return content;
  }

  Offset _getBottleMouthPosition(
    int index, {
    required BottleType bottleType,
    required Size bottleSize,
  }) {
    final key = _bottleKeys[index];
    if (key == null || key.currentContext == null) return Offset.zero;

    final box = key.currentContext!.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);
    final geometry = BottleGeometry.fromSize(bottleSize, bottleType);
    final isSource =
        _isAnimating &&
        context.read<GameCubit>().state.animSourceIndex == index;

    if (isSource) {
      final state = context.read<GameCubit>().state;
      final direction = state.animDestIndex > index ? 1.0 : -1.0;
      final mouthX = direction > 0 ? geometry.neckRight : geometry.neckLeft;
      final destPos = _getBottleBasePosition(state.animDestIndex);

      if (_sourcePos != Offset.zero && destPos != Offset.zero) {
        final mouthOffset = bottleSize.width * 0.26;
        final liftHeight = bottleSize.height * 0.3;
        final targetX =
            (destPos.dx - _sourcePos.dx) - (direction * mouthOffset);
        final targetY = (destPos.dy - _sourcePos.dy) - liftHeight;
        final translateX = targetX * _tiltAnimation.value;
        final translateY = targetY * _tiltAnimation.value;
        return Offset(
          pos.dx + mouthX + translateX,
          pos.dy + geometry.neckTop + translateY,
        );
      }

      return Offset(pos.dx + mouthX, pos.dy + geometry.neckTop);
    }

    final capacity = kMaxBottleCapacity.toDouble();
    final state = context.read<GameCubit>().state;
    final currentAmount = state.bottles[index].colors.length;
    final isDest = _isAnimating && state.animDestIndex == index;
    final fillLevel = currentAmount + (isDest ? _levelAnimation.value * state.animColorCount : 0);
    
    final fillFraction = fillLevel / capacity;
    final spaceFraction = 1.0 - fillFraction;
    
    final yTarget = geometry.neckTop + ((geometry.bottom - geometry.neckTop) * spaceFraction.clamp(0.0, 1.0));
    
    return Offset(pos.dx + geometry.centerX, pos.dy + yTarget);
  }

  Widget _buildBottomBar(BuildContext context, GameState state) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: AppTheme.surfaceDecoration(
        tint: AppTheme.accentPrimary,
        radius: 32,
        muted: true,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.undo_rounded,
              label: 'Undo',
              accentColor: AppTheme.accentPrimary,
              onTap: state.moveHistory.isNotEmpty
                  ? () {
                      context.read<SettingsCubit>().playClickSound();
                      context.read<SettingsCubit>().triggerLightHaptic();
                      context.read<GameCubit>().undo();
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildActionButton(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Hint',
              accentColor: AppTheme.accentGold,
              badgeCount: state.hintsRemaining,
              onTap:
                  state.status == GameStatus.playing && state.hintsRemaining > 0
                  ? () {
                      context.read<SettingsCubit>().playClickSound();
                      context.read<SettingsCubit>().triggerLightHaptic();
                      context.read<GameCubit>().getHint();
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildActionButton(
              icon: Icons.refresh_rounded,
              label: 'Restart',
              accentColor: AppTheme.accentWarm,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color accentColor,
    VoidCallback? onTap,
    int? badgeCount,
  }) {
    final isEnabled = onTap != null;
    final isActive = badgeCount != null && badgeCount > 0;

    return GamePressable(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isEnabled ? 1 : 0.36,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: AppTheme.actionButtonDecoration(
            isEnabled: isEnabled,
            isActive: isActive,
            accentColor: accentColor,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppTheme.textPrimary, size: 22),
                  ),
                  if (badgeCount != null)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: badgeCount > 0
                              ? AppTheme.accentWarm
                              : AppTheme.textMuted,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showOverlayDialog({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = false,
    String barrierLabel = 'Dialog',
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: barrierLabel,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Material(color: Colors.transparent, child: child),
          ),
        );
      },
      transitionBuilder: (context, animation, _, dialogChild) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: dialogChild,
          ),
        );
      },
    );
  }

  void _showWinDialog(BuildContext context, int coinsEarned) {
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerHeavyHaptic();
    _showOverlayDialog(
      context: context,
      barrierLabel: 'Level Complete',
      child: GameDialogFrame(
        title: 'Level Complete',
        subtitle:
            'Everything is sorted. Your reward is ready and the next puzzle is unlocked.',
        tint: AppTheme.accentGold,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accentGold, AppTheme.accentWarm],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withValues(alpha: 0.28),
                    blurRadius: 28,
                    spreadRadius: -6,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDialogStat(
                    icon: Icons.monetization_on_rounded,
                    label: 'Coins Earned',
                    value: '+$coinsEarned',
                    tint: AppTheme.accentGold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDialogStat(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Next Stage',
                    value: 'Level ${context.read<GameCubit>().state.level + 1}',
                    tint: AppTheme.accentSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GamePrimaryButton(
                label: 'Next Level',
                subtitle: 'Keep the streak going',
                icon: Icons.arrow_forward_rounded,
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<GameCubit>().nextLevel();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, GameState state) {
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerHeavyHaptic();
    _showOverlayDialog(
      context: context,
      barrierLabel: 'Game Over',
      child: GameDialogFrame(
        title: 'Out Of Moves',
        subtitle:
            'This board needs one more pass. Restart the level or head back to the home screen.',
        tint: AppTheme.accentWarm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accentWarm.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.accentWarm.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.hourglass_bottom_rounded,
                color: AppTheme.accentWarm,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDialogStat(
                    icon: Icons.swap_vert_rounded,
                    label: 'Moves Used',
                    value: '${state.moveCount}/${state.moveLimit}',
                    tint: AppTheme.accentWarm,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDialogStat(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Hints Left',
                    value: '${state.hintsRemaining}',
                    tint: AppTheme.accentGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GamePressable(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: AppTheme.surfaceDecoration(
                        tint: AppTheme.accentPrimary,
                        radius: 24,
                        muted: true,
                      ),
                      child: const Text(
                        'Home',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GamePrimaryButton(
                    label: 'Restart',
                    subtitle: 'Try the board again',
                    icon: Icons.refresh_rounded,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.read<GameCubit>().restartLevel();
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogStat({
    required IconData icon,
    required String label,
    required String value,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: AppTheme.surfaceDecoration(
        tint: tint,
        radius: 22,
        muted: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: tint, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter({required this.progress, required this.isAnimating});

  final double progress;
  final bool isAnimating;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = 0.04 + (sin(progress * 2 * pi) * 0.015);

    final primaryGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.08),
        radius: 0.9,
        colors: [
          AppTheme.accentPrimary.withValues(alpha: isAnimating ? 0.12 : 0.08),
          AppTheme.accentSecondary.withValues(alpha: 0.05 + pulse),
          Colors.transparent,
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), primaryGlow);

    final floorGlowRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.86),
      width: size.width * 0.74,
      height: size.height * 0.22,
    );
    final floorGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accentSecondary.withValues(alpha: 0.12 + pulse),
          Colors.transparent,
        ],
      ).createShader(floorGlowRect);
    canvas.drawOval(floorGlowRect, floorGlow);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.05);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.48),
        width: size.width * 0.84,
        height: size.height * 0.72,
      ),
      pi * 0.13,
      pi * 0.74,
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isAnimating != isAnimating;
  }
}

class _BottleGridMetrics {
  const _BottleGridMetrics({
    required this.bottleSize,
    required this.horizontalSpacing,
    required this.verticalSpacing,
  });

  final Size bottleSize;
  final double horizontalSpacing;
  final double verticalSpacing;

  static _BottleGridMetrics resolve(double width, int count) {
    final columns = _columnCountFor(count);
    const horizontalPadding = 16.0;
    const minBottleWidth = 52.0;
    const maxBottleWidth = 58.0;

    var spacing = count >= 16 ? 4.0 : (count >= 10 ? 8.0 : 12.0);
    final availableWidth = max(0.0, width - (horizontalPadding * 2));
    var bottleWidth = (availableWidth - spacing * (columns - 1)) / columns;

    if (bottleWidth > maxBottleWidth) {
      bottleWidth = maxBottleWidth;
    }
    if (bottleWidth < minBottleWidth) {
      bottleWidth = minBottleWidth;
      spacing = max(
        3.0,
        (availableWidth - bottleWidth * columns) / max(1, columns - 1),
      );
    }

    final bottleHeight = bottleWidth * 2.68;
    final verticalSpacing = count >= 16 ? 10.0 : (count >= 10 ? 14.0 : 18.0);

    return _BottleGridMetrics(
      bottleSize: Size(bottleWidth, bottleHeight),
      horizontalSpacing: spacing,
      verticalSpacing: verticalSpacing,
    );
  }

  static int _columnCountFor(int count) {
    if (count <= 5) return count;
    if (count <= 8) return 4;
    if (count <= 12) return 5;
    if (count <= 15) return 4;
    return 5;
  }
}
