import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bottle_model.dart';
import '../models/game_colors.dart';

/// CustomPainter that renders a single bottle with liquid.
///
/// Handles:
/// - Glass bottle shape with rounded bottom
/// - Liquid segments with realistic coloring
/// - Surface wave wobble using sine wave
/// - Tilt animation for pouring
/// - Liquid level animation (decrease/increase)
/// - Glass highlights and reflections
class LiquidPainter extends CustomPainter {
  /// The bottle data to render.
  final BottleModel bottle;

  /// Tilt angle in radians. Positive = tilts right, Negative = tilts left.
  final double tiltAngle;

  /// Animation progress for the liquid level change (0.0 to 1.0).
  /// For source: level decreases as this progresses.
  /// For destination: level increases.
  final double levelProgress;

  /// Whether this bottle is currently the source of a pour.
  final bool isSource;

  /// Number of segments being poured (used for level calculation).
  final int pourCount;

  /// Whether this bottle is currently selected by the player.
  final bool isSelected;

  /// Time-based wobble phase for the sine wave animation.
  final double wobblePhase;

  /// Whether the bottle is solved (all same color and full).
  final bool isSolved;

  LiquidPainter({
    required this.bottle,
    this.tiltAngle = 0.0,
    this.levelProgress = 0.0,
    this.isSource = false,
    this.pourCount = 0,
    this.isSelected = false,
    this.wobblePhase = 0.0,
    this.isSolved = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Bottle dimensions ──
    // The bottle is drawn within the given size.
    // We leave some padding at top for the bottle neck/opening.
    final bottleWidth = w * 0.7;
    final bottleHeight = h * 0.75;
    final neckWidth = bottleWidth * 0.45;
    final neckHeight = h * 0.15;
    final cornerRadius = bottleWidth * 0.2;

    // Center horizontally
    final left = (w - bottleWidth) / 2;
    final right = left + bottleWidth;
    final top = h - bottleHeight;
    final bottom = h;
    final neckLeft = (w - neckWidth) / 2;
    final neckRight = neckLeft + neckWidth;
    final neckTop = top - neckHeight;

    // ── Save canvas state for tilt ──
    canvas.save();
    if (tiltAngle != 0.0) {
      // Pivot point: the mouth of the bottle (top-center of neck)
      // When tilting right, pivot is at the right edge of the mouth
      // When tilting left, pivot is at the left edge of the mouth
      final pivotX = tiltAngle > 0 ? neckRight : neckLeft;
      final pivotY = neckTop;
      canvas.translate(pivotX, pivotY);
      canvas.rotate(tiltAngle);
      canvas.translate(-pivotX, -pivotY);
    }

    // ── Draw bottle glass (background) ──
    _drawBottleGlass(canvas, left, right, top, bottom, neckLeft, neckRight,
        neckTop, cornerRadius, bottleWidth, bottleHeight, neckHeight, w, h);

    // ── Draw liquid segments ──
    _drawLiquid(canvas, left, right, top, bottom, neckLeft, neckRight,
        neckTop, cornerRadius, bottleWidth, bottleHeight, w, h);

    // ── Draw bottle glass overlay (reflections/highlights) ──
    _drawGlassHighlights(canvas, left, right, top, bottom, neckLeft,
        neckRight, neckTop, cornerRadius, bottleWidth, bottleHeight, w, h);

    // ── Draw selection indicator ──
    if (isSelected) {
      _drawSelectionGlow(canvas, left, right, top, bottom, neckLeft,
          neckRight, neckTop, cornerRadius, w, h);
    }

    // ── Draw solved checkmark ──
    if (isSolved) {
      _drawSolvedIndicator(canvas, w, h, neckTop);
    }

    canvas.restore();
  }

  /// Draws the glass bottle outline and inner shadow.
  void _drawBottleGlass(
    Canvas canvas,
    double left,
    double right,
    double top,
    double bottom,
    double neckLeft,
    double neckRight,
    double neckTop,
    double cornerRadius,
    double bottleWidth,
    double bottleHeight,
    double neckHeight,
    double w,
    double h,
  ) {
    // Bottle body path with rounded bottom and straight neck
    final bodyPath = Path()
      // Start at neck top-left
      ..moveTo(neckLeft, neckTop)
      // Left side of neck down to body
      ..lineTo(neckLeft, top + 2)
      // Transition from neck to body (left side curve)
      ..quadraticBezierTo(neckLeft, top, left + cornerRadius * 0.3, top)
      ..lineTo(left, top + cornerRadius * 0.3)
      // Left side of body down
      ..lineTo(left, bottom - cornerRadius)
      // Bottom-left corner
      ..quadraticBezierTo(left, bottom, left + cornerRadius, bottom)
      // Bottom side
      ..lineTo(right - cornerRadius, bottom)
      // Bottom-right corner
      ..quadraticBezierTo(right, bottom, right, bottom - cornerRadius)
      // Right side up
      ..lineTo(right, top + cornerRadius * 0.3)
      // Right side transition curve
      ..lineTo(neckRight - cornerRadius * 0.3 + (right - neckRight), top)
      ..quadraticBezierTo(neckRight, top, neckRight, top + 2)
      // Right side of neck up
      ..lineTo(neckRight, neckTop)
      ..close();

    // Glass fill (semi-transparent)
    final glassPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, glassPaint);

    // Glass border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(bodyPath, borderPaint);

    // Mouth rim (top of neck)
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(neckLeft - 1, neckTop),
      Offset(neckRight + 1, neckTop),
      rimPaint,
    );
  }

  /// Draws the liquid inside the bottle.
  void _drawLiquid(
    Canvas canvas,
    double left,
    double right,
    double top,
    double bottom,
    double neckLeft,
    double neckRight,
    double neckTop,
    double cornerRadius,
    double bottleWidth,
    double bottleHeight,
    double w,
    double h,
  ) {
    if (bottle.isEmpty) return;

    final colors = bottle.colors;
    final segmentCount = colors.length;

    // ── Calculate effective fill ──
    double effectiveSegments = segmentCount.toDouble();
    if (isSource && pourCount > 0) {
      effectiveSegments = segmentCount - (pourCount * levelProgress);
    }

    // Create a clipping region for the bottle's interior
    final clipPath = Path()
      ..moveTo(left + 1.5, top + cornerRadius * 0.3)
      ..lineTo(left + 1.5, bottom - cornerRadius)
      ..quadraticBezierTo(
          left + 1.5, bottom - 1.5, left + cornerRadius, bottom - 1.5)
      ..lineTo(right - cornerRadius, bottom - 1.5)
      ..quadraticBezierTo(
          right - 1.5, bottom - 1.5, right - 1.5, bottom - cornerRadius)
      ..lineTo(right - 1.5, top + cornerRadius * 0.3)
      ..close();

    // Mapping effectiveSegments to world bounds height.
    Matrix4 matrix = Matrix4.identity();
    if (tiltAngle != 0.0) {
      final pivotX = tiltAngle > 0 ? neckRight : neckLeft;
      final pivotY = neckTop;
      matrix.translate(pivotX, pivotY);
      matrix.rotateZ(tiltAngle);
      matrix.translate(-pivotX, -pivotY);
    }
    
    Path worldClipPath = clipPath.transform(matrix.storage);
    Rect worldBounds = worldClipPath.getBounds();

    double segmentHeight = worldBounds.height / kMaxBottleCapacity;
    double currentWorldBottom = worldBounds.bottom;

    for (int i = 0; i < segmentCount; i++) {
      double thisSegHeight;
      if (i < segmentCount - 1) {
        thisSegHeight = segmentHeight;
      } else {
        final fullSegments = effectiveSegments.floor();
        if (i < fullSegments) {
          thisSegHeight = segmentHeight;
        } else {
          final fraction = effectiveSegments - fullSegments;
          if (i == fullSegments) {
            thisSegHeight = segmentHeight * fraction;
          } else {
            continue;
          }
        }
      }

      if (thisSegHeight <= 0) continue;

      final segTop = currentWorldBottom - thisSegHeight;
      final color = colors[i];

      canvas.save();
      // Clip canvas to bottle body shape
      canvas.clipPath(clipPath);

      // Additional save so we can remove the Y-band constraint but keep the bottle shape constraint
      canvas.save();

      // Clip to the World Y band for this segment
      if (tiltAngle != 0.0) {
        final pivotX = tiltAngle > 0 ? neckRight : neckLeft;
        final pivotY = neckTop;
        canvas.translate(pivotX, pivotY);
        canvas.rotate(-tiltAngle);
        canvas.translate(-pivotX, -pivotY);
        
        canvas.clipRect(Rect.fromLTRB(worldBounds.left - 20, segTop, worldBounds.right + 20, currentWorldBottom));

        canvas.translate(pivotX, pivotY);
        canvas.rotate(tiltAngle);
        canvas.translate(-pivotX, -pivotY);
      } else {
        canvas.clipRect(Rect.fromLTRB(left - 20, segTop, right + 20, currentWorldBottom));
      }

      // Draw the entire liquid local rect
      final liquidRect = Rect.fromLTRB(left + 1.5, top, right - 1.5, bottom);

      // Gradient for depth effect
      final gradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          GameColors.darken(color, 0.12),
          color,
          GameColors.lighten(color, 0.08),
          color,
          GameColors.darken(color, 0.1),
        ],
        stops: const [0.0, 0.2, 0.45, 0.7, 1.0],
      );

      final liquidPaint = Paint()
        ..shader = gradient.createShader(liquidRect)
        ..style = PaintingStyle.fill;
      canvas.drawRect(liquidRect, liquidPaint);
      canvas.restore(); // Restore local clip state

      // Draw the wobble surface in World Space exactly at segTop
      if (i == segmentCount - 1 || (isSource && i == segmentCount - 1)) {
        canvas.save();
        if (tiltAngle != 0.0) {
          final pivotX = tiltAngle > 0 ? neckRight : neckLeft;
          final pivotY = neckTop;
          canvas.translate(pivotX, pivotY);
          canvas.rotate(-tiltAngle);
          canvas.translate(-pivotX, -pivotY);
        }
        _drawWobbleSurface(canvas, worldBounds.left - 20, worldBounds.right + 20, segTop, color);
        canvas.restore();
      }

      // ── Segment divider line (subtle) ──
      if (i > 0) {
        // Draw divider line in World Space
        canvas.save();
        if (tiltAngle != 0.0) {
          final pivotX = tiltAngle > 0 ? neckRight : neckLeft;
          final pivotY = neckTop;
          canvas.translate(pivotX, pivotY);
          canvas.rotate(-tiltAngle);
          canvas.translate(-pivotX, -pivotY);
        }
        final dividerPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.08)
          ..strokeWidth = 0.5;
        canvas.drawLine(
          Offset(worldBounds.left - 20, currentWorldBottom),
          Offset(worldBounds.right + 20, currentWorldBottom),
          dividerPaint,
        );
        canvas.restore();
      }

      currentWorldBottom = segTop;

      // Restore the bottle shape clip so the next segment starts fresh
      canvas.restore();
    }

    canvas.restore();
  }

  /// Draws the wobble/wave effect on the liquid surface.
  ///
  /// Uses a sine wave: y = amplitude * sin(frequency * x + phase)
  /// where:
  ///   - amplitude scales with recent activity
  ///   - frequency creates 2-3 visible waves across the surface
  ///   - phase animates over time for the "slosh" effect
  void _drawWobbleSurface(
    Canvas canvas,
    double left,
    double right,
    double surfaceY,
    Color color,
  ) {
    final width = right - left;
    // Wave amplitude: small for idle, larger during pour
    final amplitude = isSource ? 3.0 : 1.5;

    // Frequency: 2 full waves across the surface width
    // ω = 2π * numWaves / width
    final frequency = 2.0 * pi * 2.0 / width;

    final wavePath = Path()..moveTo(left, surfaceY);

    // Generate the sine wave path across the surface
    for (double x = left; x <= right; x += 1.0) {
      // y = surfaceY + amplitude * sin(frequency * (x - left) + wobblePhase)
      final y = surfaceY + amplitude * sin(frequency * (x - left) + wobblePhase);
      wavePath.lineTo(x, y);
    }

    // Close the path by going down and across the bottom
    wavePath.lineTo(right, surfaceY + amplitude + 4);
    wavePath.lineTo(left, surfaceY + amplitude + 4);
    wavePath.close();

    // Fill with a slightly lighter color for the surface highlight
    final surfacePaint = Paint()
      ..color = GameColors.lighten(color, 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(wavePath, surfacePaint);
  }

  /// Draws glass highlights and reflections.
  void _drawGlassHighlights(
    Canvas canvas,
    double left,
    double right,
    double top,
    double bottom,
    double neckLeft,
    double neckRight,
    double neckTop,
    double cornerRadius,
    double bottleWidth,
    double bottleHeight,
    double w,
    double h,
  ) {
    // Left edge highlight (simulates light reflection)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final highlightPath = Path()
      ..moveTo(neckLeft + 2, neckTop + 2)
      ..lineTo(left + 3, top + cornerRadius + 5)
      ..lineTo(left + 3, bottom - cornerRadius - 5);

    canvas.drawPath(highlightPath, highlightPaint);

    // Small circular highlight near top-left of body
    final shinePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(left + bottleWidth * 0.25, top + bottleHeight * 0.2),
        radius: bottleWidth * 0.15,
      ))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(left + bottleWidth * 0.25, top + bottleHeight * 0.2),
      bottleWidth * 0.15,
      shinePaint,
    );
  }

  /// Draws a glow effect around the selected bottle.
  void _drawSelectionGlow(
    Canvas canvas,
    double left,
    double right,
    double top,
    double bottom,
    double neckLeft,
    double neckRight,
    double neckTop,
    double cornerRadius,
    double w,
    double h,
  ) {
    final glowPaint = Paint()
      ..color = const Color(0xFF64FFDA).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8.0);

    final glowPath = Path()
      ..moveTo(neckLeft, neckTop)
      ..lineTo(neckLeft, top + 2)
      ..quadraticBezierTo(neckLeft, top, left + cornerRadius * 0.3, top)
      ..lineTo(left, top + cornerRadius * 0.3)
      ..lineTo(left, bottom - cornerRadius)
      ..quadraticBezierTo(left, bottom, left + cornerRadius, bottom)
      ..lineTo(right - cornerRadius, bottom)
      ..quadraticBezierTo(right, bottom, right, bottom - cornerRadius)
      ..lineTo(right, top + cornerRadius * 0.3)
      ..lineTo(neckRight - cornerRadius * 0.3 + (right - neckRight), top)
      ..quadraticBezierTo(neckRight, top, neckRight, top + 2)
      ..lineTo(neckRight, neckTop);

    canvas.drawPath(glowPath, glowPaint);

    // Inner glow
    glowPaint
      ..color = const Color(0xFF64FFDA).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(glowPath, glowPaint);
  }

  /// Draws a checkmark above solved bottles.
  void _drawSolvedIndicator(Canvas canvas, double w, double h, double neckTop) {
    final centerX = w / 2;
    final checkY = neckTop - 12;

    final checkPaint = Paint()
      ..color = const Color(0xFF69F0AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(centerX - 6, checkY)
      ..lineTo(centerX - 2, checkY + 5)
      ..lineTo(centerX + 7, checkY - 4);

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant LiquidPainter oldDelegate) {
    return oldDelegate.bottle != bottle ||
        oldDelegate.tiltAngle != tiltAngle ||
        oldDelegate.levelProgress != levelProgress ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.wobblePhase != wobblePhase ||
        oldDelegate.isSource != isSource ||
        oldDelegate.pourCount != pourCount ||
        oldDelegate.isSolved != isSolved;
  }
}
