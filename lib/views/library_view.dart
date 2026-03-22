import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/home_skeleton.dart';
import '../widgets/skeleton_image.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/firestore_provider.dart';
import 'playlist_detail_view.dart';
import '../widgets/profile_drawer.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LibraryView extends ConsumerWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryPlaylistsAsync = ref.watch(userLibraryPlaylistsProvider);

    return Scaffold(
      endDrawer: const ProfileDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Library',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                  ),
                  Builder(
                    builder: (context) {
                      return GestureDetector(
                        onTap: () => Scaffold.of(context).openEndDrawer(),
                        child: Consumer(
                          builder: (context, ref, child) {
                            final user = ref.watch(authRepositoryProvider).currentUser;
                            final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.surfaceColor,
                                  backgroundImage: user?.photoURL != null 
                                    ? NetworkImage(user!.photoURL!) 
                                    : null,
                                  child: user?.photoURL == null 
                                    ? const Icon(Iconsax.user, size: 18, color: Colors.white70)
                                    : null,
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context).scaffoldBackgroundColor, 
                                          width: 2
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
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
                    }
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: libraryPlaylistsAsync.when(
                  data: (playlists) {
                    if (playlists.isEmpty) {
                      return const Center(
                        child: Text(
                          'Your library is empty.\nAdd playlists to see them here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, fontSize: 16),
                        ),
                      );
                    }
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
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
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SkeletonImage(
                                    imageUrl: playlist.imageUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    borderRadius: 12,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        playlist.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Playlist • ${playlist.creatorName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                                      ),
                                    ],
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
                  error: (e, st) => const Center(child: Text('Error loading library')),
                ),
              ),
              const SizedBox(height: 100), // Space for mini player
            ],
          ),
        ),
      ),
    );
  }
}
