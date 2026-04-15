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
import '../services/ad_service.dart';
import '../services/coin_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_config.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/bottle_widget.dart';
import '../widgets/game_ui.dart';

enum _DoubleCoinsClaimResult {
  claimed,
  alreadyClaimed,
  unavailable,
  failedToShow,
  closedWithoutReward,
  rewardHandlerFailed,
}

enum _ExtraMovesClaimResult {
  claimed,
  alreadyClaimed,
  unavailable,
  failedToShow,
  closedWithoutReward,
  rewardHandlerFailed,
}

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
  int? _rewardCompletionLevel;
  DateTime? _rewardCompletionStartedAt;
  bool _baseRewardCreditedForCompletion = false;
  bool _doubleCoinsClaimedForCompletion = false;
  bool _doubleCoinsClaimInFlight = false;
  int? _extraMovesAttemptLevel;
  DateTime? _extraMovesAttemptStartedAt;
  bool _extraMovesRewardUsedForAttempt = false;
  bool _extraMovesOfferShowing = false;
  bool _extraMovesClaimInFlight = false;

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

  void _prepareRewardCompletion(GameState state) {
    if (_rewardCompletionLevel == state.level &&
        _rewardCompletionStartedAt == state.levelStartTime) {
      return;
    }

    _rewardCompletionLevel = state.level;
    _rewardCompletionStartedAt = state.levelStartTime;
    _baseRewardCreditedForCompletion = false;
    _doubleCoinsClaimedForCompletion = false;
    _doubleCoinsClaimInFlight = false;
  }

  bool _isCurrentRewardCompletion({
    required int level,
    required DateTime levelStartedAt,
  }) {
    return _rewardCompletionLevel == level &&
        _rewardCompletionStartedAt == levelStartedAt;
  }

  void _prepareExtraMovesAttempt(GameState state) {
    if (_extraMovesAttemptLevel == state.level &&
        _extraMovesAttemptStartedAt == state.levelStartTime) {
      return;
    }

    _extraMovesAttemptLevel = state.level;
    _extraMovesAttemptStartedAt = state.levelStartTime;
    _extraMovesRewardUsedForAttempt = false;
    _extraMovesOfferShowing = false;
    _extraMovesClaimInFlight = false;
  }

  bool _isCurrentExtraMovesAttempt({
    required int level,
    required DateTime levelStartedAt,
  }) {
    return _extraMovesAttemptLevel == level &&
        _extraMovesAttemptStartedAt == levelStartedAt;
  }

  Future<_DoubleCoinsClaimResult> _claimDoubleCoinsReward({
    required BuildContext context,
    required int level,
    required DateTime levelStartedAt,
    required int earnedCoins,
  }) async {
    if (!_isCurrentRewardCompletion(
      level: level,
      levelStartedAt: levelStartedAt,
    )) {
      return _DoubleCoinsClaimResult.failedToShow;
    }
    if (_doubleCoinsClaimedForCompletion) {
      return _DoubleCoinsClaimResult.alreadyClaimed;
    }
    if (_doubleCoinsClaimInFlight) {
      return _DoubleCoinsClaimResult.failedToShow;
    }

    _doubleCoinsClaimInFlight = true;
    var bonusCredited = false;
    final shopCubit = context.read<ShopCubit>();

    final result = await AdService.instance.showRewardedAd(
      onUserEarnedReward: (_) async {
        if (!_isCurrentRewardCompletion(
              level: level,
              levelStartedAt: levelStartedAt,
            ) ||
            _doubleCoinsClaimedForCompletion) {
          return;
        }

        await shopCubit.addCoins(earnedCoins);
        _doubleCoinsClaimedForCompletion = true;
        bonusCredited = true;
      },
    );

    _doubleCoinsClaimInFlight = false;

    return switch (result) {
      RewardedAdShowResult.earned =>
        bonusCredited
            ? _DoubleCoinsClaimResult.claimed
            : _DoubleCoinsClaimResult.rewardHandlerFailed,
      RewardedAdShowResult.unavailable => _DoubleCoinsClaimResult.unavailable,
      RewardedAdShowResult.failedToShow => _DoubleCoinsClaimResult.failedToShow,
      RewardedAdShowResult.closedWithoutReward =>
        _DoubleCoinsClaimResult.closedWithoutReward,
      RewardedAdShowResult.rewardHandlerFailed =>
        _DoubleCoinsClaimResult.rewardHandlerFailed,
    };
  }

  Future<_ExtraMovesClaimResult> _claimExtraMovesReward({
    required BuildContext context,
    required int level,
    required DateTime levelStartedAt,
  }) async {
    if (!_isCurrentExtraMovesAttempt(
      level: level,
      levelStartedAt: levelStartedAt,
    )) {
      return _ExtraMovesClaimResult.failedToShow;
    }
    if (_extraMovesRewardUsedForAttempt) {
      return _ExtraMovesClaimResult.alreadyClaimed;
    }
    if (_extraMovesClaimInFlight) {
      return _ExtraMovesClaimResult.failedToShow;
    }

    _extraMovesClaimInFlight = true;
    var movesGranted = false;
    final gameCubit = context.read<GameCubit>();

    final result = await AdService.instance.showRewardedAd(
      onUserEarnedReward: (_) async {
        if (!_isCurrentExtraMovesAttempt(
              level: level,
              levelStartedAt: levelStartedAt,
            ) ||
            _extraMovesRewardUsedForAttempt) {
          return;
        }

        gameCubit.addExtraMoves(3);
        _extraMovesRewardUsedForAttempt = true;
        movesGranted = true;
      },
    );

    _extraMovesClaimInFlight = false;

    return switch (result) {
      RewardedAdShowResult.earned =>
        movesGranted
            ? _ExtraMovesClaimResult.claimed
            : _ExtraMovesClaimResult.rewardHandlerFailed,
      RewardedAdShowResult.unavailable => _ExtraMovesClaimResult.unavailable,
      RewardedAdShowResult.failedToShow => _ExtraMovesClaimResult.failedToShow,
      RewardedAdShowResult.closedWithoutReward =>
        _ExtraMovesClaimResult.closedWithoutReward,
      RewardedAdShowResult.rewardHandlerFailed =>
        _ExtraMovesClaimResult.rewardHandlerFailed,
    };
  }

  Future<void> _handleLevelWon(BuildContext context, GameState state) async {
    _prepareRewardCompletion(state);
    final reward = CoinService.rewardForLevel(state.level);
    final settingsCubit = context.read<SettingsCubit>();
    final shopCubit = context.read<ShopCubit>();

    settingsCubit.playWinSound();
    settingsCubit.triggerHeavyHaptic();

    if (!_baseRewardCreditedForCompletion) {
      await shopCubit.addCoinsFromLevelReward(state.level);
      _baseRewardCreditedForCompletion = true;
    }

    if (!context.mounted) return;
    _showWinDialog(
      context,
      reward,
      completedLevel: state.level,
      levelStartedAt: state.levelStartTime,
    );
  }

  Future<void> _handleGameOver(BuildContext context, GameState state) async {
    _prepareExtraMovesAttempt(state);

    if (_extraMovesRewardUsedForAttempt || _extraMovesOfferShowing) {
      _showFinalGameOverDialog(context, state);
      return;
    }

    _extraMovesOfferShowing = true;
    context.read<SettingsCubit>().triggerHeavyHaptic();

    final rescued = await _showExtraMovesOfferDialog(context, state);
    _extraMovesOfferShowing = false;

    if (!context.mounted || rescued == true) return;

    final currentState = context.read<GameCubit>().state;
    if (currentState.status == GameStatus.gameOver) {
      _showFinalGameOverDialog(context, currentState);
    }
  }

  void _showFinalGameOverDialog(BuildContext context, GameState state) {
    context.read<SettingsCubit>().playFailSound();
    context.read<SettingsCubit>().triggerHeavyHaptic();
    _showGameOverDialog(context, state);
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
          prev.status != curr.status ||
          prev.level != curr.level ||
          prev.levelStartTime != curr.levelStartTime,
      listener: (context, state) {
        _prepareExtraMovesAttempt(state);
        if (state.status == GameStatus.animating && !_isAnimating) {
          _startPourAnimation();
        }
        if (state.status == GameStatus.won) {
          _handleLevelWon(context, state);
          return;
        }
        if (state.status == GameStatus.gameOver) {
          _handleGameOver(context, state);
          return;
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
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          // Tight outer insets keep the gameplay chrome from stealing
                          // height from the center board on shorter devices.
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final metrics =
                                  _GameScreenViewportMetrics.resolve(
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
                                    child: _buildBottleGrid(
                                      context,
                                      state,
                                      metrics,
                                    ),
                                  ),
                                  SizedBox(height: metrics.sectionSpacing),
                                  _buildBottomBar(context, state, metrics),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const BannerAdWidget(),
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

  Widget _buildHeader(
    BuildContext context,
    GameState state,
    _GameScreenViewportMetrics metrics,
  ) {
    final theme = AppTheme.of(context);
    final movesLeft = max(0, state.moveLimit - state.moveCount);
    final isLowMoves = _shouldWarnLowMoves(state);
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
                child: AnimatedBuilder(
                  animation: _wobbleController,
                  builder: (context, child) {
                    return _CompactHeaderChip(
                      icon: Icons.swap_vert_rounded,
                      label: 'Moves',
                      value: '$movesLeft',
                      tint: isLowMoves ? theme.dangerAccent : theme.goldAccent,
                      compact: metrics.isCompact,
                      warning: isLowMoves,
                      warningProgress: _wobbleController.value,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _shouldWarnLowMoves(GameState state) {
    if (state.moveLimit <= 0 || state.status == GameStatus.won) return false;
    final movesLeft = state.moveLimit - state.moveCount;
    final activeBottles = state.bottles
        .where((bottle) => bottle.isNotEmpty && !bottle.isSolved)
        .length;
    final boardLooksTight =
        movesLeft <= 4 && activeBottles >= 3 && activeBottles > movesLeft;
    return movesLeft <= 3 || boardLooksTight || state.isOutOfMoves;
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
                          opacity: pourFrame.streamOpacity,
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
                    AdService.instance.handleUndoClick(
                      onUndoGranted: () {
                        context.read<GameCubit>().undo();
                      },
                      onAdFailed: () {},
                    );
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
            onTap: state.status == GameStatus.playing
                ? () {
                    context.read<SettingsCubit>().playClickSound();
                    context.read<SettingsCubit>().triggerLightHaptic();
                    AdService.instance.handleHintClick(
                      onHintGranted: () {
                        context.read<GameCubit>().getHint();
                      },
                      onAdFailed: () {},
                    );
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

  Future<T?> _showOverlayDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = false,
    String barrierLabel = 'Dialog',
  }) {
    return showGeneralDialog<T>(
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

  void _showWinDialog(
    BuildContext context,
    int coinsEarned, {
    required int completedLevel,
    required DateTime levelStartedAt,
  }) {
    _showOverlayDialog(
      context: context,
      barrierLabel: 'Level Complete',
      child: _WinDialog(
        coinsEarned: coinsEarned,
        doubleCoinsAlreadyClaimed: _doubleCoinsClaimedForCompletion,
        onDoubleCoins: () => _claimDoubleCoinsReward(
          context: context,
          level: completedLevel,
          levelStartedAt: levelStartedAt,
          earnedCoins: coinsEarned,
        ),
        onHome: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
        onNext: () {
          Navigator.of(context).pop();
          AdService.instance.handleLevelCompleted(
            onContinue: () {
              context.read<GameCubit>().nextLevel();
            },
          );
        },
      ),
    );
  }

  Future<bool?> _showExtraMovesOfferDialog(
    BuildContext context,
    GameState state,
  ) {
    return _showOverlayDialog<bool>(
      context: context,
      barrierLabel: 'Extra Moves',
      child: _ExtraMovesDialog(
        onWatchAd: () => _claimExtraMovesReward(
          context: context,
          level: state.level,
          levelStartedAt: state.levelStartTime,
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
    this.warning = false,
    this.warningProgress = 0.0,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final bool compact;
  final bool warning;
  final double warningProgress;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final iconSize = compact ? 14.0 : 15.0;
    final warningPulse = warning
        ? 0.5 + (sin(warningProgress * 2 * pi) * 0.5)
        : 0.0;
    final warningShake = warning
        ? sin(warningProgress * 8 * pi) * (compact ? 0.45 : 0.65)
        : 0.0;
    final effectiveTint = warning
        ? Color.lerp(tint, theme.dangerAccent, 0.72)!
        : tint;
    final warningDecoration = warning
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(theme.surfaceStrong, Colors.white, 0.1)!,
                Color.lerp(
                  theme.surface,
                  theme.dangerAccent,
                  0.14 + (warningPulse * 0.07),
                )!,
                Color.lerp(theme.backgroundDeep, theme.dangerAccent, 0.08)!,
              ],
            ),
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            border: Border.all(
              color: theme.dangerAccent.withValues(
                alpha: 0.2 + (warningPulse * 0.16),
              ),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.dangerAccent.withValues(
                  alpha: 0.12 + (warningPulse * 0.12),
                ),
                blurRadius: 18 + (warningPulse * 8),
                spreadRadius: -8,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 18,
                spreadRadius: -12,
                offset: const Offset(0, 12),
              ),
            ],
          )
        : null;

    return Transform.translate(
      offset: Offset(warningShake, 0),
      child: GlassCard(
        tint: effectiveTint,
        radius: compact ? 16 : 18,
        blurSigma: 14,
        muted: true,
        decoration: warningDecoration,
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
                  Icon(
                    icon,
                    size: iconSize,
                    color: effectiveTint.withValues(alpha: 0.88),
                  ),
                  SizedBox(width: compact ? 4.0 : 5.0),
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: warning
                          ? Color.lerp(
                              theme.textMuted,
                              theme.dangerAccent,
                              0.22 + (warningPulse * 0.12),
                            )
                          : theme.textMuted,
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
                  color: warning
                      ? Color.lerp(
                          theme.textPrimary,
                          theme.dangerAccent,
                          0.12 + (warningPulse * 0.08),
                        )
                      : theme.textPrimary,
                  fontSize: compact ? 15 : 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  height: 1.0,
                ),
              ),
            ],
          ),
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
    required this.doubleCoinsAlreadyClaimed,
    required this.onDoubleCoins,
    required this.onHome,
    required this.onNext,
  });

  final int coinsEarned;
  final bool doubleCoinsAlreadyClaimed;
  final Future<_DoubleCoinsClaimResult> Function() onDoubleCoins;
  final VoidCallback onHome;
  final VoidCallback onNext;

  @override
  State<_WinDialog> createState() => _WinDialogState();
}

class _WinDialogState extends State<_WinDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late bool _doubleCoinsClaimed;
  bool _isClaimingDoubleCoins = false;
  String? _doubleCoinsMessage;
  bool _doubleCoinsMessageIsError = false;

  @override
  void initState() {
    super.initState();
    _doubleCoinsClaimed = widget.doubleCoinsAlreadyClaimed;
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

  Future<void> _handleDoubleCoinsTap() async {
    if (_isClaimingDoubleCoins || _doubleCoinsClaimed) return;

    setState(() {
      _isClaimingDoubleCoins = true;
      _doubleCoinsMessage = null;
      _doubleCoinsMessageIsError = false;
    });

    final result = await widget.onDoubleCoins();
    if (!mounted) return;

    setState(() {
      _isClaimingDoubleCoins = false;

      switch (result) {
        case _DoubleCoinsClaimResult.claimed:
        case _DoubleCoinsClaimResult.alreadyClaimed:
          _doubleCoinsClaimed = true;
          _doubleCoinsMessage = '2x Coins Claimed';
          _doubleCoinsMessageIsError = false;
          break;
        case _DoubleCoinsClaimResult.unavailable:
          _doubleCoinsMessage = 'Ad unavailable. Try again soon.';
          _doubleCoinsMessageIsError = true;
          break;
        case _DoubleCoinsClaimResult.failedToShow:
          _doubleCoinsMessage = 'Ad could not start. Try again.';
          _doubleCoinsMessageIsError = true;
          break;
        case _DoubleCoinsClaimResult.closedWithoutReward:
          _doubleCoinsMessage = 'Finish the ad to claim 2x.';
          _doubleCoinsMessageIsError = true;
          break;
        case _DoubleCoinsClaimResult.rewardHandlerFailed:
          _doubleCoinsMessage = 'Reward could not be added. Try again.';
          _doubleCoinsMessageIsError = true;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final displayedCoins = _doubleCoinsClaimed
        ? widget.coinsEarned * 2
        : widget.coinsEarned;

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
          const SizedBox(height: 12),

          // Reward summary
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
              child: _WinRewardSection(coinsEarned: displayedCoins),
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _anim,
              curve: const Interval(0.6, 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _WideButton(
                    label: 'HOME',
                    icon: Icons.home_rounded,
                    tint: theme.primaryAccent,
                    primary: false,
                    height: 44,
                    compact: true,
                    showIcon: false,
                    onTap: _isClaimingDoubleCoins ? null : widget.onHome,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _WideButton(
                    label: 'NEXT',
                    icon: Icons.arrow_forward_rounded,
                    tint: theme.goldAccent,
                    primary: true,
                    height: 44,
                    compact: true,
                    showIcon: false,
                    onTap: _isClaimingDoubleCoins ? null : widget.onNext,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DoubleCoinsRewardCard(
                    bonusCoins: widget.coinsEarned,
                    claimed: _doubleCoinsClaimed,
                    loading: _isClaimingDoubleCoins,
                    message: _doubleCoinsMessage,
                    messageIsError: _doubleCoinsMessageIsError,
                    height: 44,
                    onTap: _doubleCoinsClaimed || _isClaimingDoubleCoins
                        ? null
                        : _handleDoubleCoinsTap,
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

class _WinRewardSection extends StatelessWidget {
  const _WinRewardSection({required this.coinsEarned});

  final int coinsEarned;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'COINS',
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 5),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.white,
                theme.goldAccent,
                theme.warmAccent.withValues(alpha: 0.94),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              '+$coinsEarned',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                height: 0.95,
                shadows: [
                  Shadow(
                    color: theme.goldAccent.withValues(alpha: 0.26),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoubleCoinsRewardCard extends StatelessWidget {
  const _DoubleCoinsRewardCard({
    required this.bonusCoins,
    required this.claimed,
    required this.loading,
    required this.message,
    required this.messageIsError,
    required this.onTap,
    this.height = 50,
  });

  final int bonusCoins;
  final bool claimed;
  final bool loading;
  final String? message;
  final bool messageIsError;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final hasErrorMessage = message != null && messageIsError;
    final tint = claimed
        ? theme.successAccent
        : hasErrorMessage
        ? theme.dangerAccent
        : theme.warmAccent;
    final enabled = onTap != null && !claimed && !loading;
    const label = 'WATCH AD';
    return SizedBox(
      width: double.infinity,
      height: height,
      child: GamePressable(
        onTap: enabled ? onTap : null,
        pressedScale: 0.97,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled || claimed || loading ? 1 : 0.62,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                width: double.infinity,
                height: height,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tint.withValues(alpha: claimed ? 0.22 : 0.26),
                      theme.surfaceStrong.withValues(alpha: 0.72),
                      theme.surfaceMuted.withValues(alpha: 0.88),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: tint.withValues(alpha: claimed ? 0.36 : 0.28),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tint.withValues(alpha: claimed ? 0.18 : 0.14),
                      blurRadius: 14,
                      spreadRadius: -8,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          label,
                          key: ValueKey<String>(label),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!claimed)
                Positioned(
                  top: -8,
                  right: 4,
                  child: _DoubleCoinsBonusBadge(
                    bonusCoins: bonusCoins,
                    tint: theme.goldAccent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoubleCoinsBonusBadge extends StatelessWidget {
  const _DoubleCoinsBonusBadge({required this.bonusCoins, required this.tint});

  final int bonusCoins;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 74),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tint.withValues(alpha: 0.34), width: 1),
          boxShadow: [
            BoxShadow(
              color: tint.withValues(alpha: 0.18),
              blurRadius: 10,
              spreadRadius: -5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            '×2 +$bonusCoins',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExtraMovesDialog extends StatefulWidget {
  const _ExtraMovesDialog({required this.onWatchAd});

  final Future<_ExtraMovesClaimResult> Function() onWatchAd;

  @override
  State<_ExtraMovesDialog> createState() => _ExtraMovesDialogState();
}

class _ExtraMovesDialogState extends State<_ExtraMovesDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  bool _isLoadingAd = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _handleWatchAd() async {
    if (_isLoadingAd) return;

    setState(() {
      _isLoadingAd = true;
    });

    final result = await widget.onWatchAd();
    if (!mounted) return;

    switch (result) {
      case _ExtraMovesClaimResult.claimed:
      case _ExtraMovesClaimResult.alreadyClaimed:
        Navigator.of(context).pop(true);
        return;
      case _ExtraMovesClaimResult.unavailable:
      case _ExtraMovesClaimResult.failedToShow:
      case _ExtraMovesClaimResult.closedWithoutReward:
      case _ExtraMovesClaimResult.rewardHandlerFailed:
        Navigator.of(context).pop(false);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return GlassCard(
      tint: theme.dangerAccent,
      radius: AppTheme.radiusLarge + 4,
      highlighted: true,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: AppTheme.dialogDecoration(
        tint: theme.dangerAccent,
        theme: theme,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HeroIcon(
            icon: Icons.warning_amber_rounded,
            tint: theme.dangerAccent,
            secondaryTint: theme.warmAccent,
            animation: _anim,
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _anim,
              curve: const Interval(0.2, 0.8),
            ),
            child: Text(
              'Need More Moves?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Watch an ad to get 3 extra moves and keep playing',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          _RecoveryDialogButton(
            label: _isLoadingAd ? 'LOADING AD' : 'WATCH AD',
            icon: _isLoadingAd
                ? Icons.hourglass_top_rounded
                : Icons.play_circle_fill_rounded,
            tint: theme.dangerAccent,
            primary: true,
            rewardBadge: true,
            onTap: _isLoadingAd ? null : _handleWatchAd,
          ),
          const SizedBox(height: 10),
          _RecoveryDialogButton(
            label: 'NO THANKS',
            icon: Icons.close_rounded,
            tint: theme.textMuted,
            primary: false,
            onTap: _isLoadingAd ? null : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

class _RecoveryDialogButton extends StatelessWidget {
  const _RecoveryDialogButton({
    required this.label,
    required this.icon,
    required this.tint,
    required this.primary,
    required this.onTap,
    this.rewardBadge = false,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final bool primary;
  final VoidCallback? onTap;
  final bool rewardBadge;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final enabled = onTap != null;

    return Center(
      child: SizedBox(
        width: 198,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            GamePressable(
              onTap: onTap,
              pressedScale: 0.96,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: enabled ? 1 : 0.48,
                child: Container(
                  width: double.infinity,
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: primary
                        ? LinearGradient(
                            colors: [
                              tint,
                              Color.lerp(tint, theme.warmAccent, 0.28)!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: primary ? null : tint.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primary
                          ? Colors.white.withValues(alpha: 0.18)
                          : tint.withValues(alpha: 0.28),
                    ),
                    boxShadow: primary
                        ? [
                            BoxShadow(
                              color: tint.withValues(alpha: 0.24),
                              blurRadius: 14,
                              spreadRadius: -5,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: primary ? Colors.white : theme.textPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primary ? Colors.white : theme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (rewardBadge)
              Positioned(
                right: 12,
                top: -9,
                child: IgnorePointer(
                  child: _ExtraMovesRewardBadge(tint: theme.goldAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExtraMovesRewardBadge extends StatelessWidget {
  const _ExtraMovesRewardBadge({required this.tint});

  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tint.withValues(alpha: 0.95),
            Color.lerp(tint, theme.dangerAccent, 0.18)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.22),
            blurRadius: 10,
            spreadRadius: -5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.swap_vert_rounded,
            color: theme.backgroundDeep.withValues(alpha: 0.82),
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            '+3',
            style: TextStyle(
              color: theme.backgroundDeep.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
              height: 1.0,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.16), width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    this.height = 54,
    this.compact = false,
    this.showIcon = true,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final bool primary;
  final VoidCallback? onTap;
  final double height;
  final bool compact;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final enabled = onTap != null;
    return GamePressable(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : 0.46,
        child: Container(
          width: double.infinity,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 0),
          decoration: BoxDecoration(
            gradient: primary
                ? LinearGradient(
                    colors: [
                      tint,
                      Color.lerp(tint, theme.primaryAccent, 0.35)!,
                    ],
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
                      blurRadius: compact ? 12 : 16,
                      spreadRadius: compact ? -5 : -2,
                      offset: Offset(0, compact ? 5 : 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showIcon) ...[
                Icon(
                  icon,
                  color: primary ? Colors.white : theme.textPrimary,
                  size: compact ? 16 : 20,
                ),
                SizedBox(width: compact ? 5 : 10),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primary ? Colors.white : theme.textPrimary,
                    fontSize: compact ? 11 : 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: compact ? 0.2 : 0.5,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
