import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/game_ui.dart';
import 'tutorial_controller.dart';

class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({super.key, required this.controller});

  final TutorialController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final step = controller.currentStep;
        if (!controller.isActive || step == null) {
          return const SizedBox.shrink();
        }

        final theme = AppTheme.of(context);
        final helperMessage = controller.helperMessage;
        final guideMessage = helperMessage ?? step.message;

        return Positioned.fill(
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    color: theme.backgroundDeep.withValues(alpha: 0.36),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: GlassCard(
                        tint: theme.primaryAccent,
                        highlighted: true,
                        radius: AppTheme.radiusLarge,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: AppTheme.dialogDecoration(
                          tint: theme.primaryAccent,
                          theme: theme,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient(
                                  theme.primaryAccent,
                                  intensity: 0.9,
                                  theme: theme,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: const Icon(
                                Icons.smart_toy_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Puzzle AI',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: theme.primaryAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    guideMessage,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: theme.textPrimary,
                                      backgroundColor: helperMessage == null
                                          ? null
                                          : theme.warmAccent.withValues(
                                              alpha: 0.08,
                                            ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      height: 1.22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            _SkipButton(onTap: controller.skip),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GamePressable(
      onTap: () {
        onTap();
      },
      pressedScale: 0.96,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.textMuted.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.textMuted.withValues(alpha: 0.24)),
        ),
        child: Text(
          'Skip',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
