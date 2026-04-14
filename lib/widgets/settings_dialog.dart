import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';
import '../theme/app_theme.dart';
import 'game_ui.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({
    super.key,
    this.onShare,
    this.onFeedback,
    this.onQuitGame,
  });

  final VoidCallback? onShare;
  final VoidCallback? onFeedback;
  final VoidCallback? onQuitGame;

  void _closeModal(BuildContext context) {
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerLightHaptic();
    Navigator.of(context).pop();
  }

  void _toggleSound(BuildContext context, bool enabled) {
    final cubit = context.read<SettingsCubit>();
    cubit.playClickSound();
    cubit.toggleSound(enabled);
    if (enabled) {
      cubit.playClickSound();
    }
  }

  void _toggleMusic(BuildContext context, bool enabled) {
    final cubit = context.read<SettingsCubit>();
    cubit.playClickSound();
    cubit.toggleMusic(enabled);
  }

  void _toggleVibration(BuildContext context, bool enabled) {
    final cubit = context.read<SettingsCubit>();
    cubit.playClickSound();
    cubit.toggleVibration(enabled);
    if (enabled) {
      cubit.triggerLightHaptic();
    }
  }

  void _showNotice(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black.withValues(alpha: 0.9),
          content: Text(message),
        ),
      );
  }

  void _handleShare(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    cubit.playClickSound();
    cubit.triggerSelectionHaptic();

    if (onShare != null) {
      onShare!.call();
      return;
    }

    Clipboard.setData(
      const ClipboardData(text: 'Mind Color Pour - premium puzzle game'),
    );
    _showNotice(context, 'Game title copied for sharing.');
  }

  Future<void> _handleFeedback(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    cubit.playClickSound();
    cubit.triggerSelectionHaptic();

    if (onFeedback != null) {
      onFeedback!.call();
      return;
    }

    // Prepare mailto link
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'ayush.patel2778@gmail.com',
      // Spaces must be encoded but Uri helper handles most of it,
      // though older url_launcher required explicit encoding.
      query: _encodeQueryParameters(<String, String>{
        'subject': 'App Feedback',
        'body': "Hi, I'd like to share feedback about the app...\n\n",
      }),
    );

    try {
      if (!await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          _showNotice(context, 'Could not open email app.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showNotice(context, 'Could not open email app.');
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _handleQuitGame(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    cubit.playClickSound();
    cubit.triggerHeavyHaptic();

    Navigator.of(context).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onQuitGame != null) {
        onQuitGame!.call();
        return;
      }
      SystemNavigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final modalWidth = math.min(screenSize.width * 0.88, 408.0);
    const rowHeight = 58.0;
    const headerHeight = 54.0;
    const horizontalPadding = 16.0;
    const topPadding = 14.0;
    const bottomPadding = 14.0;
    const rowGap = 10.0; // consistent rhythm: same as between Sound/Music/Vib
    const actionStripHeight = 52.0;

    final shareTint = Color.lerp(
      theme.textPrimary,
      theme.secondaryAccent,
      0.52,
    )!;
    final feedbackTint = Color.lerp(
      theme.primaryAccent,
      theme.secondaryAccent,
      0.22,
    )!;
    final quitTint = Color.lerp(theme.dangerAccent, theme.warmAccent, 0.12)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final toggleEntries = <_SettingsEntry>[
            _SettingsEntry(
              icon: state.soundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              tint: theme.ambientGlow,
              title: 'Sound',
              subtitle: 'Effects and reward audio',
              onTap: () => _toggleSound(context, !state.soundEnabled),
              trailing: _PremiumSettingsToggle(
                value: state.soundEnabled,
                tint: theme.ambientGlow,
                onChanged: (value) => _toggleSound(context, value),
              ),
            ),
            _SettingsEntry(
              icon: state.musicEnabled
                  ? Icons.graphic_eq_rounded
                  : Icons.music_off_rounded,
              tint: theme.secondaryAccent,
              title: 'Music',
              subtitle: 'Background game music',
              onTap: () => _toggleMusic(context, !state.musicEnabled),
              trailing: _PremiumSettingsToggle(
                value: state.musicEnabled,
                tint: theme.secondaryAccent,
                onChanged: (value) => _toggleMusic(context, value),
              ),
            ),
            _SettingsEntry(
              icon: state.vibrateEnabled
                  ? Icons.vibration_rounded
                  : Icons.phone_android_rounded,
              tint: theme.goldAccent,
              title: 'Vibration',
              subtitle: 'Haptics and feedback',
              onTap: () => _toggleVibration(context, !state.vibrateEnabled),
              trailing: _PremiumSettingsToggle(
                value: state.vibrateEnabled,
                tint: theme.goldAccent,
                onChanged: (value) => _toggleVibration(context, value),
              ),
            ),
          ];

          return SizedBox(
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
                            theme.boardAura.withValues(alpha: 0.08),
                            theme.boardHalo.withValues(alpha: 0.03),
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
                        Colors.white.withValues(alpha: 0.16),
                        theme.boardAura.withValues(alpha: 0.12),
                        theme.boardHalo.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.06),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.26),
                        blurRadius: 24,
                        spreadRadius: -16,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: theme.boardHalo.withValues(alpha: 0.06),
                        blurRadius: 14,
                        spreadRadius: -12,
                      ),
                    ],
                  ),
                  child: GlassCard(
                    tint: theme.primaryAccent,
                    radius: 29,
                    blurSigma: 10,
                    muted: true,
                    padding: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(29),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(
                            theme.surfaceStrong,
                            Colors.white,
                            0.04,
                          )!,
                          Color.lerp(
                            theme.surface,
                            theme.backgroundDark,
                            0.22,
                          )!,
                          Color.lerp(
                            theme.backgroundDeep,
                            Colors.black,
                            0.05,
                          )!,
                        ],
                        stops: const [0.0, 0.58, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 0,
                          child: IgnorePointer(
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.08),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            horizontalPadding,
                            topPadding,
                            horizontalPadding,
                            bottomPadding,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── Header ──────────────────────────────────
                              SizedBox(
                                height: headerHeight,
                                child: _SettingsHeader(
                                  onClose: () => _closeModal(context),
                                ),
                              ),
                              const SizedBox(height: rowGap),
                              // ── Toggle rows ──────────────────────────────
                              ...List.generate(toggleEntries.length, (i) {
                                final entry = toggleEntries[i];
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (i > 0) ...[
                                      _SettingsSeparator(
                                        tint: entry.tint,
                                      ),
                                    ],
                                    _SettingsOptionRow(
                                      height: rowHeight,
                                      icon: entry.icon,
                                      tint: entry.tint,
                                      title: entry.title,
                                      subtitle: entry.subtitle,
                                      trailing: entry.trailing,
                                      onTap: entry.onTap,
                                    ),
                                  ],
                                );
                              }),
                              // ── Divider + action strip ───────────────────
                              const SizedBox(height: rowGap),
                              _SettingsSeparator(tint: theme.textMuted),
                              const SizedBox(height: rowGap),
                              SizedBox(
                                height: actionStripHeight,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _SettingsActionButton(
                                        icon: Icons.ios_share_rounded,
                                        label: 'Share',
                                        tint: shareTint,
                                        onTap: () => _handleShare(context),
                                      ),
                                    ),
                                    _SettingsActionDivider(
                                      tint: theme.textMuted,
                                    ),
                                    Expanded(
                                      child: _SettingsActionButton(
                                        icon: Icons.forum_rounded,
                                        label: 'Feedback',
                                        tint: feedbackTint,
                                        onTap: () =>
                                            _handleFeedback(context),
                                      ),
                                    ),
                                    _SettingsActionDivider(
                                      tint: theme.textMuted,
                                    ),
                                    Expanded(
                                      child: _SettingsActionButton(
                                        icon:
                                            Icons.power_settings_new_rounded,
                                        label: 'Quit Game',
                                        tint: quitTint,
                                        emphasized: true,
                                        onTap: () =>
                                            _handleQuitGame(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal action button (icon on top, label beneath)
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsActionButton extends StatelessWidget {
  const _SettingsActionButton({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return GamePressable(
      onTap: onTap,
      pressedScale: 0.93,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: emphasized ? 0.14 : 0.1),
                  tint.withValues(alpha: emphasized ? 0.22 : 0.14),
                  Colors.black.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: emphasized ? 0.16 : 0.09,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: tint.withValues(
                    alpha: emphasized ? 0.18 : 0.10,
                  ),
                  blurRadius: 14,
                  spreadRadius: -8,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 10,
                  spreadRadius: -10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Subtle inner highlight
                Positioned(
                  left: 6,
                  right: 6,
                  top: 4,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    icon,
                    color: tint.withValues(
                      alpha: emphasized ? 1.0 : 0.92,
                    ),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Thin vertical divider between action buttons
class _SettingsActionDivider extends StatelessWidget {
  const _SettingsActionDivider({required this.tint});

  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            tint.withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unchanged private widgets below
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return SizedBox(
      height: 52,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.18,
                    shadows: [
                      Shadow(
                        color: theme.boardAura.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tune your play experience',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textSecondary.withValues(alpha: 0.78),
                    fontSize: 11.6,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _SettingsCloseButton(tint: theme.textSecondary, onTap: onClose),
        ],
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

class _SettingsOptionRow extends StatelessWidget {
  const _SettingsOptionRow({
    required this.height,
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final double height;
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return GamePressable(
      onTap: onTap,
      pressedScale: 0.998,
      hoverScale: 1.0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withValues(alpha: 0.03),
              tint.withValues(alpha: 0.03),
              Colors.transparent,
            ],
          ),
        ),
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              _SettingsLeadingIcon(icon: icon, tint: tint),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.12,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textSecondary.withValues(alpha: 0.82),
                        fontSize: 11.2,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 56,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: trailing,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsLeadingIcon extends StatelessWidget {
  const _SettingsLeadingIcon({required this.icon, required this.tint});

  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            tint.withValues(alpha: 0.14),
            theme.backgroundDeep.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 5,
            right: 5,
            top: 4,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(child: Icon(icon, color: tint, size: 16)),
        ],
      ),
    );
  }
}

class _PremiumSettingsToggle extends StatelessWidget {
  const _PremiumSettingsToggle({
    required this.value,
    required this.tint,
    required this.onChanged,
  });

  final bool value;
  final Color tint;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Semantics(
      button: true,
      checked: value,
      child: GamePressable(
        onTap: () => onChanged(!value),
        pressedScale: 0.98,
        hoverScale: 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: 48,
          height: 27,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: value
                ? AppTheme.accentGradient(tint, intensity: 0.76, theme: theme)
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      theme.backgroundDeep.withValues(alpha: 0.3),
                    ],
                  ),
            border: Border.all(
              color: Colors.white.withValues(alpha: value ? 0.12 : 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                spreadRadius: -10,
                offset: const Offset(0, 6),
              ),
              if (value)
                BoxShadow(
                  color: tint.withValues(alpha: 0.12),
                  blurRadius: 10,
                  spreadRadius: -12,
                ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 7,
                right: 7,
                top: 2,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.9),
                        Color.lerp(Colors.white, tint, 0.15)!,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        spreadRadius: -6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSeparator extends StatelessWidget {
  const _SettingsSeparator({required this.tint});

  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 44),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0.02),
            tint.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
      ),
    );
  }
}

class _SettingsEntry {
  const _SettingsEntry({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;
}
