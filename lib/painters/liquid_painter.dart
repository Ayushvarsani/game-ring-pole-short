import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bottle_model.dart';
import '../models/bottle_type.dart';
import '../models/fill_type.dart';
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

  /// Whether this bottle is currently the destination of a pour.
  final bool isDest;

  /// Number of segments being poured (used for level calculation).
  final int pourCount;

  /// The color being poured (if isDest is true, to know what color to fill).
  final Color? pourColor;

  /// Whether this bottle is currently selected by the player.
  final bool isSelected;

  /// Whether this bottle is highlighted as a hint.
  final bool isHint;

  /// Time-based wobble phase for the sine wave animation.
  final double wobblePhase;

  /// Whether the bottle is solved (all same color and full).
  final bool isSolved;

  /// Animation progress for the bottle cap dropping (0.0 = above, 1.0 = seated).
  final double capProgress;

  /// Animation progress for celebration particles (0.0 = start, 1.0 = done).
  final double celebrationProgress;

  /// The bottle shape type from the shop.
  final BottleType bottleType;

  /// The content type inside the bottle.
  final FillType fillType;

  LiquidPainter({
    required this.bottle,
    this.tiltAngle = 0.0,
    this.levelProgress = 0.0,
    this.isSource = false,
    this.isDest = false,
    this.pourCount = 0,
    this.pourColor,
    this.isSelected = false,
    this.isHint = false,
    this.wobblePhase = 0.0,
    this.isSolved = false,
    this.capProgress = 0.0,
    this.celebrationProgress = 0.0,
    this.bottleType = BottleType.classic,
    this.fillType = FillType.liquid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Bottle dimensions (vary by bottle type) ──
    late final double bottleWidth;
    late final double bottleHeight;
    late final double neckWidth;
    late final double neckHeight;
    late final double cornerRadius;

    switch (bottleType) {
      case BottleType.classic:
        bottleWidth = w * 0.7;
        bottleHeight = h * 0.75;
        neckWidth = bottleWidth * 0.45;
        neckHeight = h * 0.15;
        cornerRadius = bottleWidth * 0.2;
      case BottleType.round:
        bottleWidth = w * 0.8;
        bottleHeight = h * 0.7;
        neckWidth = bottleWidth * 0.35;
        neckHeight = h * 0.18;
        cornerRadius = bottleWidth * 0.45;
      case BottleType.square:
        bottleWidth = w * 0.75;
        bottleHeight = h * 0.72;
        neckWidth = bottleWidth * 0.5;
        neckHeight = h * 0.12;
        cornerRadius = bottleWidth * 0.08;
      case BottleType.tall:
        bottleWidth = w * 0.55;
        bottleHeight = h * 0.82;
        neckWidth = bottleWidth * 0.5;
        neckHeight = h * 0.1;
        cornerRadius = bottleWidth * 0.15;
      case BottleType.wide:
        bottleWidth = w * 0.85;
        bottleHeight = h * 0.62;
        neckWidth = bottleWidth * 0.35;
        neckHeight = h * 0.2;
        cornerRadius = bottleWidth * 0.25;
    }

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

    // ── Mouth rim above liquid (liquid must not cover the opening line) ──
    _drawBottleMouthRim(canvas, neckLeft, neckRight, neckTop);

    // ── Draw bottle glass overlay (reflections/highlights) ──
    _drawGlassHighlights(canvas, left, right, top, bottom, neckLeft,
        neckRight, neckTop, cornerRadius, bottleWidth, bottleHeight, w, h);

    // ── Draw selection indicator ──
    if (isSelected) {
      _drawSelectionGlow(canvas, left, right, top, bottom, neckLeft,
          neckRight, neckTop, cornerRadius, w, h);
    }

    // ── Draw hint indicator ──
    if (isHint) {
      _drawHintGlow(canvas, left, right, top, bottom, neckLeft,
          neckRight, neckTop, cornerRadius, w, h);
    }

    // ── Draw bottle cap when solved ──
    if (isSolved && capProgress > 0.0) {
      _drawBottleCap(canvas, w, neckLeft, neckRight, neckTop, capProgress);
    }

    // ── Draw celebration particles ──
    if (isSolved && celebrationProgress > 0.0 && celebrationProgress < 1.0) {
      _drawCelebration(canvas, w, h, neckTop, bottleHeight);
    }

    canvas.restore();
  }

  /// Builds the bottle body path based on the current [bottleType].
  Path _buildBottlePath(
    double left,
    double right,
    double top,
    double bottom,
    double neckLeft,
    double neckRight,
    double neckTop,
    double cornerRadius,
    double bottleWidth,
    double w,
  ) {
    switch (bottleType) {
      case BottleType.classic:
        return Path()
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
          ..lineTo(neckRight, neckTop)
          ..close();

      case BottleType.round:
        // Flask shape: bulbous body with narrow neck
        final midY = top + (bottom - top) * 0.35;
        return Path()
          ..moveTo(neckLeft, neckTop)
          ..lineTo(neckLeft, top + 4)
          // Smooth curve outward from neck to body
          ..cubicTo(neckLeft - 2, midY * 0.95, left - 2, midY * 0.85, left, midY)
          // Round bottom using large arcs
          ..quadraticBezierTo(left - 2, bottom, left + bottleWidth * 0.5, bottom)
          ..quadraticBezierTo(right + 2, bottom, right, midY)
          // Right curve from body to neck
          ..cubicTo(right + 2, midY * 0.85, neckRight + 2, midY * 0.95, neckRight, top + 4)
          ..lineTo(neckRight, neckTop)
          ..close();

      case BottleType.square:
        // Jar shape: boxy body, small corners, wide neck
        return Path()
          ..moveTo(neckLeft, neckTop)
          ..lineTo(neckLeft, top + 2)
          ..lineTo(left + cornerRadius, top)
          ..lineTo(left, top + cornerRadius)
          ..lineTo(left, bottom - cornerRadius)
          ..lineTo(left + cornerRadius, bottom)
          ..lineTo(right - cornerRadius, bottom)
          ..lineTo(right, bottom - cornerRadius)
          ..lineTo(right, top + cornerRadius)
          ..lineTo(right - cornerRadius, top)
          ..lineTo(neckRight, top + 2)
          ..lineTo(neckRight, neckTop)
          ..close();

      case BottleType.tall:
        // Tall slim bottle: slight taper, small neck difference
        final taperIn = bottleWidth * 0.06;
        return Path()
          ..moveTo(neckLeft, neckTop)
          ..lineTo(neckLeft, top + 2)
          ..quadraticBezierTo(neckLeft, top, left + taperIn, top)
          ..lineTo(left, top + (bottom - top) * 0.25)
          ..lineTo(left, bottom - cornerRadius)
          ..quadraticBezierTo(left, bottom, left + cornerRadius, bottom)
          ..lineTo(right - cornerRadius, bottom)
          ..quadraticBezierTo(right, bottom, right, bottom - cornerRadius)
          ..lineTo(right, top + (bottom - top) * 0.25)
          ..lineTo(right - taperIn, top)
          ..quadraticBezierTo(neckRight, top, neckRight, top + 2)
          ..lineTo(neckRight, neckTop)
          ..close();

      case BottleType.wide:
        // Wide bowl shape: broad body, long narrow neck
        final bodyTop = top + (bottom - top) * 0.15;
        return Path()
          ..moveTo(neckLeft, neckTop)
          ..lineTo(neckLeft, top + 2)
          // Flare out to wide body
          ..cubicTo(neckLeft, bodyTop * 0.98, left, bodyTop * 0.95, left, bodyTop)
          ..lineTo(left, bottom - cornerRadius)
          ..quadraticBezierTo(left, bottom, left + cornerRadius, bottom)
          ..lineTo(right - cornerRadius, bottom)
          ..quadraticBezierTo(right, bottom, right, bottom - cornerRadius)
          ..lineTo(right, bodyTop)
          // Narrow from body to neck
          ..cubicTo(right, bodyTop * 0.95, neckRight, bodyTop * 0.98, neckRight, top + 2)
          ..lineTo(neckRight, neckTop)
          ..close();
    }
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
    final bodyPath = _buildBottlePath(
        left, right, top, bottom, neckLeft, neckRight, neckTop, cornerRadius, bottleWidth, w);

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

    // Mouth rim is drawn after liquid so it stays visible on top — see
    // [_drawBottleMouthRim].
  }

  /// Draws the mouth rim on top of liquid so the opening reads as glass, not
  /// liquid sitting above the cap line.
  void _drawBottleMouthRim(
    Canvas canvas,
    double neckLeft,
    double neckRight,
    double neckTop,
  ) {
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
    if (bottle.isEmpty && !(isDest && pourCount > 0)) return;

    final colors = List<Color>.from(bottle.colors);
    if (isDest && pourCount > 0 && pourColor != null) {
      for (int i = 0; i < pourCount; i++) {
        colors.add(pourColor!);
      }
    }
    final segmentCount = colors.length;

    // ── Calculate effective fill ──
    double effectiveSegments = isDest ? bottle.colors.length.toDouble() : segmentCount.toDouble();
    if (isSource && pourCount > 0) {
      effectiveSegments -= (pourCount * levelProgress);
    } else if (isDest && pourCount > 0) {
      effectiveSegments += (pourCount * levelProgress);
    }

    // Create a clipping region for the bottle's interior (inset from outer path)
    final clipPath = _buildBottlePath(
        left + 1.5, right - 1.5, top, bottom - 1.5,
        neckLeft + 1, neckRight - 1, neckTop + 1,
        cornerRadius * 0.9, bottleWidth - 3, w);

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

    // Upright: split fill only across the body so the neck stays empty glass.
    // Tilted: use full transformed bounds so pour math stays consistent.
    final double segmentHeight;
    final double fillBottomStart;
    if (tiltAngle == 0.0) {
      segmentHeight = (bottom - top) / kMaxBottleCapacity;
      fillBottomStart = bottom;
    } else {
      segmentHeight = worldBounds.height / kMaxBottleCapacity;
      fillBottomStart = worldBounds.bottom;
    }
    double currentWorldBottom = fillBottomStart;

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
      if (fillType == FillType.liquid) {
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

        // Body only — do not fill the neck; top stays visibly empty.
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
      } else {
        // Draw non-liquid shapes correctly positioned within their local segment.
        final localSegHeight = (bottom - top) / kMaxBottleCapacity;
        final localSegBottom = bottom - (i * localSegHeight);
        final localSegTop = localSegBottom - localSegHeight;
        final localCy = (localSegTop + localSegBottom) / 2;
        final cx = (left + right) / 2;
        
        double fraction = 1.0;
        final fullSegments = effectiveSegments.floor();
        if (i == fullSegments) {
          fraction = effectiveSegments - fullSegments;
        }
        final scaleFactor = sin(fraction * pi / 2);
        final r = min((right - left) / 2, localSegHeight / 2) * 0.85 * scaleFactor;

        if (r > 0.5) {
          if (fillType == FillType.balls) {
            final paint = Paint()
              ..shader = RadialGradient(
                colors: [GameColors.lighten(color, 0.2), color, GameColors.darken(color, 0.2)],
                stops: const [0.0, 0.5, 1.0],
                center: const Alignment(-0.3, -0.3),
              ).createShader(Rect.fromCircle(center: Offset(cx, localCy), radius: r));
            canvas.drawCircle(Offset(cx, localCy), r, paint);
          } else if (fillType == FillType.blocks) {
            final rect = Rect.fromCenter(center: Offset(cx, localCy), width: r * 2, height: r * 2);
            final paint = Paint()
              ..color = color
              ..style = PaintingStyle.fill;
            canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
            final borderPaint = Paint()
              ..color = GameColors.darken(color, 0.2)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2;
            canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);
          } else if (fillType == FillType.stars) {
            _drawStar(canvas, cx, localCy, r, color);
          } else if (fillType == FillType.diamonds) {
            _drawDiamond(canvas, cx, localCy, r, color);
          }
        }
      }
      canvas.restore(); // Restore local clip state

      // Draw the wobble surface in World Space exactly at segTop
      if (fillType == FillType.liquid && (i == segmentCount - 1 || (isSource && i == bottle.colors.length - 1) || (isDest && i == segmentCount - 1))) {
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
  }

  void _drawStar(Canvas canvas, double cx, double cy, double radius, Color color) {
    final path = Path();
    final halfRadius = radius / 2;
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
    final amplitude = (isSource || isDest) ? 3.0 : 1.5;

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

    final glowPath = _buildBottlePath(
        left, right, top, bottom, neckLeft, neckRight, neckTop, cornerRadius,
        right - left, w);

    canvas.drawPath(glowPath, glowPaint);

    // Inner glow
    glowPaint
      ..color = const Color(0xFF64FFDA).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(glowPath, glowPaint);
  }

  /// Draws a hint glow around the bottle (golden/amber color).
  void _drawHintGlow(
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
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10.0);

    final glowPath = _buildBottlePath(
        left, right, top, bottom, neckLeft, neckRight, neckTop, cornerRadius,
        right - left, w);

    canvas.drawPath(glowPath, glowPaint);

    // Inner glow
    glowPaint
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawPath(glowPath, glowPaint);
  }

  /// Draws a bottle cap dropping onto the bottle neck.
  void _drawBottleCap(Canvas canvas, double w, double neckLeft, double neckRight,
      double neckTop, double progress) {
    final centerX = w / 2;
    final capWidth = (neckRight - neckLeft) + 6;
    final capHeight = 8.0;

    // Cap drops from 40px above to seated position
    final startY = neckTop - 40;
    final endY = neckTop - capHeight + 1;
    // Use easeOut-like curve for natural drop feel
    final easedProgress = 1.0 - (1.0 - progress) * (1.0 - progress);
    final capY = startY + (endY - startY) * easedProgress;

    final capLeft = centerX - capWidth / 2;
    final capRight = centerX + capWidth / 2;

    // Cap body (wooden cork/cap look)
    final capPath = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(capLeft, capY, capWidth, capHeight),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
        bottomLeft: const Radius.circular(1),
        bottomRight: const Radius.circular(1),
      ));

    // Cap gradient (wooden look)
    final capPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFD4A574), // Light wood
          const Color(0xFFB8834A), // Medium wood
          const Color(0xFF8B6914), // Dark wood
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(capLeft, capY, capWidth, capHeight));
    canvas.drawPath(capPath, capPaint);

    // Cap rim (slightly wider at top)
    final rimRect = Rect.fromLTWH(capLeft - 2, capY - 1, capWidth + 4, 3);
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE8C08A),
          const Color(0xFFC49A5C),
        ],
      ).createShader(rimRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rimRect, const Radius.circular(1.5)),
      rimPaint,
    );

    // Cap border
    final borderPaint = Paint()
      ..color = const Color(0xFF6B4B1A).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rimRect, const Radius.circular(1.5)),
      borderPaint,
    );

    // Small wood grain lines
    final grainPaint = Paint()
      ..color = const Color(0xFF9B7030).withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(capLeft + 3, capY + 2),
      Offset(capRight - 3, capY + 2),
      grainPaint,
    );
    canvas.drawLine(
      Offset(capLeft + 5, capY + 5),
      Offset(capRight - 5, capY + 5),
      grainPaint,
    );

    // Highlight on cap
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(capLeft + 2, capY + 1),
      Offset(capLeft + capWidth * 0.4, capY + 1),
      highlightPaint,
    );
  }

  /// Draws celebration particles (sparkles, stars) around the completed bottle.
  void _drawCelebration(Canvas canvas, double w, double h, double neckTop,
      double bottleHeight) {
    final centerX = w / 2;
    final centerY = neckTop + bottleHeight * 0.4;
    final progress = celebrationProgress;

    // Fade out in the second half
    final opacity = progress < 0.5
        ? (progress / 0.5).clamp(0.0, 1.0)
        : ((1.0 - progress) / 0.5).clamp(0.0, 1.0);

    // Particle ring expands outward
    final maxRadius = w * 0.9;
    final radius = maxRadius * progress;

    final rng = Random(42); // Fixed seed for consistent pattern

    // Draw sparkle particles
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 2 * pi + (i.isEven ? 0.2 : 0.0);
      final particleRadius = radius + rng.nextDouble() * 8;
      final px = centerX + cos(angle) * particleRadius;
      final py = centerY + sin(angle) * particleRadius * 0.7; // Slightly oval

      // Alternate between gold, green, cyan sparkles
      final colors = [
        const Color(0xFFFFD700), // Gold
        const Color(0xFF69F0AE), // Green
        const Color(0xFF64FFDA), // Cyan
        const Color(0xFFFF8A65), // Orange
        const Color(0xFFE040FB), // Purple
      ];
      final color = colors[i % colors.length];

      // Star/sparkle shape
      final size = (3.0 + rng.nextDouble() * 3.0) * opacity;
      if (size < 0.5) continue;

      final sparkPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.fill;

      // Draw diamond sparkle
      final sparkPath = Path()
        ..moveTo(px, py - size)
        ..lineTo(px + size * 0.4, py)
        ..lineTo(px, py + size)
        ..lineTo(px - size * 0.4, py)
        ..close();
      canvas.drawPath(sparkPath, sparkPaint);

      // Cross sparkle
      final crossPath = Path()
        ..moveTo(px - size, py)
        ..lineTo(px, py + size * 0.4)
        ..lineTo(px + size, py)
        ..lineTo(px, py - size * 0.4)
        ..close();
      canvas.drawPath(crossPath, sparkPaint);

      // Small glow behind sparkle
      final glowPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(px, py), size * 0.8, glowPaint);
    }

    // Small circular dots between sparkles
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi + 0.3;
      final dotRadius = radius * 0.7 + rng.nextDouble() * 10;
      final px = centerX + cos(angle) * dotRadius;
      final py = centerY + sin(angle) * dotRadius * 0.7;

      final dotPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), 1.5 * opacity, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LiquidPainter oldDelegate) {
    return oldDelegate.bottle != bottle ||
        oldDelegate.tiltAngle != tiltAngle ||
        oldDelegate.levelProgress != levelProgress ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isHint != isHint ||
        oldDelegate.wobblePhase != wobblePhase ||
        oldDelegate.isSource != isSource ||
        oldDelegate.pourCount != pourCount ||
        oldDelegate.isSolved != isSolved ||
        oldDelegate.capProgress != capProgress ||
        oldDelegate.celebrationProgress != celebrationProgress ||
        oldDelegate.bottleType != bottleType;
  }
}
