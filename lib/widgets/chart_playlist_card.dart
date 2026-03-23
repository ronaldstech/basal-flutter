import 'package:flutter/material.dart';
import '../models/music_models.dart';
import '../widgets/skeleton_image.dart';
import 'package:iconsax/iconsax.dart';
import '../views/playlist_detail_view.dart';
import '../theme/app_theme.dart';

class ChartPlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final int rank;

  const ChartPlaylistCard({super.key, required this.playlist, required this.rank});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistDetailView(playlist: playlist),
        ),
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SkeletonImage(
                  imageUrl: playlist.imageUrl,
                  height: 160,
                  width: 160,
                  borderRadius: 12,
                ),
                // Rank Badge
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Text(
                      '#$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                // Play Icon Overlay
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.play5, color: Colors.black, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Row(
              children: [
                const Icon(Iconsax.trend_up, color: AppTheme.primaryColor, size: 12),
                const SizedBox(width: 4),
                Text(
                  'Global Trending',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
