import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../animation/pour_animation_controller.dart';
import '../bloc/game_cubit.dart';
import '../bloc/game_state.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/shop_cubit.dart';
import '../models/bottle_type.dart';
import '../models/fill_type.dart';
import '../painters/pouring_stream_painter.dart';
import '../services/coin_service.dart';
import '../services/level_generator.dart';
import '../theme/app_theme.dart';
import '../widgets/bottle_widget.dart';
import '../widgets/game_ui.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final GlobalKey _pourOverlayKey = GlobalKey();

  late final PourAnimationController _pourAnimation;
  late final AnimationController _wobbleController;
  late final AnimationController _celebrationController;

  final Map<int, GlobalKey> _bottleSlotKeys = {};

  bool _isAnimating = false;
  Set<int> _newlySolvedBottles = {};
  Set<int> _previouslySolvedBottles = {};
  Size _lastBottleSize = Size.zero;

  @override
  void initState() {
    super.initState();

    _pourAnimation = PourAnimationController(vsync: this);
    _pourAnimation.controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final preState = context.read<GameCubit>().state;
        final preSolved = <int>{};
        for (int i = 0; i < preState.bottles.length; i++) {
          if (preState.bottles[i].isSolved) preSolved.add(i);
        }

        setState(() {
          _isAnimating = false;
          _pourAnimation.reset();
        });
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
    _pourAnimation.dispose();
    _wobbleController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _startPourAnimation() {
    setState(() {
      _isAnimating = true;
      _pourAnimation.reset();
    });

    // Measure after the animating build lands so the slot keys point to the
    // static grid positions instead of the previously selected visual state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareAndRunPour();
    });
  }

  void _prepareAndRunPour([int attempt = 0]) {
    if (!mounted || !_isAnimating) return;

    final state = context.read<GameCubit>().state;
    if (state.animSourceIndex < 0 || state.animDestIndex < 0) return;

    final sourceKey = _bottleSlotKeys[state.animSourceIndex];
    final destinationKey = _bottleSlotKeys[state.animDestIndex];
    final shopState = context.read<ShopCubit>().state;

    if (sourceKey == null || destinationKey == null) {
      if (attempt < 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _prepareAndRunPour(attempt + 1);
        });
        return;
      }

      setState(() {
        _isAnimating = false;
        _pourAnimation.reset();
      });
      context.read<GameCubit>().completePour();
      return;
    }

    final bottleSize = _lastBottleSize == Size.zero
        ? const Size(54, 145)
        : _lastBottleSize;
    final prepared = _pourAnimation.prepare(
      overlayKey: _pourOverlayKey,
      sourceBottleKey: sourceKey,
      destinationBottleKey: destinationKey,
      bottleType: shopState.selectedType,
      bottleSize: bottleSize,
      poursRight: state.animDestIndex > state.animSourceIndex,
    );

    if (!prepared) {
      if (attempt < 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _prepareAndRunPour(attempt + 1);
        });
        return;
      }

      setState(() {
        _isAnimating = false;
        _pourAnimation.reset();
      });
      context.read<GameCubit>().completePour();
      return;
    }

    setState(() {});
    _pourAnimation.controller.forward(from: 0.0);
    context.read<SettingsCubit>().triggerLightHaptic();
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final metrics = _GameScreenViewportMetrics.resolve(
                          constraints,
                        );

                        // The old screen felt stretched because the header and
                        // footer both used generous padding and tall cards,
                        // while the board itself sat inside a scroll view. This
                        // fixed column gives the chrome compact, content-driven
                        // height and lets the Expanded center own the leftover
                        // space like a proper puzzle board.
                        return Column(
                          children: [
                            _buildHeader(context, state, metrics),
                            SizedBox(height: metrics.sectionSpacing),
                            Expanded(
                              child: _buildBottleGrid(context, state, metrics),
                            ),
                            SizedBox(height: metrics.sectionSpacing),
                            _buildBottomBar(context, state, metrics),
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
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    GameState state,
    _GameScreenViewportMetrics metrics,
  ) {
    final movesLeft = max(0, state.moveLimit - state.moveCount);
    final isLowMoves = movesLeft <= 3;
    final difficulty = LevelGenerator.difficultyLabelForLevel(state.level);

    return GlassCard(
      tint: isLowMoves ? AppTheme.accentWarm : AppTheme.accentPrimary,
      radius: 26,
      blurSigma: 20,
      muted: true,
      padding: EdgeInsets.all(metrics.headerPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GameIconButton(
                icon: Icons.arrow_back_rounded,
                tint: AppTheme.accentPrimary,
                size: 20,
                padding: const EdgeInsets.all(10),
                onTap: () {
                  context.read<SettingsCubit>().playClickSound();
                  context.read<SettingsCubit>().triggerLightHaptic();
                  Navigator.of(context).pop();
                },
              ),
              SizedBox(width: metrics.innerSpacing),
              Expanded(
                child: _BoardHeaderCopy(
                  titleSize: metrics.headerTitleSize,
                  subtitleSize: metrics.headerSubtitleSize,
                ),
              ),
              SizedBox(width: metrics.innerSpacing),
              _BoardCountChip(
                value: '${state.bottles.length}',
                compact: metrics.isCompact,
              ),
            ],
          ),
          SizedBox(height: metrics.innerSpacing),
          Row(
            children: [
              Expanded(
                child: _CompactBoardStatCard(
                  label: 'Level',
                  value: '${state.level}',
                  icon: Icons.auto_awesome_rounded,
                  tint: AppTheme.accentPrimary,
                  compact: metrics.isCompact,
                ),
              ),
              SizedBox(width: metrics.innerSpacing),
              Expanded(
                child: _CompactBoardStatCard(
                  label: 'Difficulty',
                  value: difficulty,
                  icon: Icons.insights_rounded,
                  tint: AppTheme.accentSecondary,
                  compact: metrics.isCompact,
                ),
              ),
              SizedBox(width: metrics.innerSpacing),
              Expanded(
                child: _CompactBoardStatCard(
                  label: 'Moves',
                  value: '$movesLeft',
                  icon: Icons.swap_vert_rounded,
                  tint: isLowMoves ? AppTheme.accentWarm : AppTheme.accentGold,
                  compact: metrics.isCompact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottleGrid(
    BuildContext context,
    GameState state,
    _GameScreenViewportMetrics viewportMetrics,
  ) {
    final count = state.bottles.length;
    final shopState = context.watch<ShopCubit>().state;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pourAnimation.controller,
        _wobbleController,
        _celebrationController,
      ]),
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _BottleGridMetrics.resolve(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
              count: count,
              compact: viewportMetrics.isCompact,
            );
            _lastBottleSize = metrics.bottleSize;
            final pourFrame = _isAnimating ? _pourAnimation.frame : null;

            return Stack(
              key: _pourOverlayKey,
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
                  child: SizedBox(
                    width: metrics.boardSize.width,
                    height: metrics.boardSize.height,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: metrics.horizontalSpacing,
                      runSpacing: metrics.verticalSpacing,
                      children: List.generate(count, (idx) {
                        final hideSourceSlot =
                            _isAnimating &&
                            _pourAnimation.hasLayout &&
                            state.animSourceIndex == idx;
                        return SizedBox(
                          width: metrics.bottleSize.width,
                          child: _buildBottleWidget(
                            context,
                            state,
                            idx,
                            bottleType: shopState.selectedType,
                            fillType: shopState.selectedFill,
                            bottleSize: metrics.bottleSize,
                            measureKey: _bottleSlotKeyFor(idx),
                            renderState: hideSourceSlot
                                ? const _BottleRenderState()
                                : _resolveBottleRenderState(
                                    state,
                                    idx,
                                    pourFrame: pourFrame,
                                  ),
                            asPlaceholder: hideSourceSlot,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: viewportMetrics.isCompact ? 2 : 8,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        width: min(
                          constraints.maxWidth * 0.72,
                          metrics.boardSize.width * 0.92,
                        ),
                        height: viewportMetrics.isCompact ? 18 : 24,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.accentSecondary.withValues(alpha: 0.16),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isAnimating &&
                    state.animSourceIndex >= 0 &&
                    pourFrame != null)
                  Positioned(
                    left: pourFrame.sourceTopLeft.dx,
                    top: pourFrame.sourceTopLeft.dy,
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
                        renderState: _resolveBottleRenderState(
                          state,
                          state.animSourceIndex,
                          pourFrame: pourFrame,
                          floatingSource: true,
                        ),
                        ignoreTap: true,
                      ),
                    ),
                  ),
                if (_isAnimating &&
                    state.animSourceIndex >= 0 &&
                    state.animDestIndex >= 0 &&
                    pourFrame != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: PouringStreamPainter(
                          start: pourFrame.streamStart,
                          end: pourFrame.streamEnd,
                          color: state.animColor,
                          progress: pourFrame.streamProgress,
                          flowPhase: _pourAnimation.controller.value * 8 * pi,
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
    _BottleRenderState renderState = const _BottleRenderState(),
    Key? measureKey,
    bool asPlaceholder = false,
    bool ignoreTap = false,
  }) {
    final bottle = state.bottles[index];
    final isSelected =
        !renderState.isSource &&
        !renderState.isDest &&
        state.selectedBottleIndex == index;
    final isHint =
        !renderState.isSource &&
        !renderState.isDest &&
        (state.hintSourceIndex == index || state.hintDestIndex == index);
    final wobblePhase = renderState.isSource || renderState.isDest
        ? _pourAnimation.controller.value * 6 * pi
        : _wobbleController.value * 2 * pi;
    final bottleCanvas = SizedBox(
      width: bottleSize.width,
      height: bottleSize.height,
      child: BottleWidget(
        bottle: bottle,
        bottleType: bottleType,
        fillType: fillType,
        size: bottleSize,
        tiltAngle: renderState.tiltAngle,
        levelProgress: renderState.levelProgress,
        isSource: renderState.isSource,
        isDest: renderState.isDest,
        pourCount: (renderState.isSource || renderState.isDest)
            ? state.animColorCount
            : 0,
        pourColor: renderState.isDest ? state.animColor : null,
        isSelected: isSelected,
        isHint: isHint,
        wobblePhase: wobblePhase,
        isSolved: bottle.isSolved,
        capProgress: _newlySolvedBottles.contains(index)
            ? _celebrationController.value
            : (_previouslySolvedBottles.contains(index) || bottle.isSolved
                  ? 1.0
                  : 0.0),
        celebrationProgress: _newlySolvedBottles.contains(index)
            ? _celebrationController.value
            : 0.0,
      ),
    );

    Widget content = SizedBox(
      key: measureKey,
      width: bottleSize.width,
      height: bottleSize.height,
      child: Transform.translate(
        offset: renderState.translation,
        child: Transform.scale(
          scale: renderState.scale,
          alignment: Alignment.center,
          child: bottleCanvas,
        ),
      ),
    );

    if (asPlaceholder) {
      return IgnorePointer(
        ignoring: true,
        child: Opacity(opacity: 0.0, child: content),
      );
    }

    if (ignoreTap) {
      return IgnorePointer(child: content);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_isAnimating) return;
        context.read<SettingsCubit>().playClickSound();
        context.read<SettingsCubit>().triggerSelectionHaptic();
        context.read<GameCubit>().onBottleTap(index);
      },
      child: content,
    );
  }

  GlobalKey _bottleSlotKeyFor(int index) {
    return _bottleSlotKeys.putIfAbsent(index, () => GlobalKey());
  }

  _BottleRenderState _resolveBottleRenderState(
    GameState state,
    int index, {
    required PourAnimationFrame? pourFrame,
    bool floatingSource = false,
  }) {
    final bottle = state.bottles[index];
    final isSelected = state.selectedBottleIndex == index;
    final isHint =
        state.hintSourceIndex == index || state.hintDestIndex == index;

    if (floatingSource && pourFrame != null) {
      return _BottleRenderState(
        tiltAngle: pourFrame.sourceTiltAngle,
        scale: pourFrame.sourceScale,
        levelProgress: pourFrame.transferProgress,
        isSource: true,
      );
    }

    if (_isAnimating && state.animDestIndex == index && pourFrame != null) {
      return _BottleRenderState(
        translation: Offset(0, pourFrame.destinationLiftY),
        scale: pourFrame.destinationScale,
        levelProgress: pourFrame.transferProgress,
        isDest: true,
      );
    }

    return _BottleRenderState(
      translation: Offset(0, isSelected ? -16.0 : (isHint ? -10.0 : 0.0)),
      scale: isSelected
          ? 1.05
          : isHint
          ? 1.03
          : bottle.isSolved
          ? 0.99
          : 1.0,
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    GameState state,
    _GameScreenViewportMetrics metrics,
  ) {
    return GlassCard(
      tint: AppTheme.accentPrimary,
      radius: 26,
      muted: true,
      padding: EdgeInsets.all(metrics.bottomBarPadding),
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
          SizedBox(width: metrics.innerSpacing),
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
          SizedBox(width: metrics.innerSpacing),
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
    final isActive = badgeCount != null && badgeCount > 0;

    return GameButton(
      label: label,
      icon: icon,
      onTap: onTap,
      accentColor: accentColor,
      badgeCount: badgeCount,
      emphasized: isActive,
      minHeight: 76,
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      layout: GameButtonLayout.vertical,
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

class _BoardHeaderCopy extends StatelessWidget {
  const _BoardHeaderCopy({required this.titleSize, required this.subtitleSize});

  final double titleSize;
  final double subtitleSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Puzzle Board',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Smooth pours. Clear reads.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: subtitleSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.32,
          ),
        ),
      ],
    );
  }
}

class _BoardCountChip extends StatelessWidget {
  const _BoardCountChip({required this.value, required this.compact});

  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: AppTheme.accentSecondary,
      radius: 18,
      highlighted: true,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 24 : 28,
            height: compact ? 24 : 28,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient(AppTheme.accentSecondary),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BOARD',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
              Text(
                '$value Bottles',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactBoardStatCard extends StatelessWidget {
  const _CompactBoardStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.compact,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: tint,
      radius: 20,
      muted: true,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 9 : 10,
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 26 : 28,
            height: compact ? 26 : 28,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient(tint, intensity: 0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: compact ? 14 : 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottleRenderState {
  const _BottleRenderState({
    this.translation = Offset.zero,
    this.scale = 1.0,
    this.tiltAngle = 0.0,
    this.levelProgress = 0.0,
    this.isSource = false,
    this.isDest = false,
  });

  final Offset translation;
  final double scale;
  final double tiltAngle;
  final double levelProgress;
  final bool isSource;
  final bool isDest;
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

class _GameScreenViewportMetrics {
  const _GameScreenViewportMetrics({
    required this.isCompact,
    required this.sectionSpacing,
    required this.headerPadding,
    required this.bottomBarPadding,
    required this.innerSpacing,
    required this.headerTitleSize,
    required this.headerSubtitleSize,
  });

  final bool isCompact;
  final double sectionSpacing;
  final double headerPadding;
  final double bottomBarPadding;
  final double innerSpacing;
  final double headerTitleSize;
  final double headerSubtitleSize;

  static _GameScreenViewportMetrics resolve(BoxConstraints constraints) {
    final isCompact = constraints.maxHeight < 740 || constraints.maxWidth < 370;
    return _GameScreenViewportMetrics(
      isCompact: isCompact,
      sectionSpacing: isCompact ? 12 : 16,
      headerPadding: isCompact ? 12 : 14,
      bottomBarPadding: isCompact ? 10 : 12,
      innerSpacing: isCompact ? 10 : 12,
      headerTitleSize: isCompact ? 18 : 20,
      headerSubtitleSize: isCompact ? 11 : 12,
    );
  }
}

class _BottleGridMetrics {
  const _BottleGridMetrics({
    required this.boardSize,
    required this.bottleSize,
    required this.horizontalSpacing,
    required this.verticalSpacing,
  });

  final Size boardSize;
  final Size bottleSize;
  final double horizontalSpacing;
  final double verticalSpacing;

  static _BottleGridMetrics resolve({
    required double maxWidth,
    required double maxHeight,
    required int count,
    required bool compact,
  }) {
    final columns = _columnCountFor(count);
    final rows = (count / columns).ceil();
    const bottleAspect = 2.68;
    final horizontalPadding = compact ? 8.0 : 12.0;
    final verticalPadding = compact ? 8.0 : 12.0;
    final horizontalSpacing = count >= 16 ? 4.0 : (count >= 10 ? 8.0 : 10.0);
    final verticalSpacing = compact
        ? (count >= 10 ? 10.0 : 12.0)
        : (count >= 16 ? 10.0 : (count >= 10 ? 12.0 : 14.0));
    final availableWidth = max(0.0, maxWidth - (horizontalPadding * 2));
    final availableHeight = max(0.0, maxHeight - (verticalPadding * 2));
    final widthLimited =
        (availableWidth - horizontalSpacing * (columns - 1)) / columns;
    final heightLimited =
        ((availableHeight - verticalSpacing * (rows - 1)) / rows) /
        bottleAspect;
    final bottleWidth = min(
      widthLimited,
      heightLimited,
    ).clamp(compact ? 44.0 : 46.0, count >= 12 ? 62.0 : 68.0);
    final resolvedBottleHeight = bottleWidth * bottleAspect;
    final boardWidth =
        (columns * bottleWidth) + ((columns - 1) * horizontalSpacing);
    final boardHeight =
        (rows * resolvedBottleHeight) + ((rows - 1) * verticalSpacing);

    // The board is sized against both width and height so it can stay centered
    // and non-scrollable inside the Expanded middle section on short devices.

    return _BottleGridMetrics(
      boardSize: Size(boardWidth, boardHeight),
      bottleSize: Size(bottleWidth, resolvedBottleHeight),
      horizontalSpacing: horizontalSpacing,
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
