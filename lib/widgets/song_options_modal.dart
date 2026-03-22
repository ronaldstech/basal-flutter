import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../models/music_models.dart';
import '../providers/firestore_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'add_to_playlist_modal.dart';
import 'download_modal.dart';

void showSongOptions(BuildContext context, Song song, {String? playlistId, bool isPlaylistOwner = false}) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white12),
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
                ListTile(
                  leading: const Icon(Iconsax.share, color: Colors.white),
                  title: const Text('Share', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Iconsax.import, color: Colors.white),
                  title: Row(
                    children: [
                      const Text('Download', style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('PREMIUM', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    final isPremium = ref.read(isPremiumProvider);
                    if (isPremium) {
                      showModalBottomSheet(
                        context: context,
                        useRootNavigator: true,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => DownloadModal(songs: [song]),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Downloads are for Premium members only'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Iconsax.music_playlist, color: Colors.white),
                  title: Text(playlistId != null ? 'Add to another playlist' : 'Add to playlist', style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => AddToPlaylistModal(songsToAdd: [song]),
                    );
                  },
                ),
                if (playlistId != null && isPlaylistOwner)
                  ListTile(
                    leading: const Icon(Iconsax.trash, color: Colors.redAccent),
                    title: const Text('Remove from playlist', style: TextStyle(color: Colors.redAccent)),
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(firestoreServiceProvider).removeSongFromPlaylist(playlistId, song.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed ${song.title}'), backgroundColor: Colors.redAccent));
                      }
                    },
                  ),
                const SafeArea(child: SizedBox(height: 16)),
              ],
            ),
          );
        },
      );
    },
  );
}
