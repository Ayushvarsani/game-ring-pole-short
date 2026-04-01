import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';
import '../theme/app_theme.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: AppTheme.dialogDecoration(),
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppTheme.textPrimary, AppTheme.accentSecondary],
                          ).createShader(bounds),
                          child: const Text(
                            'Settings',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 26),
                        onPressed: () {
                          context.read<SettingsCubit>().playClickSound();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSwitchTile(
                  icon: state.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  title: 'Sound',
                  value: state.soundEnabled,
                  onChanged: (val) {
                    context.read<SettingsCubit>().toggleSound(val);
                    if (val) context.read<SettingsCubit>().playClickSound();
                  },
                ),
                const SizedBox(height: 16),
                _buildSwitchTile(
                  icon: state.vibrateEnabled ? Icons.vibration_rounded : Icons.phone_android_rounded,
                  title: 'Vibrate',
                  value: state.vibrateEnabled,
                  onChanged: (val) {
                    context.read<SettingsCubit>().toggleVibration(val);
                    if (val) context.read<SettingsCubit>().triggerLightHaptic();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentSecondary.withValues(alpha: 0.25),
                      AppTheme.accentPrimary.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.accentSecondary, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.accentSecondary,
            activeTrackColor: AppTheme.accentSecondary.withValues(alpha: 0.3),
            inactiveThumbColor: AppTheme.textSecondary,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }
}
