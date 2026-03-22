import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import '../models/music_models.dart';
import '../providers/firestore_provider.dart';
import '../theme/app_theme.dart';
import '../views/playlist_detail_view.dart';
import '../widgets/skeleton_image.dart';
import '../widgets/home_skeleton.dart';

class AddToPlaylistModal extends ConsumerStatefulWidget {
  final List<Song> songsToAdd;

  const AddToPlaylistModal({super.key, required this.songsToAdd});

  @override
  ConsumerState<AddToPlaylistModal> createState() => _AddToPlaylistModalState();
}

class _AddToPlaylistModalState extends ConsumerState<AddToPlaylistModal> {
  final TextEditingController _playlistNameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _playlistNameController.dispose();
    super.dispose();
  }

  Future<void> _createNewPlaylist() async {
    final name = _playlistNameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      final songIds = widget.songsToAdd.map((s) => s.id).toList();
      final newPlaylist = await ref.read(firestoreServiceProvider).createPlaylist(name, songIds);
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistDetailView(playlist: newPlaylist)));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created playlist "$name"', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.primaryColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _addToExisting(Playlist playlist) async {
    try {
      final songIds = widget.songsToAdd.map((s) => s.id).toList();
      await ref.read(firestoreServiceProvider).addSongsToPlaylist(playlist.id, songIds);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to "${playlist.name}"', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.primaryColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _playlistNameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'My Awesome Playlist',
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              _createNewPlaylist();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // We get all playlists and filter to those created by user OR in their library.
    // For modifying, they usually must own it. We'll filter to createdBy == uid.
    final playlistsAsync = ref.watch(playlistsStreamProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add to Playlist', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                if (_isCreating)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Iconsax.add, color: Colors.white),
            ),
            title: const Text('New Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onTap: _showCreateDialog,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Divider(color: Colors.white12),
          ),
          Flexible(
            child: playlistsAsync.when(
              data: (playlists) {
                final userPlaylists = playlists.where((p) => p.creatorUid == uid).toList();
                if (userPlaylists.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Text('You have not created any playlists yet.', style: TextStyle(color: Colors.white54)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: userPlaylists.length,
                  itemBuilder: (context, index) {
                    final playlist = userPlaylists[index];
                    final hasSong = widget.songsToAdd.any((song) => playlist.songIds.contains(song.id));

                    return ListTile(
                      enabled: !hasSong,
                      leading: Opacity(
                        opacity: hasSong ? 0.4 : 1.0,
                        child: SkeletonImage(
                          imageUrl: playlist.imageUrl,
                          width: 50,
                          height: 50,
                          borderRadius: 4,
                          errorWidget: Container(
                            width: 50,
                            height: 50,
                            color: Colors.white12,
                            child: const Icon(Iconsax.music_playlist, color: Colors.white54),
                          ),
                        ),
                      ),
                      title: Text(playlist.name, style: TextStyle(color: hasSong ? Colors.white38 : Colors.white)),
                      subtitle: Text(hasSong ? 'Song already exists' : '${playlist.songIds.length} songs', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      onTap: hasSong ? null : () => _addToExisting(playlist),
                    );
                  },
                );
              },
              loading: () => const PlaylistGridSkeleton(),
              error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
            ),
          ),
          const SafeArea(child: SizedBox(height: 10)),
        ],
      ),
    );
  }
}
