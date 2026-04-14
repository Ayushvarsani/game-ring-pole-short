import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/settings_cubit.dart';
import '../models/cross_promo_game.dart';
import '../theme/app_theme.dart';
import 'game_ui.dart';

class OurGamesDialog extends StatelessWidget {
  const OurGamesDialog({super.key});

  void _closeModal(BuildContext context) {
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerLightHaptic();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final modalWidth = math.min(screenSize.width * 0.88, 408.0);
    const horizontalPadding = 16.0;
    const topPadding = 14.0;
    const bottomPadding = 14.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SizedBox(
        width: modalWidth,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.08,
                      colors: [
                        theme.primaryAccent.withOpacity(0.12),
                        theme.boardHalo.withOpacity(0.04),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.44, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    theme.primaryAccent.withOpacity(0.15),
                    theme.secondaryAccent.withOpacity(0.15),
                    Colors.white.withOpacity(0.08),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 24,
                    spreadRadius: -12,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: GlassCard(
                tint: theme.primaryAccent,
                radius: 29,
                blurSigma: 12,
                muted: true,
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(29),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(theme.surfaceStrong, Colors.white, 0.06)!,
                      Color.lerp(theme.surface, theme.backgroundDark, 0.25)!,
                      Color.lerp(theme.backgroundDeep, Colors.black, 0.1)!,
                    ],
                    stops: const [0.0, 0.58, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topPadding,
                    horizontalPadding,
                    bottomPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      SizedBox(
                        height: 54,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Our Games',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: theme.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.18,
                                      shadows: [
                                        Shadow(
                                          color: theme.boardAura
                                              .withValues(alpha: 0.1),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Check out our newest hit',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: theme.textSecondary
                                          .withOpacity(0.78),
                                      fontSize: 11.6,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            _SettingsCloseButton(
                                tint: theme.textSecondary,
                                onTap: () => _closeModal(context)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Single Featured Game Card
                      const _FeaturedGameCard(),
                      const SizedBox(height: 20),
                      // Footer Branding
                      Center(
                        child: Text(
                          'Powered by Brainora Infotech',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCloseButton extends StatelessWidget {
  const _SettingsCloseButton({required this.tint, required this.onTap});

  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GamePressable(
      onTap: onTap,
      pressedScale: 0.96,
      hoverScale: 1.0,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              tint.withValues(alpha: 0.06),
              Colors.black.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: -10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 5,
              right: 5,
              top: 3,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(child: Icon(Icons.close_rounded, color: tint, size: 15)),
          ],
        ),
      ),
    );
  }
}

class _FeaturedGameCard extends StatefulWidget {
  const _FeaturedGameCard();

  @override
  State<_FeaturedGameCard> createState() => _FeaturedGameCardState();
}

class _FeaturedGameCardState extends State<_FeaturedGameCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  final CrossPromoGame game = predefinedCrossPromoGames.first;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _launchGame() async {
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerLightHaptic();
    final url = Uri.parse(game.playStoreUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {}
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return GestureDetector(
      onTapDown: (_) {
        _animController.forward();
        setState(() => _isHovered = true);
      },
      onTapUp: (_) {
        _animController.reverse();
        setState(() => _isHovered = false);
        _launchGame();
      },
      onTapCancel: () {
        _animController.reverse();
        setState(() => _isHovered = false);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withOpacity(0.12)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered
                  ? theme.primaryAccent.withOpacity(0.5)
                  : Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: theme.primaryAccent.withOpacity(0.2),
                      blurRadius: 15,
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 90,
                height: 90,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryAccent.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: Image.asset(
                      game.iconUrl,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.secondaryAccent.withOpacity(0.2),
                        child: const Icon(Icons.videogame_asset_rounded,
                            color: Colors.white54, size: 36),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      game.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: theme.goldAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Play Now',
                          style: TextStyle(
                            color: theme.goldAccent.withOpacity(0.95),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
