import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GamePressable extends StatefulWidget {
  const GamePressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.965,
    this.duration = const Duration(milliseconds: 120),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final Duration duration;

  @override
  State<GamePressable> createState() => _GamePressableState();
}

class _GamePressableState extends State<GamePressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        scale: enabled && _pressed ? widget.pressedScale : 1,
        child: widget.child,
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
    final accent = tint ?? AppTheme.accentPrimary;
    return GamePressable(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: onTap == null ? 0.42 : 1,
        child: Container(
          padding: padding,
          decoration: AppTheme.surfaceDecoration(
            tint: accent,
            radius: 18,
            muted: true,
          ),
          child: Icon(icon, color: AppTheme.textPrimary, size: size),
        ),
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
    final accent = tint ?? AppTheme.accentPrimary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 10 : 12,
      ),
      decoration: AppTheme.chipDecoration(tint: accent, emphasized: compact),
      child: compact
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: accent, size: 16),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
                  style: TextStyle(
                    color: AppTheme.textMuted.withValues(alpha: 0.95),
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GamePressable(
      onTap: onTap,
      pressedScale: 0.97,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          padding: padding,
          decoration: AppTheme.primaryButtonDecoration(
            glowStrength: onTap == null ? 0.08 : 0.28,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
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

class GameDialogFrame extends StatelessWidget {
  const GameDialogFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.tint,
    this.padding = const EdgeInsets.fromLTRB(24, 22, 24, 24),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final Color? tint;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: AppTheme.dialogDecoration(tint: tint),
      child: Column(
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
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 16), trailing!],
            ],
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}
