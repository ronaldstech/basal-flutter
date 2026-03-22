import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../widgets/skeleton_image.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/audio_provider.dart';
import '../views/player_screen.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final currentSong = audioState.currentSong;

    if (currentSong == null) return const SizedBox.shrink();

    final position = audioState.position;
    final duration = audioState.totalDuration;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PlayerScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 64,
          borderRadius: 16,
          blur: 20,
          alignment: Alignment.center,
          border: 1,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.1),
            ],
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      SkeletonImage(
                        imageUrl: currentSong.thumbnailUrl,
                        width: 48,
                        height: 48,
                        borderRadius: 8,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSong.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currentSong.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Stack(
                          children: [
                            const Icon(Iconsax.backward5, color: Colors.white, size: 20),
                            if (!ref.watch(isPremiumProvider))
                              const Positioned(
                                right: 0,
                                top: 0,
                                child: Icon(Icons.lock, size: 8, color: AppTheme.primaryColor),
                              ),
                          ],
                        ),
                        onPressed: () {
                          if (ref.read(isPremiumProvider)) {
                            ref.read(audioProvider.notifier).skipToPrevious();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Previous track skipping is for Premium members only'),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          audioState.isPlaying ? Iconsax.pause5 : Iconsax.play5,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          ref.read(audioProvider.notifier).togglePlay();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.forward5, color: Colors.white, size: 20),
                        onPressed: () => ref.read(audioProvider.notifier).skipToNext(),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 12,
                right: 12,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    minHeight: 2,
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
