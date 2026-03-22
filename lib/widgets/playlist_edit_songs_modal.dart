import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/skeleton_image.dart';
import '../models/music_models.dart';
import '../providers/firestore_provider.dart';

class PlaylistEditSongsModal extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistEditSongsModal({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsStreamProvider);
    final playlistsAsync = ref.watch(playlistsStreamProvider);
    final currentPlaylist = playlistsAsync.valueOrNull?.firstWhere(
      (p) => p.id == playlist.id,
      orElse: () => playlist,
    ) ?? playlist;

    final allSongs = songsAsync.valueOrNull ?? [];
    final playlistSongs = allSongs
        .where((song) => currentPlaylist.songIds.contains(song.id))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Edit Songs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: playlistSongs.isEmpty
                ? const Center(child: Text('Playlist is empty', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: playlistSongs.length,
                    itemBuilder: (context, index) {
                      final song = playlistSongs[index];
                      return ListTile(
                        leading: IconButton(
                          icon: const Icon(Iconsax.minus_cirlce, color: Colors.redAccent),
                          onPressed: () async {
                            await ref.read(firestoreServiceProvider).removeSongFromPlaylist(
                              currentPlaylist.id,
                              song.id
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Removed ${song.title}'), backgroundColor: Colors.redAccent),
                              );
                            }
                          },
                        ),
                        title: Text(song.title, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: SkeletonImage(
                          imageUrl: song.thumbnailUrl,
                          width: 48,
                          height: 48,
                          borderRadius: 8,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
