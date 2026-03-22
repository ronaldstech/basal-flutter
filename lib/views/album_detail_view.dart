import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../models/music_models.dart';
import '../providers/audio_provider.dart';
import '../providers/firestore_provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
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
    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 220;
      if (shouldShow != _showTitle) {
        setState(() => _showTitle = shouldShow);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentAlbum.artist,
                          style: const TextStyle(color: Colors.white70, fontSize: 15),
                        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  GestureDetector(
                    onTap: () {
                      if (albumSongs.isEmpty) return;
                      final shuffled = List<Song>.from(albumSongs)..shuffle();
                      ref.read(audioProvider.notifier).playFromSongs(shuffled, shuffled.first);
                    },
                    child: const Icon(Iconsax.shuffle, color: Colors.white70, size: 28),
                  ),
                  const Icon(Iconsax.heart, color: Colors.white70, size: 28),
                  const Icon(Iconsax.more, color: Colors.white70, size: 28),
                ],
              ),
            ),
          ),
          songsAsync.when(
            data: (allSongs) {
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
                      leading: CircleAvatar(
                        backgroundColor: isCurrentSong
                            ? AppTheme.primaryColor.withOpacity(0.2)
                            : Colors.white12,
                        radius: 18,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isCurrentSong ? AppTheme.primaryColor : Colors.white54,
                          ),
                        ),
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
