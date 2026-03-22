import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/skeleton_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../providers/audio_provider.dart';
import '../providers/firestore_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/lyrics_sheet.dart';
import '../widgets/queue_sheet.dart';
import '../providers/auth_provider.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final currentSong = audioState.currentSong;
    final likedIds = ref.watch(likedSongIdsProvider).valueOrNull ?? [];

    if (currentSong == null) return const Scaffold();

    final isLiked = likedIds.contains(currentSong.id);
    final isShuffled = audioState.isShuffled;
    final repeatMode = audioState.repeatMode;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Hero(
                tag: 'song-${currentSong.id}',
                child: SkeletonImage(
                  imageUrl: currentSong.thumbnailUrl,
                  height: MediaQuery.of(context).size.width * 0.8,
                  width: MediaQuery.of(context).size.width * 0.8,
                  borderRadius: 24,
                ),
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSong.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            currentSong.artist,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isLiked ? Iconsax.heart5 : Iconsax.heart,
                        color: isLiked ? AppTheme.primaryColor : Colors.white70,
                        size: 28,
                      ),
                      onPressed: () async {
                        await ref.read(firestoreServiceProvider).toggleLikedSong(currentSong);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                ProgressBar(
                  progress: audioState.position,
                  buffered: audioState.bufferedPosition,
                  total: audioState.totalDuration,
                  progressBarColor: AppTheme.primaryColor,
                  baseBarColor: Colors.white12,
                  bufferedBarColor: Colors.white24,
                  thumbColor: Colors.white,
                  thumbRadius: 8,
                  onSeek: (duration) {
                    ref.read(audioProvider.notifier).seek(duration);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Shuffle
                    IconButton(
                      icon: Stack(
                        children: [
                          Icon(
                            Iconsax.shuffle,
                            color: isShuffled ? AppTheme.primaryColor : Colors.white70,
                            size: 22,
                          ),
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
                          ref.read(audioProvider.notifier).toggleShuffle();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Shuffle is for Premium members only'),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          );
                        }
                      },
                    ),
                    // Previous
                    IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Iconsax.previous5, color: Colors.white, size: 40),
                          if (!ref.watch(isPremiumProvider))
                            const Positioned(
                              right: 2,
                              top: 2,
                              child: Icon(Icons.lock, size: 12, color: AppTheme.primaryColor),
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
                    // Play / Pause
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        padding: const EdgeInsets.all(14),
                        icon: Icon(
                          audioState.isPlaying ? Iconsax.pause5 : Iconsax.play5,
                          color: Colors.black,
                          size: 36,
                        ),
                        onPressed: () => ref.read(audioProvider.notifier).togglePlay(),
                      ),
                    ),
                    // Next
                    IconButton(
                      icon: const Icon(Iconsax.next5, color: Colors.white, size: 40),
                      onPressed: () => ref.read(audioProvider.notifier).skipToNext(),
                    ),
                    // Repeat
                    IconButton(
                      icon: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            repeatMode == RepeatMode.one
                                ? Iconsax.repeate_one5
                                : Iconsax.repeate_music,
                            color: repeatMode != RepeatMode.none
                                ? AppTheme.primaryColor
                                : Colors.white70,
                            size: 22,
                          ),
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
                          ref.read(audioProvider.notifier).cycleRepeatMode();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Repeat modes are for Premium members only'),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom row: Lyrics (left) and Queue (right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.lyrics_outlined, size: 20, color: Colors.white54),
                  label: const Text('Lyrics', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  onPressed: () => showLyricsSheet(context, currentSong),
                ),
                TextButton.icon(
                  icon: const Icon(Iconsax.music_playlist, size: 20, color: Colors.white54),
                  label: const Text('Queue', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  onPressed: () => showQueueSheet(context, ref),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
