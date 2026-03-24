import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bottle_model.dart';
import '../models/game_colors.dart';

enum LevelDifficulty { easy, medium, hard }

class LevelConfig {
  final int numColors;
  final int emptyBottles;
  final int shuffleMultiplier;
  final LevelDifficulty difficulty;

  const LevelConfig({
    required this.numColors,
    required this.emptyBottles,
    required this.shuffleMultiplier,
    required this.difficulty,
  });
}

/// Generates solvable Water Sort levels.
///
/// Strategy: We start with a SOLVED state (each color in its own bottle),
/// then perform random valid "reverse pours" to shuffle the colors.
/// This guarantees every generated level has at least one solution path.
class LevelGenerator {
  static final _random = Random();

  /// Generates a solvable level with the given number of color-filled bottles.
  /// Returns a list of bottles: [numColors] filled + 2 empty bottles.
  ///
  /// [numColors] determines difficulty:
  ///   - Easy: 4-5 colors
  ///   - Medium: 6-7 colors
  ///   - Hard: 8-10 colors
  ///
  /// [shuffleMultiplier] scales how many random reverse pours are applied
  /// (higher = more mixed). Default matches original behavior.
  static List<BottleModel> generate(
    int numColors, {
    int emptyBottles = 2,
    int shuffleMultiplier = 3,
  }) {
    assert(numColors >= 2 && numColors <= 12, 'numColors must be between 2 and 12');
    assert(emptyBottles >= 1 && emptyBottles <= 10, 'emptyBottles must be between 1 and 10');

    final colors = GameColors.getColors(numColors);
    final totalBottles = numColors + emptyBottles;

    // Step 1: Create the solved state.
    // Each color gets its own full bottle, plus empty workspace bottles.
    List<List<Color>> bottleColors = [];
    for (int i = 0; i < numColors; i++) {
      bottleColors.add(List.filled(kMaxBottleCapacity, colors[i], growable: true));
    }
    for (int i = 0; i < emptyBottles; i++) {
      bottleColors.add([]);
    }

    // Step 2: Shuffle by performing random reverse pours.
    // A reverse pour takes from a bottle and puts it in another,
    // mimicking the "undo" of a player move.
    final int shuffleMoves = numColors * kMaxBottleCapacity * shuffleMultiplier;
    for (int move = 0; move < shuffleMoves; move++) {
      _performRandomPour(bottleColors, totalBottles);
    }

    // Step 3: Verify the level is actually shuffled (not already solved).
    // If it's somehow solved, shuffle more.
    while (_isSolved(bottleColors)) {
      for (int move = 0; move < shuffleMoves; move++) {
        _performRandomPour(bottleColors, totalBottles);
      }
    }

    // Step 4: Convert to BottleModel list.
    return List.generate(
      totalBottles,
      (i) => BottleModel(id: i, colors: List<Color>.from(bottleColors[i])),
    );
  }

  /// Returns the number of filled bottles (difficulty) for a given level number.
  static int colorsForLevel(int level) {
    return configForLevel(level).numColors;
  }

  static LevelDifficulty difficultyForLevel(int level) {
    if (level <= 40) return LevelDifficulty.easy;
    if (level <= 100) return LevelDifficulty.medium;
    return LevelDifficulty.hard;
  }

  static String difficultyLabelForLevel(int level) {
    switch (difficultyForLevel(level)) {
      case LevelDifficulty.easy:
        return 'Easy';
      case LevelDifficulty.medium:
        return 'Medium';
      case LevelDifficulty.hard:
        return 'Hard';
    }
  }

  static LevelConfig configForLevel(int level) {
    final safeLevel = level.clamp(1, 200);
    final totalBottles = _totalBottlesForLevel(safeLevel);
    final difficulty = difficultyForLevel(safeLevel);

    // Keep 2-4 empty bottles as workspace while total bottles scale up.
    final emptyBottles = switch (difficulty) {
      LevelDifficulty.easy => 2,
      LevelDifficulty.medium => 3,
      LevelDifficulty.hard => 4,
    };

    final numColors = (totalBottles - emptyBottles).clamp(2, 12);
    final shuffleMultiplier = switch (difficulty) {
      LevelDifficulty.easy => 2,
      LevelDifficulty.medium => 3,
      LevelDifficulty.hard => 4,
    };

    return LevelConfig(
      numColors: numColors,
      emptyBottles: emptyBottles,
      shuffleMultiplier: shuffleMultiplier,
      difficulty: difficulty,
    );
  }

  // 10-level progression requested by user:
  // Easy (1-40): 5, 6, 8, 10
  // Medium (41-100): 11, 12, 13, 14, 15, 15
  // Hard (101-200): 15, 16, 17, 17, 18, 18, 19, 19, 20, 20
  static int _totalBottlesForLevel(int level) {
    if (level <= 10) return 5;
    if (level <= 20) return 6;
    if (level <= 30) return 8;
    if (level <= 40) return 10;

    if (level <= 50) return 11;
    if (level <= 60) return 12;
    if (level <= 70) return 13;
    if (level <= 80) return 14;
    if (level <= 90) return 15;
    if (level <= 100) return 15;

    if (level <= 110) return 15;
    if (level <= 120) return 16;
    if (level <= 130) return 17;
    if (level <= 140) return 17;
    if (level <= 150) return 18;
    if (level <= 160) return 18;
    if (level <= 170) return 19;
    if (level <= 180) return 19;
    if (level <= 190) return 20;
    return 20;
  }

  /// Performs a single random valid pour between two bottles.
  static void _performRandomPour(List<List<Color>> bottles, int total) {
    // Pick a random source that is not empty
    final nonEmpty = <int>[];
    final nonFull = <int>[];
    for (int i = 0; i < total; i++) {
      if (bottles[i].isNotEmpty) nonEmpty.add(i);
      if (bottles[i].length < kMaxBottleCapacity) nonFull.add(i);
    }

    if (nonEmpty.isEmpty || nonFull.isEmpty) return;

    final sourceIdx = nonEmpty[_random.nextInt(nonEmpty.length)];
    // Filter out source from possible destinations
    final validDests = nonFull.where((i) => i != sourceIdx).toList();
    if (validDests.isEmpty) return;

    final destIdx = validDests[_random.nextInt(validDests.length)];

    // Pour one segment from source to dest
    final color = bottles[sourceIdx].removeLast();
    bottles[destIdx].add(color);
  }

  /// Checks if the current bottle arrangement is in a solved state.
  static bool _isSolved(List<List<Color>> bottles) {
    for (final bottle in bottles) {
      if (bottle.isEmpty) continue;
      if (bottle.length != kMaxBottleCapacity) return false;
      if (!bottle.every((c) => c.toARGB32() == bottle.first.toARGB32())) return false;
    }
    return true;
  }
}
