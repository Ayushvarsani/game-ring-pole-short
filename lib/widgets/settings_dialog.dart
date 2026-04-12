import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';
import '../theme/app_theme.dart';
import 'game_ui.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return GameDialogFrame(
            title: 'Settings',
            subtitle: 'Tune the game feel for your play sessions.',
            tint: theme.primaryAccent,
            trailing: GameIconButton(
              icon: Icons.close_rounded,
              tint: theme.warmAccent,
              onTap: () {
                context.read<SettingsCubit>().playClickSound();
                Navigator.of(context).pop();
              },
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSwitchTile(
                  context: context,
                  icon: state.soundEnabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  title: 'Sound',
                  subtitle: 'Tap sounds, rewards, and feedback cues',
                  value: state.soundEnabled,
                  tint: theme.secondaryAccent,
                  onChanged: (value) {
                    context.read<SettingsCubit>().toggleSound(value);
                    if (value) context.read<SettingsCubit>().playClickSound();
                  },
                ),
                const SizedBox(height: 14),
                _buildSwitchTile(
                  context: context,
                  icon: state.vibrateEnabled
                      ? Icons.vibration_rounded
                      : Icons.phone_android_rounded,
                  title: 'Vibration',
                  subtitle: 'Haptics for taps, pours, and rewards',
                  value: state.vibrateEnabled,
                  tint: theme.goldAccent,
                  onChanged: (value) {
                    context.read<SettingsCubit>().toggleVibration(value);
                    if (value) {
                      context.read<SettingsCubit>().triggerLightHaptic();
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color tint,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: AppTheme.surfaceDecoration(
        tint: tint,
        radius: 22,
        muted: true,
        theme: theme,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: tint, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: tint,
            inactiveThumbColor: theme.textSecondary,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}
