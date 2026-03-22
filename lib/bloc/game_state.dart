import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../models/bottle_model.dart';

/// Possible states of the game.
enum GameStatus {
  playing,
  won,
  animating, // While pour animation is running
}

/// The complete game state managed by GameCubit.
class GameState extends Equatable {
  /// Current list of bottles.
  final List<BottleModel> bottles;

  /// Current level number.
  final int level;

  /// Index of the currently selected (source) bottle, or -1 if none.
  final int selectedBottleIndex;

  /// Current game status.
  final GameStatus status;

  /// Stack of moves for undo functionality.
  final List<PourMove> moveHistory;

  /// Total number of moves made this level.
  final int moveCount;

  /// Total undos used this level.
  final int undoCount;

  /// Timestamp when the level started.
  final DateTime levelStartTime;

  // ── Animation state ──

  /// Source bottle index during pour animation.
  final int animSourceIndex;

  /// Destination bottle index during pour animation.
  final int animDestIndex;

  /// Number of color segments being poured.
  final int animColorCount;

  /// The color being poured.
  final Color animColor;

  const GameState({
    required this.bottles,
    required this.level,
    this.selectedBottleIndex = -1,
    this.status = GameStatus.playing,
    this.moveHistory = const [],
    this.moveCount = 0,
    this.undoCount = 0,
    required this.levelStartTime,
    this.animSourceIndex = -1,
    this.animDestIndex = -1,
    this.animColorCount = 0,
    this.animColor = Colors.transparent,
  });

  /// Creates a copy with overridden fields.
  GameState copyWith({
    List<BottleModel>? bottles,
    int? level,
    int? selectedBottleIndex,
    GameStatus? status,
    List<PourMove>? moveHistory,
    int? moveCount,
    int? undoCount,
    DateTime? levelStartTime,
    int? animSourceIndex,
    int? animDestIndex,
    int? animColorCount,
    Color? animColor,
  }) {
    return GameState(
      bottles: bottles ?? this.bottles,
      level: level ?? this.level,
      selectedBottleIndex: selectedBottleIndex ?? this.selectedBottleIndex,
      status: status ?? this.status,
      moveHistory: moveHistory ?? this.moveHistory,
      moveCount: moveCount ?? this.moveCount,
      undoCount: undoCount ?? this.undoCount,
      levelStartTime: levelStartTime ?? this.levelStartTime,
      animSourceIndex: animSourceIndex ?? this.animSourceIndex,
      animDestIndex: animDestIndex ?? this.animDestIndex,
      animColorCount: animColorCount ?? this.animColorCount,
      animColor: animColor ?? this.animColor,
    );
  }

  /// Whether the game has been won (all bottles solved or empty).
  bool get isWon => bottles.every((b) => b.isEmpty || b.isSolved);

  @override
  List<Object?> get props => [
        bottles,
        level,
        selectedBottleIndex,
        status,
        moveHistory,
        moveCount,
        undoCount,
        levelStartTime,
        animSourceIndex,
        animDestIndex,
        animColorCount,
        animColor,
      ];
}
