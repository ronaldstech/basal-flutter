import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Account'),
          _buildSettingsTile(Iconsax.user, 'Profile details'),
          _buildSettingsTile(Iconsax.lock, 'Privacy & Security'),
          const SizedBox(height: 24),
          _buildSectionHeader('Playback'),
          _buildSettingsTile(Iconsax.music_dashboard, 'Audio Quality'),
          _buildSettingsTile(Iconsax.headphone, 'Equalizer'),
          const SizedBox(height: 24),
          _buildSectionHeader('Storage'),
          _buildSettingsTile(Iconsax.folder_open, 'Download Location'),
          _buildSettingsTile(Iconsax.trash, 'Clear Cache'),
          const SizedBox(height: 24),
          _buildSectionHeader('About'),
          _buildSettingsTile(Iconsax.info_circle, 'Version 1.0.0'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: () {},
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
