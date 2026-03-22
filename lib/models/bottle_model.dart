import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Maximum number of color segments a bottle can hold.
const int kMaxBottleCapacity = 4;

/// Represents a single bottle in the Water Sort puzzle.
///
/// Each bottle contains a list of [colors] where index 0 is the bottom-most
/// color segment and the last index is the top-most.
class BottleModel extends Equatable {
  /// The list of color segments in this bottle.
  /// Index 0 = bottom, last index = top.
  final List<Color> colors;

  /// Unique identifier for this bottle.
  final int id;

  const BottleModel({
    required this.id,
    required this.colors,
  });

  /// Whether this bottle is completely empty.
  bool get isEmpty => colors.isEmpty;

  /// Whether this bottle has at least one color segment.
  bool get isNotEmpty => colors.isNotEmpty;

  /// Whether this bottle is completely filled.
  bool get isFull => colors.length >= kMaxBottleCapacity;

  /// Whether this bottle contains a single color and is completely filled.
  /// This means the bottle is "solved".
  bool get isSolved =>
      colors.length == kMaxBottleCapacity &&
      colors.every((c) => c.toARGB32() == colors.first.toARGB32());

  /// The topmost color in the bottle, or null if empty.
  Color? get topColor => colors.isNotEmpty ? colors.last : null;

  /// How many consecutive segments from the top share the same color.
  int get topColorCount {
    if (colors.isEmpty) return 0;
    int count = 1;
    for (int i = colors.length - 2; i >= 0; i--) {
      if (colors[i].toARGB32() == colors.last.toARGB32()) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// The number of empty slots remaining.
  int get emptySlots => kMaxBottleCapacity - colors.length;

  /// Current fill level as a fraction (0.0 to 1.0).
  double get fillLevel => colors.length / kMaxBottleCapacity;

  /// Creates a copy with an added color segment on top.
  BottleModel addColor(Color color) {
    assert(!isFull, 'Cannot add to a full bottle');
    return BottleModel(
      id: id,
      colors: [...colors, color],
    );
  }

  /// Creates a copy with the top color segment removed.
  BottleModel removeTop() {
    assert(!isEmpty, 'Cannot remove from an empty bottle');
    return BottleModel(
      id: id,
      colors: colors.sublist(0, colors.length - 1),
    );
  }

  /// Creates a deep copy of this bottle.
  BottleModel copyWith({int? id, List<Color>? colors}) {
    return BottleModel(
      id: id ?? this.id,
      colors: colors ?? List<Color>.from(this.colors),
    );
  }

  @override
  List<Object?> get props => [id, colors.map((c) => c.toARGB32()).toList()];
}

/// Represents a single pour move for undo functionality.
class PourMove extends Equatable {
  final int sourceIndex;
  final int destIndex;
  final int colorCount; // number of segments poured

  const PourMove({
    required this.sourceIndex,
    required this.destIndex,
    required this.colorCount,
  });

  @override
  List<Object?> get props => [sourceIndex, destIndex, colorCount];
}
