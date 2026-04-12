import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/bottle_model.dart';
import '../services/level_generator.dart';
import '../services/level_progress_service.dart';
import '../services/analytics_service.dart';
import 'game_state.dart';

/// Cubit that manages all game logic for the Water Sort puzzle.
///
/// Handles:
/// - Level initialization and progression
/// - Bottle selection and pour validation
/// - Undo functionality
/// - Animation state coordination
/// - Win detection
class GameCubit extends Cubit<GameState> {
  static const int maxLevel = 200;
  final FirebaseAnalyticsService _analytics;

  GameCubit({FirebaseAnalyticsService? analytics, int initialLevel = 1})
    : _analytics = analytics ?? FirebaseAnalyticsService(),
      super(
        GameState(
          bottles: const [],
          level: initialLevel.clamp(1, maxLevel),
          levelStartTime: DateTime.now(),
        ),
      ) {
    startLevel(initialLevel);
  }

  /// Start a new level.
  void startLevel(int level) {
    final safeLevel = level.clamp(1, maxLevel);
    final config = LevelGenerator.configForLevel(safeLevel);
    final numColors = config.numColors;
    final bottles = LevelGenerator.generate(
      numColors,
      emptyBottles: config.emptyBottles,
      shuffleMultiplier: config.shuffleMultiplier,
    );
    final moveLimit = _moveLimitForLevel(safeLevel, numColors);

    emit(
      GameState(
        bottles: bottles,
        level: safeLevel,
        moveLimit: moveLimit,
        levelStartTime: DateTime.now(),
      ),
    );

    _analytics.logLevelStarted(level: safeLevel, numColors: numColors);
  }

  /// Restart the current level.
  void restartLevel() {
    startLevel(state.level);
  }

  /// Handle a bottle tap.
  ///
  /// If no bottle is selected → select this bottle (if it's not empty).
  /// If this bottle is already selected → deselect.
  /// If another bottle is selected → attempt to pour.
  void onBottleTap(int bottleIndex) {
    if (state.status != GameStatus.playing) return;

    // Clear hint when player interacts
    clearHint();

    final currentSelected = state.selectedBottleIndex;

    if (currentSelected == -1) {
      // No selection yet → select if not empty
      if (state.bottles[bottleIndex].isEmpty) return;
      emit(state.copyWith(selectedBottleIndex: bottleIndex));
    } else if (currentSelected == bottleIndex) {
      // Same bottle tapped → deselect
      emit(state.copyWith(selectedBottleIndex: -1));
    } else {
      // Different bottle tapped → try to pour
      _attemptPour(currentSelected, bottleIndex);
    }
  }

  /// Attempt to pour from [sourceIdx] to [destIdx].
  void _attemptPour(int sourceIdx, int destIdx) {
    final source = state.bottles[sourceIdx];
    final dest = state.bottles[destIdx];

    // Validation
    if (source.isEmpty) {
      emit(state.copyWith(selectedBottleIndex: -1));
      return;
    }
    if (dest.isFull) {
      emit(state.copyWith(selectedBottleIndex: -1));
      return;
    }

    final sourceColor = source.topColor!;

    // Destination must be empty OR have matching top color
    if (dest.isNotEmpty &&
        dest.topColor!.toARGB32() != sourceColor.toARGB32()) {
      // Invalid pour → select the tapped bottle instead if it's not empty
      if (dest.isEmpty) {
        emit(state.copyWith(selectedBottleIndex: -1));
      } else {
        emit(state.copyWith(selectedBottleIndex: destIdx));
      }
      return;
    }

    // Calculate how many segments we can pour
    // (consecutive same-color from source top, limited by dest capacity)
    final pourCount = source.topColorCount.clamp(0, dest.emptySlots);
    if (pourCount == 0) {
      emit(state.copyWith(selectedBottleIndex: -1));
      return;
    }

    // Start the animation phase
    emit(
      state.copyWith(
        status: GameStatus.animating,
        selectedBottleIndex: -1,
        animSourceIndex: sourceIdx,
        animDestIndex: destIdx,
        animColorCount: pourCount,
        animColor: sourceColor,
      ),
    );

    // The actual state mutation happens when the animation completes.
    // See [completePour].
  }

  /// Called when the pour animation finishes.
  /// Applies the actual color transfer and checks for win.
  void completePour() {
    final sourceIdx = state.animSourceIndex;
    final destIdx = state.animDestIndex;
    final pourCount = state.animColorCount;
    final color = state.animColor;

    if (sourceIdx == -1 || destIdx == -1) return;

    // Apply the pour: remove from source, add to dest
    final newBottles = List<BottleModel>.from(
      state.bottles.map((b) => b.copyWith()),
    );

    for (int i = 0; i < pourCount; i++) {
      newBottles[sourceIdx] = newBottles[sourceIdx].removeTop();
    }
    for (int i = 0; i < pourCount; i++) {
      newBottles[destIdx] = newBottles[destIdx].addColor(color);
    }

    // Record the move
    final newHistory = [
      ...state.moveHistory,
      PourMove(
        sourceIndex: sourceIdx,
        destIndex: destIdx,
        colorCount: pourCount,
      ),
    ];

    final playedState = state.copyWith(
      bottles: newBottles,
      status: GameStatus.playing,
      moveHistory: newHistory,
      moveCount: state.moveCount + 1,
      animSourceIndex: -1,
      animDestIndex: -1,
      animColorCount: 0,
      animColor: Colors.transparent,
    );

    // Check for win
    if (playedState.isWon) {
      final duration = DateTime.now()
          .difference(state.levelStartTime)
          .inSeconds;
      _analytics.logLevelCompleted(
        level: state.level,
        moves: playedState.moveCount,
        undosUsed: playedState.undoCount,
        durationSeconds: duration,
      );
      LevelProgressService.saveAfterLevelCompleted(state.level);
      emit(playedState.copyWith(status: GameStatus.won));
    } else if (playedState.isOutOfMoves) {
      emit(playedState.copyWith(status: GameStatus.gameOver));
    } else {
      emit(playedState);
    }

    // Log analytics
    _analytics.logBottlePoured(
      sourceBottle: sourceIdx,
      destBottle: destIdx,
      colorCount: pourCount,
    );
  }

  /// Undo the last move.
  void undo() {
    if (state.status == GameStatus.animating) return;
    if (state.moveHistory.isEmpty) return;

    final lastMove = state.moveHistory.last;

    // Reverse the pour
    final newBottles = List<BottleModel>.from(
      state.bottles.map((b) => b.copyWith()),
    );

    // Get the color that was poured (it's at the top of destination)
    final color = newBottles[lastMove.destIndex].topColor!;

    // Remove from destination and add back to source
    for (int i = 0; i < lastMove.colorCount; i++) {
      newBottles[lastMove.destIndex] = newBottles[lastMove.destIndex]
          .removeTop();
    }
    for (int i = 0; i < lastMove.colorCount; i++) {
      newBottles[lastMove.sourceIndex] = newBottles[lastMove.sourceIndex]
          .addColor(color);
    }

    emit(
      state.copyWith(
        bottles: newBottles,
        moveHistory: state.moveHistory.sublist(0, state.moveHistory.length - 1),
        undoCount: state.undoCount + 1,
        selectedBottleIndex: -1,
      ),
    );

    _analytics.logUndoUsed(level: state.level, moveNumber: state.moveCount);
  }

  /// Show a hint by highlighting a valid pour move.
  void getHint() {
    if (state.status != GameStatus.playing) return;
    if (state.hintsRemaining <= 0) return;

    final bottles = state.bottles;

    // Find the best valid pour move
    for (int src = 0; src < bottles.length; src++) {
      if (bottles[src].isEmpty) continue;
      if (bottles[src].isSolved) continue;

      final sourceColor = bottles[src].topColor!;
      final pourCount = bottles[src].topColorCount;

      for (int dest = 0; dest < bottles.length; dest++) {
        if (dest == src) continue;
        if (bottles[dest].isFull) continue;

        // Destination must be empty or have matching top color
        if (bottles[dest].isNotEmpty &&
            bottles[dest].topColor!.toARGB32() != sourceColor.toARGB32()) {
          continue;
        }

        final canPour = pourCount.clamp(0, bottles[dest].emptySlots);
        if (canPour == 0) continue;

        // Skip pouring to an empty bottle if source only has one color
        // (pointless move)
        if (bottles[dest].isEmpty &&
            bottles[src].topColorCount == bottles[src].colors.length) {
          continue;
        }

        // Found a valid move — highlight it
        emit(
          state.copyWith(
            hintSourceIndex: src,
            hintDestIndex: dest,
            hintsRemaining: state.hintsRemaining - 1,
            selectedBottleIndex: -1,
          ),
        );

        _analytics.logHintUsed(level: state.level, moveNumber: state.moveCount);
        return;
      }
    }
  }

  /// Clear the hint highlight.
  void clearHint() {
    if (state.hintSourceIndex != -1 || state.hintDestIndex != -1) {
      emit(state.copyWith(hintSourceIndex: -1, hintDestIndex: -1));
    }
  }

  /// Advance to the next level.
  void nextLevel() {
    startLevel((state.level + 1).clamp(1, maxLevel));
  }

  int _moveLimitForLevel(int level, int numColors) {
    final config = LevelGenerator.configForLevel(level);
    final estimatedMinMoves = (config.numColors * 2) + config.emptyBottles;

    // Keep a small difficulty-based buffer above estimated minimum moves.
    final buffer = switch (config.difficulty) {
      LevelDifficulty.easy => 1,
      LevelDifficulty.medium => 2,
      LevelDifficulty.hard => 3,
    };

    return estimatedMinMoves + buffer;
  }
}
