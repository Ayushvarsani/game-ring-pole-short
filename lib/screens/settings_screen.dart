import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSettingsTile(
            icon: Icons.volume_up_rounded,
            title: 'Sound Effects',
            trailing: Switch(
              value: true,
              onChanged: (val) {},
            ),
          ),
          const SizedBox(height: 15),
          _buildSettingsTile(
            icon: Icons.vibration_rounded,
            title: 'Haptic Feedback',
            trailing: Switch(
              value: true,
              onChanged: (val) {},
            ),
          ),
          const SizedBox(height: 15),
          _buildSettingsTile(
            icon: Icons.star_rate_rounded,
            title: 'Rate Us',
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
            onTap: () {},
          ),
          const SizedBox(height: 15),
          _buildSettingsTile(
            icon: Icons.privacy_tip_rounded,
            title: 'Privacy Policy',
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
            onTap: () {},
          ),
        ],
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
      tileColor: Colors.white.withValues(alpha: 0.08),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF4FC3F7), size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing,
    );
  }
}
