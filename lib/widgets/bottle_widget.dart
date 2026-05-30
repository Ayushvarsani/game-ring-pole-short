import 'package:flutter/material.dart';

import '../models/bottle_model.dart';
import '../models/bottle_type.dart';
import '../models/fill_type.dart';
import '../painters/liquid_painter.dart';
import '../theme/app_theme.dart';

class BottleWidget extends StatelessWidget {
  const BottleWidget({
    super.key,
    required this.bottle,
    required this.bottleType,
    required this.fillType,
    required this.size,
    this.tiltAngle = 0.0,
    this.levelProgress = 0.0,
    this.pourCount = 0,
    this.pourColor,
    this.isSource = false,
    this.isDest = false,
    this.isSelected = false,
    this.isHint = false,
    this.wobblePhase = 0.0,
    this.isSolved = false,
    this.capProgress = 0.0,
    this.celebrationProgress = 0.0,
    this.scale = 1.0,
    this.translation = Offset.zero,
    this.measureKey,
  });

  final BottleModel bottle;
  final BottleType bottleType;
  final FillType fillType;
  final Size size;
  final double tiltAngle;
  final double levelProgress;
  final int pourCount;
  final Color? pourColor;
  final bool isSource;
  final bool isDest;
  final bool isSelected;
  final bool isHint;
  final double wobblePhase;
  final bool isSolved;
  final double capProgress;
  final double celebrationProgress;
  final double scale;
  final Offset translation;
  final Key? measureKey;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return SizedBox(
      key: measureKey,
      width: size.width,
      height: size.height,
      child: Transform.translate(
        offset: translation,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: CustomPaint(
              painter: LiquidPainter(
                bottle: bottle,
                tiltAngle: tiltAngle,
                levelProgress: levelProgress,
                isSource: isSource,
                isDest: isDest,
                pourCount: pourCount,
                pourColor: pourColor,
                isSelected: isSelected,
                isHint: isHint,
                wobblePhase: wobblePhase,
                isSolved: isSolved,
                capProgress: capProgress,
                celebrationProgress: celebrationProgress,
                bottleType: bottleType,
                fillType: fillType,
                theme: theme,
              ),
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}
