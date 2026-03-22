import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/app_theme.dart';

class WhatsNewView extends StatelessWidget {
  const WhatsNewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What\'s New', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Iconsax.discover, size: 64, color: AppTheme.primaryColor),
          const SizedBox(height: 24),
          const Text(
            'Welcome to the new Basal',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),
          _buildFeatureRow(
            Iconsax.music_playlist,
            'Custom Playlists',
            'Create your own custom playlists, add your favorite local songs, and keep everything in sync.',
          ),
          const SizedBox(height: 24),
          _buildFeatureRow(
            Iconsax.import,
            'Download Manager',
            'Download individual tracks or entire playlists directly to your device for offline listening.',
          ),
          const SizedBox(height: 24),
          _buildFeatureRow(
            Iconsax.crown,
            'Premium Architecture',
            'Enjoy an ad-free experience, unlimited skips, and premium sound quality with our new subscription plans.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
