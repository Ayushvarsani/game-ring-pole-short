import 'dart:math';

import 'package:flutter/material.dart';

import '../models/fill_type.dart';
import '../models/game_colors.dart';

class PouringStreamPainter extends CustomPainter {
  PouringStreamPainter({
    required this.start,
    required this.end,
    required this.color,
    required this.progress,
    required this.flowPhase,
    this.fillType = FillType.liquid,
  });

  final Offset start;
  final Offset end;
  final Color color;
  final double progress;
  final double flowPhase;
  final FillType fillType;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || start == Offset.zero || end == Offset.zero) return;

    final curve = _buildCurve();
    if (fillType != FillType.liquid) {
      _paintObjects(canvas, curve);
      return;
    }

    final points = _sampleCurve(curve);
    if (points.length < 2) return;

    final outerPath = _buildStreamShape(points, widthMultiplier: 1.0);
    final innerPath = _buildStreamShape(points, widthMultiplier: 0.44);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(outerPath, glowPaint);

    final streamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          GameColors.lighten(color, 0.16),
          color,
          GameColors.darken(color, 0.16),
        ],
      ).createShader(Rect.fromPoints(start, end))
      ..style = PaintingStyle.fill;
    canvas.drawPath(outerPath, streamPaint);

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.36),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromPoints(start, end))
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerPath, highlightPaint);

    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(_buildCenterLine(points), edgePaint);

    if (progress > 0.26) {
      final tip = points.last;
      final dropletRect = Rect.fromCenter(
        center: tip + const Offset(0, 2),
        width: 8,
        height: 12,
      );
      final dropletPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GameColors.lighten(color, 0.12), color],
        ).createShader(dropletRect);
      canvas.drawOval(dropletRect, dropletPaint);
    }
  }

  _CurveData _buildCurve() {
    final distance = (end - start).distance;
    final direction = end.dx >= start.dx ? 1.0 : -1.0;
    final controlHeight = min(88.0, distance * 0.36 + 14);
    final controlA = Offset(
      start.dx + (distance * 0.18 * direction),
      start.dy - controlHeight,
    );
    final controlB = Offset(
      end.dx - (distance * 0.14 * direction),
      end.dy - (controlHeight * 0.34),
    );
    return _CurveData(controlA: controlA, controlB: controlB);
  }

  List<Offset> _sampleCurve(_CurveData curve) {
    final points = <Offset>[];
    const samples = 42;
    final visibleEnd = progress.clamp(0.0, 1.0);

    for (int i = 0; i <= samples; i++) {
      final t = (i / samples) * visibleEnd;
      final oneMinusT = 1 - t;
      final point =
          (start * (oneMinusT * oneMinusT * oneMinusT)) +
          (curve.controlA * (3 * oneMinusT * oneMinusT * t)) +
          (curve.controlB * (3 * oneMinusT * t * t)) +
          (end * (t * t * t));
      points.add(point);
    }
    return points;
  }

  Path _buildStreamShape(
    List<Offset> points, {
    required double widthMultiplier,
  }) {
    final leftSide = <Offset>[];
    final rightSide = <Offset>[];
    final baseWidth = 5.8 * widthMultiplier;

    for (int i = 0; i < points.length; i++) {
      final t = i / max(1, points.length - 1);
      final widthFactor = 0.2 + sin(t * pi) * 0.82;
      final halfWidth = baseWidth * widthFactor;

      Offset tangent;
      if (i == 0) {
        tangent = points[1] - points[0];
      } else if (i == points.length - 1) {
        tangent = points[i] - points[i - 1];
      } else {
        tangent = points[i + 1] - points[i - 1];
      }
      final length = tangent.distance;
      if (length == 0) continue;

      final normal = Offset(-tangent.dy / length, tangent.dx / length);
      final flowDisplacement = sin((t * 7.5 * pi) + flowPhase) * 0.7;

      leftSide.add(points[i] + normal * (halfWidth + flowDisplacement));
      rightSide.add(points[i] - normal * (halfWidth - flowDisplacement));
    }

    final path = Path();
    if (leftSide.isEmpty) return path;
    path.moveTo(leftSide.first.dx, leftSide.first.dy);
    for (final point in leftSide.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    for (final point in rightSide.reversed) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    return path;
  }

  Path _buildCenterLine(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  void _paintObjects(Canvas canvas, _CurveData curve) {
    const objectCount = 3;
    for (int i = 0; i < objectCount; i++) {
      final t = ((flowPhase * 1.4) + (i / objectCount)) % 1.0;
      final visible = progress < 0.2
          ? (progress / 0.2).clamp(0.0, 1.0)
          : (progress > 0.85 ? ((1.0 - progress) / 0.15).clamp(0.0, 1.0) : 1.0);
      if (visible <= 0) continue;

      final oneMinusT = 1 - t;
      final point =
          (start * (oneMinusT * oneMinusT * oneMinusT)) +
          (curve.controlA * (3 * oneMinusT * oneMinusT * t)) +
          (curve.controlB * (3 * oneMinusT * t * t)) +
          (end * (t * t * t));
      final radius = 8.5 * visible;

      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.scale(visible, visible);
      if (fillType == FillType.balls) {
        final paint = Paint()
          ..shader = RadialGradient(
            colors: [
              GameColors.lighten(color, 0.2),
              color,
              GameColors.darken(color, 0.22),
            ],
            stops: const [0.0, 0.55, 1.0],
            center: const Alignment(-0.3, -0.3),
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
        canvas.drawCircle(Offset.zero, radius, paint);
      } else if (fillType == FillType.blocks) {
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: radius * 2,
          height: radius * 2,
        );
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              GameColors.lighten(color, 0.14),
              color,
              GameColors.darken(color, 0.16),
            ],
          ).createShader(rect);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          paint,
        );
      } else if (fillType == FillType.stars) {
        _drawStar(canvas, 0, 0, radius, color);
      } else if (fillType == FillType.diamonds) {
        _drawDiamond(canvas, 0, 0, radius, color);
      }
      canvas.restore();
    }
  }

  void _drawStar(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    Color color,
  ) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * pi / 5) - pi / 2;
      final x = cx + cos(angle) * radius;
      final y = cy + sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          GameColors.lighten(color, 0.18),
          color,
          GameColors.darken(color, 0.16),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawPath(path, paint);
  }

  void _drawDiamond(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    Color color,
  ) {
    final path = Path()
      ..moveTo(cx, cy - radius)
      ..lineTo(cx + radius * 0.78, cy)
      ..lineTo(cx, cy + radius)
      ..lineTo(cx - radius * 0.78, cy)
      ..close();
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          GameColors.lighten(color, 0.16),
          color,
          GameColors.darken(color, 0.16),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant PouringStreamPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.flowPhase != flowPhase ||
        oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.fillType != fillType ||
        oldDelegate.color != color;
  }
}

class _CurveData {
  const _CurveData({required this.controlA, required this.controlB});

  final Offset controlA;
  final Offset controlB;
}
