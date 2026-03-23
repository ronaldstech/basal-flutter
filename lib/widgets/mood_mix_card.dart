import 'package:flutter/material.dart';
import '../models/music_models.dart';
import '../widgets/skeleton_image.dart';
import 'package:iconsax/iconsax.dart';
import '../views/playlist_detail_view.dart';

class MoodMixCard extends StatelessWidget {
  final Playlist playlist;

  const MoodMixCard({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    // Determine gradient based on playlist name or logic
    final Color moodColor = _getMoodColor(playlist.name);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistDetailView(playlist: playlist),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              moodColor.withOpacity(0.8),
              moodColor.withOpacity(0.2),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: moodColor.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Abstract background pattern or slightly visible image
              Positioned(
                right: -20,
                bottom: -20,
                child: Opacity(
                  opacity: 0.3,
                  child: SkeletonImage(
                    imageUrl: playlist.imageUrl,
                    width: 100,
                    height: 100,
                    borderRadius: 50,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.music_filter, color: Colors.white, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(0, 2))
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Personalized for you',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('chill')) return Colors.blueAccent;
    if (n.contains('focus')) return Colors.teal;
    if (n.contains('energy') || n.contains('party')) return Colors.orangeAccent;
    if (n.contains('sad') || n.contains('blues')) return Colors.indigo;
    if (n.contains('gym') || n.contains('workout')) return Colors.redAccent;
    return Colors.purpleAccent; // Default
  }
}
