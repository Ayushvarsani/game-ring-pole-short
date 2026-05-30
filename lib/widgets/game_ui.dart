import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_theme_config.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.space16),
    this.margin,
    this.tint,
    this.radius = AppTheme.radiusMedium,
    this.blurSigma = 18,
    this.highlighted = false,
    this.muted = false,
    this.borderColor,
    this.decoration,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? tint;
  final double radius;
  final double blurSigma;
  final bool highlighted;
  final bool muted;
  final Color? borderColor;
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final borderRadius = BorderRadius.circular(radius);
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration:
                decoration ??
                AppTheme.glassDecoration(
                  theme: theme,
                  tint: tint,
                  borderColor: borderColor,
                  radius: radius,
                  highlighted: highlighted,
                  muted: muted,
                ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class GamePressable extends StatefulWidget {
  const GamePressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.95,
    this.hoverScale = 1.01,
    this.duration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final double hoverScale;
  final Duration duration;

  @override
  State<GamePressable> createState() => _GamePressableState();
}

class _GamePressableState extends State<GamePressable> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final scale = enabled && _pressed
        ? widget.pressedScale
        : enabled && _hovered
        ? widget.hoverScale
        : 1.0;

    return MouseRegion(
      onEnter: enabled ? (_) => _setHovered(true) : null,
      onExit: enabled ? (_) => _setHovered(false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        child: AnimatedScale(
          duration: widget.duration,
          curve: Curves.easeInOut,
          scale: scale,
          child: widget.child,
        ),
      ),
    );
  }
}

class GameIconButton extends StatelessWidget {
  const GameIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tint,
    this.size = 22,
    this.padding = const EdgeInsets.all(12),
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? tint;
  final double size;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final accent = tint ?? theme.primaryAccent;
    return GamePressable(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: onTap == null ? 0.42 : 1,
        child: GlassCard(
          tint: accent,
          radius: 18,
          muted: true,
          padding: padding,
          child: Icon(icon, color: theme.textPrimary, size: size),
        ),
      ),
    );
  }
}

class GameBadge extends StatelessWidget {
  const GameBadge({
    super.key,
    required this.text,
    required this.tint,
    this.icon,
  });

  final String text;
  final Color tint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient(tint, intensity: 0.84, theme: theme),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: AppTheme.premiumShadows(
          tint,
          emphasized: false,
          theme: theme,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class GameStatChip extends StatelessWidget {
  const GameStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tint,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? tint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final accent = tint ?? theme.primaryAccent;
    final iconBubble = Container(
      width: compact ? 28 : 34,
      height: compact ? 28 : 34,
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient(accent, intensity: 0.9, theme: theme),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Icon(icon, color: Colors.white, size: compact ? 15 : 18),
    );

    return GlassCard(
      tint: accent,
      radius: compact ? 18 : 22,
      highlighted: compact,
      muted: !compact,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 14,
      ),
      child: compact
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconBubble,
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textMuted.withValues(alpha: 0.94),
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    iconBubble,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.28,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

enum GameButtonLayout { horizontal, vertical }

class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.accentColor,
    this.onTap,
    this.subtitle,
    this.icon,
    this.badgeCount,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    this.minHeight = 72,
    this.radius = 24,
    this.layout = GameButtonLayout.horizontal,
    this.emphasized = false,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final int? badgeCount;
  final VoidCallback? onTap;
  final Color accentColor;
  final EdgeInsetsGeometry padding;
  final double minHeight;
  final double radius;
  final GameButtonLayout layout;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final enabled = onTap != null;
    return GamePressable(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.42,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: DecoratedBox(
            decoration: AppTheme.gradientButtonDecoration(
              accentColor: accentColor,
              isEnabled: enabled,
              emphasized: emphasized,
              radius: radius,
              theme: theme,
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 1,
                  right: 1,
                  top: 1,
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius - 2),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: padding,
                  child: layout == GameButtonLayout.vertical
                      ? _buildVerticalContent(enabled, theme)
                      : _buildHorizontalContent(enabled, theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalContent(bool enabled, AppThemeConfig theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: enabled ? 0.82 : 0.65,
                    ),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalContent(bool enabled, AppThemeConfig theme) {
    final compact = subtitle == null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null)
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: compact ? 36 : 42,
                height: compact ? 36 : 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: compact ? 19 : 22),
              ),
              if (badgeCount != null)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 22,
                      minHeight: 22,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient(
                        badgeCount! > 0 ? theme.warmAccent : theme.textMuted,
                        theme: theme,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        if (icon != null) SizedBox(height: compact ? 7 : 10),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: enabled ? 1.0 : 0.72),
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w800,
            letterSpacing: compact ? 0.32 : 0.42,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: enabled ? 0.76 : 0.58),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class GamePrimaryButton extends StatelessWidget {
  const GamePrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GameButton(
      label: label,
      subtitle: subtitle,
      icon: icon,
      onTap: onTap,
      accentColor: theme.primaryAccent,
      padding: padding,
      minHeight: 52,
      radius: 22,
      layout: GameButtonLayout.horizontal,
      emphasized: true,
    );
  }
}

class GameTabItem {
  const GameTabItem({required this.label, required this.tint, this.icon});

  final String label;
  final Color tint;
  final IconData? icon;
}

class GameSegmentedTabBar extends StatelessWidget {
  const GameSegmentedTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<GameTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final currentTint = items[selectedIndex].tint;
    return GlassCard(
      tint: currentTint,
      radius: 24,
      muted: true,
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / items.length;
          return SizedBox(
            height: 52,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  left: selectedIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: DecoratedBox(
                      decoration: AppTheme.gradientButtonDecoration(
                        accentColor: currentTint,
                        emphasized: true,
                        radius: 18,
                        theme: theme,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final selected = index == selectedIndex;
                    return Expanded(
                      child: GamePressable(
                        onTap: () => onChanged(index),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: selected ? 1.0 : 0.62,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item.icon != null) ...[
                                  Icon(
                                    item.icon,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      letterSpacing: selected ? 0.4 : 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class GameDialogFrame extends StatelessWidget {
  const GameDialogFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.tint,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final Color? tint;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GlassCard(
      tint: tint ?? theme.primaryAccent,
      radius: AppTheme.radiusLarge,
      highlighted: true,
      padding: padding,
      decoration: AppTheme.dialogDecoration(tint: tint, theme: theme),
      child: Stack(
        children: [
          Positioned(
            left: -28,
            right: -28,
            top: -34,
            height: 130,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.9,
                    colors: [
                      (tint ?? theme.primaryAccent).withValues(alpha: 0.16),
                      theme.boardAura.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.1,
                            height: 1.04,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: theme.textSecondary.withValues(
                                alpha: 0.86,
                              ),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                              letterSpacing: 0.14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 14),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ],
      ),
    );
  }
}
