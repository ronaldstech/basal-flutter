import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/skeleton_image.dart';
import '../widgets/home_skeleton.dart';
import '../models/music_models.dart';
import '../providers/firestore_provider.dart';
import '../theme/app_theme.dart';

class PlaylistAddSongsModal extends ConsumerStatefulWidget {
  final Playlist playlist;
  const PlaylistAddSongsModal({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistAddSongsModal> createState() => _PlaylistAddSongsModalState();
}

class _PlaylistAddSongsModalState extends ConsumerState<PlaylistAddSongsModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsStreamProvider);
    final playlistsAsync = ref.watch(playlistsStreamProvider);
    final currentPlaylist = playlistsAsync.valueOrNull?.firstWhere(
      (p) => p.id == widget.playlist.id,
      orElse: () => widget.playlist,
    ) ?? widget.playlist;

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
            'Add Songs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search songs...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Iconsax.search_normal, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: songsAsync.when(
              data: (allSongs) {
                final availableSongs = allSongs.where((song) {
                  final matchesSearch = song.title.toLowerCase().contains(_searchQuery) ||
                                        song.artist.toLowerCase().contains(_searchQuery);
                  final notInPlaylist = !currentPlaylist.songIds.contains(song.id);
                  return matchesSearch && notInPlaylist;
                }).toList();

                if (availableSongs.isEmpty) {
                  return const Center(
                    child: Text('No songs found', style: TextStyle(color: Colors.white54)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: availableSongs.length,
                  itemBuilder: (context, index) {
                    final song = availableSongs[index];
                    return ListTile(
                      leading: SkeletonImage(
                        imageUrl: song.thumbnailUrl,
                        width: 48,
                        height: 48,
                        borderRadius: 8,
                      ),
                      title: Text(song.title, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Iconsax.add_circle, color: AppTheme.primaryColor),
                        onPressed: () async {
                          await ref.read(firestoreServiceProvider).addSongsToPlaylist(
                            currentPlaylist.id,
                            [song.id]
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added ${song.title}', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.primaryColor),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const PlaylistGridSkeleton(),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }
}
