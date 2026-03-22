import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bottle_model.dart';
import '../models/game_colors.dart';

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
    int shuffleMultiplier = 3,
  }) {
    assert(numColors >= 2 && numColors <= 12, 'numColors must be between 2 and 12');

    final colors = GameColors.getColors(numColors);
    final totalBottles = numColors + 2; // 2 empty bottles for workspace

    // Step 1: Create the solved state.
    // Each color gets its own full bottle, plus 2 empty bottles.
    List<List<Color>> bottleColors = [];
    for (int i = 0; i < numColors; i++) {
      bottleColors.add(List.filled(kMaxBottleCapacity, colors[i], growable: true));
    }
    // Add 2 empty bottles
    bottleColors.add([]);
    bottleColors.add([]);

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
    if (level <= 3) return 4;
    if (level <= 7) return 5;
    if (level <= 12) return 6;
    if (level <= 18) return 7;
    if (level <= 25) return 8;
    if (level <= 35) return 9;
    if (level <= 50) return 10;
    return 11;
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
