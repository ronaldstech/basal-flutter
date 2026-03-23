import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../models/music_models.dart';
import '../providers/audio_provider.dart';
import '../providers/firestore_provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/download_modal.dart';
import '../widgets/song_options_modal.dart';
import '../widgets/skeleton_image.dart';
import '../widgets/home_skeleton.dart';


class AlbumDetailView extends ConsumerStatefulWidget {
  final Album album;

  const AlbumDetailView({super.key, required this.album});

  @override
  ConsumerState<AlbumDetailView> createState() => _AlbumDetailViewState();
}

class _AlbumDetailViewState extends ConsumerState<AlbumDetailView> {
  late ScrollController _scrollController;
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
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

  Widget _buildAction(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        avatar: Icon(icon, color: iconColor ?? Colors.white, size: 16),
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

  void _showAlbumOptions(
      BuildContext context, List<Song> albumSongs, bool isSaved) {
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
                    if (albumSongs.isNotEmpty) {
                      _showDownloadModal(context, albumSongs);
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
                      .updateAlbumLibrary(widget.album.id, !isSaved);
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

    // Watch for live updates by re-matching the album from the stream
    final albumsAsync = ref.watch(albumsStreamProvider);
    final currentAlbum = albumsAsync.valueOrNull?.firstWhere(
          (a) => a.id == widget.album.id,
          orElse: () => widget.album,
        ) ??
        widget.album;

    final libraryAlbumIds = ref.watch(userLibraryAlbumIdsProvider).valueOrNull ?? [];
    final isSaved = libraryAlbumIds.contains(currentAlbum.id);

    final allSongs = songsAsync.valueOrNull ?? [];
    final albumSongs = currentAlbum.songIds
        .map((id) {
          try {
            return allSongs.firstWhere((s) => s.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<Song>()
        .toList();

    final isCurrentAlbumPlaying = audioState.currentSong != null &&
        currentAlbum.songIds.contains(audioState.currentSong!.id);
    final isPlaying = isCurrentAlbumPlaying && audioState.isPlaying;

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
                currentAlbum.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  SkeletonImage(
                    imageUrl: currentAlbum.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 0,
                    errorWidget: Container(
                      color: AppTheme.surfaceColor,
                      child: const Icon(Iconsax.music, size: 80, color: Colors.white24),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
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
                          currentAlbum.title,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Album • ${currentAlbum.artist}',
                          style: const TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        if (currentAlbum.createdBy.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Uploaded by ${currentAlbum.createdBy}',
                            style: const TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${albumSongs.length} songs',
                          style: const TextStyle(color: Colors.white38, fontSize: 13),
                        ),
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
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (albumSongs.isEmpty) return;
                      if (isCurrentAlbumPlaying) {
                        ref.read(audioProvider.notifier).togglePlay();
                      } else {
                        ref.read(audioProvider.notifier).playFromSongs(albumSongs, albumSongs.first);
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      radius: 28,
                      child: Icon(
                        isPlaying ? Iconsax.pause : Iconsax.play,
                        color: Colors.black,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildAction(
                            context,
                            icon: isSaved ? Iconsax.tick_circle5 : Iconsax.add_circle,
                            label: isSaved ? 'Saved' : 'Library',
                            onTap: () {
                              ref
                                  .read(firestoreServiceProvider)
                                  .updateAlbumLibrary(currentAlbum.id, !isSaved);
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
                          _buildAction(
                            context,
                            icon: Iconsax.shuffle,
                            label: 'Shuffle',
                            onTap: () {
                              if (albumSongs.isEmpty) return;
                              final shuffled = List<Song>.from(albumSongs)..shuffle();
                              ref.read(audioProvider.notifier).playFromSongs(shuffled, shuffled.first);
                            },
                          ),
                          _buildAction(
                            context,
                            icon: Iconsax.import,
                            label: 'Download',
                            onTap: () {
                              final isPremium = ref.read(isPremiumProvider);
                              if (isPremium) {
                                if (albumSongs.isNotEmpty) {
                                  _showDownloadModal(context, albumSongs);
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
                          _buildAction(
                            context,
                            icon: Iconsax.more,
                            label: 'More',
                            onTap: () => _showAlbumOptions(context, albumSongs, isSaved),
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
              if (albumSongs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text(
                        'No songs found for this album.',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = albumSongs[index];
                    final isCurrentSong =
                        ref.watch(audioProvider).currentSong?.id == song.id;

                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
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
                          color: isCurrentSong ? AppTheme.primaryColor : (ref.watch(isPremiumProvider) ? Colors.white : Colors.white38),
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
                          ? Icon(Iconsax.volume_high, color: AppTheme.primaryColor, size: 20)
                          : GestureDetector(
                              onTap: () => showSongOptions(context, song),
                              child: const Icon(Iconsax.more, color: Colors.white54, size: 20),
                            ),
                      onTap: () {
                        if (ref.read(isPremiumProvider)) {
                          ref.read(audioProvider.notifier).playFromSongs(albumSongs, song);
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
                  childCount: albumSongs.length,
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
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

