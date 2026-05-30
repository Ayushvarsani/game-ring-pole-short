import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../models/bottle_model.dart';
import '../models/bottle_type.dart';
import '../models/fill_type.dart';
import '../models/game_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_config.dart';

class BottleGeometry {
  const BottleGeometry._({
    required this.bottleWidth,
    required this.bottleHeight,
    required this.neckWidth,
    required this.neckHeight,
    required this.cornerRadius,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.neckLeft,
    required this.neckRight,
    required this.neckTop,
  });

  final double bottleWidth;
  final double bottleHeight;
  final double neckWidth;
  final double neckHeight;
  final double cornerRadius;
  final double left;
  final double right;
  final double top;
  final double bottom;
  final double neckLeft;
  final double neckRight;
  final double neckTop;

  double get centerX => left + (bottleWidth / 2);

  factory BottleGeometry.fromSize(Size size, BottleType bottleType) {
    final w = size.width;
    final h = size.height;

    late final double bottleWidth;
    late final double bottleHeight;
    late final double neckWidth;
    late final double neckHeight;
    late final double cornerRadius;

    switch (bottleType) {
      case BottleType.classic:
        bottleWidth = w * 0.68;
        bottleHeight = h * 0.72;
        neckWidth = bottleWidth * 0.42;
        neckHeight = h * 0.13;
        cornerRadius = bottleWidth * 0.24;
      case BottleType.round:
        bottleWidth = w * 0.78;
        bottleHeight = h * 0.66;
        neckWidth = bottleWidth * 0.32;
        neckHeight = h * 0.18;
        cornerRadius = bottleWidth * 0.48;
      case BottleType.square:
        bottleWidth = w * 0.74;
        bottleHeight = h * 0.68;
        neckWidth = bottleWidth * 0.54;
        neckHeight = h * 0.11;
        cornerRadius = bottleWidth * 0.1;
      case BottleType.tall:
        bottleWidth = w * 0.54;
        bottleHeight = h * 0.79;
        neckWidth = bottleWidth * 0.46;
        neckHeight = h * 0.095;
        cornerRadius = bottleWidth * 0.18;
      case BottleType.wide:
        bottleWidth = w * 0.84;
        bottleHeight = h * 0.58;
        neckWidth = bottleWidth * 0.32;
        neckHeight = h * 0.19;
        cornerRadius = bottleWidth * 0.28;
    }

    final bottom = h * 0.94;
    final top = bottom - bottleHeight;
    final left = (w - bottleWidth) / 2;
    final right = left + bottleWidth;
    final neckLeft = (w - neckWidth) / 2;
    final neckRight = neckLeft + neckWidth;
    final neckTop = top - neckHeight;

    return BottleGeometry._(
      bottleWidth: bottleWidth,
      bottleHeight: bottleHeight,
      neckWidth: neckWidth,
      neckHeight: neckHeight,
      cornerRadius: cornerRadius,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      neckLeft: neckLeft,
      neckRight: neckRight,
      neckTop: neckTop,
    );
  }
}

class LiquidPainter extends CustomPainter {
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
    this.theme,
  });

  final BottleModel bottle;
  final double tiltAngle;
  final double levelProgress;
  final bool isSource;
  final bool isDest;
  final int pourCount;
  final Color? pourColor;
  final bool isSelected;
  final bool isHint;
  final double wobblePhase;
  final bool isSolved;
  final double capProgress;
  final double celebrationProgress;
  final BottleType bottleType;
  final FillType fillType;
  final AppThemeConfig? theme;

  @override
  void paint(Canvas canvas, Size size) {
    final activeTheme = theme ?? AppTheme.fallbackConfig;
    final geometry = BottleGeometry.fromSize(size, bottleType);
    final bodyPath = _buildBottlePath(geometry);

    canvas.save();
    if (tiltAngle != 0.0) {
      final pivotX = tiltAngle > 0 ? geometry.neckRight : geometry.neckLeft;
      final pivotY = geometry.neckTop;
      canvas.translate(pivotX, pivotY);
      canvas.rotate(tiltAngle);
      canvas.translate(-pivotX, -pivotY);
    }

    _drawGroundShadow(canvas, geometry, activeTheme);
    _drawBottleGlass(canvas, bodyPath, geometry, activeTheme);
    _drawLiquid(canvas, geometry);
    _drawBottleMouthRim(canvas, geometry);
    _drawGlassHighlights(canvas, geometry);

    if (isSource) {
      _drawStateGlow(canvas, bodyPath, activeTheme.primaryAccent, 0.28, 9);
    }
    if (isDest) {
      _drawStateGlow(canvas, bodyPath, activeTheme.secondaryAccent, 0.24, 9);
    }
    if (isSelected) {
      _drawStateGlow(canvas, bodyPath, activeTheme.secondaryAccent, 0.34, 10);
    }
    if (isHint) {
      _drawStateGlow(canvas, bodyPath, activeTheme.goldAccent, 0.3, 11);
    }
    if (isSolved && !isSource && !isDest) {
      _drawStateGlow(canvas, bodyPath, activeTheme.successAccent, 0.18, 8);
    }

    if (isSolved && capProgress > 0.0) {
      _drawBottleCap(canvas, geometry, capProgress);
    }
    if (isSolved && celebrationProgress > 0.0 && celebrationProgress < 1.0) {
      _drawCelebration(canvas, geometry);
    }

    canvas.restore();
  }

  Path _buildBottlePath(BottleGeometry g) {
    switch (bottleType) {
      case BottleType.classic:
        return Path()
          ..moveTo(g.neckLeft, g.neckTop)
          ..lineTo(g.neckLeft, g.top + 2)
          ..quadraticBezierTo(
            g.neckLeft,
            g.top,
            g.left + g.cornerRadius * 0.28,
            g.top,
          )
          ..lineTo(g.left, g.top + g.cornerRadius * 0.35)
          ..lineTo(g.left, g.bottom - g.cornerRadius)
          ..quadraticBezierTo(
            g.left,
            g.bottom,
            g.left + g.cornerRadius,
            g.bottom,
          )
          ..lineTo(g.right - g.cornerRadius, g.bottom)
          ..quadraticBezierTo(
            g.right,
            g.bottom,
            g.right,
            g.bottom - g.cornerRadius,
          )
          ..lineTo(g.right, g.top + g.cornerRadius * 0.35)
          ..lineTo(g.right - g.cornerRadius * 0.28, g.top)
          ..quadraticBezierTo(g.neckRight, g.top, g.neckRight, g.top + 2)
          ..lineTo(g.neckRight, g.neckTop)
          ..close();
      case BottleType.round:
        final midY = g.top + g.bottleHeight * 0.36;
        return Path()
          ..moveTo(g.neckLeft, g.neckTop)
          ..lineTo(g.neckLeft, g.top + 4)
          ..cubicTo(
            g.neckLeft - 1,
            midY * 0.96,
            g.left - 2,
            midY * 0.86,
            g.left,
            midY,
          )
          ..quadraticBezierTo(
            g.left - 1,
            g.bottom,
            g.left + g.bottleWidth * 0.5,
            g.bottom,
          )
          ..quadraticBezierTo(g.right + 1, g.bottom, g.right, midY)
          ..cubicTo(
            g.right + 2,
            midY * 0.86,
            g.neckRight + 1,
            midY * 0.96,
            g.neckRight,
            g.top + 4,
          )
          ..lineTo(g.neckRight, g.neckTop)
          ..close();
      case BottleType.square:
        return Path()
          ..moveTo(g.neckLeft, g.neckTop)
          ..lineTo(g.neckLeft, g.top + 1)
          ..lineTo(g.left + g.cornerRadius, g.top)
          ..lineTo(g.left, g.top + g.cornerRadius)
          ..lineTo(g.left, g.bottom - g.cornerRadius)
          ..lineTo(g.left + g.cornerRadius, g.bottom)
          ..lineTo(g.right - g.cornerRadius, g.bottom)
          ..lineTo(g.right, g.bottom - g.cornerRadius)
          ..lineTo(g.right, g.top + g.cornerRadius)
          ..lineTo(g.right - g.cornerRadius, g.top)
          ..lineTo(g.neckRight, g.top + 1)
          ..lineTo(g.neckRight, g.neckTop)
          ..close();
      case BottleType.tall:
        final taper = g.bottleWidth * 0.08;
        return Path()
          ..moveTo(g.neckLeft, g.neckTop)
          ..lineTo(g.neckLeft, g.top + 2)
          ..quadraticBezierTo(g.neckLeft, g.top, g.left + taper, g.top)
          ..lineTo(g.left, g.top + g.bottleHeight * 0.24)
          ..lineTo(g.left, g.bottom - g.cornerRadius)
          ..quadraticBezierTo(
            g.left,
            g.bottom,
            g.left + g.cornerRadius,
            g.bottom,
          )
          ..lineTo(g.right - g.cornerRadius, g.bottom)
          ..quadraticBezierTo(
            g.right,
            g.bottom,
            g.right,
            g.bottom - g.cornerRadius,
          )
          ..lineTo(g.right, g.top + g.bottleHeight * 0.24)
          ..lineTo(g.right - taper, g.top)
          ..quadraticBezierTo(g.neckRight, g.top, g.neckRight, g.top + 2)
          ..lineTo(g.neckRight, g.neckTop)
          ..close();
      case BottleType.wide:
        final bodyTop = g.top + g.bottleHeight * 0.18;
        return Path()
          ..moveTo(g.neckLeft, g.neckTop)
          ..lineTo(g.neckLeft, g.top + 2)
          ..cubicTo(
            g.neckLeft,
            bodyTop * 0.98,
            g.left,
            bodyTop * 0.95,
            g.left,
            bodyTop,
          )
          ..lineTo(g.left, g.bottom - g.cornerRadius)
          ..quadraticBezierTo(
            g.left,
            g.bottom,
            g.left + g.cornerRadius,
            g.bottom,
          )
          ..lineTo(g.right - g.cornerRadius, g.bottom)
          ..quadraticBezierTo(
            g.right,
            g.bottom,
            g.right,
            g.bottom - g.cornerRadius,
          )
          ..lineTo(g.right, bodyTop)
          ..cubicTo(
            g.right,
            bodyTop * 0.95,
            g.neckRight,
            bodyTop * 0.98,
            g.neckRight,
            g.top + 2,
          )
          ..lineTo(g.neckRight, g.neckTop)
          ..close();
    }
  }

  Path _buildInteriorPath(BottleGeometry g) {
    return _buildBottlePath(
      BottleGeometry._(
        bottleWidth: g.bottleWidth - 3,
        bottleHeight: g.bottleHeight,
        neckWidth: g.neckWidth - 2,
        neckHeight: g.neckHeight,
        cornerRadius: g.cornerRadius * 0.92,
        left: g.left + 1.5,
        right: g.right - 1.5,
        top: g.top,
        bottom: g.bottom - 1.5,
        neckLeft: g.neckLeft + 1,
        neckRight: g.neckRight - 1,
        neckTop: g.neckTop + 1,
      ),
    );
  }

  void _drawGroundShadow(
    Canvas canvas,
    BottleGeometry g,
    AppThemeConfig theme,
  ) {
    final shadowRect = Rect.fromCenter(
      center: Offset(g.centerX, g.bottom + 4),
      width: g.bottleWidth * (isSource || isDest ? 0.95 : 0.82),
      height: g.bottleWidth * 0.22,
    );
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: isSource || isDest ? 0.22 : 0.16),
          Colors.transparent,
        ],
      ).createShader(shadowRect);
    canvas.drawOval(shadowRect, shadowPaint);

    final glowColor = isSource
        ? theme.primaryAccent
        : isDest
        ? theme.secondaryAccent
        : isSelected
        ? theme.secondaryAccent
        : isHint
        ? theme.goldAccent
        : null;
    if (glowColor != null) {
      final glowRect = Rect.fromCenter(
        center: Offset(g.centerX, g.bottom + 3),
        width: g.bottleWidth * (isSelected ? 1.08 : 0.98),
        height: g.bottleWidth * 0.26,
      );
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            glowColor.withValues(
              alpha: isSelected ? 0.22 : (isSource || isDest ? 0.16 : 0.12),
            ),
            Colors.transparent,
          ],
        ).createShader(glowRect);
      canvas.drawOval(glowRect, glowPaint);
    }
  }

  void _drawBottleGlass(
    Canvas canvas,
    Path bodyPath,
    BottleGeometry g,
    AppThemeConfig theme,
  ) {
    final glassRect = Rect.fromLTRB(g.left, g.neckTop, g.right, g.bottom);
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.08),
          theme.surfaceStrong.withValues(alpha: 0.18),
        ],
        stops: const [0.0, 0.28, 1.0],
      ).createShader(glassRect);
    canvas.drawPath(bodyPath, fillPaint);

    final outerBorder = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.68),
          Colors.white.withValues(alpha: 0.34),
          Colors.white.withValues(alpha: 0.22),
        ],
      ).createShader(glassRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;
    canvas.drawPath(bodyPath, outerBorder);

    final innerBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(bodyPath.shift(const Offset(0.5, 0.5)), innerBorder);
  }

  void _drawLiquid(Canvas canvas, BottleGeometry g) {
    if (bottle.isEmpty && !(isDest && pourCount > 0)) return;

    final colors = bottle.colors
        .map(GameColors.normalize)
        .toList(growable: true);
    if (isDest && pourCount > 0 && pourColor != null) {
      for (int i = 0; i < pourCount; i++) {
        colors.add(GameColors.normalize(pourColor!));
      }
    }

    final segmentCount = colors.length;
    var effectiveSegments = isDest
        ? bottle.colors.length.toDouble()
        : segmentCount.toDouble();
    if (isSource && pourCount > 0) {
      effectiveSegments -= pourCount * levelProgress;
    } else if (isDest && pourCount > 0) {
      effectiveSegments += pourCount * levelProgress;
    }

    final clipPath = _buildInteriorPath(g);
    final matrix = Matrix4.identity();
    if (tiltAngle != 0.0) {
      final pivotX = tiltAngle > 0 ? g.neckRight : g.neckLeft;
      final pivotY = g.neckTop;
      matrix.translateByDouble(pivotX, pivotY, 0, 1);
      matrix.rotateZ(tiltAngle);
      matrix.translateByDouble(-pivotX, -pivotY, 0, 1);
    }
    final worldClipPath = clipPath.transform(matrix.storage);
    final worldBounds = worldClipPath.getBounds();

    final segmentHeight = tiltAngle == 0.0
        ? (g.bottom - g.top) / kMaxBottleCapacity
        : worldBounds.height / kMaxBottleCapacity;
    var currentWorldBottom = tiltAngle == 0.0 ? g.bottom : worldBounds.bottom;

    for (int i = 0; i < segmentCount; i++) {
      final fullSegments = effectiveSegments.floor();
      late final double thisSegmentHeight;
      if (i < segmentCount - 1) {
        thisSegmentHeight = segmentHeight;
      } else if (i < fullSegments) {
        thisSegmentHeight = segmentHeight;
      } else if (i == fullSegments) {
        thisSegmentHeight = segmentHeight * (effectiveSegments - fullSegments);
      } else {
        continue;
      }

      if (thisSegmentHeight <= 0) continue;
      final segTop = currentWorldBottom - thisSegmentHeight;
      final color = GameColors.normalize(colors[i]);

      canvas.save();
      canvas.clipPath(clipPath);
      canvas.save();

      if (fillType == FillType.liquid) {
        if (tiltAngle != 0.0) {
          final pivotX = tiltAngle > 0 ? g.neckRight : g.neckLeft;
          final pivotY = g.neckTop;
          canvas.translate(pivotX, pivotY);
          canvas.rotate(-tiltAngle);
          canvas.translate(-pivotX, -pivotY);
          canvas.clipRect(
            Rect.fromLTRB(
              worldBounds.left - 20,
              segTop,
              worldBounds.right + 20,
              currentWorldBottom,
            ),
            doAntiAlias: false,
          );
          canvas.translate(pivotX, pivotY);
          canvas.rotate(tiltAngle);
          canvas.translate(-pivotX, -pivotY);
        } else {
          canvas.clipRect(
            Rect.fromLTRB(
              g.left - 20,
              segTop,
              g.right + 20,
              currentWorldBottom,
            ),
            doAntiAlias: false,
          );
        }

        final liquidRect = Rect.fromLTRB(
          g.left + 1.5,
          g.top,
          g.right - 1.5,
          g.bottom,
        );
        final liquidPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = false;
        canvas.drawRect(liquidRect, liquidPaint);
      } else {
        _drawStructuredFill(canvas, g, i, effectiveSegments, color);
      }

      canvas.restore();

      if (fillType == FillType.liquid &&
          (i == segmentCount - 1 ||
              (isSource && i == bottle.colors.length - 1))) {
        canvas.save();
        if (tiltAngle != 0.0) {
          final pivotX = tiltAngle > 0 ? g.neckRight : g.neckLeft;
          final pivotY = g.neckTop;
          canvas.translate(pivotX, pivotY);
          canvas.rotate(-tiltAngle);
          canvas.translate(-pivotX, -pivotY);
        }
        _drawWobbleSurface(
          canvas,
          worldBounds.left - 20,
          worldBounds.right + 20,
          segTop,
          color,
        );
        canvas.restore();
      }

      if (i > 0) {
        canvas.save();
        if (tiltAngle != 0.0) {
          final pivotX = tiltAngle > 0 ? g.neckRight : g.neckLeft;
          final pivotY = g.neckTop;
          canvas.translate(pivotX, pivotY);
          canvas.rotate(-tiltAngle);
          canvas.translate(-pivotX, -pivotY);
        }
        final dividerPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.09)
          ..strokeWidth = 0.7;
        canvas.drawLine(
          Offset(worldBounds.left - 20, currentWorldBottom),
          Offset(worldBounds.right + 20, currentWorldBottom),
          dividerPaint,
        );
        canvas.restore();
      }

      currentWorldBottom = segTop;
      canvas.restore();
    }
  }

  void _drawStructuredFill(
    Canvas canvas,
    BottleGeometry g,
    int segmentIndex,
    double effectiveSegments,
    Color color,
  ) {
    final baseColor = GameColors.normalize(color);
    final localSegHeight = (g.bottom - g.top) / kMaxBottleCapacity;
    final localSegBottom = g.bottom - (segmentIndex * localSegHeight);
    final localSegTop = localSegBottom - localSegHeight;
    final localCy = (localSegTop + localSegBottom) / 2;
    final cx = g.centerX;

    var fraction = 1.0;
    final fullSegments = effectiveSegments.floor();
    if (segmentIndex == fullSegments) {
      fraction = effectiveSegments - fullSegments;
    }
    final scaleFactor = sin(fraction * pi / 2);
    final radius =
        min(g.bottleWidth / 2, localSegHeight / 2) * 0.82 * scaleFactor;
    if (radius <= 0.5) return;

    if (fillType == FillType.balls) {
      final paint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                GameColors.lighten(baseColor, 0.22),
                baseColor,
                GameColors.darken(baseColor, 0.24),
              ],
              stops: const [0.0, 0.56, 1.0],
              center: const Alignment(-0.3, -0.3),
            ).createShader(
              Rect.fromCircle(center: Offset(cx, localCy), radius: radius),
            );
      canvas.drawCircle(Offset(cx, localCy), radius, paint);
    } else if (fillType == FillType.blocks) {
      final rect = Rect.fromCenter(
        center: Offset(cx, localCy),
        width: radius * 2,
        height: radius * 2,
      );
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GameColors.lighten(baseColor, 0.16),
            baseColor,
            GameColors.darken(baseColor, 0.16),
          ],
        ).createShader(rect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        fillPaint,
      );
      final borderPaint = Paint()
        ..color = GameColors.darken(baseColor, 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        borderPaint,
      );
    } else if (fillType == FillType.stars) {
      _drawStar(canvas, cx, localCy, radius, baseColor);
    } else if (fillType == FillType.diamonds) {
      _drawDiamond(canvas, cx, localCy, radius, baseColor);
    }
  }

  void _drawBottleMouthRim(Canvas canvas, BottleGeometry g) {
    final rimPaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.72),
              Colors.white.withValues(alpha: 0.35),
              Colors.white.withValues(alpha: 0.68),
            ],
          ).createShader(
            Rect.fromLTRB(
              g.neckLeft - 2,
              g.neckTop - 1,
              g.neckRight + 2,
              g.neckTop + 2,
            ),
          )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(g.neckLeft - 1, g.neckTop),
      Offset(g.neckRight + 1, g.neckTop),
      rimPaint,
    );
  }

  void _drawGlassHighlights(Canvas canvas, BottleGeometry g) {
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9;

    final primaryHighlight = Path()
      ..moveTo(g.neckLeft + 2, g.neckTop + 3)
      ..lineTo(g.left + 3, g.top + g.cornerRadius + 6)
      ..lineTo(g.left + 3, g.bottom - g.cornerRadius - 8);
    canvas.drawPath(primaryHighlight, highlightPaint);

    final secondaryHighlight = Path()
      ..moveTo(g.centerX + g.bottleWidth * 0.18, g.top + g.bottleHeight * 0.18)
      ..quadraticBezierTo(
        g.right - 5,
        g.top + g.bottleHeight * 0.32,
        g.right - 6,
        g.top + g.bottleHeight * 0.68,
      );
    canvas.drawPath(
      secondaryHighlight,
      highlightPaint..color = Colors.white.withValues(alpha: 0.08),
    );

    final shinePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                g.left + g.bottleWidth * 0.26,
                g.top + g.bottleHeight * 0.2,
              ),
              radius: g.bottleWidth * 0.16,
            ),
          );
    canvas.drawCircle(
      Offset(g.left + g.bottleWidth * 0.26, g.top + g.bottleHeight * 0.2),
      g.bottleWidth * 0.16,
      shinePaint,
    );
  }

  void _drawStateGlow(
    Canvas canvas,
    Path glowPath,
    Color color,
    double alpha,
    double blur,
  ) {
    final outerGlow = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, blur);
    canvas.drawPath(glowPath, outerGlow);

    final innerGlow = Paint()
      ..color = color.withValues(alpha: alpha * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(glowPath, innerGlow);
  }

  void _drawBottleCap(Canvas canvas, BottleGeometry g, double progress) {
    final capWidth = (g.neckRight - g.neckLeft) + 7;
    final capHeight = 8.0;
    final startY = g.neckTop - (g.bottleHeight * 0.28);
    final endY = g.neckTop - capHeight + 1;
    final eased = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));
    final capY = lerpDouble(startY, endY, eased)!;
    final capLeft = g.centerX - (capWidth / 2);

    final capRect = Rect.fromLTWH(capLeft, capY, capWidth, capHeight);
    final capPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFE8C18B), Color(0xFFC88D4F), Color(0xFF8C5A24)],
      ).createShader(capRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(3)),
      capPaint,
    );

    final rimRect = Rect.fromLTWH(capLeft - 1.5, capY - 1, capWidth + 3, 3);
    final rimPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFFF2D4A5), Color(0xFFDAA56B)],
      ).createShader(rimRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rimRect, const Radius.circular(2)),
      rimPaint,
    );
  }

  void _drawCelebration(Canvas canvas, BottleGeometry g) {
    final activeTheme = theme ?? AppTheme.fallbackConfig;
    final center = Offset(g.centerX, g.top + g.bottleHeight * 0.38);
    final progress = celebrationProgress;
    final opacity = progress < 0.55
        ? (progress / 0.55).clamp(0.0, 1.0)
        : ((1.0 - progress) / 0.45).clamp(0.0, 1.0);
    final radius = g.bottleWidth * (0.45 + progress * 0.8);
    final rng = Random(42);
    final sparkColors = [
      activeTheme.goldAccent,
      activeTheme.secondaryAccent,
      activeTheme.successAccent,
      activeTheme.warmAccent,
    ];

    for (int i = 0; i < 14; i++) {
      final angle = (i / 14) * 2 * pi + (i.isEven ? 0.18 : 0.0);
      final offsetRadius = radius + rng.nextDouble() * 6;
      final point = Offset(
        center.dx + cos(angle) * offsetRadius,
        center.dy + sin(angle) * offsetRadius * 0.7,
      );
      final color = sparkColors[i % sparkColors.length];
      final size = (2.8 + rng.nextDouble() * 2.2) * opacity;
      final sparkPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.95);

      final sparkPath = Path()
        ..moveTo(point.dx, point.dy - size)
        ..lineTo(point.dx + size * 0.4, point.dy)
        ..lineTo(point.dx, point.dy + size)
        ..lineTo(point.dx - size * 0.4, point.dy)
        ..close();
      canvas.drawPath(sparkPath, sparkPaint);
    }
  }

  void _drawWobbleSurface(
    Canvas canvas,
    double left,
    double right,
    double surfaceY,
    Color color,
  ) {
    final baseColor = GameColors.normalize(color);
    final width = right - left;
    final amplitude = (isSource || isDest) ? 2.8 : 1.4;
    final frequency = 2.0 * pi * 1.7 / width;
    final wavePath = Path()..moveTo(left, surfaceY);

    for (double x = left; x <= right; x += 1.4) {
      final y =
          surfaceY + amplitude * sin(frequency * (x - left) + wobblePhase);
      wavePath.lineTo(x, y);
    }

    wavePath
      ..lineTo(right, surfaceY + amplitude + 5)
      ..lineTo(left, surfaceY + amplitude + 5)
      ..close();

    final surfacePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;
    canvas.drawPath(wavePath, surfacePaint);
  }

  void _drawStar(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    Color color,
  ) {
    final baseColor = GameColors.normalize(color);
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
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          GameColors.lighten(baseColor, 0.18),
          baseColor,
          GameColors.darken(baseColor, 0.16),
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
    final baseColor = GameColors.normalize(color);
    final path = Path()
      ..moveTo(cx, cy - radius)
      ..lineTo(cx + radius * 0.78, cy)
      ..lineTo(cx, cy + radius)
      ..lineTo(cx - radius * 0.78, cy)
      ..close();
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          GameColors.lighten(baseColor, 0.18),
          baseColor,
          GameColors.darken(baseColor, 0.14),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LiquidPainter oldDelegate) {
    return oldDelegate.bottle != bottle ||
        oldDelegate.tiltAngle != tiltAngle ||
        oldDelegate.levelProgress != levelProgress ||
        oldDelegate.isSource != isSource ||
        oldDelegate.isDest != isDest ||
        oldDelegate.pourCount != pourCount ||
        oldDelegate.pourColor != pourColor ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isHint != isHint ||
        oldDelegate.wobblePhase != wobblePhase ||
        oldDelegate.isSolved != isSolved ||
        oldDelegate.capProgress != capProgress ||
        oldDelegate.celebrationProgress != celebrationProgress ||
        oldDelegate.bottleType != bottleType ||
        oldDelegate.fillType != fillType ||
        oldDelegate.theme != theme;
  }
}
