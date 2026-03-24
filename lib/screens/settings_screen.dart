import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Settings',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSettingsTile(
                    icon: Icons.volume_up_rounded,
                    title: 'Sound Effects',
                    trailing: Switch(
                      value: true,
                      onChanged: (val) {},
                      activeColor: AppTheme.accentSecondary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildSettingsTile(
                    icon: Icons.vibration_rounded,
                    title: 'Haptic Feedback',
                    trailing: Switch(
                      value: true,
                      onChanged: (val) {},
                      activeColor: AppTheme.accentSecondary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildSettingsTile(
                    icon: Icons.star_rate_rounded,
                    title: 'Rate Us',
                    trailing: Icon(Icons.arrow_forward_ios_rounded,
                        color: AppTheme.textSecondary, size: 18),
                    onTap: () {},
                  ),
                  const SizedBox(height: 15),
                  _buildSettingsTile(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    trailing: Icon(Icons.arrow_forward_ios_rounded,
                        color: AppTheme.textSecondary, size: 18),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      tileColor: Colors.white.withValues(alpha: 0.06),
      leading: Container(
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
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing,
    );
  }
}
