import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/firestore_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../views/playlist_detail_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePlaylistDialog extends ConsumerStatefulWidget {
  const CreatePlaylistDialog({super.key});

  @override
  ConsumerState<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends ConsumerState<CreatePlaylistDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      final playlists = ref.read(playlistsStreamProvider).value ?? [];
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final userPlaylists = playlists.where((p) => p.creatorUid == uid).toList();
      
      if (userPlaylists.length >= 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Free members are limited to 3 playlists. Upgrade to Premium for unlimted!'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isCreating = true);
    try {
      final newPlaylist = await ref.read(firestoreServiceProvider).createPlaylist(name, []);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
      content: _isCreating 
          ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)))
          : TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'My Awesome Playlist',
                hintStyle: TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
              ),
            ),
      actions: _isCreating ? null : [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.black),
          onPressed: _create,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
