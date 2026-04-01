import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_colors.dart';
import '../models/fill_type.dart';

/// Paints the liquid stream flowing from source bottle to destination bottle.
///
/// The stream is rendered as a curved path from the source mouth to the
/// destination mouth, with animated width and flow particles.
class PouringStreamPainter extends CustomPainter {
  /// Start point of the stream (source bottle mouth).
  final Offset start;

  /// End point of the stream (destination bottle mouth).
  final Offset end;

  /// The color being poured.
  final Color color;

  /// Animation progress (0.0 to 1.0). Controls stream length.
  final double progress;

  /// Time-based phase for flow animation.
  final double flowPhase;

  /// The user-selected fill type.
  final FillType fillType;

  PouringStreamPainter({
    required this.start,
    required this.end,
    required this.color,
    required this.progress,
    required this.flowPhase,
    this.fillType = FillType.liquid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    // ── Calculate the stream path ──
    // The stream arcs upward from source, then curves down to destination.
    // We use a quadratic bezier curve with a control point above both bottles.

    // Control point: midpoint horizontally, elevated above both points
    final midX = (start.dx + end.dx) / 2;
    // Arc height: higher arc for bottles that are further apart
    final distance = (end.dx - start.dx).abs();
    final arcHeight = min(distance * 0.4, 80.0);
    final controlY = min(start.dy, end.dy) - arcHeight;
    final controlPoint = Offset(midX, controlY);

    if (fillType != FillType.liquid) {
      final numObjects = 2; // 2 items flowing back-to-back
      for (int k = 0; k < numObjects; k++) {
        // Make 't' loop continuously from 0 to 1 based on flowPhase
        final t = ((flowPhase * 1.5 + k * (2 * pi / numObjects)) / (2 * pi)) % 1.0;
        
        final opacity = progress < 0.2 ? (progress / 0.2).clamp(0.0, 1.0) : (progress > 0.8 ? ((1.0 - progress) / 0.2).clamp(0.0, 1.0) : 1.0);
        if (opacity <= 0) continue;

        final oneMinusT = 1 - t;
        final cx = oneMinusT * oneMinusT * start.dx +
            2 * oneMinusT * t * controlPoint.dx +
            t * t * end.dx;
        final cy = oneMinusT * oneMinusT * start.dy +
            2 * oneMinusT * t * controlPoint.dy +
            t * t * end.dy;

        final baseR = 10.0;

        canvas.save();
        canvas.translate(cx, cy);
        canvas.scale(opacity, opacity);
        
        if (fillType == FillType.balls) {
          final paint = Paint()
            ..shader = RadialGradient(
              colors: [GameColors.lighten(color, 0.2), color, GameColors.darken(color, 0.2)],
              stops: const [0.0, 0.5, 1.0],
              center: const Alignment(-0.3, -0.3),
            ).createShader(Rect.fromCircle(center: Offset.zero, radius: baseR));
          canvas.drawCircle(Offset.zero, baseR, paint);
        } else if (fillType == FillType.blocks) {
          final rect = Rect.fromCenter(center: Offset.zero, width: baseR * 2, height: baseR * 2);
          final paint = Paint()..color = color..style = PaintingStyle.fill;
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
        } else if (fillType == FillType.stars) {
          _drawStar(canvas, 0, 0, baseR, color);
        } else if (fillType == FillType.diamonds) {
          _drawDiamond(canvas, 0, 0, baseR, color);
        }
        canvas.restore();
      }
      return;
    }

    // ── Draw the stream with varying width ──
    // The stream has a main body and a drip at the end.
    final streamWidth = 5.0;

    // Clamp the visible portion of the stream based on progress
    final streamPath = Path();

    // Generate points along the bezier curve
    final points = <Offset>[];
    final numPoints = 40;
    final visibleEnd = progress.clamp(0.0, 1.0);

    for (int i = 0; i <= numPoints; i++) {
      final t = (i / numPoints) * visibleEnd;

      // Quadratic Bezier formula:
      // B(t) = (1-t)² * P0 + 2(1-t)t * P1 + t² * P2
      final oneMinusT = 1 - t;
      final x = oneMinusT * oneMinusT * start.dx +
          2 * oneMinusT * t * controlPoint.dx +
          t * t * end.dx;
      final y = oneMinusT * oneMinusT * start.dy +
          2 * oneMinusT * t * controlPoint.dy +
          t * t * end.dy;
      points.add(Offset(x, y));
    }

    if (points.length < 2) return;

    // ── Create a thick stream path with variable width ──
    // Width tapers at start and end for natural look
    final leftSide = <Offset>[];
    final rightSide = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final t = i / (points.length - 1);

      // Width envelope: thin at start, full in middle, thin at end
      final widthFactor = sin(t * pi) * 0.8 + 0.2;
      final halfW = (streamWidth * widthFactor) / 2;

      // Calculate perpendicular direction
      Offset tangent;
      if (i == 0) {
        tangent = (points[1] - points[0]);
      } else if (i == points.length - 1) {
        tangent = (points[i] - points[i - 1]);
      } else {
        tangent = (points[i + 1] - points[i - 1]);
      }
      final len = tangent.distance;
      if (len == 0) continue;
      final normal = Offset(-tangent.dy / len, tangent.dx / len);

      // Add a subtle sine wave for "flow" effect
      // displacement = amplitude * sin(frequency * t + phase)
      final flowDisplacement = sin(t * 8 * pi + flowPhase) * 0.8;

      leftSide.add(points[i] + normal * (halfW + flowDisplacement));
      rightSide.add(points[i] - normal * (halfW - flowDisplacement));
    }

    // Build the stream shape
    if (leftSide.isNotEmpty) {
      streamPath.moveTo(leftSide.first.dx, leftSide.first.dy);
      for (final p in leftSide) {
        streamPath.lineTo(p.dx, p.dy);
      }
      for (final p in rightSide.reversed) {
        streamPath.lineTo(p.dx, p.dy);
      }
      streamPath.close();
    }

    // ── Paint the stream ──
    final streamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          GameColors.lighten(color, 0.1),
          color,
          GameColors.darken(color, 0.1),
        ],
      ).createShader(Rect.fromPoints(start, end))
      ..style = PaintingStyle.fill;

    canvas.drawPath(streamPath, streamPaint);

    // ── Highlight on stream ──
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    if (leftSide.length > 1) {
      final highlightPath = Path();
      highlightPath.moveTo(leftSide.first.dx, leftSide.first.dy);
      for (int i = 1; i < leftSide.length; i++) {
        highlightPath.lineTo(leftSide[i].dx, leftSide[i].dy);
      }
      canvas.drawPath(highlightPath, highlightPaint);
    }

    // ── Drip effect at the end of the stream ──
    if (progress > 0.3 && points.isNotEmpty) {
      final dripPoint = points.last;
      final dripRadius = streamWidth * 0.6;
      final dripPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: dripPoint + const Offset(0, 2),
          width: dripRadius * 2,
          height: dripRadius * 2.5,
        ),
        dripPaint,
      );
    }
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

  void _drawStar(Canvas canvas, double cx, double cy, double radius, Color color) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
        final outerAngle = (i * 4 * pi / 5) - pi / 2;
        final x = cx + cos(outerAngle) * radius;
        final y = cy + sin(outerAngle) * radius;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
    }
    path.close();
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  void _drawDiamond(Canvas canvas, double cx, double cy, double radius, Color color) {
    final path = Path()
      ..moveTo(cx, cy - radius)
      ..lineTo(cx + radius * 0.8, cy)
      ..lineTo(cx, cy + radius)
      ..lineTo(cx - radius * 0.8, cy)
      ..close();
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [GameColors.lighten(color, 0.1), GameColors.darken(color, 0.1)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawPath(path, paint);
  }
}
