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
import '../theme/app_theme.dart';
import '../theme/app_theme_config.dart';
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
          context.read<SettingsCubit>().playBottleSolvedSound();
          context.read<SettingsCubit>().triggerLightHaptic();
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
    context.read<SettingsCubit>().playPourSound();
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
          context.read<SettingsCubit>().playWinSound();
          context.read<SettingsCubit>().triggerHeavyHaptic();
          _showWinDialog(context, reward);
        }
        if (state.status == GameStatus.gameOver) {
          context.read<SettingsCubit>().playFailSound();
          context.read<SettingsCubit>().triggerHeavyHaptic();
          _showGameOverDialog(context, state);
        }
        if (state.moveCount == 0) {
          _previouslySolvedBottles = {};
          _newlySolvedBottles = {};
        }
      },
      builder: (context, state) {
        final theme = AppTheme.of(context);
        return Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: theme.backgroundGradient),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: theme.overlayGradient),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    // Tight outer insets keep the gameplay chrome from stealing
                    // height from the center board on shorter devices.
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
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
    final theme = AppTheme.of(context);
    final movesLeft = max(0, state.moveLimit - state.moveCount);
    final isLowMoves = movesLeft <= 3;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GameIconButton(
          icon: Icons.arrow_back_rounded,
          tint: theme.primaryAccent,
          size: metrics.isCompact ? 18 : 19,
          padding: EdgeInsets.all(metrics.backButtonPadding),
          onTap: () {
            context.read<SettingsCubit>().playClickSound();
            context.read<SettingsCubit>().triggerLightHaptic();
            Navigator.of(context).pop();
          },
        ),
        SizedBox(width: metrics.innerSpacing),
        // One compact header row keeps the board status visible while leaving
        // most of the vertical space for the playable bottle area.
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _CompactHeaderChip(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Level',
                  value: '${state.level}',
                  tint: theme.primaryAccent,
                  compact: metrics.isCompact,
                ),
              ),
              SizedBox(width: metrics.innerSpacing),
              Expanded(
                child: _CompactHeaderChip(
                  icon: Icons.swap_vert_rounded,
                  label: 'Moves',
                  value: '$movesLeft',
                  tint: isLowMoves ? theme.warmAccent : theme.goldAccent,
                  compact: metrics.isCompact,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottleGrid(
    BuildContext context,
    GameState state,
    _GameScreenViewportMetrics viewportMetrics,
  ) {
    final count = state.bottles.length;
    final shopState = context.watch<ShopCubit>().state;
    final theme = AppTheme.of(context);

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
                      theme: theme,
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
                              theme.boardAura.withValues(alpha: 0.16),
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
    final theme = AppTheme.of(context);
    // The controls stay in one low-profile row so the footer reads quickly
    // and the Expanded middle section keeps the most vertical space.
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            metrics: metrics,
            icon: Icons.undo_rounded,
            label: 'Undo',
            accentColor: theme.primaryAccent,
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
            metrics: metrics,
            icon: Icons.lightbulb_outline_rounded,
            label: 'Hint',
            accentColor: theme.goldAccent,
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
            metrics: metrics,
            icon: Icons.refresh_rounded,
            label: 'Restart',
            accentColor: theme.warmAccent,
            onTap: () {
              context.read<SettingsCubit>().playClickSound();
              context.read<SettingsCubit>().triggerLightHaptic();
              context.read<GameCubit>().restartLevel();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required _GameScreenViewportMetrics metrics,
    required IconData icon,
    required String label,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return _CompactActionButton(
      icon: icon,
      label: label,
      tint: accentColor,
      onTap: onTap,
      compact: metrics.isCompact,
      height: metrics.actionButtonHeight,
      radius: metrics.actionButtonRadius,
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
      barrierColor: Colors.black.withValues(alpha: 0.70),
      transitionDuration: const Duration(milliseconds: 320),
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
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeInCubic,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: dialogChild,
          ),
        );
      },
    );
  }

  void _showWinDialog(BuildContext context, int coinsEarned) {
    final nextLevel = context.read<GameCubit>().state.level + 1;
    _showOverlayDialog(
      context: context,
      barrierLabel: 'Level Complete',
      child: _WinDialog(
        coinsEarned: coinsEarned,
        nextLevel: nextLevel,
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        onNext: () {
          Navigator.of(context).pop();
          context.read<GameCubit>().nextLevel();
        },
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, GameState state) {
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerHeavyHaptic();
    _showOverlayDialog(
      context: context,
      barrierLabel: 'Game Over',
      child: _GameOverDialog(
        moveCount: state.moveCount,
        moveLimit: state.moveLimit,
        hintsRemaining: state.hintsRemaining,
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        onRestart: () {
          Navigator.of(context).pop();
          context.read<GameCubit>().restartLevel();
        },
      ),
    );
  }
}

class _CompactHeaderChip extends StatelessWidget {
  const _CompactHeaderChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final iconSize = compact ? 14.0 : 15.0;

    return GlassCard(
      tint: tint,
      radius: compact ? 16 : 18,
      blurSigma: 14,
      muted: true,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 7 : 8,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: iconSize, color: tint.withValues(alpha: 0.88)),
                SizedBox(width: compact ? 4.0 : 5.0),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 2 : 3),
            Text(
              value,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: compact ? 15 : 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
    required this.compact,
    required this.height,
    required this.radius,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback? onTap;
  final bool compact;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final enabled = onTap != null;

    return GamePressable(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.42,
        child: DecoratedBox(
          decoration: AppTheme.gradientButtonDecoration(
            accentColor: tint,
            isEnabled: enabled,
            emphasized: false,
            radius: radius,
            theme: theme,
          ),
          child: SizedBox(
            height: height,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: compact ? 6 : 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: compact ? 17 : 18),
                  SizedBox(width: compact ? 6 : 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: enabled ? 1.0 : 0.74,
                        ),
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
  const _BoardPainter({
    required this.progress,
    required this.isAnimating,
    required this.theme,
  });

  final double progress;
  final bool isAnimating;
  final AppThemeConfig theme;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = 0.04 + (sin(progress * 2 * pi) * 0.015);

    final primaryGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.08),
        radius: 0.9,
        colors: [
          theme.boardHalo.withValues(alpha: isAnimating ? 0.12 : 0.08),
          theme.boardAura.withValues(alpha: 0.05 + pulse),
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
          theme.boardAura.withValues(alpha: 0.12 + pulse),
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
        oldDelegate.isAnimating != isAnimating ||
        oldDelegate.theme != theme;
  }
}

class _GameScreenViewportMetrics {
  const _GameScreenViewportMetrics({
    required this.isCompact,
    required this.sectionSpacing,
    required this.innerSpacing,
    required this.actionButtonHeight,
    required this.actionButtonRadius,
    required this.backButtonPadding,
  });

  final bool isCompact;
  final double sectionSpacing;
  final double innerSpacing;
  final double actionButtonHeight;
  final double actionButtonRadius;
  final double backButtonPadding;

  static _GameScreenViewportMetrics resolve(BoxConstraints constraints) {
    final isCompact = constraints.maxHeight < 740 || constraints.maxWidth < 370;
    return _GameScreenViewportMetrics(
      isCompact: isCompact,
      sectionSpacing: isCompact ? 8 : 10,
      innerSpacing: isCompact ? 6 : 8,
      actionButtonHeight: isCompact ? 52 : 56,
      actionButtonRadius: isCompact ? 16 : 18,
      backButtonPadding: isCompact ? 8 : 9,
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

class _WinDialog extends StatefulWidget {
  const _WinDialog({
    required this.coinsEarned,
    required this.nextLevel,
    required this.onHome,
    required this.onNext,
  });

  final int coinsEarned;
  final int nextLevel;
  final VoidCallback onHome;
  final VoidCallback onNext;

  @override
  State<_WinDialog> createState() => _WinDialogState();
}

class _WinDialogState extends State<_WinDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return GlassCard(
      tint: theme.goldAccent,
      radius: AppTheme.radiusLarge + 4,
      highlighted: true,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: AppTheme.dialogDecoration(
        tint: theme.goldAccent,
        theme: theme,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hero Icon with pulsing ambient glow
          _HeroIcon(
            icon: Icons.emoji_events_rounded,
            tint: theme.goldAccent,
            secondaryTint: theme.warmAccent,
            animation: _anim,
          ),
          const SizedBox(height: 24),

          // Gradient Title
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _anim,
              curve: const Interval(0.2, 0.8),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.white, theme.goldAccent.withValues(alpha: 0.8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                'LEVEL COMPLETE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Stats Row
          SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _anim,
                    curve: const Interval(0.4, 0.9, curve: Curves.easeOutBack),
                  ),
                ),
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _anim,
                curve: const Interval(0.4, 0.9),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.monetization_on_rounded,
                      label: 'COINS',
                      value: '+${widget.coinsEarned}',
                      tint: theme.goldAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.auto_awesome_rounded,
                      label: 'NEXT STAGE',
                      value: 'Lv ${widget.nextLevel}',
                      tint: theme.secondaryAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Actions
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _anim,
              curve: const Interval(0.6, 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WideButton(
                  label: 'CONTINUE',
                  icon: Icons.arrow_forward_rounded,
                  tint: theme.goldAccent,
                  primary: true,
                  onTap: widget.onNext,
                ),
                const SizedBox(height: 12),
                _WideButton(
                  label: 'MAIN MENU',
                  icon: Icons.home_rounded,
                  tint: theme.primaryAccent,
                  primary: false,
                  onTap: widget.onHome,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverDialog extends StatefulWidget {
  const _GameOverDialog({
    required this.moveCount,
    required this.moveLimit,
    required this.hintsRemaining,
    required this.onHome,
    required this.onRestart,
  });

  final int moveCount;
  final int moveLimit;
  final int hintsRemaining;
  final VoidCallback onHome;
  final VoidCallback onRestart;

  @override
  State<_GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<_GameOverDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return GlassCard(
      tint: theme.warmAccent,
      radius: AppTheme.radiusLarge + 4,
      highlighted: true,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: AppTheme.dialogDecoration(
        tint: theme.warmAccent,
        theme: theme,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HeroIcon(
            icon: Icons.hourglass_bottom_rounded,
            tint: theme.warmAccent,
            secondaryTint: theme.dangerAccent,
            animation: _anim,
          ),
          const SizedBox(height: 24),

          FadeTransition(
            opacity: CurvedAnimation(
              parent: _anim,
              curve: const Interval(0.2, 0.8),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.white, theme.warmAccent.withValues(alpha: 0.8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: Text(
                'OUT OF MOVES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _anim,
                    curve: const Interval(0.4, 0.9, curve: Curves.easeOutBack),
                  ),
                ),
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _anim,
                curve: const Interval(0.4, 0.9),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.swap_vert_rounded,
                      label: 'MOVES',
                      value: '${widget.moveCount}/${widget.moveLimit}',
                      tint: theme.warmAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.lightbulb_outline_rounded,
                      label: 'HINTS',
                      value: '${widget.hintsRemaining}',
                      tint: theme.goldAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          FadeTransition(
            opacity: CurvedAnimation(
              parent: _anim,
              curve: const Interval(0.6, 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WideButton(
                  label: 'TRY AGAIN',
                  icon: Icons.refresh_rounded,
                  tint: theme.warmAccent,
                  primary: true,
                  onTap: widget.onRestart,
                ),
                const SizedBox(height: 12),
                _WideButton(
                  label: 'MAIN MENU',
                  icon: Icons.home_rounded,
                  tint: theme.primaryAccent,
                  primary: false,
                  onTap: widget.onHome,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({
    required this.icon,
    required this.tint,
    required this.secondaryTint,
    required this.animation,
  });

  final IconData icon;
  final Color tint;
  final Color secondaryTint;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow pulse
          FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.2).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.5, 1.0),
              ),
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.6).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                ),
              ),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: tint.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          // Solid inner circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [tint, secondaryTint],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tint.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.16), width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tint, size: 14),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _WideButton extends StatelessWidget {
  const _WideButton({
    required this.label,
    required this.icon,
    required this.tint,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GamePressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: primary
              ? LinearGradient(
                  colors: [tint, Color.lerp(tint, theme.primaryAccent, 0.35)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: primary ? null : tint.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primary
                ? Colors.white.withValues(alpha: 0.2)
                : tint.withValues(alpha: 0.3),
            width: primary ? 1.0 : 1.5,
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: tint.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: primary ? Colors.white : theme.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: primary ? Colors.white : theme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
