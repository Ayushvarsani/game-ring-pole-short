import 'package:flutter_test/flutter_test.dart';
import 'package:mind_color_pour/models/bottle_model.dart';
import 'package:flutter/material.dart';

void main() {
  group('BottleModel', () {
    test('empty bottle reports isEmpty', () {
      final bottle = BottleModel(id: 0, colors: []);
      expect(bottle.isEmpty, true);
      expect(bottle.isNotEmpty, false);
    });

    test('full bottle reports isFull', () {
      final bottle = BottleModel(
        id: 0,
        colors: [Colors.red, Colors.red, Colors.red, Colors.red],
      );
      expect(bottle.isFull, true);
    });

    test('solved bottle detection', () {
      final solved = BottleModel(
        id: 0,
        colors: [Colors.blue, Colors.blue, Colors.blue, Colors.blue],
      );
      expect(solved.isSolved, true);

      final notSolved = BottleModel(
        id: 1,
        colors: [Colors.blue, Colors.red, Colors.blue, Colors.blue],
      );
      expect(notSolved.isSolved, false);
    });

    test('topColorCount counts consecutive top colors', () {
      final bottle = BottleModel(
        id: 0,
        colors: [Colors.red, Colors.blue, Colors.blue, Colors.blue],
      );
      expect(bottle.topColorCount, 3);
    });
  });
}
