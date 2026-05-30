import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: theme.backgroundGradient),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Settings',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              iconTheme: IconThemeData(color: theme.textPrimary),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.volume_up_rounded,
                    title: 'Sound Effects',
                    trailing: Switch(
                      value: true,
                      onChanged: (val) {},
                      activeThumbColor: theme.secondaryAccent,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.vibration_rounded,
                    title: 'Haptic Feedback',
                    trailing: Switch(
                      value: true,
                      onChanged: (val) {},
                      activeThumbColor: theme.secondaryAccent,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.star_rate_rounded,
                    title: 'Rate Us',
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.textSecondary,
                      size: 18,
                    ),
                    onTap: () {},
                  ),
                  const SizedBox(height: 15),
                  _buildSettingsTile(
                    context: context,
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: theme.textSecondary,
                      size: 18,
                    ),
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final theme = AppTheme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.white.withValues(alpha: 0.06),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.secondaryAccent.withValues(alpha: 0.25),
              theme.primaryAccent.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.secondaryAccent, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: theme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing,
    );
  }
}
