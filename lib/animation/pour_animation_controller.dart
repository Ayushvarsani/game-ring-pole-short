import 'dart:math';

import 'package:flutter/material.dart';

import '../models/bottle_type.dart';
import '../painters/liquid_painter.dart';

class PourAnimationController {
  PourAnimationController({
    required TickerProvider vsync,
    this.duration = const Duration(milliseconds: 1200),
  }) : controller = AnimationController(vsync: vsync, duration: duration) {
    travel = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubicEmphasized)),
        weight: 24,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 62),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubicEmphasized)),
        weight: 14,
      ),
    ]).animate(controller);

    tilt = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 24),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 16,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 32),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 14,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 14),
    ]).animate(controller);

    stream = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutQuart)),
        weight: 8,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 18),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 6,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 28),
    ]).animate(controller);

    streamLength = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 8,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 24),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 28),
    ]).animate(controller);

    transfer = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 32,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 28),
    ]).animate(controller);
  }

  static const double maxTiltAngle = 1.46;
  static const double sourceBottleScale = 1.05;

  final Duration duration;
  final AnimationController controller;

  late final Animation<double> tilt;
  late final Animation<double> travel;
  late final Animation<double> stream;
  late final Animation<double> streamLength;
  late final Animation<double> transfer;

  _PourLayout? _layout;

  bool get hasLayout => _layout != null;

  PourAnimationFrame? get frame {
    final layout = _layout;
    if (layout == null) return null;

    final travelProgress = travel.value;
    final sourceTopLeft =
        layout.sourceTopLeft +
        (layout.travel * travelProgress) +
        Offset(0, -sin(travelProgress * pi) * 10.0);
    final sourceTiltAngle = layout.direction * maxTiltAngle * tilt.value;
    final destinationLiftY = -sin(transfer.value * pi) * 6.0;
    final destinationScale = 1.0 + (sin(transfer.value * pi) * 0.035);
    final streamOpacity = tilt.value >= 0.98 ? stream.value : 0.0;
    final activeStreamLength = streamOpacity > 0.01 ? streamLength.value : 0.0;

    return PourAnimationFrame(
      sourceTopLeft: sourceTopLeft,
      sourceTiltAngle: sourceTiltAngle,
      sourceScale: sourceBottleScale,
      destinationLiftY: destinationLiftY,
      destinationScale: destinationScale,
      transferProgress: transfer.value,
      streamProgress: activeStreamLength,
      streamOpacity: streamOpacity,
      streamStart: _transformBottlePoint(
        localPoint: layout.sourcePourPoint,
        bottleSize: layout.bottleSize,
        topLeft: sourceTopLeft,
        rotationPivot: layout.sourcePivot,
        rotation: sourceTiltAngle,
        scale: sourceBottleScale,
      ),
      streamEnd: _transformBottlePoint(
        localPoint: layout.destinationPourPoint,
        bottleSize: layout.bottleSize,
        topLeft: layout.destinationTopLeft + Offset(0, destinationLiftY),
        rotationPivot: layout.destinationPourPoint,
        rotation: 0.0,
        scale: destinationScale,
      ),
    );
  }

  bool prepare({
    required GlobalKey overlayKey,
    required GlobalKey sourceBottleKey,
    required GlobalKey destinationBottleKey,
    required BottleType bottleType,
    required Size bottleSize,
    required bool poursRight,
  }) {
    final overlayBox =
        overlayKey.currentContext?.findRenderObject() as RenderBox?;
    final sourceBox =
        sourceBottleKey.currentContext?.findRenderObject() as RenderBox?;
    final destinationBox =
        destinationBottleKey.currentContext?.findRenderObject() as RenderBox?;

    if (overlayBox == null ||
        sourceBox == null ||
        destinationBox == null ||
        !overlayBox.hasSize ||
        !sourceBox.hasSize ||
        !destinationBox.hasSize) {
      return false;
    }

    final geometry = BottleGeometry.fromSize(bottleSize, bottleType);
    final direction = poursRight ? 1.0 : -1.0;
    // Both bottle slots are converted into the overlay Stack's local space via
    // localToGlobal/globalToLocal so the floating source bottle and the stream
    // painter use the exact same coordinates.
    final sourceTopLeft = _convertToOverlay(sourceBox, overlayBox);
    final destinationTopLeft = _convertToOverlay(destinationBox, overlayBox);

    // The stream bug came from measuring only the bottle box and then guessing
    // a mouth offset. The bottle itself rotates inside LiquidPainter, so the
    // guessed point stayed in the old space and the stream fell straight down.
    final sourcePivot = Offset(
      direction > 0 ? geometry.neckRight : geometry.neckLeft,
      geometry.neckTop + 1,
    );
    final destinationPourPoint = Offset(geometry.centerX, geometry.neckTop + 1);

    final desiredSourceMouth =
        destinationTopLeft +
        destinationPourPoint +
        Offset(-direction * bottleSize.width * 0.5, -bottleSize.height * 0.26);

    final mouthAtFullTilt = _transformBottlePoint(
      localPoint: sourcePivot,
      bottleSize: bottleSize,
      topLeft: sourceTopLeft,
      rotationPivot: sourcePivot,
      rotation: direction * maxTiltAngle,
      scale: sourceBottleScale,
    );

    _layout = _PourLayout(
      sourceTopLeft: sourceTopLeft,
      destinationTopLeft: destinationTopLeft,
      bottleSize: bottleSize,
      sourcePivot: sourcePivot,
      sourcePourPoint: sourcePivot,
      destinationPourPoint: destinationPourPoint,
      travel: desiredSourceMouth - mouthAtFullTilt,
      direction: direction,
    );
    return true;
  }

  void reset() {
    controller.stop();
    controller.reset();
    _layout = null;
  }

  void dispose() {
    controller.dispose();
  }

  static Offset _convertToOverlay(RenderBox box, RenderBox overlayBox) {
    final globalTopLeft = box.localToGlobal(Offset.zero);
    return overlayBox.globalToLocal(globalTopLeft);
  }

  static Offset _transformBottlePoint({
    required Offset localPoint,
    required Size bottleSize,
    required Offset topLeft,
    required Offset rotationPivot,
    required double rotation,
    required double scale,
  }) {
    var point = localPoint;

    if (rotation != 0.0) {
      point = _rotateAround(point, rotationPivot, rotation);
    }

    if (scale != 1.0) {
      final center = Offset(bottleSize.width / 2, bottleSize.height / 2);
      point = center + ((point - center) * scale);
    }

    return topLeft + point;
  }

  static Offset _rotateAround(Offset point, Offset pivot, double angle) {
    final dx = point.dx - pivot.dx;
    final dy = point.dy - pivot.dy;
    final sinAngle = sin(angle);
    final cosAngle = cos(angle);
    return Offset(
      pivot.dx + (dx * cosAngle) - (dy * sinAngle),
      pivot.dy + (dx * sinAngle) + (dy * cosAngle),
    );
  }
}

class PourAnimationFrame {
  const PourAnimationFrame({
    required this.sourceTopLeft,
    required this.sourceTiltAngle,
    required this.sourceScale,
    required this.destinationLiftY,
    required this.destinationScale,
    required this.transferProgress,
    required this.streamProgress,
    required this.streamOpacity,
    required this.streamStart,
    required this.streamEnd,
  });

  final Offset sourceTopLeft;
  final double sourceTiltAngle;
  final double sourceScale;
  final double destinationLiftY;
  final double destinationScale;
  final double transferProgress;
  final double streamProgress;
  final double streamOpacity;
  final Offset streamStart;
  final Offset streamEnd;
}

class _PourLayout {
  const _PourLayout({
    required this.sourceTopLeft,
    required this.destinationTopLeft,
    required this.bottleSize,
    required this.sourcePivot,
    required this.sourcePourPoint,
    required this.destinationPourPoint,
    required this.travel,
    required this.direction,
  });

  final Offset sourceTopLeft;
  final Offset destinationTopLeft;
  final Size bottleSize;
  final Offset sourcePivot;
  final Offset sourcePourPoint;
  final Offset destinationPourPoint;
  final Offset travel;
  final double direction;
}
