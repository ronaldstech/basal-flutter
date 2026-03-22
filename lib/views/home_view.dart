import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_provider.dart';
import '../widgets/song_card.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../providers/firestore_provider.dart';
import 'playlist_detail_view.dart';
import 'album_detail_view.dart';
import '../widgets/profile_drawer.dart';
import '../widgets/home_skeleton.dart';
import '../widgets/skeleton_image.dart';
import 'package:iconsax/iconsax.dart';
import '../models/music_models.dart';
import '../widgets/banners_carousel.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsStreamProvider);
    final albumsAsync = ref.watch(albumsStreamProvider);
    final userPlaylistsAsync = ref.watch(dynamicUserPlaylistsProvider);

    return Scaffold(
      endDrawer: const ProfileDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _greeting(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Builder(builder: (context) {
                  return GestureDetector(
                    onTap: () => Scaffold.of(context).openEndDrawer(),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final user =
                            ref.watch(authRepositoryProvider).currentUser;
                        final unreadCount =
                            ref.watch(unreadNotificationsCountProvider).value ??
                                0;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.surfaceColor,
                              backgroundImage: user?.photoURL != null
                                  ? NetworkImage(user!.photoURL!)
                                  : null,
                              child: user?.photoURL == null
                                  ? const Icon(Iconsax.user,
                                      size: 18, color: Colors.white70)
                                  : null,
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        width: 2),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    unreadCount > 99
                                        ? '99+'
                                        : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banners Section
                  const BannersCarousel(),
                  const SizedBox(height: 32),

                  // Playlists Section
                  Text(
                    'Playlists Made for You',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  userPlaylistsAsync.when(
                    data: (playlists) {
                      final displayPlaylists = playlists.take(6).toList();
                      if (displayPlaylists.isEmpty)
                        return const SizedBox.shrink();

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.2,
                        ),
                        itemCount: displayPlaylists.length,
                        itemBuilder: (context, index) {
                          final playlist = displayPlaylists[index];
                          return InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PlaylistDetailView(playlist: playlist),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  SkeletonImage(
                                    imageUrl: playlist.imageUrl,
                                    height: 60,
                                    width: 50,
                                    borderRadius: 0,
                                    errorWidget: Container(
                                        width: 50,
                                        color: Colors.white12,
                                        child: const Icon(
                                            Iconsax.music_playlist,
                                            size: 20)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      playlist.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const PlaylistGridSkeleton(),
                    error: (e, st) => Text('Error: $e'),
                  ),

                  const SizedBox(height: 32),

                  // Recently Played (Real History)
                  Text(
                    'Recently Played',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ref.watch(recentlyPlayedSongsProvider).when(
                        data: (songs) =>
                            _buildSongHorizontal(ref, songs.take(6).toList()),
                        loading: () => const HorizontalScrollSkeleton(
                            height: 220, width: 160),
                        error: (e, st) => Text('Error: $e'),
                      ),

                  const SizedBox(height: 32),

                  // Listen Again Section
                  _buildSectionTitle(context, 'Listen Again'),
                  const SizedBox(height: 16),
                  ref.watch(likedSongsProvider).when(
                        data: (songs) =>
                            _buildSongHorizontal(ref, songs.take(10).toList()),
                        loading: () => const HorizontalScrollSkeleton(
                            height: 220, width: 160),
                        error: (e, st) => const SizedBox.shrink(),
                      ),

                  const SizedBox(height: 32),

                  // Made For You Section
                  _buildSectionTitle(context, 'Made For You'),
                  const SizedBox(height: 16),
                  ref.watch(dynamicDailyMixProvider).when(
                        data: (playlists) =>
                            _buildPlaylistHorizontal(context, playlists),
                        loading: () => const HorizontalScrollSkeleton(
                            height: 180, width: 140),
                        error: (e, st) => const SizedBox.shrink(),
                      ),

                  const SizedBox(height: 32),

                  // Recommended Radio Section
                  ref.watch(recommendedRadioProvider).when(
                        data: (songs) {
                          if (songs.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(context, 'Recommended Radio'),
                              const SizedBox(height: 8),
                              const Text('Similar to your recent favorites',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 13)),
                              const SizedBox(height: 16),
                              _buildSongHorizontal(ref, songs),
                              const SizedBox(height: 32),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (e, st) => const SizedBox.shrink(),
                      ),

                  // Trending Now Section
                  _buildSectionTitle(context, 'Trending Now'),
                  const SizedBox(height: 16),
                  ref.watch(trendingSongsProvider).when(
                        data: (songs) => _buildSongHorizontal(ref, songs),
                        loading: () => const HorizontalScrollSkeleton(
                            height: 220, width: 160),
                        error: (e, st) => const SizedBox.shrink(),
                      ),

                  const SizedBox(height: 32),

                  // New Releases Section
                  _buildSectionTitle(context, 'New Releases'),
                  const SizedBox(height: 16),
                  ref.watch(newReleasesProvider).when(
                        data: (songs) => _buildSongHorizontal(ref, songs),
                        loading: () => const HorizontalScrollSkeleton(
                            height: 220, width: 160),
                        error: (e, st) => const SizedBox.shrink(),
                      ),

                  const SizedBox(height: 32),

                  // Jump Back In (Latest Track)
                  ref.watch(recentlyPlayedSongsProvider).when(
                        data: (songs) {
                          if (songs.isEmpty) return const SizedBox.shrink();
                          final latest = songs.first;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(context, 'Jump Back In'),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => ref
                                    .read(audioProvider.notifier)
                                    .playSong(latest),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF1DB954).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color:
                                            Color(0xFF1DB954).withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      SkeletonImage(
                                        imageUrl: latest.thumbnailUrl,
                                        width: 60,
                                        height: 60,
                                        borderRadius: 8,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              latest.title,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                            Text(
                                              latest.artist,
                                              style: const TextStyle(
                                                  color: Colors.white54),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Iconsax.play5,
                                          color: Color(0xFF1DB954), size: 32),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (e, st) => const SizedBox.shrink(),
                      ),

                  // Top Artists Section
                  _buildSectionTitle(context, 'Top Artists'),
                  const SizedBox(height: 16),
                  ref.watch(topArtistsProvider).when(
                        data: (artists) =>
                            _buildArtistHorizontal(context, artists),
                        loading: () => const HorizontalScrollSkeleton(
                            height: 140, width: 100, isCircle: true),
                        error: (e, st) => const SizedBox.shrink(),
                      ),

                  const SizedBox(height: 32),

                  // Featured Artists (from Firestore)
                  Text(
                    'Featured Artists',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  artistsAsync.when(
                    data: (artists) => SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: artists.length,
                        itemBuilder: (context, index) {
                          final artist = artists[index];
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                SkeletonImage(
                                  imageUrl: artist.imageUrl,
                                  width: 80,
                                  height: 80,
                                  shape: BoxShape.circle,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  artist.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    loading: () => const HorizontalScrollSkeleton(
                        height: 140, width: 100, isCircle: true),
                    error: (e, st) => Text('Error: $e'),
                  ),

                  const SizedBox(height: 32),

                  // Popular Albums (from Firestore)
                  Text(
                    'Popular Albums',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  albumsAsync.when(
                    data: (albums) => SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: albums.length,
                        itemBuilder: (context, index) {
                          final album = albums[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AlbumDetailView(album: album),
                              ),
                            ),
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SkeletonImage(
                                    imageUrl: album.imageUrl,
                                    height: 130,
                                    width: 140,
                                    borderRadius: 12,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    album.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    album.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.white54),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    loading: () =>
                        const HorizontalScrollSkeleton(height: 180, width: 140),
                    error: (e, st) => Text('Error: $e'),
                  ),

                  const SizedBox(height: 32),

                  // Mood Mixes Section
                  _buildSectionTitle(context, 'Mood Mixes'),
                  const SizedBox(height: 16),
                  ref.watch(moodMixesProvider).when(
                        data: (playlists) =>
                            _buildPlaylistHorizontal(context, playlists),
                        loading: () => const HorizontalScrollSkeleton(
                            height: 180, width: 140),
                        error: (e, st) => const SizedBox.shrink(),
                      ),

                  const SizedBox(height: 32),

                  // Top Charts Section
                  _buildSectionTitle(context, 'Top Charts'),
                  const SizedBox(height: 16),
                  ref.watch(topChartsProvider).when(
                        data: (playlists) =>
                            _buildPlaylistHorizontal(context, playlists),
                        loading: () => const HorizontalScrollSkeleton(
                            height: 180, width: 140),
                        error: (e, st) => const SizedBox.shrink(),
                      ),
                  const SizedBox(height: 32),

                  // Podcast Highlights Section
                  _buildSectionTitle(context, 'Podcast Highlights'),
                  const SizedBox(height: 16),
                  ref.watch(podcastProvider).when(
                        data: (podcasts) => _buildPlaylistHorizontal(
                            context, podcasts,
                            isPodcast: true),
                        loading: () => const HorizontalScrollSkeleton(
                            height: 180, width: 140),
                        error: (e, st) => const SizedBox.shrink(),
                      ),

                  const SizedBox(height: 32),

                  // Live Radio Section
                  _buildSectionTitle(context, 'Live Radio'),
                  const SizedBox(height: 16),
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1DB954).withOpacity(0.2),
                          Colors.black26
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.radio,
                            color: Color(0xFF1DB954), size: 32),
                        const SizedBox(width: 16),
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Basal Live Fm',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('24/7 curated beats',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistHorizontal(BuildContext context, List<Artist> artists) {
    if (artists.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                SkeletonImage(
                  imageUrl: artist.imageUrl,
                  width: 80,
                  height: 80,
                  shape: BoxShape.circle,
                ),
                const SizedBox(height: 8),
                Text(
                  artist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildSongHorizontal(WidgetRef ref, List<Song> songs) {
    if (songs.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return SongCard(
            song: song,
            onTap: () => ref.read(audioProvider.notifier).playSong(song),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistHorizontal(
      BuildContext context, List<Playlist> playlists,
      {bool isPodcast = false}) {
    if (playlists.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaylistDetailView(playlist: playlist),
              ),
            ),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonImage(
                    imageUrl: playlist.imageUrl,
                    height: 130,
                    width: 140,
                    borderRadius: 12,
                    errorWidget: Container(
                      width: 140,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Iconsax.music_playlist, size: 40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${isPodcast ? 'Podcast' : 'Playlist'} • ${playlist.creatorName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref, String message) {
    return Center(
      child: Column(
        children: [
          Text(message, style: const TextStyle(color: Colors.white38)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () =>
                    ref.read(firestoreServiceProvider).populateWithMockData(),
                child: const Text('Populate Mock'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () =>
                    ref.read(firestoreServiceProvider).normalizeSongs(),
                child: const Text('Normalize Existing'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 5) {
      const phrases = [
        'Still up? 🌙',
        'Burning the midnight oil',
        'Night owl vibes',
        'Late night session',
        'Can\'t sleep? Let\'s listen',
      ];
      return phrases[DateTime.now().second % phrases.length];
    } else if (hour < 9) {
      const phrases = [
        'Rise and shine ☀️',
        'Good early morning',
        'Start your day right',
        'Morning energy',
        'Early bird gets the beats',
      ];
      return phrases[DateTime.now().second % phrases.length];
    } else if (hour < 12) {
      const phrases = [
        'Good morning ☀️',
        'Morning vibes',
        'Ready for the day?',
        'Morning, let\'s go!',
        'Have a great morning',
      ];
      return phrases[DateTime.now().second % phrases.length];
    } else if (hour < 14) {
      const phrases = [
        'Good afternoon',
        'Midday beats 🎵',
        'Afternoon session',
        'Keeping you going',
        'Lunchtime tunes',
      ];
      return phrases[DateTime.now().second % phrases.length];
    } else if (hour < 17) {
      const phrases = [
        'Afternoon vibes',
        'Powering through',
        'Almost there 🎶',
        'Keep the energy up',
        'Afternoon groove',
      ];
      return phrases[DateTime.now().second % phrases.length];
    } else if (hour < 20) {
      const phrases = [
        'Good evening 🌇',
        'Evening groove',
        'Unwind time',
        'Time to relax 🎵',
        'Evening session',
      ];
      return phrases[DateTime.now().second % phrases.length];
    } else {
      const phrases = [
        'Good night 🌙',
        'Wind down mode',
        'Chill night vibes',
        'Night session',
        'Stars & good music ✨',
      ];
      return phrases[DateTime.now().second % phrases.length];
    }
  }
}
