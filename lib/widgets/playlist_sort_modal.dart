import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/music_models.dart';
import '../providers/firestore_provider.dart';

class PlaylistSortModal extends ConsumerWidget {
  final Playlist playlist;
  final List<Song> playlistSongs;

  const PlaylistSortModal({super.key, required this.playlist, required this.playlistSongs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            'Sort Playlist',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Title (A-Z)', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              final sorted = List<Song>.from(playlistSongs)..sort((a, b) => a.title.compareTo(b.title));
              final songIds = sorted.map((s) => s.id).toList();
              await ref.read(firestoreServiceProvider).updatePlaylistOrder(playlist.id, songIds);
            },
          ),
          ListTile(
            title: const Text('Artist (A-Z)', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              final sorted = List<Song>.from(playlistSongs)..sort((a, b) => a.artist.compareTo(b.artist));
              final songIds = sorted.map((s) => s.id).toList();
              await ref.read(firestoreServiceProvider).updatePlaylistOrder(playlist.id, songIds);
            },
          ),
          ListTile(
            title: const Text('Original Order', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom sort coming soon')));
            },
          ),
          const SafeArea(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
