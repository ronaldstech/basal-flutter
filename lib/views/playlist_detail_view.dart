import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/skeleton_image.dart';
import '../widgets/home_skeleton.dart';
import 'package:iconsax/iconsax.dart';
import '../models/music_models.dart';
import '../providers/firestore_provider.dart';
import '../providers/audio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/download_modal.dart';
import '../widgets/song_options_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/playlist_add_songs_modal.dart';
import '../widgets/playlist_edit_songs_modal.dart';
import '../widgets/playlist_sort_modal.dart';
import '../widgets/playlist_edit_details_modal.dart';
import '../providers/auth_provider.dart';

class PlaylistDetailView extends ConsumerStatefulWidget {
  final Playlist playlist;

  const PlaylistDetailView({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistDetailView> createState() => _PlaylistDetailViewState();
}

class _PlaylistDetailViewState extends ConsumerState<PlaylistDetailView> {
  Widget _buildOwnerAction(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        avatar: Icon(icon, color: Colors.white, size: 16),
        label: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        onPressed: onTap,
      ),
    );
  }

  late ScrollController _scrollController;
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Track interaction for dynamic Home grid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(firestoreServiceProvider).touchPlaylist(widget.playlist.id);
    });
  }

  void _onScroll() {
    if (_scrollController.offset > 240 && !_showTitle) {
      setState(() => _showTitle = true);
    } else if (_scrollController.offset <= 240 && _showTitle) {
      setState(() => _showTitle = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _showDownloadModal(BuildContext context, List<Song> songs) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DownloadModal(songs: songs);
      },
    );
  }

  void _showPlaylistOptions(
      BuildContext context, List<Song> playlistSongs, bool isSaved) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                title:
                    const Text('Share', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Iconsax.import, color: Colors.white),
                title: Row(
                  children: [
                    const Text('Download',
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('PREMIUM',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  final isPremium = ref.read(isPremiumProvider);
                  if (isPremium) {
                    if (playlistSongs.isNotEmpty) {
                      _showDownloadModal(context, playlistSongs);
                    }
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
                leading: Icon(
                    isSaved ? Iconsax.tick_circle5 : Iconsax.add_circle,
                    color: Colors.white),
                title: Text(isSaved ? 'Remove from library' : 'Add to library',
                    style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(firestoreServiceProvider)
                      .updatePlaylistLibrary(widget.playlist.id, !isSaved);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isSaved ? 'Removed from Library' : 'Added to Library',
                        style: const TextStyle(color: Colors.white),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.grey[900],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.flag, color: Colors.white),
                title:
                    const Text('Report', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
              const SafeArea(child: SizedBox(height: 16)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsStreamProvider);
    final audioState = ref.watch(audioProvider);

    final playlistsAsync = ref.watch(playlistsStreamProvider);
    final currentPlaylist = playlistsAsync.valueOrNull?.firstWhere(
          (p) => p.id == widget.playlist.id,
          orElse: () => widget.playlist,
        ) ??
        widget.playlist;

    final libraryIds = ref.watch(userLibraryIdsProvider).valueOrNull ?? [];
    final isSaved = libraryIds.contains(currentPlaylist.id);

    final isCurrentPlaylistPlaying = audioState.currentSong != null &&
        currentPlaylist.songIds.contains(audioState.currentSong!.id);
    final isPlaying = isCurrentPlaylistPlaying && audioState.isPlaying;

    final allSongs = songsAsync.valueOrNull ?? [];
    final playlistSongs = currentPlaylist.songIds
        .map((id) {
          try {
            return allSongs.firstWhere((s) => s.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<Song>()
        .toList();

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            centerTitle: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: AnimatedOpacity(
              opacity: _showTitle ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                currentPlaylist.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  SkeletonImage(
                    imageUrl: currentPlaylist.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 0,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Theme.of(context)
                              .scaffoldBackgroundColor
                              .withOpacity(0.8),
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentPlaylist.name,
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Created by ${currentPlaylist.creatorName}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (currentPlaylist.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            currentPlaylist.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (playlistSongs.isEmpty) return;
                          if (isCurrentPlaylistPlaying) {
                            ref.read(audioProvider.notifier).togglePlay();
                          } else {
                            ref
                                .read(audioProvider.notifier)
                                .playFromSongs(playlistSongs, playlistSongs.first);
                          }
                        },
                        child: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          radius: 28,
                          child: Icon(isPlaying ? Iconsax.pause : Iconsax.play,
                              color: Colors.black, size: 30),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildOwnerAction(
                                context,
                                icon: isSaved ? Iconsax.tick_circle5 : Iconsax.add_circle,
                                label: isSaved ? 'Saved' : 'Library',
                                onTap: () {
                                  ref
                                      .read(firestoreServiceProvider)
                                      .updatePlaylistLibrary(currentPlaylist.id, !isSaved);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isSaved ? 'Removed from Library' : 'Added to Library',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: Colors.grey[900],
                                    ),
                                  );
                                },
                              ),
                              _buildOwnerAction(
                                context,
                                icon: Iconsax.import,
                                label: 'Download',
                                onTap: () {
                                  final isPremium = ref.read(isPremiumProvider);
                                  if (isPremium) {
                                    if (playlistSongs.isNotEmpty) {
                                      _showDownloadModal(context, playlistSongs);
                                    }
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
                              _buildOwnerAction(
                                context,
                                icon: Iconsax.more,
                                label: 'More',
                                onTap: () => _showPlaylistOptions(
                                    context, playlistSongs, isSaved),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (FirebaseAuth.instance.currentUser?.uid ==
                      currentPlaylist.creatorUid)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildOwnerAction(
                              context,
                              icon: Iconsax.add,
                              label: 'Add',
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  useRootNavigator: true,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => PlaylistAddSongsModal(
                                      playlist: currentPlaylist),
                                );
                              },
                            ),
                            _buildOwnerAction(
                              context,
                              icon: Iconsax.edit,
                              label: 'Edit',
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  useRootNavigator: true,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => PlaylistEditSongsModal(
                                      playlist: currentPlaylist),
                                );
                              },
                            ),
                            _buildOwnerAction(
                              context,
                              icon: Iconsax.sort,
                              label: 'Sort',
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  useRootNavigator: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => PlaylistSortModal(
                                      playlist: currentPlaylist,
                                      playlistSongs: playlistSongs),
                                );
                              },
                            ),
                            _buildOwnerAction(
                              context,
                              icon: Iconsax.edit_2,
                              label: 'Details & Cover',
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  useRootNavigator: true,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      PlaylistEditDetailsModal(
                                          playlist: currentPlaylist),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          songsAsync.when(
            data: (allSongs) {
              final playlistSongs = currentPlaylist.songIds
                  .map((id) {
                    try {
                      return allSongs.firstWhere((s) => s.id == id);
                    } catch (_) {
                      return null;
                    }
                  })
                  .whereType<Song>()
                  .toList();

              if (playlistSongs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text('No songs in this playlist yet.',
                          style: TextStyle(color: Colors.white38)),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = playlistSongs[index];
                    final isCurrentSong =
                        ref.watch(audioProvider).currentSong?.id == song.id;

                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 0),
                      leading: SkeletonImage(
                        imageUrl: song.thumbnailUrl,
                        width: 40,
                        height: 40,
                        borderRadius: 4,
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCurrentSong
                              ? AppTheme.primaryColor
                              : (ref.watch(isPremiumProvider) ? Colors.white : Colors.white38),
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: ref.watch(isPremiumProvider) ? Colors.white70 : Colors.white24,
                        ),
                      ),
                      trailing: isCurrentSong
                          ? Icon(Iconsax.volume_high,
                              color: AppTheme.primaryColor, size: 20)
                          : GestureDetector(
                              onTap: () => showSongOptions(
                                context,
                                song,
                                playlistId: currentPlaylist.id,
                                isPlaylistOwner: FirebaseAuth.instance.currentUser?.uid == currentPlaylist.creatorUid,
                              ),
                              child: const Icon(Iconsax.more,
                                  color: Colors.white54, size: 20),
                            ),
                      onTap: () {
                        if (ref.read(isPremiumProvider)) {
                          ref
                              .read(audioProvider.notifier)
                              .playFromSongs(playlistSongs, song);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Direct song selection is for Premium members. Use the Play button to start shuffle play.'),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          );
                        }
                      },
                    );
                  },
                  childCount: playlistSongs.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: HorizontalScrollSkeleton(height: 60, width: double.infinity),
              ),
            ),
            error: (e, st) => const SliverToBoxAdapter(
              child: Center(child: Text('Error loading songs')),
            ),
          ),
          const SliverToBoxAdapter(
              child: SizedBox(height: 120)), // Space for mini player
        ],
      ),
    );
  }
}
